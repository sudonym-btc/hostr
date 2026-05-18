import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/coinlib_gift_wrap.dart';
import '../../util/custom_logger.dart';
import 'reservation_participant_authorization.dart';
import 'reservation_participant_tags.dart';

class ReservationParticipantAuthorizationResolver {
  final CustomLogger? _logger;

  const ReservationParticipantAuthorizationResolver({CustomLogger? logger})
    : _logger = logger;

  Future<String?> tryDecryptAuthorization({
    required Reservation reservation,
    required ReservationParticipantAuthorizationDraft draft,
    required KeyPair recipientKeyPair,
  }) async {
    final recipientPrivateKey = recipientKeyPair.privateKey;
    if (recipientPrivateKey == null || recipientPrivateKey.isEmpty) {
      return null;
    }

    final tradeId = reservation.getDtag();
    if (tradeId == null || tradeId != draft.tradeId) return null;

    final proofMap = reservationParticipantProofsByPubkey(reservation);
    for (final proof in proofMap[draft.participantPubkey] ?? const []) {
      if (proof.scheme != kReservationParticipantProofSchemeNip44) continue;
      if (proof.role != draft.role) continue;
      if (proof.recipientPubkey != recipientKeyPair.publicKey) continue;

      try {
        final plaintext = await coinlibDecryptNip44(
          proof.payload,
          recipientPrivateKey,
          reservation.pubKey,
        );
        if (!proof.matchesPayload(plaintext)) continue;

        final payload = ReservationParticipantAuthorizationPayload.tryDecode(
          plaintext,
        );
        if (payload == null) continue;
        if (payload.pubkey != draft.identityPubkey) continue;
        if (!payload.verifiesForReservation(
          tradeId: draft.tradeId,
          listingAnchor: reservation.parsedTags.listingAnchor,
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
    required ReservationParticipantAuthorizationDraft draft,
    required KeyPair recipientKeyPair,
    required Iterable<Reservation> candidates,
  }) async {
    for (final candidate in candidates) {
      final plaintext = await tryDecryptAuthorization(
        reservation: candidate,
        draft: draft,
        recipientKeyPair: recipientKeyPair,
      );
      if (plaintext != null) return plaintext;
    }
    return null;
  }

  Future<ParticipationProof> createReviewProof({
    required Reservation reservation,
    required String role,
    required KeyPair recipientKeyPair,
    required String identityPubkey,
  }) async {
    final tradeId = reservation.getDtag();
    if (tradeId == null || tradeId.isEmpty) {
      throw StateError('Reservation trade id is required to publish a review');
    }

    final participantPubkey = reservation.participantPubkeyForRole(role);
    final draft = ReservationParticipantAuthorizationDraft(
      tradeId: tradeId,
      role: role,
      identityPubkey: identityPubkey,
      participantPubkey: participantPubkey,
    );
    final plaintext = await tryDecryptAuthorization(
      reservation: reservation,
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
