import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';

enum ThreadHeaderSource { reservation, reservationRequest, listing }

enum ThreadPartyRole { host, guest }

enum ThreadHeaderStatus {
  none,
  requestOnly,
  confirmed,
  pendingConfirmation,
  blocked,
}

enum ThreadHeaderActionType {
  cancel,
  refund,
  claim,
  messageEscrow,
  accept,
  counter,
  pay,
  counterOffer,
}

class ThreadHeaderResolution {
  final ThreadHeaderSource source;
  final ThreadPartyRole role;
  final ThreadHeaderStatus status;
  final Reservation? reservation;
  final ReservationRequest? reservationRequest;
  final ReservationRequest? lastReservationRequest;
  final List<ThreadHeaderActionType> actions;
  final bool isBlocked;
  final String? blockedReason;
  final bool isEscrowAlreadyInThread;
  final String? escrowPubkey;
  final EscrowService? escrowService;

  const ThreadHeaderResolution({
    required this.source,
    required this.role,
    required this.status,
    required this.reservation,
    required this.reservationRequest,
    required this.lastReservationRequest,
    required this.actions,
    required this.isBlocked,
    required this.blockedReason,
    required this.isEscrowAlreadyInThread,
    required this.escrowPubkey,
    required this.escrowService,
  });
}

class ThreadHeaderResolver {
  static ThreadHeaderResolution resolve({
    required Listing listing,
    required String? ourPubkey,
    required ProfileMetadata listingProfile,
    required List<ReservationRequest> reservationRequests,
    required List<Reservation> reservations,
    required List<Reservation> allListingReservations,
    required List<Message> messages,
    required List<PaymentEvent> paymentEvents,
  }) {
    final role = listing.pubKey == ourPubkey
        ? ThreadPartyRole.host
        : ThreadPartyRole.guest;

    final sortedRequests = [...reservationRequests]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final lastRequest = sortedRequests.isEmpty ? null : sortedRequests.last;

    final sortedReservations = [...reservations]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestReservation = sortedReservations.isEmpty
        ? null
        : sortedReservations.first;
    final activeReservation =
        latestReservation != null && !latestReservation.parsedContent.cancelled
        ? latestReservation
        : null;
    final hasAnyReservation = latestReservation != null;

    final escrowsFromProofs = sortedReservations
        .where(
          (reservation) => reservation.parsedContent.proof?.escrowProof != null,
        )
        .map(
          (reservation) =>
              reservation.parsedContent.proof!.escrowProof!.escrowService,
        );
    final escrowFromProof = escrowsFromProofs.isEmpty
        ? null
        : escrowsFromProofs.first;

    final source = hasAnyReservation
        ? ThreadHeaderSource.reservation
        : (lastRequest != null
              ? ThreadHeaderSource.reservationRequest
              : ThreadHeaderSource.listing);

    final overlapLock = _resolveOverlapLock(
      ourPubkey: ourPubkey,
      lastRequest: lastRequest,
      allListingReservations: allListingReservations,
      activeReservation: activeReservation,
    );

    if (overlapLock.isBlocked) {
      return ThreadHeaderResolution(
        source: source,
        role: role,
        status: ThreadHeaderStatus.blocked,
        reservation: activeReservation,
        reservationRequest: lastRequest,
        lastReservationRequest: lastRequest,
        actions: const [],
        isBlocked: true,
        blockedReason: overlapLock.reason,
        isEscrowAlreadyInThread: false,
        escrowPubkey: escrowFromProof?.pubKey,
        escrowService: escrowFromProof,
      );
    }

    final actions = <ThreadHeaderActionType>[];
    ThreadHeaderStatus status = ThreadHeaderStatus.none;

    final hasActiveReservation = activeReservation != null;
    final isSelfSigned = activeReservation != null
        ? activeReservation.pubKey != listing.pubKey
        : false;

    final hasEscrow = escrowFromProof != null;

    final now = DateTime.now();
    final reservationEnd = activeReservation?.parsedContent.end;
    final hasReservationEnded =
        reservationEnd != null && reservationEnd.isBefore(now);
    final hasAnyCancelledReservation = reservations.any(
      (reservation) => reservation.parsedContent.cancelled,
    );
    final hasTerminalPaymentState = paymentEvents.any(
      (event) =>
          event is PaymentClaimedEvent ||
          event is PaymentArbitratedEvent ||
          event is PaymentReleasedEvent,
    );
    final canShowCancel =
        hasActiveReservation &&
        !hasReservationEnded &&
        !hasTerminalPaymentState &&
        !hasAnyCancelledReservation;
    final canShowRefund = hasActiveReservation && !hasTerminalPaymentState;

    final escrowPubkey = escrowFromProof?.parsedContent.pubkey;

    final isEscrowAlreadyInThread =
        escrowPubkey != null &&
        messages.any(
          (message) =>
              message.pubKey == escrowPubkey ||
              message.pTags.contains(escrowPubkey),
        );
    final canShowMessageEscrow =
        escrowPubkey != null && !isEscrowAlreadyInThread;

    if (role == ThreadPartyRole.host) {
      if (!hasTerminalPaymentState && hasEscrow) {
        actions.add(ThreadHeaderActionType.claim);
      }
    }

    if (hasActiveReservation) {
      if (role == ThreadPartyRole.host) {
        if (canShowCancel) {
          actions.add(ThreadHeaderActionType.cancel);
        }
        if (canShowRefund) {
          actions.add(ThreadHeaderActionType.refund);
        }
        if (hasEscrow && canShowMessageEscrow) {
          actions.add(ThreadHeaderActionType.messageEscrow);
        }
      } else {
        if (canShowCancel) {
          actions.add(ThreadHeaderActionType.cancel);
        }
        if (hasEscrow && canShowMessageEscrow) {
          actions.add(ThreadHeaderActionType.messageEscrow);
        }
      }

      status = role == ThreadPartyRole.guest && isSelfSigned
          ? ThreadHeaderStatus.pendingConfirmation
          : ThreadHeaderStatus.confirmed;
    } else if (!hasAnyReservation && lastRequest != null) {
      final lastSentByUs = lastRequest.pubKey == ourPubkey;
      final listedAmount = listing.cost(
        lastRequest.parsedContent.start,
        lastRequest.parsedContent.end,
      );
      final requestAmount = lastRequest.parsedContent.amount;
      final sameCurrency = listedAmount.currency == requestAmount.currency;
      final underListedPrice =
          sameCurrency && requestAmount.value < listedAmount.value;

      if (role == ThreadPartyRole.host) {
        if (!lastSentByUs) {
          actions.add(ThreadHeaderActionType.accept);
          if (listing.parsedContent.allowBarter && underListedPrice) {
            actions.add(ThreadHeaderActionType.counter);
          }
        }
      } else {
        final isAtOrAboveListedPrice =
            sameCurrency && requestAmount.value >= listedAmount.value;
        final canPayByEvmAndPrice =
            listingProfile.evmAddress != null && isAtOrAboveListedPrice;
        if (!lastSentByUs || canPayByEvmAndPrice) {
          actions.add(ThreadHeaderActionType.pay);
        }
        if (!lastSentByUs && listing.parsedContent.allowBarter) {
          actions.add(ThreadHeaderActionType.counterOffer);
        }
      }
      status = ThreadHeaderStatus.requestOnly;
    }

    return ThreadHeaderResolution(
      source: source,
      role: role,
      status: status,
      reservation: activeReservation,
      reservationRequest: lastRequest,
      lastReservationRequest: lastRequest,
      actions: actions,
      isBlocked: false,
      blockedReason: null,
      isEscrowAlreadyInThread: isEscrowAlreadyInThread,
      escrowPubkey: escrowPubkey,
      escrowService: escrowFromProof,
    );
  }

