import 'package:models/main.dart';

import '../../util/main.dart';
import '../reservations/reservation_participant_keyring.dart';
import '../reservations/reservation_participant_tags.dart';

class ResolvedReservationParticipants {
  final Reservation reservation;
  final Set<String> rawParticipantSet;
  final Set<String> resolvedParticipantSet;
  final List<ResolvedReservationParticipantProof> resolvedProofs;

  const ResolvedReservationParticipants({
    required this.reservation,
    required this.rawParticipantSet,
    required this.resolvedParticipantSet,
    required this.resolvedProofs,
  });

  Map<String, String> get identityByParticipantPubkey => {
    for (final proof in resolvedProofs)
      proof.participantPubkey: proof.identityPubkey,
  };

  bool hasParticipantProofFor(String participantPubkey) =>
      reservationHasParticipantProof(reservation, participantPubkey);

  bool hasResolvedProofFor(String participantPubkey) =>
      identityByParticipantPubkey.containsKey(participantPubkey);
}

class ResolvedReservationGroupParticipants {
  final ReservationGroup group;
  final String rawGroupId;
  final String resolvedGroupId;
  final Set<String> rawParticipantSet;
  final Set<String> resolvedParticipantSet;
  final List<ResolvedReservationParticipantProof> resolvedProofs;

  const ResolvedReservationGroupParticipants({
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
        final buyerRecipient = group.buyerReservation?.recipient;
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

    for (final reservation in group.reservations.reversed) {
      final tagged = reservation.parsedTags.getTagValueByMarker('p', role);
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
    return reservationGroupHasParticipantProof(group, participantPubkey);
  }

  bool hasResolvedProofFor(String participantPubkey) =>
      identityByParticipantPubkey.containsKey(participantPubkey);
}

class ResolvedValidatedReservationGroupParticipants {
  final Validation<ReservationGroup> validation;
  final ResolvedReservationGroupParticipants participants;

  const ResolvedValidatedReservationGroupParticipants({
    required this.validation,
    required this.participants,
  });

  ReservationGroup get group => validation.event;
}

Future<ResolvedReservationParticipants> resolveReservationParticipants({
  required Reservation reservation,
  required ReservationParticipantKeyring keyring,
}) async {
  final resolvedProofsByParticipant =
      <String, ResolvedReservationParticipantProof>{};
  final proofMap = reservationParticipantProofsByPubkey(reservation);

  for (final proofs in proofMap.values) {
    for (final proof in proofs) {
      final resolved = await keyring.tryDecryptParticipantProof(
        reservation: reservation,
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
  return ResolvedReservationParticipants(
    reservation: reservation,
    rawParticipantSet: rawReservationParticipantSet(reservation),
    resolvedParticipantSet: resolvedReservationParticipantSet(
      reservation: reservation,
      resolvedProofs: resolvedProofs,
    ),
    resolvedProofs: List.unmodifiable(resolvedProofs),
  );
}

Future<ResolvedReservationGroupParticipants>
resolveReservationGroupParticipants({
  required ReservationGroup group,
  required ReservationParticipantKeyring keyring,
}) async {
  final resolvedProofsByParticipant =
      <String, ResolvedReservationParticipantProof>{};

  for (final reservation in group.reservations) {
    final resolved = await resolveReservationParticipants(
      reservation: reservation,
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
  return ResolvedReservationGroupParticipants(
    group: group,
    rawGroupId: rawReservationGroupIdForGroup(group),
    resolvedGroupId: resolvedReservationGroupIdForGroup(
      group: group,
      resolvedProofs: resolvedProofs,
    ),
    rawParticipantSet: rawReservationGroupParticipantSet(group),
    resolvedParticipantSet: resolvedReservationGroupParticipantSet(
      group: group,
      resolvedProofs: resolvedProofs,
    ),
    resolvedProofs: List.unmodifiable(resolvedProofs),
  );
}

class ReservationGroupParticipantResolver {
  final ReservationParticipantKeyring _keyring;

  const ReservationGroupParticipantResolver({
    required ReservationParticipantKeyring keyring,
  }) : _keyring = keyring;

  Future<ResolvedReservationGroupParticipants> resolve(
    ReservationGroup group,
  ) => resolveReservationGroupParticipants(group: group, keyring: _keyring);

  StreamWithStatus<ResolvedReservationGroupParticipants> resolveStream(
    StreamWithStatus<ReservationGroup> source,
  ) {
    return source.asyncMap(resolve);
  }

  StreamWithStatus<ResolvedValidatedReservationGroupParticipants>
  resolveValidatedStream(
    StreamWithStatus<Validation<ReservationGroup>> source,
  ) {
    return source.asyncMap((validation) async {
      return ResolvedValidatedReservationGroupParticipants(
        validation: validation,
        participants: await resolve(validation.event),
      );
    });
  }
}

extension ReservationGroupParticipantResolutionStream
    on StreamWithStatus<ReservationGroup> {
  StreamWithStatus<ResolvedReservationGroupParticipants>
  resolveParticipantSets({
    required ReservationGroupParticipantResolver resolver,
  }) {
    return resolver.resolveStream(this);
  }
}

extension ValidatedReservationGroupParticipantResolutionStream
    on StreamWithStatus<Validation<ReservationGroup>> {
  StreamWithStatus<ResolvedValidatedReservationGroupParticipants>
  resolveParticipantSets({
    required ReservationGroupParticipantResolver resolver,
  }) {
    return resolver.resolveValidatedStream(this);
  }
}
