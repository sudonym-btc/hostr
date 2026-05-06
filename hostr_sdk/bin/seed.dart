import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:hostr_sdk/seed/relay_seed.dart';
import 'package:models/secp256k1.dart'
    show describeSecp256k1Backend, loadSecp256k1Backend;

/// Allow self-signed certificates so the seeder can connect to local
/// relay/blossom/etc. over TLS without a trusted CA chain.
class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    return client;
  }
}

Future<void> main(List<String> arguments) async {
  HttpOverrides.global = _PermissiveHttpOverrides();

  // NDK's internal WebSocket transport can fire SocketExceptions from
  // dart:io Timer callbacks when the relay drops the connection or during
  // ndk.destroy(). These are uncatchable with try/catch, so we absorb
  // them here so they don't crash the process with exit code 255.
  await runZonedGuarded(
    () async {
      await _run(arguments);
    },
    (error, stack) {
      // SocketExceptions from a closed relay socket are expected during
      // teardown — log and swallow.
      if (error is SocketException) {
        stderr.writeln(
          '[warn] Ignoring async SocketException during '
          'teardown: $error',
        );
        return;
      }
      // Anything else is unexpected — print and set a non-zero exit code.
      stderr.writeln('[error] Unhandled async error: $error');
      stderr.writeln(stack);
      exitCode = 1;
    },
  );
}

Future<void> _run(List<String> arguments) async {
  await loadSecp256k1Backend();
  print('runtime backend secp256k1: ${describeSecp256k1Backend()}');

  SeedPipelineConfig? config;

  final positionalArgs = arguments
      .where((arg) => !arg.startsWith('--'))
      .toList();
  if (positionalArgs.isNotEmpty) {
    print(
      'Positional arguments are not supported. Set relayUrl in config JSON/file.',
    );
    exitCode = 64;
    return;
  }

  for (final arg in arguments) {
    if (arg.startsWith('--config-json=')) {
      final json = jsonDecode(arg.substring('--config-json='.length));
      final map = Map<String, dynamic>.from(json as Map);
      config = SeedPipelineConfig.fromJson(map);
    } else if (arg.startsWith('--config-file=')) {
      final path = arg.substring('--config-file='.length);
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw);
      final map = Map<String, dynamic>.from(json as Map);
      config = SeedPipelineConfig.fromJson(map);
    } else if (arg.startsWith('--')) {
      print(
        'Unsupported flag: $arg. relayUrl/rpcUrl/fundProfiles/tradeSponsorPrivateKey must be provided in config JSON/file.',
      );
      exitCode = 64;
      return;
    }
  }

  final seeder = RelaySeeder();
  final resolved = _withEnvOverrides(config ?? const SeedPipelineConfig());
  final sponsor = resolved.tradeSponsorPrivateKey?.trim();
  if (!resolved.fundProfiles && (sponsor == null || sponsor.isEmpty)) {
    throw StateError(
      'Seed config has fundProfiles=false but no tradeSponsorPrivateKey. '
      'Set SEED_TRADE_SPONSOR_PRIVATE_KEY or provide tradeSponsorPrivateKey '
      'in the seed config so a dedicated keypair funds seeded trades.',
    );
  }
  await seeder.runPipeline(config: resolved);
}

