import 'package:crypto/crypto.dart' as crypto;
import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/coinlib_gift_wrap.dart';
import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../relays/relays.dart';
import '../orders/order_participant_tags.dart';
import '../trade_account_allocator/trade_account_allocator.dart';

/// Use-case for creating negotiate-stage [Order] events (formerly
/// "order requests"). The class name is kept for DI compatibility but
/// now produces [Order] instances with `stage = negotiate`.
@Singleton()
class OrderRequests extends CrudUseCase<Order> {
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  final Relays _relays;
  OrderRequests({
    required super.requests,
    required super.logger,
    required Auth auth,
    required TradeAccountAllocator tradeAccountAllocator,
    required Relays relays,
  }) : _auth = auth,
       _tradeAccountAllocator = tradeAccountAllocator,
       _relays = relays,
       super(kind: Order.kinds[0]);

  @override
  Future<void> beforeUpsert(Order event) async {
    if (event.stage == OrderStage.negotiate) {
      throw StateError(
        'Negotiate-stage orders must be sent as private messages, not broadcast.',
      );
    }
  }

  Future<Order> _signOrder({
    required Order order,
    required KeyPair signerKeyPair,
  }) async {
    final activeNdkPubkey = requests.ndk.accounts.getPublicKey();
    if (activeNdkPubkey == signerKeyPair.publicKey) {
      return Order.fromNostrEvent(await requests.ndk.accounts.sign(order));
    }

    return order.signAs(signerKeyPair, Order.fromNostrEvent);
  }