  static ({bool isBlocked, String? reason}) _resolveOverlapLock({
    required String? ourPubkey,
    required ReservationRequest? lastRequest,
    required List<Reservation> allListingReservations,
    required Reservation? activeReservation,
  }) {
    final request = lastRequest;
    if (request == null || ourPubkey == null) {
      return (isBlocked: false, reason: null);
    }

    final threadAnchor = request.anchor;
    final ourCommitment = ParticipationProof.computeCommitmentHash(
      ourPubkey,
      request.parsedContent.salt,
    );

    final overlapsOtherCommitment = allListingReservations.any((reservation) {
      if (reservation.parsedContent.cancelled) {
        return false;
      }

      if (activeReservation != null && reservation.id == activeReservation.id) {
        return false;
      }

      if (threadAnchor != null && reservation.threadAnchor == threadAnchor) {
        return false;
      }

      if (!_overlapsRange(
        startA: request.parsedContent.start,
        endA: request.parsedContent.end,
        startB: reservation.parsedContent.start,
        endB: reservation.parsedContent.end,
      )) {
        return false;
      }

      return reservation.parsedContent.commitmentHash != ourCommitment;
    });

    if (!overlapsOtherCommitment) {
      return (isBlocked: false, reason: null);
    }

    return (
      isBlocked: true,
      reason:
          'Dates overlap with an existing reservation for a different guest.',
    );
  }

  static bool _overlapsRange({
    required DateTime startA,
    required DateTime endA,
    required DateTime startB,
    required DateTime endB,
  }) {
    DateTime normalize(DateTime value) =>
        DateTime(value.year, value.month, value.day);

    var aStart = normalize(startA);
    var aEnd = normalize(endA);
    var bStart = normalize(startB);
    var bEnd = normalize(endB);

    if (aEnd.isBefore(aStart)) {
      final temp = aStart;
      aStart = aEnd;
      aEnd = temp;
    }
    if (bEnd.isBefore(bStart)) {
      final temp = bStart;
      bStart = bEnd;
      bEnd = temp;
    }

    final aEffectiveEnd = aEnd.isAtSameMomentAs(aStart)
        ? aEnd.add(const Duration(days: 1))
        : aEnd;
    final bEffectiveEnd = bEnd.isAtSameMomentAs(bStart)
        ? bEnd.add(const Duration(days: 1))
        : bEnd;

    return aStart.isBefore(bEffectiveEnd) && aEffectiveEnd.isAfter(bStart);
  }
}
