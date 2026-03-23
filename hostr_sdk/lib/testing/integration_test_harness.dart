import 'dart:io';
import 'dart:math';

import 'package:hydrated_bloc/hydrated_bloc.dart' as hydrated;
import 'package:logger/logger.dart';
import 'package:models/nostr_kinds.dart';
import 'package:ndk/ndk.dart' hide ConsoleOutput;
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../config.dart';
import '../datasources/main.dart';
import '../hostr.dart';
import '../injection.dart';
import '../seed/seed.dart';
import '../usecase/evm/config/evm_config.dart';
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
  final AlbyHubClient albyHub;
  final TestSeedHelper seeds;
  final Directory hydratedDir;

  /// Whether this harness created the [hostr] instance (and therefore
  /// owns its lifecycle).  When `false`, [dispose] will skip
  /// `hostr.dispose()` and `getIt.reset()`.
  final bool _ownsHostr;

  /// Pubkeys of NWC app connections created during this harness lifetime.
  /// Used by [dispose] to tear them down and free relay subscription slots.
  final List<String> _createdAppPubkeys = [];

  IntegrationTestHarness({
    required this.hostr,
    required this.anvil,
    required this.albyHub,
    required this.seeds,
    required this.hydratedDir,
    this.fundedKeys = const [],
    bool ownsHostr = true,
  }) : _ownsHostr = ownsHostr;

  static const bootstrapRelays = ['wss://relay.hostr.development'];
  static const bootstrapBlossom = ['https://blossom.hostr.development'];
  static const hostrRelay = 'wss://relay.hostr.development';
  static const anvilRpc = 'https://anvil.hostr.development';
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
    // Accept self-signed dev TLS certs for all HTTP/WebSocket connections.
    HttpOverrides.global = _PermissiveHttpOverrides();

    CustomLogger.configure(output: ConsoleOutput(), level: logLevel);
    final seeds = TestSeedHelper(seed: seed);
    final storageDir = Directory('${Directory.systemTemp.path}/$name');

    // When an external Hostr is supplied the caller already set up hydrated
    // storage — skip the setup to avoid overwriting it.
    if (hostr == null) {
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
            bootstrapBlossom: bootstrapBlossom,
            hostrRelay: hostrRelay,
            evmConfig: _developmentEvmConfig(),
          ),
        );

    final anvil = AnvilClient(rpcUri: Uri.parse(anvilRpc));
    List<KeyPair> fundKeys = [seeds.deriveKeyPair(Random().nextInt(1000000))];
    await Future.wait([
      anvil.setAutomine(true),
      ...fundKeys.map(
        (key) async => anvil.setBalance(
          address: (await deriveEvmKey(key.privateKey!)).address.eip55With0x,
          amountWei: rbtcFromSatsInt(1000000).getInWei,
        ),
      ),
    ]);
    final albyHub = AlbyHubClient(
      baseUri: Uri.parse(albyHubUrl),
      unlockPassword: Platform.environment['ALBYHUB_PASSWORD'] ?? 'Testing123!',
    );

    return IntegrationTestHarness(
      hostr: resolvedHostr,
      anvil: anvil,
      albyHub: albyHub,
      hydratedDir: storageDir,
      seeds: seeds,
      fundedKeys: fundKeys,
      ownsHostr: hostr == null,
    );
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
}

/// Reads token contract addresses from runtime environment variables.
Map<String, TokenConfig> _envTokens() {
  final tbtcAddr = Platform.environment['ARBITRUM_TBTC_ADDRESS']?.trim();
  final tbtcDec = Platform.environment['ARBITRUM_TBTC_DECIMALS']?.trim();
  final usdtAddr = Platform.environment['ARBITRUM_USDT_ADDRESS']?.trim();
  final usdtDec = Platform.environment['ARBITRUM_USDT_DECIMALS']?.trim();

  return {
    if (tbtcAddr != null && tbtcAddr.isNotEmpty)
      'tBTC': TokenConfig(
        address: tbtcAddr,
        decimals: int.tryParse(tbtcDec ?? '') ?? 18,
      ),
    if (usdtAddr != null && usdtAddr.isNotEmpty)
      'USDT': TokenConfig(
        address: usdtAddr,
        decimals: int.tryParse(usdtDec ?? '') ?? 6,
      ),
  };
}

EvmConfig _developmentEvmConfig() {
  String _requireEnv(String key) {
    final value = Platform.environment[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
    throw StateError(
      'Missing environment variable $key. '
      'Run ./scripts/restart.sh to sync .env with deployed contract addresses.',
    );
  }

  return EvmConfig(
    boltz: BoltzConfig(apiUrl: 'https://boltz.hostr.development/v2'),
    chains: [
      EvmChainConfig(
        id: 'anvil',
        chainId: 412346,
        rpcUrl: IntegrationTestHarness.anvilRpc,
        accountAbstraction: AAConfig(
          bundlerUrl:
              Platform.environment['AA_BUNDLER_URL']?.trim() ??
              'https://paymaster.hostr.development',
          entryPointAddress: _requireEnv('AA_ENTRY_POINT_ADDRESS'),
          accountFactoryAddress: _requireEnv('AA_ACCOUNT_FACTORY_ADDRESS'),
          paymasterAddress: _requireEnv('AA_PAYMASTER_ADDRESS'),
        ),
        tokens: _envTokens(),
      ),
    ],
  );
}
