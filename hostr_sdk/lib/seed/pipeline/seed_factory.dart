import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'seed_context.dart';
import 'seed_pipeline_config.dart';
import 'seed_pipeline_models.dart';
import 'stages/build_listings.dart' as stage_listings;
import 'stages/build_messages.dart' as stage_messages;
import 'stages/build_profiles.dart' as stage_profiles;
import 'stages/build_reviews.dart' as stage_reviews;
import 'stages/build_threads.dart' as stage_threads;
import 'stages/build_users.dart' as stage_users;

/// Pure-data seed factory.  **No I/O, no network, no chain.**
///
/// Produces deterministic, signed Nostr events from a seed integer.
/// Every method is either synchronous or only async because of
/// NIP-17 gift-wrapping (local crypto), never because of network calls.
///
/// Use this in unit tests, widget tests, and screenshot pipelines where
/// you want realistic data without spinning up Docker / Anvil / relays.
///
/// ```dart
/// final factory = SeedFactory(
///   config: SeedPipelineConfig(seed: 42, userCount: 4, hostRatio: 0.5),
/// );
/// final data = await factory.buildAll();
/// testRequests.seedEvents(data.allEvents);
/// ```
///
/// For the full infrastructure-backed seeder (EVM funding, LNbits setup,
/// on-chain escrow trades) use [SeedPipeline] instead — it delegates to
/// this factory for the pure-data stages and layers infrastructure on top.
class SeedFactory {
  final SeedPipelineConfig config;
  final SeedContext _ctx;

  SeedFactory({
    required this.config,
    String contractAddress = '0x0000000000000000000000000000000000000000',
  }) : _ctx = SeedContext(
         seed: config.seed,
         contractAddress: contractAddress,
         rpcUrl: 'unused', // never called — all stages are pure data
         userCount: config.userCount + config.userOverrides.length,
         reservationRequestsPerGuest: config.reservationRequestsPerGuest,
       );

  /// Internal constructor used by [SeedPipeline] to share its [SeedContext].
  SeedFactory.fromContext({required this.config, required SeedContext ctx})
    : _ctx = ctx;

  /// Expose the context for advanced callers (key derivation, timestamps).
  SeedContext get context => _ctx;

  // ── Individual stages ─────────────────────────────────────────────────────

  List<SeedUser> buildUsers() =>
      stage_users.buildUsers(ctx: _ctx, config: config);

  List<ProfileMetadata> buildProfiles(List<SeedUser> users) =>
      stage_profiles.buildProfiles(ctx: _ctx, users: users);

  ProfileMetadata buildEscrowProfile() =>
      stage_profiles.buildEscrowProfile(ctx: _ctx);

  List<EscrowService> buildEscrowServices({String? contractAddress}) =>
      stage_profiles.buildEscrowServices(
        contractAddress: contractAddress ?? _ctx.contractAddress,
      );

  Future<List<EscrowTrust>> buildEscrowTrusts(List<SeedUser> users) =>
      stage_profiles.buildEscrowTrusts(ctx: _ctx, users: users);

  Future<List<EscrowMethod>> buildEscrowMethods(List<SeedUser> users) =>
      stage_profiles.buildEscrowMethods(ctx: _ctx, users: users);

  List<Listing> buildListings(List<SeedUser> hosts) =>
      stage_listings.buildListings(ctx: _ctx, config: config, hosts: hosts);

  /// Build threads in "pending" state (reservation request, no outcome).
  ///
  /// [now] is the reference timestamp for date calculations.  Defaults to
  /// `DateTime.now().toUtc()` so no chain connection is required.
  Future<List<SeedThread>> buildThreads({
    required List<SeedUser> hosts,
    required List<SeedUser> guests,
    required List<Listing> listings,
    DateTime? now,
  }) => stage_threads.buildThreads(
    ctx: _ctx,
    config: config,
    hosts: hosts,
    guests: guests,
    listings: listings,
    now: now ?? DateTime.now().toUtc(),
  );

  Future<List<Nip01Event>> buildMessages(List<SeedThread> threads) =>
      stage_messages.buildMessages(ctx: _ctx, threads: threads);

  Future<List<Nip01Event>> buildEscrowSelectedMessages(
    List<SeedThread> threads,
  ) => stage_messages.buildEscrowSelectedMessages(ctx: _ctx, threads: threads);

