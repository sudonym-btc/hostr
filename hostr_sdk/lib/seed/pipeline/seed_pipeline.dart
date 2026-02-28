import 'package:hostr_sdk/datasources/anvil/anvil.dart';
import 'package:hostr_sdk/datasources/lnbits/lnbits.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';

import 'seed_context.dart';
import 'seed_factory.dart';
import 'seed_pipeline_config.dart';
import 'seed_pipeline_models.dart';
import 'stages/build_outcomes.dart' as stage_outcomes;
import 'stages/build_reservation_transitions.dart';

/// Full infrastructure-backed seed pipeline.
///
/// Delegates pure-data stages (users, profiles, listings, threads,
/// messages, reviews) to [SeedFactory] and layers on top:
///   - EVM funding via Anvil
///   - LNbits wallet + NIP-05 setup
///   - On-chain escrow trade creation via [buildOutcomes]
///
/// Use [run] for the full CLI/seeder flow — it returns [SeedStreams]
/// with typed [ReplaySubject]s that consumers can subscribe to
/// independently.
///
/// For tests that don't need infrastructure, use [SeedFactory] directly.
///
/// ```dart
/// final pipeline = SeedPipeline(config: config, contractAddress: addr);
/// final streams = pipeline.run();
///
/// // Broadcast events as they arrive:
/// streams.events
///     .bufferCount(50)
///     .asyncMap((batch) => broadcastBatch(ndk, batch))
///     .listen((_) {});
///
/// // React to chain transactions:
/// streams.chainTx.listen((r) =>
///     print('${r.action} tx=${r.txHash}'));
///
/// // Aggregate summary at the end:
/// final data = await streams.done.first;
/// print(data.summary.toJson());
/// ```
class SeedPipeline {
  final SeedPipelineConfig config;
  final SeedContext _ctx;

  /// The underlying pure-data factory.  Exposed so callers (including
  /// [TestSeedHelper]) can access stage methods without duplicating code.
  late final SeedFactory factory;

  SeedPipeline({required this.config, required String contractAddress})
    : _ctx = SeedContext(
        seed: config.seed,
        contractAddress: contractAddress,
        rpcUrl: config.rpcUrl,
        userCount: config.userCount + config.userOverrides.length,
        reservationRequestsPerGuest: config.reservationRequestsPerGuest,
      ) {
    factory = SeedFactory.fromContext(config: config, ctx: _ctx);
  }

  /// Expose the context for advanced callers (e.g. TestSeedHelper).
  SeedContext get context => _ctx;

  // ── Delegated pure-data stages ────────────────────────────────────────────

  List<SeedUser> buildUsers() => factory.buildUsers();

  List<ProfileMetadata> buildProfiles(List<SeedUser> users) =>
      factory.buildProfiles(users);

  ProfileMetadata buildEscrowProfile() => factory.buildEscrowProfile();

  List<EscrowService> buildEscrowServices() => factory.buildEscrowServices();

  Future<List<EscrowTrust>> buildEscrowTrusts(List<SeedUser> users) =>
      factory.buildEscrowTrusts(users);

  Future<List<EscrowMethod>> buildEscrowMethods(List<SeedUser> users) =>
      factory.buildEscrowMethods(users);

  List<Listing> buildListings(List<SeedUser> hosts) =>
      factory.buildListings(hosts);

  Future<List<SeedThread>> buildThreads({
    required List<SeedUser> hosts,
    required List<SeedUser> guests,
    required List<Listing> listings,
    DateTime? now,
  }) => factory.buildThreads(
    hosts: hosts,
    guests: guests,
    listings: listings,
    now: now,
  );

  Future<List<Nip01Event>> buildMessages(List<SeedThread> threads) =>
      factory.buildMessages(threads);

  Future<List<Nip01Event>> buildEscrowSelectedMessages(
    List<SeedThread> threads,
  ) => factory.buildEscrowSelectedMessages(threads);

  List<Review> buildReviews(List<SeedThread> threads) =>
      factory.buildReviews(threads);

  // ── Infrastructure-only stage ─────────────────────────────────────────────

  /// Phase 0: deterministic outcome planning — synchronous, no I/O.
  ///
  /// Call after [buildThreads] and the chain timestamp are both available.
  /// Pass the result directly into [buildOutcomes].
  List<SeedOutcomePlan> buildOutcomePlans({
    required List<SeedThread> threads,
    required Map<String, EscrowTrust> trustByPubkey,
    required Map<String, EscrowMethod> methodByPubkey,
    required DateTime chainNow,
  }) => stage_outcomes.buildOutcomePlans(
    ctx: _ctx,
    threads: threads,
    trustByPubkey: trustByPubkey,
    methodByPubkey: methodByPubkey,
    chainNow: chainNow,
  );

