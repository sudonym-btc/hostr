import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';

import 'seed_pipeline_config.dart';

// ─── Reactive streams ───────────────────────────────────────────────────────

/// A typed record for EVM funding events.
typedef UserFunded = ({SeedUser user, BigInt amountWei, String address});

/// A typed record for on-chain escrow transactions.
typedef ChainTransaction = ({SeedThread thread, String txHash, String action});

/// A typed record for NIP-05 identity creation.
typedef Nip05Created = ({String username, String domain});

/// Reactive streams emitted by [SeedPipeline.run].
///
/// All subjects are [ReplaySubject]s — late subscribers receive every
/// previously emitted value, so consumers can attach after the pipeline
/// has already started producing.
///
/// ```dart
/// final streams = pipeline.run();
///
/// // Broadcast events as they arrive:
/// streams.events
///     .bufferCount(50)
///     .asyncMap((batch) => broadcastBatch(ndk, batch))
///     .listen((_) {});
///
/// // React to funding:
/// streams.userFunded.listen((r) =>
///     print('Funded ${r.address} with ${r.amountWei} wei'));
///
/// // Accumulate summary at the end:
/// final data = await streams.done.first;
/// print(data.summary.toJson());
/// ```
class SeedStreams {
  /// Every Nostr event ready for relay broadcast, emitted as each
  /// pipeline stage completes.
  final events = ReplaySubject<Nip01Event>();

  /// EVM address funded via `anvil_setBalance`.
  final userFunded = ReplaySubject<UserFunded>();

  /// On-chain escrow transaction confirmed (createTrade / settle / etc).
  final chainTx = ReplaySubject<ChainTransaction>();

  /// NIP-05 identity entry created via LNbits nostrnip5 extension.
  final nip05Created = ReplaySubject<Nip05Created>();

  /// Terminal signal — carries the full aggregate [SeedPipelineData].
  final done = ReplaySubject<SeedPipelineData>();

  /// Closes all subjects.  Safe to call multiple times.
  void dispose() {
    events.close();
    userFunded.close();
    chainTx.close();
    nip05Created.close();
    done.close();
  }
}

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
  String? invalidReservationReason;

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
    this.invalidReservationReason,
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
      messages: threadMessages.length,
      reservations: reservations.length,
      zapReceipts: zapReceipts.length,
      reviews: reviews.length,
      escrowServices: escrowServices.length,
      escrowTrusts: escrowTrusts.length,
      escrowMethods: escrowMethods.length,
      invalidReservations: invalidReservations,
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
  final List<InvalidReservationInfo> invalidReservations;

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
    required this.invalidReservations,
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
    'invalidReservations': invalidReservations
        .map((info) => info.toJson())
        .toList(),
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
