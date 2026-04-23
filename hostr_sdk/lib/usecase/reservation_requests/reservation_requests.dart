import 'package:crypto/crypto.dart' as crypto;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../relays/relays.dart';
import '../reservations/reservation_pubkey_proofs.dart';
import '../trade_account_allocator/trade_account_allocator.dart';

/// Use-case for creating negotiate-stage [Reservation] events (formerly
/// "reservation requests"). The class name is kept for DI compatibility but
/// now produces [Reservation] instances with `stage = negotiate`.
@Singleton()
class ReservationRequests extends CrudUseCase {
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  final Relays _relays;
  ReservationRequests({
    required super.requests,
    required super.logger,
    required Auth auth,
    required TradeAccountAllocator tradeAccountAllocator,
    required Relays relays,
  }) : _auth = auth,
       _tradeAccountAllocator = tradeAccountAllocator,
       _relays = relays,
       super(kind: Reservation.kinds[0]);

  Future<Reservation> _signReservation({
    required Reservation reservation,
    required KeyPair signerKeyPair,
  }) async {
    final activeNdkPubkey = requests.ndk.accounts.getPublicKey();
    if (activeNdkPubkey == signerKeyPair.publicKey) {
      return Reservation.fromNostrEvent(
        await requests.ndk.accounts.sign(reservation),
      );
    }

    return reservation.signAs(signerKeyPair, Reservation.fromNostrEvent);
  }

  static String getReservationRequestId({
    required Listing listing,
    required Reservation request,
  }) {
    final hash = crypto.sha256.convert(request.toString().codeUnits);
    return '${listing.anchor}/${hash.bytes}';
  }

  /// Creates a negotiate-stage [Reservation] (replaces the old
  /// `createReservationRequest`). The returned event is a full [Reservation]
  /// with `stage = negotiate` and a `commit` object.
  ///
  /// The `recipient` field is automatically set to the deterministic
  /// trade pubkey allocated for this trade.
  Future<Reservation> createReservationRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    DenominatedAmount? amount,
  }) => logger.span('createReservationRequest', () async {
    final accountIndex = await _tradeAccountAllocator.reserveNextTradeIndex();
    final nonce = await _auth.hd.getTradeId(accountIndex: accountIndex);

    logger.d(
      'Creating negotiate reservation with deterministic tradeId $nonce '
      'at account index $accountIndex',
    );

    final recipientKey = await _auth.hd.getTradeKeyPair(
      accountIndex: accountIndex,
    );

    // Sign and publish with the disposable trade key, but attach an encrypted
    // proof from the real buyer key for authorized recipients.
    final reservation = Reservation.create(
      pubKey: recipientKey.publicKey,
      dTag: nonce,
      listingAnchor: listing.anchor!,
      start: startDate,
      end: endDate,
      stage: ReservationStage.negotiate,
      quantity: 1,
      amount: amount ?? listing.cost(start: startDate, end: endDate),
      recipient: recipientKey.publicKey,
      pTags: [
        PTag.seller(
          getPubKeyFromAnchor(listing.anchor!),
          relayHint: await _relays.relayHintFor(
            getPubKeyFromAnchor(listing.anchor!),
          ),
        ),
        PTag.buyer(
          recipientKey.publicKey,
          relayHint: await _relays.relayHintFor(recipientKey.publicKey),
        ),
      ],
    );
    final withBuyerProof = await reservation.attachPubkeyProof(
      role: 'buyer',
      proofKeyPair: _auth.getActiveKey(),
      encryptionKeyPair: recipientKey,
      signAuthorization:
          requests.ndk.accounts.getPublicKey() == _auth.getActiveKey().publicKey
          ? (unsignedEvent) => requests.ndk.accounts.sign(unsignedEvent)
          : null,
    );
    return _signReservation(
      reservation: withBuyerProof,
      signerKeyPair: recipientKey,
    );
  });

  Future<Reservation> createCounterOffer({
    required Listing listing,
    required Reservation previousRequest,
    required DenominatedAmount amount,
    required KeyPair signerKeyPair,
  }) => logger.span('createCounterOffer', () async {
    final listingAnchor = previousRequest.parsedTags.listingAnchor;

    var counterOffer = Reservation.create(
      pubKey: signerKeyPair.publicKey,
      dTag: previousRequest.getDtag()!,
      listingAnchor: listingAnchor,
      threadAnchor: previousRequest.getFirstTag(kThreadRefTag),
      start: previousRequest.start,
      end: previousRequest.end,
      stage: ReservationStage.negotiate,
      quantity: previousRequest.quantity,
      amount: amount,
      recipient: previousRequest.recipient,
      pTags: [
        PTag.seller(
          getPubKeyFromAnchor(listingAnchor),
          relayHint: await _relays.relayHintFor(
            getPubKeyFromAnchor(listingAnchor),
          ),
        ),
        PTag.buyer(
          signerKeyPair.publicKey == getPubKeyFromAnchor(listingAnchor)
              ? previousRequest.pubKey
              : signerKeyPair.publicKey,
          relayHint: await _relays.relayHintFor(
            signerKeyPair.publicKey == getPubKeyFromAnchor(listingAnchor)
                ? previousRequest.pubKey
                : signerKeyPair.publicKey,
          ),
        ),
      ],
    );

    if (signerKeyPair.publicKey == getPubKeyFromAnchor(listingAnchor)) {
      final unsignedCommitAuthorization = CommitAuthorization.create(
        pubKey: signerKeyPair.publicKey,
        listingAnchor: listingAnchor,
        tradeId: previousRequest.getDtag()!,
        commitHash: counterOffer.commitHash(),
      );
      final activeNdkPubkey = requests.ndk.accounts.getPublicKey();
      final signedCommitAuthorization =
          activeNdkPubkey == signerKeyPair.publicKey
          ? CommitAuthorization.fromNostrEvent(
              await requests.ndk.accounts.sign(unsignedCommitAuthorization),
            )
          : unsignedCommitAuthorization.signAs(
              signerKeyPair,
              CommitAuthorization.fromNostrEvent,
            );
      counterOffer = counterOffer.copy(
        content: counterOffer.parsedContent.copyWith(
          commitAuthorization: signedCommitAuthorization,
        ),
      );
    } else {
      counterOffer = await counterOffer.attachPubkeyProof(
        role: 'buyer',
        proofKeyPair: _auth.getActiveKey(),
        encryptionKeyPair: signerKeyPair,
        signAuthorization:
            requests.ndk.accounts.getPublicKey() ==
                _auth.getActiveKey().publicKey
            ? (unsignedEvent) => requests.ndk.accounts.sign(unsignedEvent)
            : null,
      );
    }

    return _signReservation(
      reservation: counterOffer,
      signerKeyPair: signerKeyPair,
    );
  });

  Future<Reservation> createCancellation({
    required Reservation previousRequest,
    required KeyPair signerKeyPair,
  }) => logger.span('createCancellation', () async {
    final cancellation = previousRequest.copy(
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      id: null,
      pubKey: signerKeyPair.publicKey,
      content: previousRequest.parsedContent.copyWith(
        stage: ReservationStage.cancel,
      ),
    );

    return _signReservation(
      reservation: cancellation,
      signerKeyPair: signerKeyPair,
    );
  });
}