  Future<void> buildOutcomes({
    required List<SeedThread> threads,
    required Map<String, ProfileMetadata> profileByPubkey,
    required EscrowService escrowService,
    required Map<String, EscrowTrust> trustByPubkey,
    required Map<String, EscrowMethod> methodByPubkey,
    required List<SeedOutcomePlan> plans,
    double? invalidReservationRate,
    DateTime? chainNow,
  }) => stage_outcomes.buildOutcomes(
    ctx: _ctx,
    threads: threads,
    profileByPubkey: profileByPubkey,
    escrowService: escrowService,
    trustByPubkey: trustByPubkey,
    methodByPubkey: methodByPubkey,
    plans: plans,
    invalidReservationRate:
        invalidReservationRate ?? config.invalidReservationRate,
    chainNow: chainNow,
  );

  // ── Full pipeline run ─────────────────────────────────────────────────────

  /// Runs all stages and returns [SeedStreams].
  ///
  /// Each subject is a [ReplaySubject] — late subscribers see every
  /// value emitted before they attached.  All subjects close when the
  /// pipeline finishes (or errors).
  SeedStreams run() {
    final streams = SeedStreams();
    _runPipeline(streams).then(
      (_) => streams.dispose(),
      onError: (Object e, StackTrace st) {
        streams.events.addError(e, st);
        streams.dispose();
      },
    );
    return streams;
  }

  // ── Internal pipeline orchestration ───────────────────────────────────────

  Future<void> _runPipeline(SeedStreams s) async {
    try {
      final sw = Stopwatch()..start();

      // ── Users + funding ──────────────────────────────────────────────

      final users = buildUsers();
      final hosts = users.where((u) => u.isHost).toList(growable: false);
      final guests = users.where((u) => !u.isHost).toList(growable: false);

      // Kick off funding concurrently — it only needs user keys.
      final fundingFuture = config.fundProfiles
          ? _fundUsers(s, users)
          : Future<void>.value();

      // ── Profiles + escrow config ─────────────────────────────────────

      final profiles = [...buildProfiles(users), buildEscrowProfile()];
      _emitAll(s, profiles);

      final profileByPubkey = {for (final p in profiles) p.pubKey: p};

      final escrowServices = buildEscrowServices();
      final escrowTrusts = await buildEscrowTrusts(users);
      final escrowMethods = await buildEscrowMethods(users);
      final trustByPubkey = {for (final t in escrowTrusts) t.pubKey: t};
      final methodByPubkey = {for (final m in escrowMethods) m.pubKey: m};

      _emitAll(s, escrowServices);
      _emitAll(s, escrowTrusts);
      _emitAll(s, escrowMethods);

      // ── Listings ─────────────────────────────────────────────────────

      final listings = buildListings(hosts);
      _emitAll(s, listings);

      print('[pipeline] users+profiles+listings: ${sw.elapsedMilliseconds} ms');

      // Kick off LNbits concurrently — it only needs profile data.
      final lnbitsFuture = config.setupLnbits
          ? _setupLnbits(s, profiles)
          : Future<void>.value();

      // ── Threads ──────────────────────────────────────────────────────

      sw.reset();
      final threads = await buildThreads(
        hosts: hosts,
        guests: guests,
        listings: listings,
      );

      final reservationRequests = threads
          .map((t) => t.request)
          .toList(growable: false);
      _emitAll(s, reservationRequests);

      print('[pipeline] buildThreads: ${sw.elapsedMilliseconds} ms');

      // Pre-fetch chain timestamp before the parallel block so it
      // resolves before gift-wrapping monopolises the event loop.
      final chainNow = (await _ctx.chainClient().getBlockInformation())
          .timestamp
          .toUtc();

      // ── Plan: deterministic outcome decisions (no I/O) ───────────────

      final outcomePlans = buildOutcomePlans(
        threads: threads,
        trustByPubkey: trustByPubkey,
        methodByPubkey: methodByPubkey,
        chainNow: chainNow,
      );
      SeedPipelineSpec(
        seed: config.seed,
        users: users,
        listings: listings,
        threads: threads,
        outcomePlans: outcomePlans,
      ).printSpec();

      // ── Concurrent: outcomes + messages ──────────────────────────────

      sw.reset();
      late final List<Nip01Event> baseMessages;

      if (escrowServices.isNotEmpty) {
        final results = await Future.wait([
          buildOutcomes(
            threads: threads,
            profileByPubkey: profileByPubkey,
            escrowService: escrowServices.first,
            trustByPubkey: trustByPubkey,
            methodByPubkey: methodByPubkey,
            plans: outcomePlans,
            chainNow: chainNow,
          ),
          buildMessages(threads).then((msgs) {
            _emitAll(s, msgs);
            return msgs;
          }),
        ]);
        baseMessages = results[1] as List<Nip01Event>;
      } else {
        baseMessages = await buildMessages(threads);
        _emitAll(s, baseMessages);
      }

      // Post-outcome events (reservations, zap receipts).
      final reservations = threads
          .where((t) => t.reservation != null)
          .map((t) => t.reservation!)
          .toList(growable: false);
      final reservationTransitions = buildReservationTransitions(
        threads: threads,
      );
      final zapReceipts = threads
          .map((t) => t.zapReceipt)
          .whereType<Nip01Event>()
          .toList(growable: false);

      _emitAll(s, reservations);
      _emitAll(s, reservationTransitions);
      _emitAll(s, zapReceipts);

      SeedPipelineOutcome(threads: threads, plans: outcomePlans).printOutcome();

      // Push chain tx info from completed escrow trades.
      for (final thread in threads) {
        if (thread.paidViaEscrow) {
          final proof = thread.reservation?.parsedContent.proof;
          final txHash = proof?.escrowProof?.txHash;
          if (txHash != null) {
            s.chainTx.add((
              thread: thread,
              txHash: txHash,
              action: 'createTrade',
            ));
          }
        }
      }

      print(
        '[pipeline] buildOutcomes + buildMessages (parallel): '
        '${sw.elapsedMilliseconds} ms',
      );

      // ── Escrow-selected messages (needs outcome data) ────────────────

      sw.reset();
      final escrowSelectedMessages = await buildEscrowSelectedMessages(threads);
      _emitAll(s, escrowSelectedMessages);
      print(
        '[pipeline] buildEscrowSelectedMessages: '
        '${sw.elapsedMilliseconds} ms '
        '(${escrowSelectedMessages.length} events)',
      );

      // ── Reviews ──────────────────────────────────────────────────────

      sw.reset();
      final reviews = buildReviews(threads);
      _emitAll(s, reviews);
      print('[pipeline] buildReviews: ${sw.elapsedMilliseconds} ms');

      // ── Wait for side-effects ────────────────────────────────────────

      await fundingFuture;
      await lnbitsFuture;

      // ── Terminal: aggregate data ─────────────────────────────────────

      final threadMessages = [...baseMessages, ...escrowSelectedMessages];

      s.done.add(
        SeedPipelineData(
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
        ),
      );
    } finally {
      _ctx.dispose();
    }
  }

