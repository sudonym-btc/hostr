import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/coinlib_gift_wrap.dart';
import '../../util/custom_logger.dart';
import 'order_participant_authorization.dart';
import 'order_participant_tags.dart';

class OrderParticipantAuthorizationResolver {
  final CustomLogger? _logger;

  const OrderParticipantAuthorizationResolver({CustomLogger? logger})
    : _logger = logger;

  Future<String?> tryDecryptAuthorization({
    required Order order,
    required OrderParticipantAuthorizationDraft draft,
    required KeyPair recipientKeyPair,
  }) async {
    final recipientPrivateKey = recipientKeyPair.privateKey;
    if (recipientPrivateKey == null || recipientPrivateKey.isEmpty) {
      return null;
    }

    final tradeId = order.getDtag();
    if (tradeId == null || tradeId != draft.tradeId) return null;

    final proofMap = orderParticipantProofsByPubkey(order);
    for (final proof in proofMap[draft.participantPubkey] ?? const []) {
      if (proof.scheme != kOrderParticipantProofSchemeNip44) continue;
      if (proof.role != draft.role) continue;
      if (proof.recipientPubkey != recipientKeyPair.publicKey) continue;

      try {
        final plaintext = await coinlibDecryptNip44(
          proof.payload,
          recipientPrivateKey,
          order.pubKey,
        );
        if (!proof.matchesPayload(plaintext)) continue;

        final payload = OrderParticipantAuthorizationPayload.tryDecode(
          plaintext,
        );
        if (payload == null) continue;
        if (payload.pubkey != draft.identityPubkey) continue;
        if (!payload.verifiesForOrder(
          tradeId: draft.tradeId,
          listingAnchor: order.parsedTags.listingAnchor,
          participantPubkey: draft.participantPubkey,
          role: draft.role,
        )) {
          continue;
        }
        return plaintext;
      } catch (error, stackTrace) {
        _logger?.w(
          'Failed to decrypt participant authorization for ${draft.tradeId}',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return null;
  }

  Future<String?> findReusableAuthorization({
    required OrderParticipantAuthorizationDraft draft,
    required KeyPair recipientKeyPair,
    required Iterable<Order> candidates,
  }) async {
    for (final candidate in candidates) {
      final plaintext = await tryDecryptAuthorization(
        order: candidate,
        draft: draft,
        recipientKeyPair: recipientKeyPair,
      );
      if (plaintext != null) return plaintext;
    }
    return null;
  }

  Future<ParticipationProof> createReviewProof({
    required Order order,
    required String role,
    required KeyPair recipientKeyPair,
    required String identityPubkey,
  }) async {
    final tradeId = order.getDtag();
    if (tradeId == null || tradeId.isEmpty) {
      throw StateError('Order trade id is required to publish a review');
    }

    final participantPubkey = order.participantPubkeyForRole(role);
    final draft = OrderParticipantAuthorizationDraft(
      tradeId: tradeId,
      role: role,
      identityPubkey: identityPubkey,
      participantPubkey: participantPubkey,
    );
    final plaintext = await tryDecryptAuthorization(
      order: order,
      draft: draft,
      recipientKeyPair: recipientKeyPair,
    );
    if (plaintext == null) {
      throw StateError('No matching participant proof found for review author');
    }

    return ParticipationProof(
      role: role,
      participantPubkey: participantPubkey,
      authorizationPayload: plaintext,
    );
  }
}
