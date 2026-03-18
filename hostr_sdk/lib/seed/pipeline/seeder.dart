import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';

import 'seed_context.dart';
import 'seed_factory.dart';
import 'seed_pipeline_config.dart';
import 'seed_pipeline_models.dart';
import 'sink/seed_sink.dart';
import 'stages/build_outcomes.dart' as stage_outcomes;

/// Drives the full seed pipeline, routing side effects through [SeedSink].
///
/// Pure-data stages (users, profiles, listings, threads, messages, reviews)
/// delegate to [SeedFactory].  Chain operations (trade creation / settlement)
/// and relay broadcast are pushed through the sink so the caller controls
/// the backend (in-memory for tests, real chain + relay for CLI).
///
/// ```dart
/// // Tests (no Docker, no chain):
/// final seeder = Seeder(config: config);
/// final sink = TestSink();
/// final data = await seeder.seed(sink);
/// requests.seedEvents(sink.events);
///
/// // CLI (real infrastructure):
/// final seeder = Seeder(config: config, contractAddress: addr);
/// final sink = InfrastructureSink(rpcUrl: url, relayUrl: relay);
/// final data = await seeder.seed(sink);
/// ```
class Seeder {
  final SeedPipelineConfig config;
  final SeedFactory factory;

  Seeder({
    required this.config,
    String contractAddress = '0x0000000000000000000000000000000000000000',
  }) : factory = SeedFactory(config: config, contractAddress: contractAddress);

  /// Expose the context for key derivation / timestamp helpers.
  SeedContext get context => factory.context;

