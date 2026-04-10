import 'dart:io';
import 'dart:math';

import 'package:hydrated_bloc/hydrated_bloc.dart' as hydrated;
import 'package:logger/logger.dart';
import 'package:models/nostr_kinds.dart';
import 'package:ndk/ndk.dart' hide ConsoleOutput;
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../config.dart';
import '../config/generated/test_env.g.dart' as env;
import '../datasources/main.dart';
import '../hostr.dart';
import '../injection.dart';
import '../seed/seed.dart';
import '../util/deterministic_key_derivation.dart';
import '../util/main.dart';
import 'in_memory_hydrated_storage.dart';

/// Allow self-signed certificates so integration tests can connect to the
/// local Docker stack's TLS endpoints (relay, blossom, lnbits, etc.) without
/// a trusted CA chain.
class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    return client;
  }
}

/// Shared integration-test bootstrap for Hostr SDK tests.
///
/// Provides a single place for:
/// - hydrated storage setup
/// - Hostr config defaults
/// - Anvil client setup
/// - AlbyHub client setup
/// - optional NWC pairing helper
/// - seed-backed fixture generator
class IntegrationTestHarness {
  final Hostr hostr;
  final AnvilClient anvil;
  final AnvilClient anvilRootstock;
  final AlbyHubClient albyHub;
  final TestSeedHelper seeds;

  /// Whether this harness created the [hostr] instance (and therefore
  /// owns its lifecycle).  When `false`, [dispose] will skip
  /// `hostr.dispose()` and `getIt.reset()`.
  final bool _ownsHostr;

  /// Pubkeys of NWC app connections created during this harness lifetime.
  /// Used by [dispose] to tear them down and free relay subscription slots.
  final List<String> _createdAppPubkeys = [];

  /// Anvil snapshot IDs captured after the initial setup.  Used by
  /// [resetToCleanState] to cheaply revert chain state between tests.
  String? _snapshotId;
  String? _rootstockSnapshotId;

  IntegrationTestHarness({
    required this.hostr,
    required this.anvil,
    required this.anvilRootstock,
    required this.albyHub,
    required this.seeds,
    this.fundedKeys = const [],
    bool ownsHostr = true,
  }) : _ownsHostr = ownsHostr;

  static const bootstrapRelays = env.bootstrapRelays;
  static const bootstrapBlossom = env.blossomUrl;
  static const hostrRelay = env.relayUrl;

  /// RPC URL for the Arbitrum-regtest anvil (ERC-20 / escrow / AA tests).
  static var anvilRpc = env.evmConfig.chains
      .firstWhere((c) => c.id.contains('arbitrum'))
      .rpcUrl;

  /// RPC URL for the Rootstock-regtest anvil (native swap tests).
  static var rootstockRpc = env.evmConfig.chains
      .firstWhere((c) => c.id.contains('rootstock'))
      .rpcUrl;

  static const albyHubUrl = 'https://alby.hostr.development';

  final List<KeyPair> fundedKeys;

  /// Accept self-signed dev TLS certs for all HTTP/WebSocket connections.
  ///
  /// Call from `setUpAll` in tests that talk to the Docker stack's TLS
  /// endpoints but don't need the full [IntegrationTestHarness].
  static void acceptSelfSignedCerts() {
    HttpOverrides.global = _PermissiveHttpOverrides();
  }

  /// Create a new harness.
  ///
  /// When [hostr] is provided the caller owns the [Hostr] lifecycle (storage,
  /// auth, etc.) and the harness re-uses it instead of constructing its own.
  /// This is useful in Flutter integration tests where `initCore` has already
  /// bootstrapped a [Hostr] singleton.
  static Future<IntegrationTestHarness> create({
    required String name,
    Hostr? hostr,
    String environment = Env.dev,
    int seed = 42,
    Level logLevel = Level.debug,
    bool cleanHydratedStorage = true,
  }) async {
    CustomLogger.configure(output: ConsoleOutput(), level: logLevel);
    final seeds = TestSeedHelper(seed: seed);

    // When an external Hostr is supplied the caller already set up hydrated
    // storage — skip the setup to avoid overwriting it.
    // The dart:io APIs (HttpOverrides, Directory) are also only safe on
    // native runtimes, so keep them inside this guard.
    if (hostr == null) {
      HttpOverrides.global = _PermissiveHttpOverrides();
      final storageDir = Directory('${Directory.systemTemp.path}/$name');
      if (cleanHydratedStorage && storageDir.existsSync()) {
        storageDir.deleteSync(recursive: true);
      }
      if (!storageDir.existsSync()) {
        storageDir.createSync(recursive: true);
      }

      hydrated.HydratedBloc.storage = InMemoryHydratedStorage();
    }

    final resolvedHostr =
        hostr ??
        Hostr(
          environment: environment,
          config: HostrConfig(
            logs: CustomLogger(),
            bootstrapRelays: bootstrapRelays,
            bootstrapBlossom: [bootstrapBlossom],
            hostrRelay: hostrRelay,
            evmConfig: env.evmConfig,
          ),
        );

    final anvil = AnvilClient(rpcUri: Uri.parse(anvilRpc));
    final anvilRootstock = AnvilClient(rpcUri: Uri.parse(rootstockRpc));
    List<KeyPair> fundKeys = [seeds.deriveKeyPair(Random().nextInt(1000000))];
    final fundFutures = <Future>[];
    for (final key in fundKeys) {
      final address = (await deriveEvmKey(key.privateKey!)).address.eip55With0x;
      final amount = rbtcFromSats(BigInt.from(1000000)).getInWei;
      fundFutures.add(anvil.setBalance(address: address, amountWei: amount));
      fundFutures.add(
        anvilRootstock.setBalance(address: address, amountWei: amount),
      );
    }
    await Future.wait([
      anvil.setAutomine(true),
      anvilRootstock.setAutomine(true),
      ...fundFutures,
    ]);
    final albyHub = AlbyHubClient(
      baseUri: Uri.parse(albyHubUrl),
      unlockPassword: Platform.environment['ALBYHUB_PASSWORD'] ?? 'Testing123!',
    );

    // Run Boltz chain discovery so swap providers are attached before any
    // test tries to use swaps.  This mirrors what Hostr.connect() does but
    // without the relay/auth subscription side-effects.
    await resolvedHostr.evm.init();

    final harness = IntegrationTestHarness(
      hostr: resolvedHostr,
      anvil: anvil,
      anvilRootstock: anvilRootstock,
      albyHub: albyHub,
      seeds: seeds,
      fundedKeys: fundKeys,
      ownsHostr: hostr == null,
    );

    // Capture chain state so resetToCleanState() can cheaply revert.
    harness._snapshotId = await anvil.snapshot();
    harness._rootstockSnapshotId = await anvilRootstock.snapshot();

    return harness;
  }

