import 'package:models/main.dart';

import '../../util/main.dart';
import '../reservations/reservation_participant_keyring.dart';
import '../reservations/reservation_participant_tags.dart';

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

  String? resolvedParticipantPubkeyForRole(String role) {
    final rawPubkey = rawParticipantPubkeyForRole(role);
    if (rawPubkey == null || rawPubkey.isEmpty) return null;
    return identityByParticipantPubkey[rawPubkey] ?? rawPubkey;
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
    if (participantPubkey.isEmpty) return false;
    return group.reservations.any(
      (reservation) => reservation.parsedTags.participantProofs.any(
        (proof) => proof.participantPubkey == participantPubkey,
      ),
    );
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

class ReservationGroupParticipantResolver {
  final ReservationParticipantKeyring _keyring;

  const ReservationGroupParticipantResolver({
    required ReservationParticipantKeyring keyring,
  }) : _keyring = keyring;

  Future<ResolvedReservationGroupParticipants> resolve(
    ReservationGroup group,
  ) async {
    final resolvedProofsByParticipant =
        <String, ResolvedReservationParticipantProof>{};

    for (final reservation in group.reservations) {
      for (final proof in reservation.parsedTags.participantProofs) {
        final resolved = await _keyring.tryDecryptParticipantProof(
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

    final rawParticipants = group.participantSet;
    final resolvedParticipants = rawParticipants.toSet();
    for (final proof in resolvedProofsByParticipant.values) {
      if (resolvedParticipants.remove(proof.participantPubkey)) {
        resolvedParticipants.add(proof.identityPubkey);
      }
    }

    return ResolvedReservationGroupParticipants(
      group: group,
      rawGroupId: group.groupId,
      resolvedGroupId: ReservationGroup.groupIdForParticipants(
        tradeId: group.tradeId,
        participants: resolvedParticipants,
      ),
      rawParticipantSet: Set.unmodifiable(rawParticipants),
      resolvedParticipantSet: Set.unmodifiable(resolvedParticipants),
      resolvedProofs: List.unmodifiable(resolvedProofsByParticipant.values),
    );
  }

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
