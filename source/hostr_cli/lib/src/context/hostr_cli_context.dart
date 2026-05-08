import 'dart:io';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart' as sdk_injection;
import 'package:logger/logger.dart';
import 'package:ndk/ndk.dart'
    as ndk
    show Logger, LogLevel, MemCacheManager, NdkConfig, NdkEngine;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../config/cli_environment.dart';
import '../config/development_tls.dart';
import '../storage/cli_key_value_storage.dart';

class HostrCliOptions {
  const HostrCliOptions({
    required this.environment,
    required this.stateDir,
    required this.json,
    required this.dryRun,
    required this.allowInsecureFileSecrets,
    this.relayOverride,
  });

  final HostrCliEnvironment environment;
  final Directory stateDir;
  final bool json;
  final bool dryRun;
  final bool allowInsecureFileSecrets;
  final String? relayOverride;
}

class HostrCliContext {
  HostrCliContext._({
    required this.options,
    required this.hostr,
    required this.database,
  });

  final HostrCliOptions options;
  final Hostr hostr;
  final sqlite.Database database;

  static Future<HostrCliContext> create(HostrCliOptions options) async {
    final foundation = await _HostrCliFoundation.create(options);
    final hostr = Hostr(
      config: foundation.config,
      environment: foundation.environment.sdkEnvironment,
    );
    await hostr.initAuth();
    return HostrCliContext._(
      options: options,
      hostr: hostr,
      database: foundation.database,
    );
  }

  Future<void> dispose() async {
    try {
      await hostr.dispose();
    } finally {
      database.close();
      await sdk_injection.getIt.reset(dispose: true);
    }
  }
}

class HostrCliRuntimeContext {
  HostrCliRuntimeContext._({
    required this.options,
    required this.runtime,
    required this.database,
  });

  final HostrCliOptions options;
  final HostrRuntime runtime;
  final sqlite.Database database;

  static Future<HostrCliRuntimeContext> create(HostrCliOptions options) async {
    final foundation = await _HostrCliFoundation.create(options);
    return HostrCliRuntimeContext._(
      options: options,
      runtime: HostrRuntime(
        config: foundation.config,
        environment: foundation.environment.sdkEnvironment,
      ),
      database: foundation.database,
    );
  }

  Future<void> dispose() async {
    try {
      await runtime.dispose();
    } finally {
      database.close();
      await sdk_injection.getIt.reset(dispose: true);
    }
  }
}

class _HostrCliFoundation {
  const _HostrCliFoundation({
    required this.environment,
    required this.config,
    required this.database,
  });

  final HostrCliEnvironment environment;
  final HostrConfig config;
  final sqlite.Database database;

  static Future<_HostrCliFoundation> create(HostrCliOptions options) async {
    await options.stateDir.create(recursive: true);

    if (sdk_injection.getIt.isRegistered<HostrConfig>()) {
      await sdk_injection.getIt.reset(dispose: true);
    }

    final env = options.relayOverride == null
        ? options.environment
        : options.environment.copyWith(
            hostrRelay: options.relayOverride,
            bootstrapRelays: [options.relayOverride!],
          );
    configureDevelopmentTlsTrust(env);

    final dbPath = p.join(options.stateDir.path, '${env.name}.sqlite3');
    final db = sqlite.sqlite3.open(dbPath);
    final storage = CliKeyValueStorage(
      stateDir: Directory(p.join(options.stateDir.path, env.name)),
      allowInsecureFileStorage: options.allowInsecureFileSecrets,
    );

    final daemonLogsEnabled =
        Platform.environment['HOSTR_DAEMON_LOGS'] == '1' ||
        Platform.environment['HOSTR_DAEMON_LOGS'] == 'true';
    final logLevel = _logLevelFromEnvironment(
      Platform.environment['HOSTR_DAEMON_LOG_LEVEL'],
    );
    final ndkLogLevel = _ndkLogLevelFromEnvironment(
      Platform.environment['HOSTR_DAEMON_NDK_LOG_LEVEL'],
    );
    CustomLogger.configure(
      output: options.json && !daemonLogsEnabled
          ? _SilentLogOutput()
          : _StderrLogOutput(),
      level: daemonLogsEnabled
          ? logLevel
          : (options.json ? Level.off : Level.warning),
    );
    ndk.Logger.setLogLevel(
      daemonLogsEnabled
          ? ndkLogLevel
          : (options.json ? ndk.LogLevel.off : ndk.LogLevel.warning),
    );
    final eventVerifier = CoinlibVerifier();
    CoinlibEventSigner eventSignerFactory({
      required String publicKey,
      String? privateKey,
    }) {
      return CoinlibEventSigner(privateKey: privateKey, publicKey: publicKey);
    }

    final nip44Cryptography = CoinlibNip44Cryptography();
    final ndkConfig = ndk.NdkConfig(
      eventVerifier: eventVerifier,
      eventSignerFactory: eventSignerFactory,
      nip44Cryptography: nip44Cryptography,
      cache: ndk.MemCacheManager(),
      fetchedRangesEnabled: true,
      engine: ndk.NdkEngine.RELAY_SETS,
      defaultQueryTimeout: const Duration(seconds: 10),
      bootstrapRelays: [if (env.hostrRelay.trim().isNotEmpty) env.hostrRelay],
      ignoreRelays: env.hostrRelay == 'wss://relay.hostr.development'
          ? const []
          : const ['wss://relay.hostr.development'],
      logLevel: daemonLogsEnabled
          ? ndkLogLevel
          : (options.json ? ndk.LogLevel.off : ndk.LogLevel.warning),
    );

    final config = HostrConfig(
      logs: CustomLogger(),
      bootstrapRelays: [
        env.hostrRelay,
        ...env.bootstrapRelays,
      ].where((relay) => relay.trim().isNotEmpty).toSet().toList(),
      bootstrapBlossom: env.bootstrapBlossom
          .where((url) => url.trim().isNotEmpty)
          .toSet()
          .toList(),
      bootstrapEscrowPubkeys: env.bootstrapEscrowPubkeys,
      hostrRelay: env.hostrRelay,
      evmConfig: env.evmConfig,
      storage: storage,
      appDatabase: AppDatabase(db),
      eventVerifier: eventVerifier,
      eventSignerFactory: eventSignerFactory,
      nip44Cryptography: nip44Cryptography,
      ndk: ndkConfig,
    );

    return _HostrCliFoundation(environment: env, config: config, database: db);
  }
}

class _SilentLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {}
}

class _StderrLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      stderr.writeln(line);
    }
  }
}

Level _logLevelFromEnvironment(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'all':
    case 'trace':
      return Level.trace;
    case 'debug':
      return Level.debug;
    case 'info':
      return Level.info;
    case 'warning':
    case 'warn':
      return Level.warning;
    case 'error':
      return Level.error;
    case 'fatal':
      return Level.fatal;
    case 'off':
      return Level.off;
    default:
      return Level.trace;
  }
}

ndk.LogLevel _ndkLogLevelFromEnvironment(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'all':
      return ndk.LogLevel.all;
    case 'trace':
      return ndk.LogLevel.trace;
    case 'debug':
      return ndk.LogLevel.debug;
    case 'info':
      return ndk.LogLevel.info;
    case 'warning':
    case 'warn':
      return ndk.LogLevel.warning;
    case 'error':
      return ndk.LogLevel.error;
    case 'fatal':
      return ndk.LogLevel.fatal;
    case 'off':
      return ndk.LogLevel.off;
    default:
      return ndk.LogLevel.trace;
  }
}