  List<Review> buildReviews(List<SeedThread> threads) =>
      stage_reviews.buildReviews(ctx: _ctx, threads: threads);

  /// Derive a deterministic key pair from an index.
  KeyPair deriveKeyPair(int index) => _ctx.deriveKeyPair(index);

  // ── Convenience: build everything at once ─────────────────────────────────

  /// Runs all pure-data stages and returns the aggregate result.
  ///
  /// Does **not** run outcomes (which require on-chain interaction) —
  /// all threads remain in "pending" state.  For completed-looking
  /// reservations without a real chain, see [buildMockReservation].
  ///
  /// [now] controls the reference timestamp for thread date generation.
  Future<SeedPipelineData> buildAll({DateTime? now}) async {
    final users = buildUsers();
    final hosts = users.where((u) => u.isHost).toList(growable: false);
    final guests = users.where((u) => !u.isHost).toList(growable: false);

    final profiles = [...buildProfiles(users), buildEscrowProfile()];
    final escrowServices = buildEscrowServices();
    final escrowTrusts = await buildEscrowTrusts(users);
    final escrowMethods = await buildEscrowMethods(users);

    final listings = buildListings(hosts);
    final threads = await buildThreads(
      hosts: hosts,
      guests: guests,
      listings: listings,
      now: now,
    );

    final reservationRequests =
        threads.map((t) => t.request).toList(growable: false);

    final messages = await buildMessages(threads);
    final escrowSelectedMessages =
        await buildEscrowSelectedMessages(threads);
    final reviews = buildReviews(threads);

    return SeedPipelineData(
      users: users,
      profiles: profiles,
      listings: listings,
      escrowServices: escrowServices,
      escrowTrusts: escrowTrusts,
      escrowMethods: escrowMethods,
      threads: threads,
      reservationRequests: reservationRequests,
      threadMessages: [...messages, ...escrowSelectedMessages],
      reservations: const [], // no outcomes — all pending
      zapReceipts: const [],
      reviews: reviews,
    );
  }

  /// Build a mock reservation for a thread **without** any chain
  /// interaction.
  ///
  /// Useful for UI tests that need a completed-looking thread.
  /// The [hostProfile] is required so the [PaymentProof] can reference
  /// the host's signed profile metadata.
  ///
  /// Set [withEscrowProof] to `true` and provide [escrowService],
  /// [escrowTrust], and [escrowMethod] for an escrow-styled proof.
  /// Otherwise a zap-receipt-based proof (with null zap receipt) is used.
  Reservation buildMockReservation(
    SeedThread thread, {
    required ProfileMetadata hostProfile,
    bool withEscrowProof = false,
    EscrowService? escrowService,
    EscrowTrust? escrowTrust,
    EscrowMethod? escrowMethod,
  }) {
    final PaymentProof? proof;
    if (withEscrowProof &&
        escrowService != null &&
        escrowTrust != null &&
        escrowMethod != null) {
      proof = PaymentProof(
        hoster: hostProfile,
        listing: thread.listing,
        zapProof: null,
        escrowProof: EscrowProof(
          txHash:
              '0x${List.generate(64, (i) => ((thread.salt.codeUnitAt(i % thread.salt.length) + i) % 16).toRadixString(16)).join()}',
          escrowService: escrowService,
          hostsTrustedEscrows: escrowTrust,
          hostsEscrowMethods: escrowMethod,
        ),
      );
    } else {
      proof = PaymentProof(
        hoster: hostProfile,
        listing: thread.listing,
        zapProof: null,
        escrowProof: null,
      );
    }

    return Reservation(
      pubKey: thread.guest.keyPair.publicKey,
      tags: ReservationTags([
        [kListingRefTag, thread.listing.anchor!],
        [kThreadRefTag, thread.request.getDtag()!],
        ['d', 'mock-reservation-${thread.salt}'],
        [kCommitmentHashTag, thread.commitmentHash],
      ]),
      createdAt: _ctx.timestampDaysAfter(80),
      content: ReservationContent(
        start: thread.start,
        end: thread.end,
        proof: proof,
      ),
    ).signAs(thread.guest.keyPair, Reservation.fromNostrEvent);
  }

  void dispose() => _ctx.dispose();
}
