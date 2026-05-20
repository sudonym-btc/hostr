import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'seed_pipeline_config.dart';

String _nsecFor(KeyPair keyPair) => keyPair.privateKey == null
    ? '(read-only)'
    : (keyPair.privateKeyBech32 ?? '(read-only)');

// ─── Core models ────────────────────────────────────────────────────────────

enum EscrowOutcome { releaseToCounterparty, arbitrated, claimedByHost }

class SeedUser {
  final int index;
  final KeyPair keyPair;
  final bool isHost;
  final bool hasEvm;
  final bool setupLnbits;

  /// If created from a [SeedUserSpec] override, retains the spec for
  /// per-user thread stage resolution.
  final SeedUserSpec? spec;

  const SeedUser({
    required this.index,
    required this.keyPair,
    required this.isHost,
    required this.hasEvm,
    this.setupLnbits = false,
    this.spec,
  });
}

/// A thread in "pending" state — reservation request created, but no
/// outcome (escrow/zap) yet. The pipeline's outcome stage operates on these.
class SeedThread {
  final SeedUser host;
  final SeedUser guest;
  final Listing listing;
  final Reservation request;
  final int guestTradeAccountIndex;
  final KeyPair requestAuthorKeyPair;

  /// Stable deterministic identifier for this seeded negotiation/thread.
  final String id;
  final DateTime start;
  final DateTime end;

  /// Resolved thread stage spec (per-user override or global default).
  final ThreadStageSpec stageSpec;

  // ── Mutable: filled in by outcome stage ──
  Reservation? reservation;
  Nip01Event? zapReceipt;
  bool paidViaEscrow;
  EscrowOutcome? escrowOutcome;
  bool selfSigned;
  String? invalidReservationReason;

  SeedThread({
    required this.host,
    required this.guest,
    required this.listing,
    required this.request,
    required this.guestTradeAccountIndex,
    required this.requestAuthorKeyPair,
    required this.id,
    required this.start,
    required this.end,
    required this.stageSpec,
    this.reservation,
    this.zapReceipt,
    this.paidViaEscrow = false,
    this.escrowOutcome,
    this.selfSigned = false,
    this.invalidReservationReason,
  });
}

// ─── Outcome plan ────────────────────────────────────────────────────────────

/// The deterministic plan for a single thread's outcome.
///
/// Computed in [buildOutcomePlans] (Phase 0, synchronous, no I/O).
/// The execution stage ([buildOutcomes]) mutates [createTxHash],
/// [tradeAlreadyExisted], and [needsSettlement] as I/O results arrive.
class SeedOutcomePlan {
  final int index;
  final SeedThread thread;
  bool useEscrow;
  EscrowOutcome? escrowOutcome;
  final bool selfSigned;
  EscrowMethod? method;

  // ── Filled in during execution (buildOutcomes) ──
  String? createTxHash;
  bool tradeAlreadyExisted = false;
  bool needsSettlement = false;
  int? assignedCreateNonce;
  int? assignedSettleNonce;

  SeedOutcomePlan({
    required this.index,
    required this.thread,
    required this.useEscrow,
    this.escrowOutcome,
    required this.selfSigned,
    this.method,
  });
}

// ─── Aggregate result ───────────────────────────────────────────────────────

class SeedPipelineData {
  final List<SeedUser> users;
  final List<ProfileMetadata> profiles;
  final List<IdentityClaims> identityClaims;
  final List<Listing> listings;
  final List<EscrowService> escrowServices;
  final List<EscrowMethod> escrowMethods;
  final List<SeedThread> threads;
  final List<Reservation> reservationRequests;
  final List<ReservationTransition> orderTransitions;
  final List<Nip01Event> threadMessages;
  final List<Reservation> reservations;
  final List<Nip01Event> zapReceipts;
  final List<Review> reviews;
  final List<BadgeDefinition> badgeDefinitions;
  final List<BadgeAward> badgeAwards;

  const SeedPipelineData({
    required this.users,
    required this.profiles,
    required this.identityClaims,
    required this.listings,
    required this.escrowServices,
    required this.escrowMethods,
    required this.threads,
    required this.reservationRequests,
    required this.orderTransitions,
    required this.threadMessages,
    required this.reservations,
    required this.zapReceipts,
    required this.reviews,
    this.badgeDefinitions = const [],
    this.badgeAwards = const [],
  });

