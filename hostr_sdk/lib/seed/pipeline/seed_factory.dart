import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'entity_factory.dart';
import 'seed_context.dart';
import 'seed_pipeline_config.dart';
import 'seed_pipeline_models.dart';
import 'stages/build_badges.dart' as stage_badges;
import 'stages/build_listings.dart' as stage_listings;
import 'stages/build_messages.dart' as stage_messages;
import 'stages/build_profiles.dart' as stage_profiles;
import 'stages/build_order_transitions.dart' as stage_transitions;
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
/// For the full pipeline with outcome resolution (EVM trades, zap
/// receipts, etc.) use [Seeder] — it delegates to this factory for
/// the pure-data stages and routes chain ops through [SeedSink].
class SeedFactory {
  final SeedPipelineConfig config;
  final SeedContext _ctx;
  late final EntityFactory _entities;

  SeedFactory({
    required this.config,
    String contractAddress = '0x0000000000000000000000000000000000000000',
  }) : _ctx = SeedContext(
         seed: config.seed,
         contractAddress: contractAddress,
         userCount: config.userCount + config.userOverrides.length,
         reservationRequestsPerGuest: config.reservationRequestsPerGuest,
       ) {
    _entities = EntityFactory(ctx: _ctx);
  }

  /// Expose the context for advanced callers (key derivation, timestamps).
  SeedContext get context => _ctx;

  /// Atomic entity builder — use this in unit tests for one-off events.
  EntityFactory get entities => _entities;

  // ── Individual stages ─────────────────────────────────────────────────────

  List<SeedUser> buildUsers() =>
      stage_users.buildUsers(ctx: _ctx, config: config);

  Future<List<ProfileMetadata>> buildProfiles(List<SeedUser> users) =>
      stage_profiles.buildProfiles(ctx: _ctx, users: users, factory: _entities);

  Future<List<IdentityClaims>> buildIdentityClaims(List<SeedUser> users) =>
      stage_profiles.buildIdentityClaims(
        ctx: _ctx,
        users: users,
        factory: _entities,
      );

  Future<ProfileMetadata> buildEscrowProfile() => stage_profiles
      .buildEscrowProfile(ctx: _ctx, config: config, factory: _entities);

  Future<IdentityClaims> buildEscrowIdentityClaims() =>
      stage_profiles.buildEscrowIdentityClaims(ctx: _ctx, factory: _entities);

  Future<List<EscrowService>> buildEscrowServices({
    String? contractAddress,
    String? multiEscrowBytecodeHash,
  }) => stage_profiles.buildEscrowServices(
    contractAddress: contractAddress ?? _ctx.contractAddress,
    multiEscrowBytecodeHash:
        multiEscrowBytecodeHash ?? config.multiEscrowBytecodeHash,
    factory: _entities,
  );

  Future<List<EscrowMethod>> buildEscrowMethods(List<SeedUser> users) =>
      stage_profiles.buildEscrowMethods(
        ctx: _ctx,
        users: users,
        multiEscrowBytecodeHash: config.multiEscrowBytecodeHash,
        chainId: config.chainId,
        tbtcAddress: config.tbtcAddress,
        usdtAddress: config.usdtAddress,
        factory: _entities,
      );

  List<Listing> buildListings(List<SeedUser> hosts) =>
      stage_listings.buildListings(
        ctx: _ctx,
        config: config,
        hosts: hosts,
        factory: _entities,
      );

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
    factory: _entities,
  );

  Future<List<Nip01Event>> buildMessages(List<SeedThread> threads) =>
      stage_messages.buildMessages(ctx: _ctx, threads: threads);

  Future<List<Nip01Event>> buildEscrowSelectedMessages(
    List<SeedThread> threads,
  ) => stage_messages.buildEscrowSelectedMessages(
    ctx: _ctx,
    threads: threads,
    factory: _entities,
  );

  List<ReservationTransition> buildOrderTransitions(List<SeedThread> threads) =>
      stage_transitions.buildOrderTransitions(
        threads: threads,
        factory: _entities,
      );

  Future<List<Review>> buildReviews(List<SeedThread> threads) => stage_reviews
      .buildReviews(ctx: _ctx, threads: threads, factory: _entities);

  stage_badges.BadgeSeedData buildBadges({
    required List<SeedUser> hosts,
    required List<Listing> listings,
  }) => stage_badges.buildBadges(
    ctx: _ctx,
    issuerKey: MockKeys.escrow,
    hosts: hosts,
    listings: listings,
  );

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

    final profiles = [
      ...await buildProfiles(users),
      await buildEscrowProfile(),
    ];
    final identityClaims = [
      ...await buildIdentityClaims(users),
      await buildEscrowIdentityClaims(),
    ];
    final escrowServices = await buildEscrowServices();
    final escrowMethods = await buildEscrowMethods(users);

    final listings = buildListings(hosts);
    final threads = await buildThreads(
      hosts: hosts,
      guests: guests,
      listings: listings,
      now: now,
    );

    final reservationRequests = threads
        .map((t) => t.request)
        .toList(growable: false);
    final orderTransitions = buildOrderTransitions(threads);

    final messages = await buildMessages(threads);
    final escrowSelectedMessages = await buildEscrowSelectedMessages(threads);
    final reviews = await buildReviews(threads);
    final badges = buildBadges(hosts: hosts, listings: listings);

    return SeedPipelineData(
      users: users,
      profiles: profiles,
      identityClaims: identityClaims,
      listings: listings,
      escrowServices: escrowServices,
      escrowMethods: escrowMethods,
      threads: threads,
      reservationRequests: reservationRequests,
      orderTransitions: orderTransitions,
      threadMessages: [...messages, ...escrowSelectedMessages],
      reservations: const [], // no outcomes — all pending
      zapReceipts: const [],
      reviews: reviews,
      badgeDefinitions: badges.definitions,
      badgeAwards: badges.awards,
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
  /// [escrowMethod] for an escrow-styled proof.
  /// Otherwise a zap-receipt-based proof (with null zap receipt) is used.
  Future<Reservation> buildMockReservation(
    SeedThread thread, {
    required ProfileMetadata hostProfile,
    bool withEscrowProof = false,
    EscrowService? escrowService,
    EscrowMethod? escrowMethod,
  }) {
    final PaymentProof? proof;
    if (withEscrowProof && escrowService != null && escrowMethod != null) {
      proof = PaymentProof(
        hoster: hostProfile,
        listing: thread.listing,
        zapProof: null,
        escrowProof: EscrowProof(
          txHash:
              '0x${List.generate(64, (i) => ((thread.id.codeUnitAt(i % thread.id.length) + i) % 16).toRadixString(16)).join()}',
          escrowService: escrowService,
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

    return _entities.reservation(
      guestKeyPair: thread.guest.keyPair,
      dTag: 'mock-reservation-${thread.id}',
      listing: thread.listing,
      pTags: [
        PTag.seller(thread.listing.pubKey),
        PTag.buyer(thread.requestAuthorKeyPair.publicKey),
        if (withEscrowProof && escrowService != null)
          PTag.escrow(escrowService.escrowPubkey),
      ],
      start: thread.start,
      end: thread.end,
      stage: ReservationStage.commit,
      quantity: thread.request.quantity,
      amount: thread.request.amount,
      recipient: thread.request.recipient,
      proof: proof,
      signerOverride: thread.requestAuthorKeyPair,
      createdAt: _ctx.timestampDaysAfter(80),
    );
  }

  void dispose() => _ctx.dispose();
}
