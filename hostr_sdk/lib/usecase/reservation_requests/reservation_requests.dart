import 'package:crypto/crypto.dart' as crypto;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../trade_account_allocator/trade_account_allocator.dart';

/// Use-case for creating negotiate-stage [Reservation] events (formerly
/// "reservation requests"). The class name is kept for DI compatibility but
/// now produces [Reservation] instances with `stage = negotiate`.
@Singleton()
class ReservationRequests extends CrudUseCase {
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  ReservationRequests({
    required super.requests,
    required super.logger,
    required Auth auth,
    required TradeAccountAllocator tradeAccountAllocator,
  }) : _auth = auth,
       _tradeAccountAllocator = tradeAccountAllocator,
       super(kind: Reservation.kinds[0]);

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
  /// The `recipient` field is automatically set to the tweaked public
  /// key derived from the active user's private key and the generated salt.
  /// This allows later review verification via [ParticipationProof].
  Future<Reservation> createReservationRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    Amount? amount,
  }) => logger.span('createReservationRequest', () async {
    final accountIndex = await _tradeAccountAllocator.reserveNextTradeIndex();
    final nonce = await _auth.hd.getTradeId(accountIndex: accountIndex);
    final salt = await _auth.hd.getTradeSalt(accountIndex: accountIndex);

    logger.d(
      'Creating negotiate reservation with deterministic tradeId $nonce '
      'at account index $accountIndex',
    );

    final recipientKey = tweakKeyPair(
      privateKey: _auth.getActiveKey().privateKey!,
      salt: salt,
    );
    final tweakMaterial = ReservationTweakMaterial(
      salt: salt,
      parity: recipientKey.parity,
    );

    // should sign as temp key
    return Reservation.create(
      pubKey: recipientKey.publicKey,
      dTag: nonce,
      listingAnchor: listing.anchor!,
      start: startDate,
      end: endDate,
      stage: ReservationStage.negotiate,
      quantity: 1,
      amount: amount ?? listing.cost(startDate, endDate),
      tweakMaterial: tweakMaterial,
      recipient: recipientKey.publicKey,
    ).signAs(recipientKey.keyPair, Reservation.fromNostrEvent);
  });

  Future<Reservation> createCounterOffer({
    required Listing listing,
    required Reservation previousRequest,
    required Amount amount,
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
      tweakMaterial: previousRequest.tweakMaterial,
      recipient: previousRequest.recipient,
    );

    if (signerKeyPair.publicKey == getPubKeyFromAnchor(listingAnchor)) {
      counterOffer = counterOffer.copy(
        content: counterOffer.parsedContent.copyWith(
          signatures: {
            signerKeyPair.publicKey: counterOffer.signCommit(signerKeyPair),
          },
        ),
      );
    }

    return counterOffer.signAs(signerKeyPair, Reservation.fromNostrEvent);
  });
}
