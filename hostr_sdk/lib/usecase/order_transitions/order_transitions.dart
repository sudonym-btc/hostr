import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/main.dart';
import '../crud.usecase.dart';

/// CRUD use-case for append-only [OrderTransition] events.
///
/// Every order stage change (negotiate ↔ counter-offer, negotiate →
/// commit, * → cancel, seller-ack) MUST be recorded as a transition so
/// relays and auditing clients can reconstruct the full history.
@Singleton()
class OrderTransitions extends CrudUseCase<OrderTransition> {
  final Ndk _ndk;

  OrderTransitions({
    required super.requests,
    required super.logger,
    required Ndk ndk,
  }) : _ndk = ndk,
       super(kind: OrderTransition.kinds[0]);

  /// Broadcast a transition event and return it.
  ///
  /// [order]       — the order being transitioned.
  /// [transitionType]    — what kind of transition this is.
  /// [fromStage]         — the stage before the transition.
  /// [toStage]           — the stage after the transition.
  /// [commitTermsHash]   — the commit-terms hash at the time of transition.
  /// [reason]            — optional human-readable note (e.g. cancellation reason).
  /// [updatedFields]     — snapshot of changed fields for counter-offers.
  /// [prevTransitionId]  — event id of the previous transition in the chain.
  Future<OrderTransition> record({
    required Order order,
    required OrderTransitionType transitionType,
    required OrderStage fromStage,
    required OrderStage toStage,
    KeyPair? signerKeyPair,
    String? commitTermsHash,
    String? reason,
    Map<String, dynamic>? updatedFields,
    String? prevTransitionId,
  }) async {
    final tradeId = order.getDtag() ?? '';
    final privateKey = signerKeyPair?.privateKey;
    final pubkey = privateKey != null && privateKey.isNotEmpty
        ? signerKeyPair!.publicKey
        : _ndk.accounts.getPublicKey()!;
    final effectivePrevTransitionId =
        prevTransitionId ??
        await _resolvePreviousTransitionId(tradeId: tradeId, pubkey: pubkey);
    final tags = <List<String>>[
      if (tradeId.isNotEmpty) ['d', tradeId],
      if (tradeId.isNotEmpty) ['t', tradeId],
      ['e', order.id],
      if (effectivePrevTransitionId != null)
        ['prev', effectivePrevTransitionId],
      if (order.parsedTags.listingAnchor.isNotEmpty)
        [kListingRefTag, order.parsedTags.listingAnchor],
    ];

    final unsigned = Nip01Event(
      kind: kNostrKindOrderTransition,
      pubKey: pubkey,
      tags: tags,
      content: OrderTransitionContent(
        transitionType: transitionType,
        fromStage: fromStage,
        toStage: toStage,
        commitTermsHash: commitTermsHash ?? order.commitHash(),
        reason: reason,
        updatedFields: updatedFields,
      ).toString(),
    );
    final transition = OrderTransition.fromNostrEvent(unsigned);
    final result = await upsert(
      transition,
      signer: privateKey != null && privateKey.isNotEmpty
          ? (event) async => Nip01Utils.signWithPrivateKey(
              event: event,
              privateKey: privateKey,
            )
          : null,
    );
    return result.event;
  }

  Future<String?> _resolvePreviousTransitionId({
    required String tradeId,
    required String pubkey,
  }) async {
    if (tradeId.isEmpty) return null;

    final existing = (await getForOrder(
      tradeId,
    )).where((transition) => transition.pubKey == pubkey).toList();
    if (existing.isEmpty) return null;

    final chain = resolveStateTransitionChain(existing);
    if (!chain.validation.isValid) {
      throw StateError(
        'Cannot append order transition: existing transition chain is '
        'invalid (${chain.validation.reason})',
      );
    }

    return chain.transitions.last.id;
  }

  /// Query all transitions for a given trade id (`d` tag).
  Future<List<OrderTransition>> getForOrder(String tradeId) {
    return list(
      Filter(kinds: OrderTransition.kinds, dTags: [tradeId]),
      name: 'order-transitions-get-$tradeId',
    );
  }

  /// Subscribe to live transitions for a given trade id (`d` tag).
  StreamWithStatus<OrderTransition> subscribeForOrder(String tradeId) {
    return subscribe(
      Filter(kinds: OrderTransition.kinds, dTags: [tradeId]),
      name: 'order-transitions-$tradeId',
    );
  }
}