  /// Push every event in [list] to [s.events].
  void _emitAll(SeedStreams s, List<Nip01Event> list) {
    for (final event in list) {
      s.events.add(event);
    }
  }

  // ── Funding ───────────────────────────────────────────────────────────────

  Future<void> _fundUsers(SeedStreams s, List<SeedUser> users) async {
    final amountWei =
        config.fundAmountWei ?? BigInt.parse('10000000000000000000');

    final privateKeys = <String>{
      if (MockKeys.hoster.privateKey != null) MockKeys.hoster.privateKey!,
      if (MockKeys.guest.privateKey != null) MockKeys.guest.privateKey!,
      if (MockKeys.escrow.privateKey != null) MockKeys.escrow.privateKey!,
      ...mockKeys.map((k) => k.privateKey).whereType<String>(),
      ...users.map((u) => u.keyPair.privateKey).whereType<String>(),
    };

    final addressByKey = {
      for (final pk in privateKeys)
        pk: getEvmCredentials(pk).address.eip55With0x,
    };
    final seen = <String>{};
    final uniqueEntries = addressByKey.entries
        .where((e) => seen.add(e.value))
        .toList(growable: false);

    final userByPk = {
      for (final u in users)
        if (u.keyPair.privateKey != null) u.keyPair.privateKey!: u,
    };

    print('Funding ${uniqueEntries.length} mock EVM addresses...');

    final anvilClient = AnvilClient(rpcUri: Uri.parse(config.rpcUrl));
    try {
      await Future.wait(
        uniqueEntries.map((entry) async {
          final funded = await anvilClient.setBalance(
            address: entry.value,
            amountWei: amountWei,
          );
          if (!funded) {
            throw Exception(
              'Could not fund ${entry.value} on ${config.rpcUrl}.',
            );
          }
          final user = userByPk[entry.key];
          if (user != null) {
            s.userFunded.add((
              user: user,
              amountWei: amountWei,
              address: entry.value,
            ));
          }
        }),
      );
    } finally {
      anvilClient.close();
    }
    print(
      'Funded ${uniqueEntries.length} mock addresses '
      'with $amountWei wei each.',
    );
  }

