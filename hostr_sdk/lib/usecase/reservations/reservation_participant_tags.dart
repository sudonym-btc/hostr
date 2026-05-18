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

Map<String, List<ReservationParticipantProofTag>>
reservationParticipantProofsByPubkey(Reservation reservation) {
  final result = <String, List<ReservationParticipantProofTag>>{};
  for (final proof in reservation.parsedTags.participantProofs) {
    final participantPubkey = proof.participantPubkey;
    if (participantPubkey.isEmpty) continue;
    result.putIfAbsent(participantPubkey, () => []).add(proof);
  }
  return Map<String, List<ReservationParticipantProofTag>>.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<ReservationParticipantProofTag>.unmodifiable(entry.value),
  });
}

Map<String, List<ReservationParticipantProofTag>>
reservationGroupParticipantProofsByPubkey(ReservationGroup group) {
  final result = <String, List<ReservationParticipantProofTag>>{};
  for (final reservation in group.reservations) {
    for (final entry in reservationParticipantProofsByPubkey(
      reservation,
    ).entries) {
      result.putIfAbsent(entry.key, () => []).addAll(entry.value);
    }
  }
  return Map<String, List<ReservationParticipantProofTag>>.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<ReservationParticipantProofTag>.unmodifiable(entry.value),
  });
}

bool reservationHasParticipantProof(
  Reservation reservation,
  String participantPubkey,
) {
  if (participantPubkey.isEmpty) return false;
  return reservationParticipantProofsByPubkey(
    reservation,
  ).containsKey(participantPubkey);
}

bool reservationGroupHasParticipantProof(
  ReservationGroup group,
  String participantPubkey,
) {
  if (participantPubkey.isEmpty) return false;
  return reservationGroupParticipantProofsByPubkey(
    group,
  ).containsKey(participantPubkey);
}

Set<String> rawReservationParticipantSet(Reservation reservation) {
  return Set.unmodifiable(
    {
      reservation.pubKey,
      ...reservation.parsedTags.getTags('p'),
    }.where((pubkey) => pubkey.isNotEmpty),
  );
}

Set<String> rawReservationGroupParticipantSet(ReservationGroup group) {
  final participants = <String>{};
  for (final reservation in group.reservations) {
    participants.addAll(rawReservationParticipantSet(reservation));
  }
  return Set.unmodifiable(participants);
}

Set<String> resolveParticipantSet({
  required Iterable<String> rawParticipants,
  Iterable<ResolvedReservationParticipantProof> resolvedProofs = const [],
}) {
  final participants = rawParticipants
      .where((pubkey) => pubkey.isNotEmpty)
      .toSet();
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

Set<String> resolvedReservationParticipantSet({
  required Reservation reservation,
  Iterable<ResolvedReservationParticipantProof> resolvedProofs = const [],
}) {
  return resolveParticipantSet(
    rawParticipants: rawReservationParticipantSet(reservation),
    resolvedProofs: resolvedProofs,
  );
}

Set<String> resolvedReservationGroupParticipantSet({
  required ReservationGroup group,
  Iterable<ResolvedReservationParticipantProof> resolvedProofs = const [],
}) {
  return resolveParticipantSet(
    rawParticipants: rawReservationGroupParticipantSet(group),
    resolvedProofs: resolvedProofs,
  );
}

String rawReservationGroupId(Reservation reservation) {
  return ReservationGroup.groupIdFromEvent(reservation);
}

String rawReservationGroupIdForGroup(ReservationGroup group) {
  return ReservationGroup.groupIdForParticipants(
    tradeId: group.tradeId,
    participants: rawReservationGroupParticipantSet(group),
  );
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

String resolvedReservationGroupIdForGroup({
  required ReservationGroup group,
  Iterable<ResolvedReservationParticipantProof> resolvedProofs = const [],
}) {
  return ReservationGroup.groupIdForParticipants(
    tradeId: group.tradeId,
    participants: resolvedReservationGroupParticipantSet(
      group: group,
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