  List<Nip01Event> get allEvents => [
    ...profiles,
    ...identityClaims,
    ...escrowServices,
    ...escrowMethods,
    ...listings,
    // reservationRequests are intentionally excluded — negotiate-stage
    // events must only appear gift-wrapped (present in threadMessages).
    ...orderTransitions,
    ...threadMessages,
    ...zapReceipts,
    ...reservations,
    ...reviews,
    ...badgeDefinitions,
    ...badgeAwards,
  ];

  SeedSummary get summary {
    final hosts = users.where((u) => u.isHost).length;
    final completedThreads = threads.where((t) => t.reservation != null).length;
    final pendingThreads = threads.where((t) => t.reservation == null).length;
    final selfSignedThreads = threads.where((t) => t.selfSigned).length;
    final escrowThreads = threads.where((t) => t.paidViaEscrow).length;
    final zapThreads = threads
        .where((t) => t.reservation != null && !t.paidViaEscrow)
        .length;
    final invalidReservations = threads
        .where(
          (t) => t.invalidReservationReason != null && t.reservation != null,
        )
        .map((t) {
          final reservation = t.reservation!;
          final listingAnchor = t.listing.anchor ?? 'unknown';
          final deterministicId =
              _findTagValue(reservation.parsedTags, 'd') ?? reservation.id;
          return InvalidReservationInfo(
            listingAnchor: listingAnchor,
            reservationId: deterministicId,
            reason: t.invalidReservationReason!,
          );
        })
        .toList(growable: false);

    return SeedSummary(
      users: users.length,
      hosts: hosts,
      guests: users.length - hosts,
      profiles: profiles.length,
      listings: listings.length,
      threads: threads.length,
      pendingThreads: pendingThreads,
      completedThreads: completedThreads,
      selfSignedThreads: selfSignedThreads,
      escrowThreads: escrowThreads,
      zapThreads: zapThreads,
      reservationRequests: reservationRequests.length,
      orderTransitions: orderTransitions.length,
      messages: threadMessages.length,
      reservations: reservations.length,
      zapReceipts: zapReceipts.length,
      reviews: reviews.length,
      escrowServices: escrowServices.length,
      escrowMethods: escrowMethods.length,
      invalidReservations: invalidReservations,
      badgeDefinitions: badgeDefinitions.length,
      badgeAwards: badgeAwards.length,
    );
  }
}

// ─── Summary ────────────────────────────────────────────────────────────────

class SeedSummary {
  final int users;
  final int hosts;
  final int guests;
  final int profiles;
  final int listings;
  final int threads;
  final int pendingThreads;
  final int completedThreads;
  final int selfSignedThreads;
  final int escrowThreads;
  final int zapThreads;
  final int reservationRequests;
  final int orderTransitions;
  final int messages;
  final int reservations;
  final int zapReceipts;
  final int reviews;
  final int escrowServices;
  final int escrowMethods;
  final List<InvalidReservationInfo> invalidReservations;
  final int badgeDefinitions;
  final int badgeAwards;

  const SeedSummary({
    required this.users,
    required this.hosts,
    required this.guests,
    required this.profiles,
    required this.listings,
    required this.threads,
    required this.pendingThreads,
    required this.completedThreads,
    required this.selfSignedThreads,
    required this.escrowThreads,
    required this.zapThreads,
    required this.reservationRequests,
    required this.orderTransitions,
    required this.messages,
    required this.reservations,
    required this.zapReceipts,
    required this.reviews,
    required this.escrowServices,
    required this.escrowMethods,
    required this.invalidReservations,
    this.badgeDefinitions = 0,
    this.badgeAwards = 0,
  });

  Map<String, dynamic> toJson() => {
    'users': users,
    'hosts': hosts,
    'guests': guests,
    'profiles': profiles,
    'listings': listings,
    'threads': threads,
    'pendingThreads': pendingThreads,
    'completedThreads': completedThreads,
    'selfSignedThreads': selfSignedThreads,
    'escrowThreads': escrowThreads,
    'zapThreads': zapThreads,
    'reservationRequests': reservationRequests,
    'orderTransitions': orderTransitions,
    'messages': messages,
    'reservations': reservations,
    'zapReceipts': zapReceipts,
    'reviews': reviews,
    'escrowServices': escrowServices,
    'escrowMethods': escrowMethods,
    'invalidReservations': invalidReservations
        .map((info) => info.toJson())
        .toList(),
    'badgeDefinitions': badgeDefinitions,
    'badgeAwards': badgeAwards,
  };
}