  /// Run the full pipeline.
  ///
  /// Every side effect (event publication, chain ops, funding, identity
  /// registration) flows through [sink].  The method returns the
  /// aggregate [SeedPipelineData] when all stages have completed.
  ///
  /// [now] is the reference timestamp for date calculations.  Defaults
  /// to `DateTime.now().toUtc()`.
  Future<SeedPipelineData> seed(SeedSink sink, {DateTime? now}) async {
    final resolvedNow = now ?? DateTime.now().toUtc();

    // ── 1. Users ─────────────────────────────────────────────────────────
    final users = factory.buildUsers();
    final hosts = users.where((u) => u.isHost).toList(growable: false);
    final guests = users.where((u) => !u.isHost).toList(growable: false);

    // ── 2. Profiles + escrow config ──────────────────────────────────────
    final profiles = [
      ...await factory.buildProfiles(users),
      await factory.buildEscrowProfile(),
    ];
    final escrowServices = await factory.buildEscrowServices();
    final escrowTrusts = await factory.buildEscrowTrusts(users);
    final escrowMethods = await factory.buildEscrowMethods(users);

    final profileByPubkey = {for (final p in profiles) p.pubKey: p};
    final trustByPubkey = {for (final t in escrowTrusts) t.pubKey: t};
    final methodByPubkey = {for (final m in escrowMethods) m.pubKey: m};

    // Publish profiles + escrow config eagerly.
    for (final p in profiles) {
      await sink.publish(p);
    }
    for (final e in escrowServices) {
      await sink.publish(e);
    }
    for (final t in escrowTrusts) {
      await sink.publish(t);
    }
    for (final m in escrowMethods) {
      await sink.publish(m);
    }

    // ── 3. Listings ──────────────────────────────────────────────────────
    final listings = factory.buildListings(hosts);
    for (final l in listings) {
      await sink.publish(l);
    }

    // ── 4. Fund + register identities (concurrent, fire-and-forget) ─────
    final fundFutures = <Future<void>>[];
    if (config.fundProfiles) {
      fundFutures.addAll(_buildFundIntents(users).map((i) => sink.fund(i)));
    }

    final identityFutures = <Future<void>>[];
    if (config.setupLnbits) {
      identityFutures.addAll(
        _buildIdentityIntents(profiles).map((i) => sink.registerIdentity(i)),
      );
    }

    // ── 5. Threads ───────────────────────────────────────────────────────
    final threads = await factory.buildThreads(
      hosts: hosts,
      guests: guests,
      listings: listings,
      now: resolvedNow,
    );

    final reservationRequests = threads
        .map((t) => t.request)
        .toList(growable: false);

    // ── 6. Outcome planning (pure, deterministic) ────────────────────────
    final outcomePlans = stage_outcomes.buildOutcomePlans(
      ctx: factory.context,
      threads: threads,
      chainNow: resolvedNow,
      trustByPubkey: trustByPubkey,
      methodByPubkey: methodByPubkey,
    );

    SeedPipelineSpec(
      seed: config.seed,
      users: users,
      listings: listings,
      threads: threads,
      outcomePlans: outcomePlans,
    ).printSpec();

    // ── 7. Messages + outcomes (concurrent) ──────────────────────────────

    // Kick off message gift-wrapping (expensive, no chain dependency).
    final messagesFuture = factory.buildMessages(threads);

    // Funding must complete before outcomes — submitTrade sends ETH from
    // buyer addresses, so they need a balance first.
    if (fundFutures.isNotEmpty) {
      await Future.wait(fundFutures);
      fundFutures.clear();
    }

    // Drive outcomes through the sink.
    final escrowService = escrowServices.isNotEmpty
        ? escrowServices.first
        : null;

    await _executeOutcomes(
      sink: sink,
      plans: outcomePlans,
      escrowService: escrowService,
      profileByPubkey: profileByPubkey,
      trustByPubkey: trustByPubkey,
      methodByPubkey: methodByPubkey,
    );

    SeedPipelineOutcome(threads: threads, plans: outcomePlans).printOutcome();

    // ── 8. Post-outcome events ───────────────────────────────────────────

    // Reservations are already set on threads by _executeOutcomes.
    final reservations = threads
        .where((t) => t.reservation != null)
        .map((t) => t.reservation!)
        .toList(growable: false);
    for (final r in reservations) {
      await sink.publish(r);
    }

    // Zap receipts.
    final zapReceipts = threads
        .map((t) => t.zapReceipt)
        .whereType<Nip01Event>()
        .toList(growable: false);
    for (final z in zapReceipts) {
      await sink.publish(z);
    }

    // Transitions (depends on reservations being set).
    final reservationTransitions = factory.buildReservationTransitions(threads);
    for (final t in reservationTransitions) {
      await sink.publish(t);
    }

    // Wait for messages and publish.
    final baseMessages = await messagesFuture;
    for (final m in baseMessages) {
      await sink.publish(m);
    }

    // Escrow-selected messages (depends on outcome data).
    final escrowSelectedMessages = await factory.buildEscrowSelectedMessages(
      threads,
    );
    for (final m in escrowSelectedMessages) {
      await sink.publish(m);
    }

    // Reviews.
    final reviews = factory.buildReviews(threads);
    for (final r in reviews) {
      await sink.publish(r);
    }

    // ── 9. Wait for fire-and-forget side effects ─────────────────────────

    await Future.wait([...fundFutures, ...identityFutures]);

    // ── 10. Aggregate result ─────────────────────────────────────────────

    final threadMessages = [...baseMessages, ...escrowSelectedMessages];

    return SeedPipelineData(
      users: users,
      profiles: profiles,
      listings: listings,
      escrowServices: escrowServices,
      escrowTrusts: escrowTrusts,
      escrowMethods: escrowMethods,
      threads: threads,
      reservationRequests: reservationRequests,
      reservationTransitions: reservationTransitions,
      threadMessages: threadMessages,
      reservations: reservations,
      zapReceipts: zapReceipts,
      reviews: reviews,
    );
  }

  // ── Outcome execution ─────────────────────────────────────────────────────

