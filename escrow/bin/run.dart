import 'dart:async';
import 'dart:io';

import 'package:escrow/shared/socket_config.dart';

/// Combined launcher: starts the daemon, waits for its socket to be ready,
/// then runs the interactive CLI.  When the CLI exits the daemon is torn down.
///
/// Usage:
///   dart run bin/run.dart
void main(List<String> arguments) async {
  final daemonExe = Platform.resolvedExecutable; // path to `dart`
  final daemonScript =
      '${Directory.current.path}/bin/daemon.dart'.replaceAll('//', '/');

  // ── 0. Check if a daemon is already running ───────────────────────────────
  final path = socketPath;
  Process? daemon;
  var daemonOwned = false;

  Future<bool> isDaemonRunning() async {
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      return false;
    }
    try {
      final probe = await Socket.connect(
        InternetAddress(path, type: InternetAddressType.unix),
        0,
      );
      await probe.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  if (await isDaemonRunning()) {
    print('Escrow daemon already running — attaching CLI…');
  } else {
    // ── 1. Start the daemon as a child process ──────────────────────────────
    print('Starting escrow daemon…');
    daemon = await Process.start(
      daemonExe,
      ['run', daemonScript, ...arguments],
      mode: ProcessStartMode.inheritStdio,
      environment: Platform.environment,
    );
    daemonOwned = true;

    // Wait for the socket to appear.
    const timeout = Duration(seconds: 30);
    const poll = Duration(milliseconds: 250);
    final deadline = DateTime.now().add(timeout);

    var ready = false;
    while (DateTime.now().isBefore(deadline)) {
      if (await isDaemonRunning()) {
        ready = true;
        break;
      }
      await Future<void>.delayed(poll);
    }

    if (!ready) {
      print('Timed out waiting for daemon socket at $path');
      daemon.kill(ProcessSignal.sigterm);
      exit(1);
    }

    // Small grace period so the daemon finishes printing its startup banner.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  // ── Signal forwarding (only if we own the daemon) ─────────────────────────
  late final List<StreamSubscription<ProcessSignal>> subs;
  void killDaemon() {
    if (daemonOwned) daemon?.kill(ProcessSignal.sigterm);
  }

  subs = [
    ProcessSignal.sigint.watch().listen((_) => killDaemon()),
    ...(() {
      try {
        return [ProcessSignal.sigterm.watch().listen((_) => killDaemon())];
      } catch (_) {
        return <StreamSubscription<ProcessSignal>>[];
      }
    })(),
  ];

  print(''); // visual separator

  // ── 2. Launch the CLI in the same terminal ────────────────────────────────
  final cliScript =
      '${Directory.current.path}/bin/cli.dart'.replaceAll('//', '/');

  final cli = await Process.start(
    daemonExe,
    ['run', cliScript],
    mode: ProcessStartMode.inheritStdio,
    environment: Platform.environment,
  );

  final cliCode = await cli.exitCode;

  // ── 4. Tear down ─────────────────────────────────────────────────────────
  print('');
  print('CLI exited (code $cliCode) — stopping daemon…');
  killDaemon();
  if (daemon != null) await daemon.exitCode;

  for (final s in subs) {
    await s.cancel();
  }
  exit(cliCode);
}
