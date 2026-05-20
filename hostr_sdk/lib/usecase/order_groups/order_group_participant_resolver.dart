import 'package:models/main.dart';

import '../../util/main.dart';
import '../orders/order_participant_keyring.dart';
import '../orders/order_participant_tags.dart';

class ResolvedOrderParticipants {
  final Order order;
  final Set<String> rawParticipantSet;
  final Set<String> resolvedParticipantSet;
  final List<ResolvedOrderParticipantProof> resolvedProofs;

  const ResolvedOrderParticipants({
    required this.order,
    required this.rawParticipantSet,
    required this.resolvedParticipantSet,
    required this.resolvedProofs,
  });

  Map<String, String> get identityByParticipantPubkey => {
    for (final proof in resolvedProofs)
      proof.participantPubkey: proof.identityPubkey,
  };

  bool hasParticipantProofFor(String participantPubkey) =>
      orderHasParticipantProof(order, participantPubkey);

  bool hasResolvedProofFor(String participantPubkey) =>
      identityByParticipantPubkey.containsKey(participantPubkey);
}

class ResolvedOrderGroupParticipants {
  final OrderGroup group;
  final String rawGroupId;
  final String resolvedGroupId;
  final Set<String> rawParticipantSet;
  final Set<String> resolvedParticipantSet;
  final List<ResolvedOrderParticipantProof> resolvedProofs;

  const ResolvedOrderGroupParticipants({
    required this.group,
    required this.rawGroupId,
    required this.resolvedGroupId,
    required this.rawParticipantSet,
    required this.resolvedParticipantSet,
    required this.resolvedProofs,
  });

  bool get hasResolvedParticipants =>
      rawParticipantSet.length != resolvedParticipantSet.length ||
      !rawParticipantSet.containsAll(resolvedParticipantSet);

  Map<String, String> get identityByParticipantPubkey => {
    for (final proof in resolvedProofs)
      proof.participantPubkey: proof.identityPubkey,
  };

  String? rawParticipantPubkeyForRole(String role) {
    switch (role) {
      case 'seller':
        final sellerPubkey = group.sellerPubkey;
        if (sellerPubkey.isNotEmpty) return sellerPubkey;
        break;
      case 'buyer':
        final buyerPubkey = group.buyerPubkey;
        if (buyerPubkey != null && buyerPubkey.isNotEmpty) {
          return buyerPubkey;
        }
        final buyerRecipient = group.buyerOrder?.recipient;
        if (buyerRecipient != null && buyerRecipient.isNotEmpty) {
          return buyerRecipient;
        }
        break;
      case 'escrow':
        final escrowPubkey = group.escrowPubkey;
        if (escrowPubkey != null && escrowPubkey.isNotEmpty) {
          return escrowPubkey;
        }
        break;
    }

    for (final order in group.orders.reversed) {
      final tagged = order.parsedTags.getTagValueByMarker('p', role);
      if (tagged != null && tagged.isNotEmpty) return tagged;
    }
    return null;
  }

  String? resolvedParticipantPubkeyForRole(
    String role, {
    bool requireResolvedProof = false,
  }) {
    final rawPubkey = rawParticipantPubkeyForRole(role);
    if (rawPubkey == null || rawPubkey.isEmpty) return null;
    if (requireResolvedProof &&
        hasParticipantProofFor(rawPubkey) &&
        !hasResolvedProofFor(rawPubkey)) {
      return null;
    }
    return identityByParticipantPubkey[rawPubkey] ?? rawPubkey;
  }

  bool hasResolvedParticipantForRole(
    String role, {
    bool requireResolvedProof = false,
  }) {
    final pubkey = resolvedParticipantPubkeyForRole(
      role,
      requireResolvedProof: requireResolvedProof,
    );
    return pubkey != null && pubkey.isNotEmpty;
  }

  Set<String> get resolvedParticipantSetWithoutEscrow {
    final participants = resolvedParticipantSet.toSet();
    final escrowPubkeys = {
      rawParticipantPubkeyForRole('escrow'),
      resolvedParticipantPubkeyForRole('escrow'),
    }.whereType<String>().where((pubkey) => pubkey.isNotEmpty);
    participants.removeAll(escrowPubkeys);
    return Set.unmodifiable(participants);
  }

  bool hasParticipantProofFor(String participantPubkey) {
    return orderGroupHasParticipantProof(group, participantPubkey);
  }

