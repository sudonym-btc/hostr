import 'dart:io';

import 'package:escrow/daemon/handlers.dart';
import 'package:escrow/daemon/rpc_socket_server.dart';
import 'package:escrow/injection.dart';
import 'package:escrow/shared/socket_config.dart';
import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/stubs/main.dart';

/// Allow self-signed certificates so the daemon can connect to local
/// relay/blossom/etc. over TLS without a trusted CA chain.
class PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}

/// Entry point for the escrow daemon.
///
/// Usage:
///   dart run bin/daemon.dart
///
/// The daemon:
///   1. Bootstraps Hostr, authenticates, deploys/publishes the escrow service.
///   2. Starts the [EscrowDaemon] to listen for on-chain events, Nostr
///      thread messages, and reservation auto-confirmation.
///   3. Opens a Unix domain socket and serves JSON-RPC requests from CLI
///      clients.
void main(List<String> arguments) async {
  print('[daemon] Starting escrow daemon…');

  // ── Process-level setup ───────────────────────────────────────────────────
  HttpOverrides.global = PermissiveHttpOverrides();
  setCryptoProvider(DartCryptoProvider());

  final String privateKey =
      Platform.environment['PRIVATE_KEY'] ?? MockKeys.escrow.privateKey!;
  final String environment = Platform.environment['ENV'] ?? 'dev';

  await setupInjection(environment: environment);
  final hostr = getIt<Hostr>();
  await hostr.auth.signin(privateKey);

  // ── 1. Bootstrap + Monitor via SDK ────────────────────────────────────────
  final chain = env.evmConfig.chains.first;
  final daemon = EscrowDaemon(hostr: hostr);
  await daemon.bootstrap(EscrowDaemonConfig(
    feePercent: 1,
    maxDuration: const Duration(days: 365),
    chainIndex: hostr.evm.configuredChains.indexWhere(
      (c) => c.config.escrowContractAddress == chain.escrowContractAddress,
    ),
  ));
  print('[daemon] Bootstrap complete');

  daemon.start();

  // ── 2. RPC server ─────────────────────────────────────────────────────────
  final handler = DaemonHandler(daemon: daemon);
  final server = RpcSocketServer(
    socketPath: socketPath,
    registerMethods: handler.register,
  );
  await server.start();

  print('[daemon] Escrow daemon ready — socket: $socketPath');
  print('[daemon] Press Ctrl-C to stop');

  // ── Graceful shutdown ─────────────────────────────────────────────────────
  Future<void> shutdown() async {
    print('\n[daemon] Shutting down…');
    await server.stop();
    await daemon.stop();
    await hostr.dispose();
    print('[daemon] Goodbye');
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => shutdown());
  // SIGTERM is not available on Windows, but that's fine for SSH/Linux usage.
  try {
    ProcessSignal.sigterm.watch().listen((_) => shutdown());
  } catch (_) {
    // Ignore — SIGTERM not supported on this platform.
  }
}
