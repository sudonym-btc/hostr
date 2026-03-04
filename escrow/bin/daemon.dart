import 'dart:io';

import 'package:escrow/daemon/bootstrap.dart';
import 'package:escrow/daemon/escrow_monitor.dart';
import 'package:escrow/daemon/handlers.dart';
import 'package:escrow/daemon/rpc_socket_server.dart';
import 'package:escrow/shared/socket_config.dart';

/// Entry point for the escrow daemon.
///
/// Usage:
///   dart run bin/daemon.dart
///
/// The daemon:
///   1. Bootstraps Hostr, authenticates, deploys/publishes the escrow service.
///   2. Starts the [EscrowMonitor] to listen for on-chain events and Nostr
///      thread messages.
///   3. Opens a Unix domain socket and serves JSON-RPC requests from CLI
///      clients.
void main(List<String> arguments) async {
  print('[daemon] Starting escrow daemon…');

  // ── 1. Bootstrap ──────────────────────────────────────────────────────────
  final ctx = await bootstrap();
  print('[daemon] Bootstrap complete');

  // ── 2. Monitor ────────────────────────────────────────────────────────────
  final monitor = EscrowMonitor(
    hostr: ctx.hostr,
    contract: ctx.contract,
    escrowService: ctx.escrowService,
  );
  monitor.start();

  // ── 3. RPC server ─────────────────────────────────────────────────────────
  final handler = DaemonHandler(ctx: ctx, monitor: monitor);
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
    await monitor.stop();
    await ctx.hostr.dispose();
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
