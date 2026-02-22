import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'seed_pipeline_config.dart';

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
  final ReservationRequest request;
  final String salt;
  final String commitmentHash;
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

  SeedThread({
    required this.host,
    required this.guest,
    required this.listing,
    required this.request,
    required this.salt,
    required this.commitmentHash,
    required this.start,
    required this.end,
    required this.stageSpec,
    this.reservation,
    this.zapReceipt,
    this.paidViaEscrow = false,
    this.escrowOutcome,
    this.selfSigned = false,
  });
}

// ─── Aggregate result ───────────────────────────────────────────────────────

class SeedPipelineData {
  final List<SeedUser> users;
  final List<ProfileMetadata> profiles;
  final List<Listing> listings;
  final List<EscrowService> escrowServices;
  final List<EscrowTrust> escrowTrusts;
  final List<EscrowMethod> escrowMethods;
  final List<SeedThread> threads;
  final List<ReservationRequest> reservationRequests;
  final List<Nip01Event> threadMessages;
  final List<Reservation> reservations;
  final List<Nip01Event> zapReceipts;
  final List<Review> reviews;

  const SeedPipelineData({
    required this.users,
    required this.profiles,
    required this.listings,
    required this.escrowServices,
    required this.escrowTrusts,
    required this.escrowMethods,
    required this.threads,
    required this.reservationRequests,
    required this.threadMessages,
    required this.reservations,
    required this.zapReceipts,
    required this.reviews,
  });

  List<Nip01Event> get allEvents => [
    ...profiles,
    ...escrowServices,
    ...escrowTrusts,
    ...escrowMethods,
    ...listings,
    ...reservationRequests,
    ...threadMessages,
    ...zapReceipts,
    ...reservations,
    ...reviews,
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
      messages: threadMessages.length,
      reservations: reservations.length,
      zapReceipts: zapReceipts.length,
      reviews: reviews.length,
      escrowServices: escrowServices.length,
      escrowTrusts: escrowTrusts.length,
      escrowMethods: escrowMethods.length,
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
  final int messages;
  final int reservations;
  final int zapReceipts;
  final int reviews;
  final int escrowServices;
  final int escrowTrusts;
  final int escrowMethods;

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
    required this.messages,
    required this.reservations,
    required this.zapReceipts,
    required this.reviews,
    required this.escrowServices,
    required this.escrowTrusts,
    required this.escrowMethods,
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
    'messages': messages,
    'reservations': reservations,
    'zapReceipts': zapReceipts,
    'reviews': reviews,
    'escrowServices': escrowServices,
    'escrowTrusts': escrowTrusts,
    'escrowMethods': escrowMethods,
  };
}