  // ── LNbits setup ──────────────────────────────────────────────────────────

  static const int _lnbitsMaxAttempts = 5;

  Future<void> _setupLnbits(
    SeedStreams s,
    List<ProfileMetadata> profiles,
  ) async {
    for (var attempt = 1; attempt <= _lnbitsMaxAttempts; attempt++) {
      try {
        await _setupLnbitsInner(s, profiles);
        return;
      } catch (e) {
        if (attempt == _lnbitsMaxAttempts) {
          print('[lnbits] All $attempt attempts failed (non-fatal): $e');
          return;
        }
        final delay = Duration(seconds: 2 * attempt);
        print(
          '[lnbits] Attempt $attempt/$_lnbitsMaxAttempts failed '
          '(${e.runtimeType}), retrying in ${delay.inSeconds}s...',
        );
        await Future.delayed(delay);
      }
    }
  }

  Future<void> _setupLnbitsInner(
    SeedStreams s,
    List<ProfileMetadata> profiles,
  ) async {
    final usernamesByDomain = <String, Set<String>>{};
    final nip05ByDomain = <String, Map<String, String>>{};

    for (final profile in profiles) {
      final lud16 = profile.metadata.lud16;
      if (lud16 != null) {
        final split = lud16.split('@');
        if (split.length == 2 && split[0].isNotEmpty && split[1].isNotEmpty) {
          usernamesByDomain
              .putIfAbsent(split[1].toLowerCase(), () => <String>{})
              .add(split[0]);
        }
      }

      final nip05 = profile.metadata.nip05;
      if (nip05 != null) {
        final split = nip05.split('@');
        if (split.length == 2 && split[0].isNotEmpty && split[1].isNotEmpty) {
          final domain = split[1].toLowerCase();
          if (domain.startsWith('lnbits')) {
            nip05ByDomain.putIfAbsent(
              domain,
              () => <String, String>{},
            )[split[0]] = profile.pubKey;
          }
        }
      }
    }

    if (usernamesByDomain.isEmpty && nip05ByDomain.isEmpty) {
      print('[lnbits] No lud16/nip05 entries found. Skipping.');
      return;
    }

    final lnbitsConfig = LnbitsSetupConfig.fromEnvironment(
      lnbits1BaseUrl: config.lnbits1BaseUrl,
      lnbits2BaseUrl: config.lnbits2BaseUrl,
      lnbitsAdminEmail: config.lnbitsAdminEmail,
      lnbitsAdminPassword: config.lnbitsAdminPassword,
      lnbitsExtensionName: config.lnbitsExtensionName,
      lnbitsNostrPrivateKey: config.lnbitsNostrPrivateKey,
    );

    final datasource = LnbitsDatasource();

    // NIP-05 must run before lnurlp setup: activate_address() internally
    // calls update_ln_address() which creates the lnurlp pay link.  If
    // lnurlp ran first the username would already be taken and the NIP-05
    // address would end up with an empty pay_link_id (broken ln-address).
    if (nip05ByDomain.isNotEmpty) {
      final totalEntries = nip05ByDomain.values.fold<int>(
        0,
        (sum, m) => sum + m.length,
      );
      print(
        '[lnbits][nip05] Setting up $totalEntries NIP-05 entries across '
        '${nip05ByDomain.length} domain(s): ${nip05ByDomain.keys.join(', ')}',
      );

      await datasource.setupNip05ByDomain(
        nip05ByDomain: nip05ByDomain,
        config: lnbitsConfig,
      );

      for (final domainEntry in nip05ByDomain.entries) {
        for (final username in domainEntry.value.keys) {
          s.nip05Created.add((username: username, domain: domainEntry.key));
        }
      }

      print(
        '[lnbits][nip05] Finished NIP-05 setup. '
        'Created/verified ${nip05ByDomain.length} domain(s): '
        '${nip05ByDomain.keys.join(', ')}',
      );
    }

    // Run lnurlp setup after NIP-05 so usernames already created by
    // activate_address() are silently skipped ("username already taken").
    if (usernamesByDomain.isNotEmpty) {
      await datasource.setupUsernamesByDomain(
        usernamesByDomain: usernamesByDomain,
        config: lnbitsConfig,
      );
    }
  }

  void dispose() => _ctx.dispose();
}
