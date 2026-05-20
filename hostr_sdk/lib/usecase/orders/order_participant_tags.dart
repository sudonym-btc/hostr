import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

typedef OrderParticipantAuthorizationSigner =
    Future<String> Function(OrderParticipantAuthorizationDraft draft);

typedef OrderParticipantProofEncryptor =
    Future<String> Function({
      required String plaintext,
      required String senderPrivateKey,
      required String recipientPubkey,
    });

typedef OrderParticipantRelayHintResolver =
    Future<String> Function(String pubkey);

class OrderParticipant {
  final String role;
  final String participantPubkey;
  final String identityPubkey;

  const OrderParticipant({
    required this.role,
    required this.participantPubkey,
    required this.identityPubkey,
  });

  factory OrderParticipant.real({
    required String role,
    required String pubkey,
  }) {
    return OrderParticipant(
      role: role,
      participantPubkey: pubkey,
      identityPubkey: pubkey,
    );
  }

  bool get requiresProof => identityPubkey != participantPubkey;
}

class OrderParticipantAuthorizationDraft {
  final String tradeId;
  final String role;
  final String identityPubkey;
  final String participantPubkey;

  const OrderParticipantAuthorizationDraft({
    required this.tradeId,
    required this.role,
    required this.identityPubkey,
    required this.participantPubkey,
  });
}

class OrderParticipantTagPlan {
  final List<List<String>> pTags;
  final List<OrderParticipantProofTag> proofTags;

  const OrderParticipantTagPlan({required this.pTags, required this.proofTags});

  List<List<String>> get tags => [
    ...pTags,
    for (final proof in proofTags) proof.toTag(),
  ];
}

class ResolvedOrderParticipantProof {
  final String participantPubkey;
  final String identityPubkey;

  const ResolvedOrderParticipantProof({
    required this.participantPubkey,
    required this.identityPubkey,
  });
}

Map<String, List<OrderParticipantProofTag>> orderParticipantProofsByPubkey(
  Order order,
) {
  final result = <String, List<OrderParticipantProofTag>>{};
  for (final proof in order.parsedTags.participantProofs) {
    final participantPubkey = proof.participantPubkey;
    if (participantPubkey.isEmpty) continue;
    result.putIfAbsent(participantPubkey, () => []).add(proof);
  }
  return Map<String, List<OrderParticipantProofTag>>.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<OrderParticipantProofTag>.unmodifiable(entry.value),
  });
}

Map<String, List<OrderParticipantProofTag>> orderGroupParticipantProofsByPubkey(
  OrderGroup group,
) {
  final result = <String, List<OrderParticipantProofTag>>{};
  for (final order in group.orders) {
    for (final entry in orderParticipantProofsByPubkey(order).entries) {
      result.putIfAbsent(entry.key, () => []).addAll(entry.value);
    }
  }
  return Map<String, List<OrderParticipantProofTag>>.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<OrderParticipantProofTag>.unmodifiable(entry.value),
  });
}

bool orderHasParticipantProof(Order order, String participantPubkey) {
  if (participantPubkey.isEmpty) return false;
  return orderParticipantProofsByPubkey(order).containsKey(participantPubkey);
}

bool orderGroupHasParticipantProof(OrderGroup group, String participantPubkey) {
  if (participantPubkey.isEmpty) return false;
  return orderGroupParticipantProofsByPubkey(
    group,
  ).containsKey(participantPubkey);
}

Set<String> rawOrderParticipantSet(Order order) {
  return Set.unmodifiable(
    {
      order.pubKey,
      ...order.parsedTags.getTags('p'),
    }.where((pubkey) => pubkey.isNotEmpty),
  );
}

Set<String> rawOrderGroupParticipantSet(OrderGroup group) {
  final participants = <String>{};
  for (final order in group.orders) {
    participants.addAll(rawOrderParticipantSet(order));
  }
  return Set.unmodifiable(participants);
}

Set<String> resolveParticipantSet({
  required Iterable<String> rawParticipants,
  Iterable<ResolvedOrderParticipantProof> resolvedProofs = const [],
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

Set<String> resolvedOrderParticipantSet({
  required Order order,
  Iterable<ResolvedOrderParticipantProof> resolvedProofs = const [],
}) {
  return resolveParticipantSet(
    rawParticipants: rawOrderParticipantSet(order),
    resolvedProofs: resolvedProofs,
  );
}

Set<String> resolvedOrderGroupParticipantSet({
  required OrderGroup group,
  Iterable<ResolvedOrderParticipantProof> resolvedProofs = const [],
}) {
  return resolveParticipantSet(
    rawParticipants: rawOrderGroupParticipantSet(group),
    resolvedProofs: resolvedProofs,
  );
}

String rawOrderGroupId(Order order) {
  return OrderGroup.groupIdFromEvent(order);
}

String rawOrderGroupIdForGroup(OrderGroup group) {
  return OrderGroup.groupIdForParticipants(
    tradeId: group.tradeId,
    participants: rawOrderGroupParticipantSet(group),
  );
}

String resolvedOrderGroupId({
  required Order order,
  Iterable<ResolvedOrderParticipantProof> resolvedProofs = const [],
}) {
  final tradeId = order.getDtag();
  if (tradeId == null || tradeId.isEmpty) {
    throw StateError('Cannot derive order group id without trade id');
  }
  return OrderGroup.groupIdForParticipants(
    tradeId: tradeId,
    participants: resolvedOrderParticipantSet(
      order: order,
      resolvedProofs: resolvedProofs,
    ),
  );
}

String resolvedOrderGroupIdForGroup({
  required OrderGroup group,
  Iterable<ResolvedOrderParticipantProof> resolvedProofs = const [],
}) {
  return OrderGroup.groupIdForParticipants(
    tradeId: group.tradeId,
    participants: resolvedOrderGroupParticipantSet(
      group: group,
      resolvedProofs: resolvedProofs,
    ),
  );
}

Future<OrderParticipantTagPlan> buildOrderParticipantTagPlan({
  required String tradeId,
  required KeyPair orderAuthorKey,
  required Iterable<OrderParticipant> participants,
  required OrderParticipantAuthorizationSigner signAuthorization,
  required OrderParticipantProofEncryptor encryptAuthorization,
  OrderParticipantRelayHintResolver? relayHintFor,
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
  final senderPrivateKey = orderAuthorKey.privateKey;
  if (aliases.isNotEmpty &&
      (senderPrivateKey == null || senderPrivateKey.isEmpty)) {
    throw StateError(
      'Order author private key is required to encrypt participant proofs',
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
  final proofTags = <OrderParticipantProofTag>[];
  for (final participant in aliases) {
    final signedAuthorization = await signAuthorization(
      OrderParticipantAuthorizationDraft(
        tradeId: tradeId,
        role: participant.role,
        identityPubkey: participant.identityPubkey,
        participantPubkey: participant.participantPubkey,
      ),
    );

    final payloadHash = OrderParticipantProofTag.hashPayload(
      signedAuthorization,
    );

    for (final recipientPubkey in recipientPubkeys) {
      proofTags.add(
        OrderParticipantProofTag(
          role: participant.role,
          participantPubkey: participant.participantPubkey,
          recipientPubkey: recipientPubkey,
          scheme: kOrderParticipantProofSchemeNip44,
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

  return OrderParticipantTagPlan(pTags: pTags, proofTags: proofTags);
}