/// Overlay token addresses from environment variables (or the token
/// manifest file) and optional local seeder credentials when the config
/// doesn't already specify them.
///
/// Resolution order for each token address:
///   1. Explicit value in the parsed config (JSON / file).
///   2. `ARBITRUM_TBTC_ADDRESS` / `ARBITRUM_USDT_ADDRESS` env vars
///      (set by `sync-contract-env.sh` → sourced by `seed_relay.sh`).
///   3. Token manifest at `docker/data/arbitrum/token-addresses.json`
///      (written by `arbitrum-init.sh` after deploying mock tokens).
SeedPipelineConfig _withEnvOverrides(SeedPipelineConfig base) {
  final env = Platform.environment;

  // Try env vars first.
  var tbtcAddr = base.tbtcAddress ?? env['ARBITRUM_TBTC_ADDRESS'];
  var usdtAddr = base.usdtAddress ?? env['ARBITRUM_USDT_ADDRESS'];
  var tbtcDec = base.tbtcDecimals;
  var usdtDec = base.usdtDecimals;

  final appBaseUrl = _resolveAppBaseUrl(env: env, relayUrl: base.relayUrl);
  final resolvedEscrowPicture =
      (base.escrowProfilePicture?.trim().isNotEmpty ?? false)
      ? base.escrowProfilePicture!.trim()
      : (env['SEED_ESCROW_PROFILE_PICTURE']?.trim().isNotEmpty ?? false)
      ? env['SEED_ESCROW_PROFILE_PICTURE']!.trim()
      : '$appBaseUrl/assets/assets/images/logo/generated/logo_base_1024.png';

  // Fallback: read the token manifest produced by arbitrum-init.
  if (tbtcAddr == null || usdtAddr == null) {
    final manifest = _readTokenManifest(base.chainId);
    tbtcAddr ??= manifest?['tBTC']?['address'] as String?;
    usdtAddr ??= manifest?['USDT']?['address'] as String?;
    if (manifest?['tBTC']?['decimals'] != null) {
      tbtcDec = (manifest!['tBTC']!['decimals'] as num).toInt();
    }
    if (manifest?['USDT']?['decimals'] != null) {
      usdtDec = (manifest!['USDT']!['decimals'] as num).toInt();
    }
  }

  if (tbtcAddr == null || tbtcAddr.isEmpty) {
    throw StateError(
      'Could not resolve tBTC token address. '
      'Set ARBITRUM_TBTC_ADDRESS in the environment, or ensure '
      'docker/data/arbitrum/token-addresses.json contains a tBTC entry.',
    );
  }
  if (usdtAddr == null || usdtAddr.isEmpty) {
    throw StateError(
      'Could not resolve USDT token address. '
      'Set ARBITRUM_USDT_ADDRESS in the environment, or ensure '
      'docker/data/arbitrum/token-addresses.json contains a USDT entry.',
    );
  }

  return base.copyWith(
    tbtcAddress: tbtcAddr,
    tbtcDecimals: tbtcDec,
    usdtAddress: usdtAddr,
    usdtDecimals: usdtDec,
    tradeSponsorPrivateKey:
        base.tradeSponsorPrivateKey ?? env['SEED_TRADE_SPONSOR_PRIVATE_KEY'],
    escrowProfilePicture: resolvedEscrowPicture,
    signetBunkerUrl: base.signetBunkerUrl ?? env['SEED_SIGNET_BUNKER_URL'],
  );
}

String _resolveAppBaseUrl({
  required Map<String, String> env,
  required String? relayUrl,
}) {
  final explicit = env['SEED_APP_BASE_URL']?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    return explicit.endsWith('/')
        ? explicit.substring(0, explicit.length - 1)
        : explicit;
  }

  final domain = env['DOMAIN']?.trim();
  if (domain != null && domain.isNotEmpty) return 'https://$domain';

  final relay = (relayUrl ?? env['RELAY_URL'])?.trim();
  final uri = relay == null ? null : Uri.tryParse(relay);
  final host = uri?.host.trim();
  if (host != null && host.isNotEmpty) {
    if (host.startsWith('relay.')) {
      return 'https://${host.substring('relay.'.length)}';
    }
    return 'https://$host';
  }

  return 'https://hostr.development';
}

/// Try to read token addresses from the JSON manifest written by
/// `arbitrum-init.sh`.  Returns the entry for the current chain's
/// network key, or `null` if the file doesn't exist / is unparseable.
Map<String, dynamic>? _readTokenManifest(int chainId) {
  // Map chainId → manifest key (mirrors sync-contract-env.sh).
  final networkKey = chainId == 42161 ? 'mainnet.42161' : 'regtest.$chainId';

  // Walk up from hostr_sdk/bin/seed.dart to repo root:
  //   bin/seed.dart → bin/ → hostr_sdk/ → hostr/
  final repoRoot = File(Platform.script.toFilePath()).parent.parent.parent.path;
  final candidates = [
    '$repoRoot/docker/data/arbitrum/token-addresses.json',
    // Also check env-overridden path.
    if (Platform.environment.containsKey('TOKEN_ADDRESSES_FILE'))
      Platform.environment['TOKEN_ADDRESSES_FILE']!,
  ];

  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    try {
      final parsed = jsonDecode(file.readAsStringSync());
      if (parsed is Map) {
        final entry = parsed[networkKey];
        if (entry is Map) return Map<String, dynamic>.from(entry);
      }
    } catch (_) {
      // Non-fatal — fall through.
    }
  }
  return null;
}