  bool hasResolvedProofFor(String participantPubkey) =>
      identityByParticipantPubkey.containsKey(participantPubkey);
}

class ResolvedValidatedOrderGroupParticipants {
  final Validation<OrderGroup> validation;
  final ResolvedOrderGroupParticipants participants;

  const ResolvedValidatedOrderGroupParticipants({
    required this.validation,
    required this.participants,
  });

  OrderGroup get group => validation.event;
}

Future<ResolvedOrderParticipants> resolveOrderParticipants({
  required Order order,
  required OrderParticipantKeyring keyring,
}) async {
  final resolvedProofsByParticipant = <String, ResolvedOrderParticipantProof>{};
  final proofMap = orderParticipantProofsByPubkey(order);

  for (final proofs in proofMap.values) {
    for (final proof in proofs) {
      final resolved = await keyring.tryDecryptParticipantProof(
        order: order,
        proof: proof,
      );
      if (resolved == null) continue;
      resolvedProofsByParticipant.putIfAbsent(
        resolved.participantPubkey,
        () => resolved,
      );
    }
  }

  final resolvedProofs = resolvedProofsByParticipant.values.toList(
    growable: false,
  );
  return ResolvedOrderParticipants(
    order: order,
    rawParticipantSet: rawOrderParticipantSet(order),
    resolvedParticipantSet: resolvedOrderParticipantSet(
      order: order,
      resolvedProofs: resolvedProofs,
    ),
    resolvedProofs: List.unmodifiable(resolvedProofs),
  );
}

Future<ResolvedOrderGroupParticipants> resolveOrderGroupParticipants({
  required OrderGroup group,
  required OrderParticipantKeyring keyring,
}) async {
  final resolvedProofsByParticipant = <String, ResolvedOrderParticipantProof>{};

  for (final order in group.orders) {
    final resolved = await resolveOrderParticipants(
      order: order,
      keyring: keyring,
    );
    for (final proof in resolved.resolvedProofs) {
      resolvedProofsByParticipant.putIfAbsent(
        proof.participantPubkey,
        () => proof,
      );
    }
  }

  final resolvedProofs = resolvedProofsByParticipant.values.toList(
    growable: false,
  );
  return ResolvedOrderGroupParticipants(
    group: group,
    rawGroupId: rawOrderGroupIdForGroup(group),
    resolvedGroupId: resolvedOrderGroupIdForGroup(
      group: group,
      resolvedProofs: resolvedProofs,
    ),
    rawParticipantSet: rawOrderGroupParticipantSet(group),
    resolvedParticipantSet: resolvedOrderGroupParticipantSet(
      group: group,
      resolvedProofs: resolvedProofs,
    ),
    resolvedProofs: List.unmodifiable(resolvedProofs),
  );
}

class OrderGroupParticipantResolver {
  final OrderParticipantKeyring _keyring;

  const OrderGroupParticipantResolver({
    required OrderParticipantKeyring keyring,
  }) : _keyring = keyring;

  Future<ResolvedOrderGroupParticipants> resolve(OrderGroup group) =>
      resolveOrderGroupParticipants(group: group, keyring: _keyring);

  StreamWithStatus<ResolvedOrderGroupParticipants> resolveStream(
    StreamWithStatus<OrderGroup> source,
  ) {
    return source.asyncMap(resolve);
  }

  StreamWithStatus<ResolvedValidatedOrderGroupParticipants>
  resolveValidatedStream(StreamWithStatus<Validation<OrderGroup>> source) {
    return source.asyncMap((validation) async {
      return ResolvedValidatedOrderGroupParticipants(
        validation: validation,
        participants: await resolve(validation.event),
      );
    });
  }
}

extension OrderGroupParticipantResolutionStream
    on StreamWithStatus<OrderGroup> {
  StreamWithStatus<ResolvedOrderGroupParticipants> resolveParticipantSets({
    required OrderGroupParticipantResolver resolver,
  }) {
    return resolver.resolveStream(this);
  }
}

extension ValidatedOrderGroupParticipantResolutionStream
    on StreamWithStatus<Validation<OrderGroup>> {
  StreamWithStatus<ResolvedValidatedOrderGroupParticipants>
  resolveParticipantSets({required OrderGroupParticipantResolver resolver}) {
    return resolver.resolveValidatedStream(this);
  }
}