  Future<void> _executeOutcomes({
    required SeedSink sink,
    required List<SeedOutcomePlan> plans,
    required EscrowService? escrowService,
    required Map<String, ProfileMetadata> profileByPubkey,
    required Map<String, EscrowTrust> trustByPubkey,
    required Map<String, EscrowMethod> methodByPubkey,
  }) async {
    final ctx = factory.context;

    // Phase 1: Zap receipts (pure, synchronous).
    for (final plan in plans.where((p) => !p.useEscrow)) {
      final tradeId = plan.thread.request.getDtag() ?? '';
      plan.thread.zapReceipt = stage_outcomes.buildZapReceipt(
        ctx: ctx,
        threadIndex: plan.index + 1,
        tradeId: tradeId,
        request: plan.thread.request,
        listing: plan.thread.listing,
        host: plan.thread.host,
        guest: plan.thread.guest,
        hostProfile: profileByPubkey[plan.thread.host.keyPair.publicKey],
      );
    }

    // Phase 2+3: Escrow trades + settlements (via sink).
    final escrowPlans = plans
        .where((p) => p.useEscrow && p.trust != null && p.method != null)
        .toList();

    await Future.wait(
      escrowPlans.map((plan) => _executeEscrowPlan(sink, plan)),
    );

    // Mark escrow-path threads.
    for (final plan in plans.where((p) => p.useEscrow)) {
      plan.thread.paidViaEscrow = true;
      plan.thread.escrowOutcome = plan.escrowOutcome;
    }

    // Phase 4: Build reservation events (pure).
    for (final plan in plans) {
      stage_outcomes.buildReservationForPlan(
        ctx: ctx,
        plan: plan,
        profileByPubkey: profileByPubkey,
        escrowService:
            escrowService ??
            EscrowService(
              pubKey: MockKeys.escrow.publicKey,
              content: EscrowServiceContent(
                pubkey: MockKeys.escrow.publicKey,
                evmAddress: '0x0',
                contractAddress: ctx.contractAddress,
                contractBytecodeHash: '0x0',
                chainId: 31337,
                maxDuration: const Duration(days: 365),
                type: EscrowType.EVM,
                feeBase: 100,
                feePercent: 1.0,
                minAmount: 1000,
              ),
              tags: EventTags([]),
              createdAt: ctx.timestampDaysAfter(1),
            ),
        trustByPubkey: trustByPubkey,
        methodByPubkey: methodByPubkey,
        invalidReservationRate: config.invalidReservationRate,
      );
    }
  }

  Future<void> _executeEscrowPlan(SeedSink sink, SeedOutcomePlan plan) async {
    final thread = plan.thread;
    final tradeId = thread.request.getDtag() ?? '';
    final guestKey = thread.guest.keyPair.privateKey!;
    final hostKey = thread.host.keyPair.privateKey!;
    final arbiterKey = MockKeys.escrow.privateKey!;
    final amountWei = thread.request.amount!.value * BigInt.from(10).pow(10);
    final unlockAt = BigInt.from(
      thread.request.end.toUtc().millisecondsSinceEpoch ~/ 1000,
    );

    final createResult = await sink.submitTrade(
      SubmitTrade(
        tradeId: tradeId,
        buyerPrivateKey: guestKey,
        sellerPrivateKey: hostKey,
        arbiterPrivateKey: arbiterKey,
        amountWei: amountWei,
        unlockAt: unlockAt,
      ),
    );

    plan.createTxHash = createResult.txHash;
    plan.tradeAlreadyExisted = createResult.alreadyExisted;

    // Settle if there's a planned outcome.
    if (plan.escrowOutcome != null) {
      final settlerKey = plan.escrowOutcome == EscrowOutcome.arbitrated
          ? arbiterKey
          : hostKey;

      await sink.settleTrade(
        SettleTrade(
          tradeId: tradeId,
          outcome: plan.escrowOutcome!,
          settlerPrivateKey: settlerKey,
        ),
      );
    }
  }

  // ── Intent builders ───────────────────────────────────────────────────────

  /// Build [FundWallet] intents for all users with EVM keys, plus
  /// well-known mock keys.
  Iterable<FundWallet> _buildFundIntents(List<SeedUser> users) sync* {
    final amountWei =
        config.fundAmountWei ?? BigInt.parse('10000000000000000000');
    final seen = <String>{};

    for (final pk in [
      if (MockKeys.hoster.privateKey != null) MockKeys.hoster.privateKey!,
      if (MockKeys.guest.privateKey != null) MockKeys.guest.privateKey!,
      if (MockKeys.escrow.privateKey != null) MockKeys.escrow.privateKey!,
      ...mockKeys.map((k) => k.privateKey).whereType<String>(),
      ...users.map((u) => u.keyPair.privateKey).whereType<String>(),
    ]) {
      if (!seen.add(pk)) continue;
      // FundWallet uses the private key as address placeholder — the sink
      // is responsible for deriving the actual EVM address.
      yield FundWallet(address: pk, amountWei: amountWei);
    }
  }

  /// Build [RegisterIdentity] intents from profile NIP-05 fields.
  Iterable<RegisterIdentity> _buildIdentityIntents(
    List<ProfileMetadata> profiles,
  ) sync* {
    for (final profile in profiles) {
      final nip05 = Metadata.fromEvent(profile).nip05;
      if (nip05 != null) {
        final split = nip05.split('@');
        if (split.length == 2 && split[0].isNotEmpty && split[1].isNotEmpty) {
          yield RegisterIdentity(
            username: split[0],
            domain: split[1].toLowerCase(),
            pubkey: profile.pubKey,
          );
        }
      }
    }
  }

  void dispose() => factory.dispose();
}
