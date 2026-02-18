import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr_sdk/hostr_sdk.dart'
    show StreamStatusLive, StreamStatusQueryComplete;
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
    final facts = _ThreadHeaderFacts.from(
      threadCubitState: threadCubitState,
      hostPubkey: hostPubkey,
      ourPubkey: ourPubkey,
    );

    final actions = <ThreadHeaderActionType>[];
    var status = ThreadHeaderStatus.none;

    if (facts.source == ThreadHeaderSource.reservation) {
      if (facts.role == ThreadPartyRole.host) {
        if (facts.hasEscrow &&
            facts.paymentStateFresh &&
            !facts.hasTerminalPaymentState) {
          actions.add(ThreadHeaderActionType.claim);
        }
        if (facts.cancelAllowedInReservationPhase) {
          actions.add(ThreadHeaderActionType.cancel);
        }
        if (facts.refundAllowedInReservationPhase) {
          actions.add(ThreadHeaderActionType.refund);
        }
        if (facts.messageEscrowAllowedInReservationPhase) {
          actions.add(ThreadHeaderActionType.messageEscrow);
        }
      } else {
        if (facts.cancelAllowedInReservationPhase) {
          actions.add(ThreadHeaderActionType.cancel);
        }
        if (facts.messageEscrowAllowedInReservationPhase) {
          actions.add(ThreadHeaderActionType.messageEscrow);
        }
      }

      status = facts.role == ThreadPartyRole.guest && facts.isSelfSigned
          ? ThreadHeaderStatus.pendingConfirmation
          : ThreadHeaderStatus.confirmed;
    } else if (facts.source == ThreadHeaderSource.reservationRequest &&
        facts.lastRequest != null) {
      if (facts.role == ThreadPartyRole.host) {
        if (!facts.lastSentByUs) {
          actions.add(ThreadHeaderActionType.accept);
          if (facts.allowBarter && facts.underListedPrice) {
            actions.add(ThreadHeaderActionType.counter);
          }
        }
      } else {
        final canPayByEvmAndPrice =
            threadCubitState.listingProfile?.evmAddress != null &&
            facts.isAtOrAboveListedPrice;
        if (!facts.lastSentByUs || canPayByEvmAndPrice) {
          actions.add(ThreadHeaderActionType.pay);
        }
        if (!facts.lastSentByUs && facts.allowBarter) {
          actions.add(ThreadHeaderActionType.counter);
        }
      }
      status = ThreadHeaderStatus.requestOnly;
    }

    return ThreadHeaderResolution(
      source: facts.source,
      role: facts.role,
      status: status,
      reservation: facts.latestReservation,
      lastReservationRequest: facts.lastRequest,
      actions: actions,
      isBlocked: facts.isBlocked,
      blockedReason: facts.blockedReason,
      isEscrowAlreadyInThread: facts.isEscrowAlreadyInThread,
      escrowPubkey: facts.escrowPubkey,
      escrowService: facts.escrowFromProof,
    );
  }
}

class _ThreadHeaderFacts {
  final ThreadHeaderSource source;
  final ThreadPartyRole role;
  final ReservationRequest? lastRequest;
  final Reservation? latestReservation;
  final EscrowService? escrowFromProof;
  final String? escrowPubkey;
  final bool isSelfSigned;
  final bool hasEscrow;
  final bool paymentStateFresh;
  final bool hasTerminalPaymentState;
  final bool hasReservationEnded;
  final bool hasAnyCancelledReservation;
  final bool cancelAllowedInReservationPhase;
  final bool refundAllowedInReservationPhase;
  final bool isEscrowAlreadyInThread;
  final bool messageEscrowAllowedInReservationPhase;
  final bool isBlocked;
  final String? blockedReason;
  final bool lastSentByUs;
  final bool allowBarter;
  final bool underListedPrice;
  final bool isAtOrAboveListedPrice;

  const _ThreadHeaderFacts({
    required this.source,
    required this.role,
    required this.lastRequest,
    required this.latestReservation,
    required this.escrowFromProof,
    required this.escrowPubkey,
    required this.isSelfSigned,
    required this.hasEscrow,
    required this.paymentStateFresh,
    required this.hasTerminalPaymentState,
    required this.hasReservationEnded,
    required this.hasAnyCancelledReservation,
    required this.cancelAllowedInReservationPhase,
    required this.refundAllowedInReservationPhase,
    required this.isEscrowAlreadyInThread,
    required this.messageEscrowAllowedInReservationPhase,
    required this.isBlocked,
    required this.blockedReason,
    required this.lastSentByUs,
    required this.allowBarter,
    required this.underListedPrice,
    required this.isAtOrAboveListedPrice,
  });

