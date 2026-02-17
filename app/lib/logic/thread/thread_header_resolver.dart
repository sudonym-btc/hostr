import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';

enum ThreadHeaderSource { reservation, reservationRequest, listing }

enum ThreadPartyRole { host, guest }

enum ThreadHeaderStatus {
  none,
  requestOnly,
  confirmed,
  pendingConfirmation,
  cancelled,
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
}

class ThreadHeaderResolution {
  final ThreadHeaderSource source;
  final ThreadPartyRole role;
  final ThreadHeaderStatus status;
  final Reservation? reservation;
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
    required ThreadCubitState threadCubitState,
    required String hostPubkey,
    required String ourPubkey,
  }) {
    // Compute variables from state
    final role = threadCubitState.listing!.pubKey == ourPubkey
        ? ThreadPartyRole.host
        : ThreadPartyRole.guest;

    final lastRequest = threadCubitState.threadState.lastReservationRequest;

    final sortedReservations =
        threadCubitState.threadState.subscriptions.reservations
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final cancelledReservations = sortedReservations
        .where((reservation) => reservation.parsedContent.cancelled)
        .toList();

    final reservationWasCancelled = cancelledReservations.isEmpty
        ? null
        : (cancelledReservations.first.pubKey == hostPubkey
              ? ThreadPartyRole.host
              : ThreadPartyRole.guest);

    final hasAnyReservation = sortedReservations.isNotEmpty;

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

    // Compute overlap
    final startDate =
        sortedReservations.firstOrNull?.parsedContent.start ??
        lastRequest.parsedContent.start;
    final endDate =
        sortedReservations.firstOrNull?.parsedContent.end ??
        lastRequest.parsedContent.end;

    final overlapLock = resolveOverlapLock(
      ourPubkey: ourPubkey,
      allListingReservations:
          threadCubitState.threadState.subscriptions.reservations,
      startDate: startDate,
      endDate: endDate,
      salt: threadCubitState.threadState.salt!,
    );

    final actions = <ThreadHeaderActionType>[];
    ThreadHeaderStatus status = ThreadHeaderStatus.none;

    final hasActiveReservation = sortedReservations.isNotEmpty;
    final isSelfSigned = !sortedReservations.any(
      (reservation) => reservation.pubKey == threadCubitState.listing!.pubKey,
    );

    final hasEscrow = escrowFromProof != null;

    final now = DateTime.now();
    final hasReservationEnded = endDate.isBefore(now);
    final hasAnyCancelledReservation = cancelledReservations.isNotEmpty;
    final hasTerminalPaymentState = threadCubitState
        .threadState
        .subscriptions
        .paymentEvents
        .any(
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
        threadCubitState.threadState.messages.any(
          (message) =>
              message.pubKey == escrowPubkey ||
              message.pTags.contains(escrowPubkey),
        );
    final canShowMessageEscrow =
        escrowPubkey != null && !isEscrowAlreadyInThread;

    // Compute actions and status

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
      final listedAmount = threadCubitState.listing!.cost(
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
          if (threadCubitState.listing!.parsedContent.allowBarter &&
              underListedPrice) {
            actions.add(ThreadHeaderActionType.counter);
          }
        }
      } else {
        final isAtOrAboveListedPrice =
            sameCurrency && requestAmount.value >= listedAmount.value;
        final canPayByEvmAndPrice =
            threadCubitState.listingProfile!.evmAddress != null &&
            isAtOrAboveListedPrice;
        if (!lastSentByUs || canPayByEvmAndPrice) {
          actions.add(ThreadHeaderActionType.pay);
        }
        if (!lastSentByUs &&
            threadCubitState.listing!.parsedContent.allowBarter) {
          actions.add(ThreadHeaderActionType.counter);
        }
      }
      status = ThreadHeaderStatus.requestOnly;
    }

    return ThreadHeaderResolution(
      source: source,
      role: role,
      status: status,
      lastReservationRequest: lastRequest,
      actions: actions,
      isBlocked: false,
      blockedReason: null,
      isEscrowAlreadyInThread: isEscrowAlreadyInThread,
      escrowPubkey: escrowPubkey,
      escrowService: escrowFromProof,
    );
  }
}

({bool isBlocked, String? reason}) resolveOverlapLock({
  required List<Reservation> allListingReservations,
  required DateTime startDate,
  required DateTime endDate,
  required String salt,
  required String ourPubkey,
}) {
  final ourCommitment = ParticipationProof.computeCommitmentHash(
    ourPubkey,
    salt,
  );

  final overlapsOtherCommitment = allListingReservations.any((reservation) {
    if (reservation.parsedContent.cancelled) {
      return false;
    }
    if (!_overlapsRange(
      startA: startDate,
      endA: endDate,
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
    reason: 'Dates overlap with an existing reservation for a different guest.',
  );
}

bool _overlapsRange({
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