  /// Revert both Anvil chains to their post-setup snapshots and clear Boltz
  /// pending transactions.
  ///
  /// Call from `setUp` to get per-test isolation without the cost of full
  /// harness re-creation:
  ///
  /// ```dart
  /// late IntegrationTestHarness harness;
  /// setUpAll(() async => harness = await IntegrationTestHarness.create(name: 'my-test'));
  /// setUp(() => harness.resetToCleanState());
  /// tearDownAll(() => harness.dispose());
  /// ```
  Future<void> resetToCleanState() async {
    if (_snapshotId != null) {
      await anvil.revert(_snapshotId!);
      _snapshotId = await anvil.snapshot();
    }
    if (_rootstockSnapshotId != null) {
      await anvilRootstock.revert(_rootstockSnapshotId!);
      _rootstockSnapshotId = await anvilRootstock.snapshot();
    }
    await clearBoltzPendingEvmTransactions();
  }

  Future<void> signInAndConnectNwc({
    required KeyPair user,
    required String appNamePrefix,
  }) async {
    await hostr.auth.signin(user.privateKey!);
    await connectNwc(user: user, appNamePrefix: appNamePrefix);
  }

  /// Pair the current user's wallet via the local AlbyHub and register the
  /// NWC connection on [hostr].
  ///
  /// Unlike [signInAndConnectNwc] this does **not** call `auth.signin` first,
  /// so it can be used when the caller has already authenticated (e.g. via the
  /// Flutter UI login flow).
  Future<void> connectNwc({
    required KeyPair user,
    required String appNamePrefix,
  }) async {
    final pairingUrl = await albyHub.getConnectionForUser(
      user,
      appName: '$appNamePrefix-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (pairingUrl == null) {
      throw StateError(
        'Failed to obtain NWC pairing URL for ${user.publicKey}',
      );
    }

    // Wait for AlbyHub to publish the kind 13194 info event for this app's
    // wallet pubkey to the relay. Without this, NDK's connect() may query
    // before the event has propagated → empty permissions → "method not in
    // permissions" errors.
    final parsedUri = Uri.parse(pairingUrl);
    final walletPubkey = parsedUri.host;

    // The `secret` query param is the app's private key. Derive its public
    // key — that's the appPubkey AlbyHub indexes connections by.
    final appSecret = parsedUri.queryParameters['secret'];
    if (appSecret != null) {
      _createdAppPubkeys.add(Bip340.getPublicKey(appSecret));
    }
    await hostr.requests
        .subscribe(
          filter: Filter(kinds: [kNostrKindNWCInfo], authors: [walletPubkey]),
          name: 'nwc-info-wait',
        )
        .stream
        .take(1)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: (sink) {
            print(
              '[harness] connectNwc: NWC info event timed out after 15s, continuing anyway',
            );
            sink.close();
          },
        )
        .toList();
    await hostr.nwc.initiateAndAdd(pairingUrl);
  }

  /// Clears stale pending EVM transactions from Boltz's database.
  ///
  /// The Boltz backend's Node.js `InjectedProvider` stores every broadcast
  /// attempt in the `pendingEthereumTransactions` table **before** the actual
  /// RPC broadcast.  When the Rust sidecar (boltz-evm, using alloy) wins the
  /// nonce race, the Node.js broadcast fails with "nonce too low" but the
  /// stale DB entry remains.  Subsequent `getTransactionCount` calls return
  /// `max(stale_nonce) + 1` instead of querying the chain, causing a
  /// snowballing nonce desync that makes every other reverse-swap lockup fail.
  ///
  /// Call this before any test that triggers a Boltz reverse swap (swap-in).
  static Future<void> clearBoltzPendingEvmTransactions() async {
    final result = await Process.run('docker', [
      'exec',
      'boltz-postgres',
      'psql',
      '-U',
      'boltz',
      '-d',
      'boltz',
      '-c',
      'DELETE FROM "pendingEthereumTransactions";',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'Failed to clear Boltz pending EVM transactions: ${result.stderr}',
      );
    }
  }

  /// Trigger an immediate Boltz claim sweep for the given [symbol] (e.g.
  /// `"tBTC"`, `"RBTC"`), or for **all** configured symbols when [symbol] is
  /// omitted.
  ///
  /// Under the default regtest config, EVM symbols are no longer deferred
  /// (they were removed from `deferredClaimSymbols`), so this helper is
  /// mainly useful when a test intentionally re-enables deferred claiming or
  /// as a debugging tool.
  ///
  /// Internally this calls the `boltzrpc.Boltz/SweepSwaps` gRPC endpoint
  /// from inside the boltz-backend container using the compiled proto stubs
  /// that ship with the image.
  static Future<void> triggerBoltzClaimSweep({String? symbol}) async {
    // The Node.js script must run from /boltz-backend so that local
    // require() paths resolve (node_modules + compiled proto stubs).
    final sym = symbol ?? '';
    final script =
        '''
const grpc = require('@grpc/grpc-js');
const fs   = require('fs');
const svc  = require('./dist/lib/proto/boltzrpc_grpc_pb');
const msg  = require('./dist/lib/proto/boltzrpc_pb');

const creds = grpc.credentials.createSsl(
  fs.readFileSync('/boltz-data/certificates/ca.pem'),
  fs.readFileSync('/boltz-data/certificates/client-key.pem'),
  fs.readFileSync('/boltz-data/certificates/client.pem'),
);
const client = new svc.BoltzClient('127.0.0.1:9000', creds);
const req = new msg.SweepSwapsRequest();
if ('$sym') req.setSymbol('$sym');
client.sweepSwaps(req, (err, resp) => {
  if (err) { process.stderr.write(err.message); process.exit(1); }
  process.stdout.write(JSON.stringify(resp.toObject()));
  process.exit(0);
});
setTimeout(() => { process.stderr.write('timeout'); process.exit(1); }, 15000);
''';
    final result = await Process.run('docker', [
      'exec',
      '-w',
      '/boltz-backend',
      'boltz-backend',
      'node',
      '-e',
      script,
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'triggerBoltzClaimSweep(${symbol ?? "all"}) failed: ${result.stderr}',
      );
    }
  }

  Future<void> dispose({bool resetGetIt = true}) async {
    if (_ownsHostr) {
      await hostr.dispose();
      if (resetGetIt) {
        await getIt.reset();
      }
    }

    // Tear down NWC app connections on AlbyHub to free relay subscription
    // slots. Errors are swallowed so a single failure doesn't block the rest.
    for (final pubkey in _createdAppPubkeys) {
      try {
        await albyHub.destroyConnection(pubkey);
      } catch (e) {
        // best-effort cleanup
        CustomLogger().e(
          'Failed to destroy AlbyHub connection for $pubkey',
          error: e,
        );
      }
    }
    _createdAppPubkeys.clear();
    albyHub.close();
    seeds.dispose();
  }

  static void resetLogLevel() {
    CustomLogger.configure(level: Level.trace);
  }

  /// Shorthand for the arrange phase common to most EVM integration tests.
  ///
  /// 1. Creates a fresh trade (with EVM escrow service).
  /// 2. Signs in as the guest and pairs NWC.
  /// 3. Funds the guest's EVM address on both Anvil chains.
  ///
  /// Returns an [ArrangedEvmTest] with everything pre-wired.
  Future<ArrangedEvmTest> arrangeEvmTest({
    String appNamePrefix = 'evm-test',
    BigInt? fundAmountWei,
  }) async {
    final trade = await seeds.freshTrade(hostHasEvm: true);
    await signInAndConnectNwc(
      user: trade.guest.keyPair,
      appNamePrefix: appNamePrefix,
    );
    final evmKey = await hostr.auth.hd.getActiveEvmKey();
    final evmAddress = evmKey.address.eip55With0x;
    final amount = fundAmountWei ?? rbtcFromSats(BigInt.from(1000000)).getInWei;
    await Future.wait([
      anvil.setBalance(address: evmAddress, amountWei: amount),
      anvilRootstock.setBalance(address: evmAddress, amountWei: amount),
    ]);
    return ArrangedEvmTest(
      trade: trade,
      evmKey: evmKey,
      evmAddress: evmAddress,
    );
  }
}

/// Result of [IntegrationTestHarness.arrangeEvmTest].
class ArrangedEvmTest {
  final TestTrade trade;
  final EthPrivateKey evmKey;
  final String evmAddress;

  ArrangedEvmTest({
    required this.trade,
    required this.evmKey,
    required this.evmAddress,
  });
}