  factory _ThreadHeaderFacts.from({
    required ThreadCubitState threadCubitState,
    required String hostPubkey,
    required String ourPubkey,
  }) {
    final listing = threadCubitState.listing;
    final threadState = threadCubitState.threadState;
    final role = listing != null && listing.pubKey == ourPubkey
        ? ThreadPartyRole.host
        : ThreadPartyRole.guest;

    final lastRequest = threadState.reservationRequests
        .map((message) => message.child)
        .whereType<ReservationRequest>()
        .lastOrNull;

    final sortedReservations = [...threadState.subscriptions.reservations]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestReservation = sortedReservations.firstOrNull;
    final cancelledReservations = sortedReservations
        .where((reservation) => reservation.parsedContent.cancelled)
        .toList();

    final escrowFromProof = sortedReservations
        .where(
          (reservation) => reservation.parsedContent.proof?.escrowProof != null,
        )
        .map(
          (reservation) =>
              reservation.parsedContent.proof!.escrowProof!.escrowService,
        )
        .firstOrNull;

    final source = sortedReservations.isNotEmpty
        ? ThreadHeaderSource.reservation
        : (lastRequest != null
              ? ThreadHeaderSource.reservationRequest
              : ThreadHeaderSource.listing);

    final startDate =
        latestReservation?.parsedContent.start ??
        lastRequest?.parsedContent.start;
    final endDate =
        latestReservation?.parsedContent.end ?? lastRequest?.parsedContent.end;

    final overlapLock =
        startDate != null && endDate != null && threadState.salt != null
        ? resolveOverlapLock(
            ourPubkey: ourPubkey,
            allListingReservations: threadState.subscriptions.reservations,
            startDate: startDate,
            endDate: endDate,
            salt: threadState.salt!,
          )
        : (isBlocked: false, reason: null);

    final paymentState = threadState.subscriptions.paymentStreamStatus;
    final paymentStateFresh =
        paymentState is StreamStatusLive ||
        paymentState is StreamStatusQueryComplete;
    final hasTerminalPaymentState =
        paymentStateFresh &&
        threadState.subscriptions.paymentEvents.any(
          (event) =>
              event is PaymentClaimedEvent ||
              event is PaymentArbitratedEvent ||
              event is PaymentReleasedEvent,
        );

    final hasReservationEnded = endDate != null
        ? endDate.isBefore(DateTime.now())
        : false;
    final hasAnyCancelledReservation = cancelledReservations.isNotEmpty;

    final isSelfSigned = listing != null
        ? !sortedReservations.any(
            (reservation) => reservation.pubKey == listing.pubKey,
          )
        : false;

    final hasEscrow = escrowFromProof != null;
    final escrowPubkey = escrowFromProof?.parsedContent.pubkey;
    final isEscrowAlreadyInThread =
        escrowPubkey != null &&
        threadState.messages.any(
          (message) =>
              message.pubKey == escrowPubkey ||
              message.pTags.contains(escrowPubkey),
        );
    final messageEscrowAllowedInReservationPhase =
        escrowPubkey != null && !isEscrowAlreadyInThread;

    final cancelAllowedInReservationPhase =
        paymentStateFresh &&
        !hasReservationEnded &&
        !hasTerminalPaymentState &&
        !hasAnyCancelledReservation;
    final refundAllowedInReservationPhase =
        paymentStateFresh && !hasTerminalPaymentState;

    final listedAmount = lastRequest != null && listing != null
        ? listing.cost(
            lastRequest.parsedContent.start,
            lastRequest.parsedContent.end,
          )
        : null;
    final requestAmount = lastRequest?.parsedContent.amount;
    final sameCurrency =
        listedAmount != null &&
        requestAmount != null &&
        listedAmount.currency == requestAmount.currency;
    final underListedPrice =
        sameCurrency && requestAmount.value < listedAmount.value;
    final isAtOrAboveListedPrice =
        sameCurrency && requestAmount.value >= listedAmount.value;

    return _ThreadHeaderFacts(
      source: source,
      role: role,
      lastRequest: lastRequest,
      latestReservation: latestReservation,
      escrowFromProof: escrowFromProof,
      escrowPubkey: escrowPubkey,
      isSelfSigned: isSelfSigned,
      hasEscrow: hasEscrow,
      paymentStateFresh: paymentStateFresh,
      hasTerminalPaymentState: hasTerminalPaymentState,
      hasReservationEnded: hasReservationEnded,
      hasAnyCancelledReservation: hasAnyCancelledReservation,
      cancelAllowedInReservationPhase: cancelAllowedInReservationPhase,
      refundAllowedInReservationPhase: refundAllowedInReservationPhase,
      isEscrowAlreadyInThread: isEscrowAlreadyInThread,
      messageEscrowAllowedInReservationPhase:
          messageEscrowAllowedInReservationPhase,
      isBlocked: overlapLock.isBlocked,
      blockedReason: overlapLock.reason,
      lastSentByUs: lastRequest?.pubKey == ourPubkey,
      allowBarter: listing?.parsedContent.allowBarter ?? false,
      underListedPrice: underListedPrice,
      isAtOrAboveListedPrice: isAtOrAboveListedPrice,
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

    return reservation.parsedTags.commitmentHash != ourCommitment;
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
