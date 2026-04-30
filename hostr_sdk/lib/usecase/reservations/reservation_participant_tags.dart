import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

typedef ReservationParticipantAuthorizationSigner =
    Future<String> Function(ReservationParticipantAuthorizationDraft draft);

typedef ReservationParticipantProofEncryptor =
    Future<String> Function({
      required String plaintext,
      required String senderPrivateKey,
      required String recipientPubkey,
    });

typedef ReservationParticipantRelayHintResolver =
    Future<String> Function(String pubkey);

class ReservationParticipant {
  final String role;
  final String participantPubkey;
  final String identityPubkey;

  const ReservationParticipant({
    required this.role,
    required this.participantPubkey,
    required this.identityPubkey,
  });

  factory ReservationParticipant.real({
    required String role,
    required String pubkey,
  }) {
    return ReservationParticipant(
      role: role,
      participantPubkey: pubkey,
      identityPubkey: pubkey,
    );
  }

  bool get requiresProof => identityPubkey != participantPubkey;
}

class ReservationParticipantAuthorizationDraft {
  final String tradeId;
  final String role;
  final String identityPubkey;
  final String participantPubkey;

  const ReservationParticipantAuthorizationDraft({
    required this.tradeId,
    required this.role,
    required this.identityPubkey,
    required this.participantPubkey,
  });
}

class ReservationParticipantTagPlan {
  final List<List<String>> pTags;
  final List<ReservationParticipantProofTag> proofTags;

  const ReservationParticipantTagPlan({
    required this.pTags,
    required this.proofTags,
  });

  List<List<String>> get tags => [
    ...pTags,
    for (final proof in proofTags) proof.toTag(),
  ];
}

class ResolvedReservationParticipantProof {
  final String participantPubkey;
  final String identityPubkey;

  const ResolvedReservationParticipantProof({
    required this.participantPubkey,
    required this.identityPubkey,
  });
}

Set<String> rawReservationParticipantSet(Reservation reservation) {
  return Set.unmodifiable(
    {
      reservation.pubKey,
      ...reservation.parsedTags.getTags('p'),
    }.where((pubkey) => pubkey.isNotEmpty),
  );
}

Set<String> resolvedReservationParticipantSet({
  required Reservation reservation,
  Iterable<ResolvedReservationParticipantProof> resolvedProofs = const [],
}) {
  final participants = rawReservationParticipantSet(reservation).toSet();
  for (final proof in resolvedProofs) {
    if (proof.participantPubkey.isEmpty) {
      throw ArgumentError.value(
        proof.participantPubkey,
        'participantPubkey',
        'must not be empty',
      );
    }
    if (proof.identityPubkey.isEmpty) {
      throw ArgumentError.value(
        proof.identityPubkey,
        'identityPubkey',
        'must not be empty',
      );
    }
    if (participants.remove(proof.participantPubkey)) {
      participants.add(proof.identityPubkey);
    }
  }
  return Set.unmodifiable(participants);
}

String rawReservationGroupId(Reservation reservation) {
  return ReservationGroup.groupIdFromEvent(reservation);
}

String resolvedReservationGroupId({
  required Reservation reservation,
  Iterable<ResolvedReservationParticipantProof> resolvedProofs = const [],
}) {
  final tradeId = reservation.getDtag();
  if (tradeId == null || tradeId.isEmpty) {
    throw StateError('Cannot derive reservation group id without trade id');
  }
  return ReservationGroup.groupIdForParticipants(
    tradeId: tradeId,
    participants: resolvedReservationParticipantSet(
      reservation: reservation,
      resolvedProofs: resolvedProofs,
    ),
  );
}

Future<ReservationParticipantTagPlan> buildReservationParticipantTagPlan({
  required String tradeId,
  required KeyPair reservationAuthorKey,
  required Iterable<ReservationParticipant> participants,
  required ReservationParticipantAuthorizationSigner signAuthorization,
  required ReservationParticipantProofEncryptor encryptAuthorization,
  ReservationParticipantRelayHintResolver? relayHintFor,
}) async {
  final participantList = participants.toList(growable: false);
  if (participantList.isEmpty) {
    throw ArgumentError.value(
      participants,
      'participants',
      'must not be empty',
    );
  }

  for (final participant in participantList) {
    if (participant.role.isEmpty) {
      throw ArgumentError.value(participant.role, 'role', 'must not be empty');
    }
    if (participant.participantPubkey.isEmpty) {
      throw ArgumentError.value(
        participant.participantPubkey,
        'participantPubkey',
        'must not be empty',
      );
    }
    if (participant.identityPubkey.isEmpty) {
      throw ArgumentError.value(
        participant.identityPubkey,
        'identityPubkey',
        'must not be empty',
      );
    }
  }

  final aliases = participantList
      .where((participant) => participant.requiresProof)
      .toList(growable: false);
  final senderPrivateKey = reservationAuthorKey.privateKey;
  if (aliases.isNotEmpty &&
      (senderPrivateKey == null || senderPrivateKey.isEmpty)) {
    throw StateError(
      'Reservation author private key is required to encrypt participant proofs',
    );
  }

  final pTags = <List<String>>[];
  for (final participant in participantList) {
    pTags.add(
      PTag(
        participant.participantPubkey,
        relayHint:
            await relayHintFor?.call(participant.participantPubkey) ?? '',
        role: participant.role,
      ).toTag(),
    );
  }

  final recipientPubkeys = {
    for (final participant in participantList) participant.participantPubkey,
  };
  final proofTags = <ReservationParticipantProofTag>[];
  for (final participant in aliases) {
    final signedAuthorization = await signAuthorization(
      ReservationParticipantAuthorizationDraft(
        tradeId: tradeId,
        role: participant.role,
        identityPubkey: participant.identityPubkey,
        participantPubkey: participant.participantPubkey,
      ),
    );

    final payloadHash = ReservationParticipantProofTag.hashPayload(
      signedAuthorization,
    );

    for (final recipientPubkey in recipientPubkeys) {
      proofTags.add(
        ReservationParticipantProofTag(
          role: participant.role,
          participantPubkey: participant.participantPubkey,
          recipientPubkey: recipientPubkey,
          scheme: kReservationParticipantProofSchemeNip44,
          payloadHash: payloadHash,
          payload: await encryptAuthorization(
            plaintext: signedAuthorization,
            senderPrivateKey: senderPrivateKey!,
            recipientPubkey: recipientPubkey,
          ),
        ),
      );
    }
  }

  return ReservationParticipantTagPlan(pTags: pTags, proofTags: proofTags);
}
