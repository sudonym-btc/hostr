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

  // ── 1. Start the daemon as a child process ────────────────────────────────
  print('Starting escrow daemon…');
  final daemon = await Process.start(
    daemonExe,
    ['run', daemonScript, ...arguments],
    mode: ProcessStartMode.inheritStdio,
    environment: Platform.environment,
  );

  // Forward signals so Ctrl-C doesn't leave an orphan.
  late final List<StreamSubscription<ProcessSignal>> subs;
  void killDaemon() {
    daemon.kill(ProcessSignal.sigterm);
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

  // ── 2. Wait for the socket to appear ──────────────────────────────────────
  final path = socketPath;
  const timeout = Duration(seconds: 30);
  const poll = Duration(milliseconds: 250);
  final deadline = DateTime.now().add(timeout);

  var ready = false;
  while (DateTime.now().isBefore(deadline)) {
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound) {
      // Socket file exists — try a real connection to confirm the daemon is
      // listening (not just leftover from a previous run).
      try {
        final probe = await Socket.connect(
          InternetAddress(path, type: InternetAddressType.unix),
          0,
        );
        await probe.close();
        ready = true;
        break;
      } catch (_) {
        // Not ready yet.
      }
    }
    await Future<void>.delayed(poll);
  }

  if (!ready) {
    print('Timed out waiting for daemon socket at $path');
    killDaemon();
    for (final s in subs) {
      await s.cancel();
    }
    exit(1);
  }

  // Small grace period so the daemon finishes printing its startup banner.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  print(''); // visual separator

  // ── 3. Launch the CLI in the same terminal ────────────────────────────────
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
  await daemon.exitCode;

  for (final s in subs) {
    await s.cancel();
  }
  exit(cliCode);
}
