import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'seed_context.dart';
import 'seed_pipeline_config.dart';
import 'seed_pipeline_models.dart';
import 'stages/build_listings.dart' as stage_listings;
import 'stages/build_messages.dart' as stage_messages;
import 'stages/build_outcomes.dart' as stage_outcomes;
import 'stages/build_profiles.dart' as stage_profiles;
import 'stages/build_reviews.dart' as stage_reviews;
import 'stages/build_threads.dart' as stage_threads;
import 'stages/build_users.dart' as stage_users;

/// Composable seed pipeline.
///
/// Use [run] for the full CLI/seeder flow, or call individual stages
/// for integration tests that only need a subset of seed data.
///
/// ```dart
/// // Full run (CLI):
/// final pipeline = SeedPipeline(config: config, contractAddress: addr);
/// final data = await pipeline.run();
///
/// // Integration test (individual stages):
/// final pipeline = SeedPipeline(config: testConfig, contractAddress: addr);
/// final users = pipeline.buildUsers();
/// final profiles = pipeline.buildProfiles(users);
/// final listings = pipeline.buildListings(users.where((u) => u.isHost).toList());
/// final threads = await pipeline.buildThreads(
///   hosts: ..., guests: ..., listings: listings,
/// );
/// // Don't call buildOutcomes → test drives the outcome itself
/// ```
class SeedPipeline {
  final SeedPipelineConfig config;
  final SeedContext _ctx;

  SeedPipeline({required this.config, required String contractAddress})
    : _ctx = SeedContext(
        seed: config.seed,
        contractAddress: contractAddress,
        rpcUrl: config.rpcUrl,
        userCount: config.userCount + config.userOverrides.length,
        reservationRequestsPerGuest: config.reservationRequestsPerGuest,
      );

  /// Expose the context for advanced callers (e.g. TestSeedHelper).
  SeedContext get context => _ctx;

  // ── Individual stages ─────────────────────────────────────────────────────

  List<SeedUser> buildUsers() =>
      stage_users.buildUsers(ctx: _ctx, config: config);

  List<ProfileMetadata> buildProfiles(List<SeedUser> users) =>
      stage_profiles.buildProfiles(ctx: _ctx, users: users);

  ProfileMetadata buildEscrowProfile() =>
      stage_profiles.buildEscrowProfile(ctx: _ctx);

  List<EscrowService> buildEscrowServices() =>
      stage_profiles.buildEscrowServices(contractAddress: _ctx.contractAddress);

  Future<List<EscrowTrust>> buildEscrowTrusts(List<SeedUser> users) =>
      stage_profiles.buildEscrowTrusts(ctx: _ctx, users: users);

  Future<List<EscrowMethod>> buildEscrowMethods(List<SeedUser> users) =>
      stage_profiles.buildEscrowMethods(ctx: _ctx, users: users);

  List<Listing> buildListings(List<SeedUser> hosts) =>
      stage_listings.buildListings(ctx: _ctx, config: config, hosts: hosts);

  Future<List<SeedThread>> buildThreads({
    required List<SeedUser> hosts,
    required List<SeedUser> guests,
    required List<Listing> listings,
  }) => stage_threads.buildThreads(
    ctx: _ctx,
    config: config,
    hosts: hosts,
    guests: guests,
    listings: listings,
  );

  Future<void> buildOutcomes({
    required List<SeedThread> threads,
    required Map<String, ProfileMetadata> profileByPubkey,
    required EscrowService escrowService,
    required Map<String, EscrowTrust> trustByPubkey,
    required Map<String, EscrowMethod> methodByPubkey,
  }) => stage_outcomes.buildOutcomes(
    ctx: _ctx,
    threads: threads,
    profileByPubkey: profileByPubkey,
    escrowService: escrowService,
    trustByPubkey: trustByPubkey,
    methodByPubkey: methodByPubkey,
  );

  Future<List<Nip01Event>> buildMessages(List<SeedThread> threads) =>
      stage_messages.buildMessages(ctx: _ctx, config: config, threads: threads);

  List<Review> buildReviews(List<SeedThread> threads) =>
      stage_reviews.buildReviews(ctx: _ctx, threads: threads);

  // ── Full pipeline run ─────────────────────────────────────────────────────

  /// Runs all stages in sequence and returns the aggregate data.
  Future<SeedPipelineData> run() async {
    try {
      final users = buildUsers();
      final hosts = users.where((u) => u.isHost).toList(growable: false);
      final guests = users.where((u) => !u.isHost).toList(growable: false);

      final profiles = [...buildProfiles(users), buildEscrowProfile()];
      final profileByPubkey = {for (final p in profiles) p.pubKey: p};

      final escrowServices = buildEscrowServices();
      final escrowTrusts = await buildEscrowTrusts(users);
      final escrowMethods = await buildEscrowMethods(users);
      final trustByPubkey = {for (final t in escrowTrusts) t.pubKey: t};
      final methodByPubkey = {for (final m in escrowMethods) m.pubKey: m};

      final listings = buildListings(hosts);

      final threads = await buildThreads(
        hosts: hosts,
        guests: guests,
        listings: listings,
      );

      // Outcome stage: resolve completed threads.
      if (escrowServices.isNotEmpty) {
        await buildOutcomes(
          threads: threads,
          profileByPubkey: profileByPubkey,
          escrowService: escrowServices.first,
          trustByPubkey: trustByPubkey,
          methodByPubkey: methodByPubkey,
        );
      }

      final reservationRequests = threads
          .map((t) => t.request)
          .toList(growable: false);
      final reservations = threads
          .where((t) => t.reservation != null)
          .map((t) => t.reservation!)
          .toList(growable: false);
      final zapReceipts = threads
          .map((t) => t.zapReceipt)
          .whereType<Nip01Event>()
          .toList(growable: false);

      final threadMessages = await buildMessages(threads);
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
        threadMessages: threadMessages,
        reservations: reservations,
        zapReceipts: zapReceipts,
        reviews: reviews,
      );
    } finally {
      _ctx.dispose();
    }
  }

  void dispose() => _ctx.dispose();
}