class InvalidReservationInfo {
  final String listingAnchor;
  final String reservationId;
  final String reason;

  const InvalidReservationInfo({
    required this.listingAnchor,
    required this.reservationId,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'listingAnchor': listingAnchor,
    'reservationId': reservationId,
    'reason': reason,
  };
}

String? _findTagValue(EventTags tags, String tagType) {
  for (final tag in tags.tags) {
    if (tag.length >= 2 && tag[0] == tagType) {
      return tag[1];
    }
  }
  return null;
}

// ─── Pipeline spec (pre-run plan) ────────────────────────────────────────────

/// A fully-deterministic description of what the pipeline intends to build.
///
/// Computed synchronously from [buildOutcomePlans] before any I/O.
/// Print at the very start of the run so the full plan is visible before
/// waiting for EVM / LNbits calls.
class SeedPipelineSpec {
  final int seed;
  final List<SeedUser> users;
  final List<Listing> listings;
  final List<SeedThread> threads;
  final List<SeedOutcomePlan> outcomePlans;

  const SeedPipelineSpec({
    required this.seed,
    required this.users,
    required this.listings,
    required this.threads,
    required this.outcomePlans,
  });

  void printSpec() {
    print(
      "\n[seed][plan]\n${JsonEncoder.withIndent('  ').convert(toSummaryJson())}",
    );
  }

  Map<String, dynamic> toSummaryJson() {
    final hosts = users.where((u) => u.isHost).toList();
    final guests = users.where((u) => !u.isHost).toList();

    return {
      'seed': seed,
      'totals': _totalsJson(hosts: hosts, guests: guests),
      'planned_escrow_outcomes': _plannedEscrowOutcomesJson(),
    };
  }

  Map<String, dynamic> toJson() {
    final hosts = users.where((u) => u.isHost).toList();
    final guests = users.where((u) => !u.isHost).toList();
    final planByThreadId = {for (final p in outcomePlans) p.thread.id: p};

    return {
      'seed': seed,
      'totals': _totalsJson(hosts: hosts, guests: guests),
      'planned_escrow_outcomes': _plannedEscrowOutcomesJson(),
      'hosts': [
        for (final host in hosts)
          <String, dynamic>{
            'pubkey': host.keyPair.publicKey,
            'privkey': host.keyPair.privateKey ?? '(read-only)',
            'nsec': _nsecFor(host.keyPair),
            'has_evm': host.hasEvm,
            'listings': listings
                .where((l) => l.pubKey == host.keyPair.publicKey)
                .map((l) => l.anchor ?? 'unknown')
                .toList(),
            'threads': [
              for (final t in threads.where(
                (t) => t.host.keyPair.publicKey == host.keyPair.publicKey,
              ))
                _threadSpecEntry(t, planByThreadId[t.id]),
            ],
          },
      ],
      'guests': [
        for (final guest in guests)
          <String, dynamic>{
            'pubkey': guest.keyPair.publicKey,
            'privkey': guest.keyPair.privateKey ?? '(read-only)',
            'nsec': _nsecFor(guest.keyPair),
            'threads': [
              for (final t in threads.where(
                (t) => t.guest.keyPair.publicKey == guest.keyPair.publicKey,
              ))
                _threadSpecEntry(t, planByThreadId[t.id]),
            ],
          },
      ],
    };
  }

  Map<String, dynamic> _totalsJson({
    required List<SeedUser> hosts,
    required List<SeedUser> guests,
  }) {
    return {
      'users': users.length,
      'hosts': hosts.length,
      'guests': guests.length,
      'listings': listings.length,
      'threads': threads.length,
      'threads_with_planned_outcome': outcomePlans.length,
      'threads_pending': threads.length - outcomePlans.length,
      'escrow_threads': outcomePlans.where((p) => p.useEscrow).length,
      'zap_threads': outcomePlans.where((p) => !p.useEscrow).length,
      'self_signed_by_buyer': outcomePlans.where((p) => p.selfSigned).length,
    };
  }