  Future<String> _signParticipantAuthorization({
    required String listingAnchor,
    required KeyPair identityKeyPair,
    required OrderParticipantAuthorizationDraft draft,
  }) async {
    if (draft.identityPubkey != identityKeyPair.publicKey) {
      throw StateError(
        'Participant authorization identity must match the signer key',
      );
    }

    final authorization = TradeKeyAuthorization.create(
      identityPubkey: draft.identityPubkey,
      listingAnchor: listingAnchor,
      tradeId: draft.tradeId,
      participantPubkey: draft.participantPubkey,
      role: draft.role,
    );
    final activeNdkPubkey = requests.ndk.accounts.getPublicKey();
    final signedAuthorization = activeNdkPubkey == identityKeyPair.publicKey
        ? TradeKeyAuthorization.fromNostrEvent(
            await requests.ndk.accounts.sign(authorization),
          )
        : authorization.signAs(
            identityKeyPair,
            TradeKeyAuthorization.fromNostrEvent,
          );
    return OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
      signedAuthorization,
    ).encode();
  }

  static String getOrderRequestId({
    required Listing listing,
    required Order request,
  }) {
    final hash = crypto.sha256.convert(request.toString().codeUnits);
    return '${listing.anchor}/${hash.bytes}';
  }

  /// Creates a negotiate-stage [Order] (replaces the old
  /// `createOrderRequest`). The returned event is a full [Order]
  /// with `stage = negotiate` and a `commit` object.
  ///
  /// The `recipient` field is automatically set to the deterministic
  /// trade pubkey allocated for this trade.
  Future<Order> createOrderRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    DenominatedAmount? amount,
  }) => logger.span('createOrderRequest', () async {
    final accountIndex = await _tradeAccountAllocator.reserveNextTradeIndex();
    final nonce = await _auth.hd.getTradeId(accountIndex: accountIndex);

    logger.d(
      'Creating negotiate order with deterministic tradeId $nonce '
      'at account index $accountIndex',
    );

    final recipientKey = await _auth.hd.getTradeKeyPair(
      accountIndex: accountIndex,
    );

    final sellerPubkey = getPubKeyFromAnchor(listing.anchor!);
    final participantTags = await buildOrderParticipantTagPlan(
      tradeId: nonce,
      orderAuthorKey: recipientKey,
      participants: [
        OrderParticipant.real(role: 'seller', pubkey: sellerPubkey),
        OrderParticipant(
          role: 'buyer',
          participantPubkey: recipientKey.publicKey,
          identityPubkey: _auth.getActiveKey().publicKey,
        ),
      ],
      relayHintFor: _relays.relayHintFor,
      signAuthorization: (draft) => _signParticipantAuthorization(
        listingAnchor: listing.anchor!,
        identityKeyPair: _auth.getActiveKey(),
        draft: draft,
      ),
      encryptAuthorization:
          ({
            required plaintext,
            required senderPrivateKey,
            required recipientPubkey,
          }) =>
              coinlibEncryptNip44(plaintext, senderPrivateKey, recipientPubkey),
    );

    // Sign and publish with the disposable trade key, but attach encrypted
    // participant proofs from the real buyer key for every participant.
    final order = Order.create(
      pubKey: recipientKey.publicKey,
      dTag: nonce,
      listingAnchor: listing.anchor!,
      start: startDate,
      end: endDate,
      stage: OrderStage.negotiate,
      quantity: 1,
      amount: amount ?? listing.cost(start: startDate, end: endDate),
      recipient: recipientKey.publicKey,
      extraTags: participantTags.tags,
    );
    return _signOrder(order: order, signerKeyPair: recipientKey);
  });

  Future<Order> createCounterOffer({
    required Listing listing,
    required Order previousRequest,
    required DenominatedAmount amount,
    required KeyPair signerKeyPair,
  }) => logger.span('createCounterOffer', () async {
    final listingAnchor = previousRequest.parsedTags.listingAnchor;

    final sellerPubkey = getPubKeyFromAnchor(listingAnchor);
    final buyerPubkey = signerKeyPair.publicKey == sellerPubkey
        ? previousRequest.pubKey
        : signerKeyPair.publicKey;
    final participantTags = await buildOrderParticipantTagPlan(
      tradeId: previousRequest.getDtag()!,
      orderAuthorKey: signerKeyPair,
      participants: [
        OrderParticipant.real(role: 'seller', pubkey: sellerPubkey),
        signerKeyPair.publicKey == sellerPubkey
            ? OrderParticipant.real(role: 'buyer', pubkey: buyerPubkey)
            : OrderParticipant(
                role: 'buyer',
                participantPubkey: buyerPubkey,
                identityPubkey: _auth.getActiveKey().publicKey,
              ),
      ],
      relayHintFor: _relays.relayHintFor,
      signAuthorization: (draft) => _signParticipantAuthorization(
        listingAnchor: listingAnchor,
        identityKeyPair: _auth.getActiveKey(),
        draft: draft,
      ),
      encryptAuthorization:
          ({
            required plaintext,
            required senderPrivateKey,
            required recipientPubkey,
          }) =>
              coinlibEncryptNip44(plaintext, senderPrivateKey, recipientPubkey),
    );

    var counterOffer = Order.create(
      pubKey: signerKeyPair.publicKey,
      dTag: previousRequest.getDtag()!,
      listingAnchor: listingAnchor,
      start: previousRequest.start,
      end: previousRequest.end,
      stage: OrderStage.negotiate,
      quantity: previousRequest.quantity,
      amount: amount,
      recipient: previousRequest.recipient,
      extraTags: participantTags.tags,
    );

    if (signerKeyPair.publicKey == sellerPubkey) {
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
    }

    return _signOrder(order: counterOffer, signerKeyPair: signerKeyPair);
  });

  Future<Order> createCancellation({
    required Order previousRequest,
    required KeyPair signerKeyPair,
  }) => logger.span('createCancellation', () async {
    final cancellation = previousRequest.copy(
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      id: null,
      pubKey: signerKeyPair.publicKey,
      content: previousRequest.parsedContent.copyWith(stage: OrderStage.cancel),
    );

    return _signOrder(order: cancellation, signerKeyPair: signerKeyPair);
  });
}