  Map<String, dynamic> _plannedEscrowOutcomesJson() {
    return {
      'claimed_by_host': outcomePlans
          .where((p) => p.escrowOutcome == EscrowOutcome.claimedByHost)
          .length,
      'released_to_counterparty': outcomePlans
          .where((p) => p.escrowOutcome == EscrowOutcome.releaseToCounterparty)
          .length,
      'arbitrated': outcomePlans
          .where((p) => p.escrowOutcome == EscrowOutcome.arbitrated)
          .length,
    };
  }

  static Map<String, dynamic> _threadSpecEntry(
    SeedThread thread,
    SeedOutcomePlan? plan,
  ) {
    return <String, dynamic>{
      'trade_id': thread.request.getDtag() ?? thread.id,
      'listing_anchor': thread.listing.anchor ?? 'unknown',
      'check_in': thread.start.toIso8601String().substring(0, 10),
      'check_out': thread.end.toIso8601String().substring(0, 10),
      'planned_outcome': plan == null
          ? 'pending'
          : <String, dynamic>{
              'proof_type': plan.useEscrow ? 'escrow' : 'zap',
              if (plan.useEscrow)
                'escrow_settlement': plan.escrowOutcome?.name ?? 'active',
              'self_signed_by_buyer': plan.selfSigned,
            },
    };
  }
}

// ─── Pipeline outcome (post-run report) ──────────────────────────────────────

/// Outcome report produced after all I/O (EVM trades, zap receipts) has
/// completed. Contains only information that was NOT known at planning time:
/// tx hashes, on-chain settlement confirmations, and proof validity.
class SeedPipelineOutcome {
  final List<SeedThread> threads;
  final List<SeedOutcomePlan> plans;

  const SeedPipelineOutcome({required this.threads, required this.plans});

  void printOutcome() {
    print(
      "\n[seed][outcome]\n${JsonEncoder.withIndent('  ').convert(toSummaryJson())}",
    );
  }

  Map<String, dynamic> toSummaryJson() {
    return {
      'totals': _totalsJson(),
      'settlements': {
        'claimed_by_host': plans
            .where((p) => p.escrowOutcome == EscrowOutcome.claimedByHost)
            .length,
        'released_to_counterparty': plans
            .where(
              (p) => p.escrowOutcome == EscrowOutcome.releaseToCounterparty,
            )
            .length,
        'arbitrated': plans
            .where((p) => p.escrowOutcome == EscrowOutcome.arbitrated)
            .length,
      },
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'totals': _totalsJson(),
      'hosts': _groupByHost(_completedPlans()),
      'guests': _groupByGuest(_completedPlans()),
      if (_pendingThreads().isNotEmpty)
        'pending_threads': [
          for (final t in _pendingThreads())
            <String, dynamic>{
              'trade_id': t.request.getDtag() ?? t.id,
              'host_pubkey': t.host.keyPair.publicKey,
              'guest_pubkey': t.guest.keyPair.publicKey,
              'check_in': t.start.toIso8601String().substring(0, 10),
              'check_out': t.end.toIso8601String().substring(0, 10),
            },
        ],
    };
  }

  List<SeedOutcomePlan> _completedPlans() =>
      plans.where((p) => p.thread.reservation != null).toList();

  List<SeedThread> _pendingThreads() =>
      threads.where((t) => t.reservation == null).toList();

  Map<String, dynamic> _totalsJson() {
    final completedPlans = plans
        .where((p) => p.thread.reservation != null)
        .toList();
    final pendingThreads = threads.where((t) => t.reservation == null).toList();

    return {
      'threads_total': threads.length,
      'threads_with_reservation': completedPlans.length,
      'threads_pending': pendingThreads.length,
      'escrow_trades_newly_created': completedPlans
          .where((p) => p.createTxHash != null && !p.tradeAlreadyExisted)
          .length,
      'escrow_trades_already_existed_on_chain': completedPlans
          .where((p) => p.tradeAlreadyExisted)
          .length,
      'zap_receipts_built': completedPlans
          .where((p) => !p.useEscrow && p.thread.zapReceipt != null)
          .length,
      'invalid_reservations': completedPlans
          .where((p) => p.thread.invalidReservationReason != null)
          .length,
    };
  }

  static List<Map<String, dynamic>> _groupByHost(List<SeedOutcomePlan> plans) {
    final byHost = <String, List<SeedOutcomePlan>>{};
    final privkeyByHost = <String, String>{};
    final nsecByHost = <String, String>{};
    for (final p in plans) {
      final pub = p.thread.host.keyPair.publicKey;
      byHost.putIfAbsent(pub, () => []).add(p);
      privkeyByHost[pub] = p.thread.host.keyPair.privateKey ?? '(read-only)';
      nsecByHost[pub] = _nsecFor(p.thread.host.keyPair);
    }
    return [
      for (final pub in byHost.keys)
        <String, dynamic>{
          'pubkey': pub,
          'privkey': privkeyByHost[pub],
          'nsec': nsecByHost[pub],
          'threads': byHost[pub]!.map(_threadOutcomeEntry).toList(),
        },
    ];
  }

  static List<Map<String, dynamic>> _groupByGuest(List<SeedOutcomePlan> plans) {
    final byGuest = <String, List<SeedOutcomePlan>>{};
    final privkeyByGuest = <String, String>{};
    final nsecByGuest = <String, String>{};
    for (final p in plans) {
      final pub = p.thread.guest.keyPair.publicKey;
      byGuest.putIfAbsent(pub, () => []).add(p);
      privkeyByGuest[pub] = p.thread.guest.keyPair.privateKey ?? '(read-only)';
      nsecByGuest[pub] = _nsecFor(p.thread.guest.keyPair);
    }
    return [
      for (final pub in byGuest.keys)
        <String, dynamic>{
          'pubkey': pub,
          'privkey': privkeyByGuest[pub],
          'nsec': nsecByGuest[pub],
          'threads': byGuest[pub]!.map(_threadOutcomeEntry).toList(),
        },
    ];
  }

  static Map<String, dynamic> _threadOutcomeEntry(SeedOutcomePlan plan) {
    final thread = plan.thread;
    final proof = thread.reservation?.proof;
    final invalidReason = thread.invalidReservationReason;

    final Map<String, dynamic> proofEntry;
    if (proof == null) {
      proofEntry = <String, dynamic>{
        'type': 'no_proof',
        'fault': invalidReason ?? 'not_required',
      };
    } else if (proof.escrowProof != null) {
      final e = proof.escrowProof!;
      proofEntry = <String, dynamic>{
        'type': 'escrow',
        'tx_hash': e.txHash,
        'contract_address': e.escrowService.contractAddress,
        'settlement_outcome': plan.escrowOutcome?.name ?? 'active',
        'trade_already_existed_on_chain': plan.tradeAlreadyExisted,
        'proof_valid': invalidReason == null,
        if (invalidReason != null)
          'validity_fault': <String, dynamic>{
            'reason': invalidReason,
            'wrong_contract_address': invalidReason == 'bogus_escrow_proof',
            'proof_intentionally_dropped':
                invalidReason == 'missing_payment_proof',
          },
      };
    } else {
      String? amountMsats;
      final zap = thread.zapReceipt;
      if (zap != null) {
        for (final tag in zap.tags) {
          if (tag.length >= 2 && tag[0] == 'amount') {
            amountMsats = tag[1];
            break;
          }
        }
      }
      proofEntry = <String, dynamic>{
        'type': 'zap',
        'amount_msats': amountMsats,
        'receipt_event_id': thread.zapReceipt?.id,
        'proof_valid': invalidReason == null,
        if (invalidReason != null)
          'validity_fault': <String, dynamic>{
            'reason': invalidReason,
            'proof_intentionally_dropped': true,
          },
      };
    }

    return <String, dynamic>{
      'trade_id': thread.request.getDtag() ?? thread.id,
      'check_in': thread.start.toIso8601String().substring(0, 10),
      'check_out': thread.end.toIso8601String().substring(0, 10),
      'reservation_stage': thread.reservation?.stage.name,
      'self_signed_by_buyer': plan.selfSigned,
      'proof': proofEntry,
    };
  }
}
