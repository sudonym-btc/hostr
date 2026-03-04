import 'dart:io';

import 'package:escrow/cli/cli_app.dart';
import 'package:escrow/cli/daemon_client.dart';
import 'package:escrow/shared/socket_config.dart';

/// Entry point for the interactive escrow CLI.
///
/// Usage:
///   dart run bin/cli.dart
///
/// Connects to the running daemon via Unix domain socket, then presents an
/// interactive menu that works well over SSH.
void main(List<String> arguments) async {
  final client = DaemonClient();

  try {
    await client.connect(socketPath);
  } on SocketException catch (e) {
    print('Could not connect to the escrow daemon at $socketPath');
    print('Is the daemon running?  Start it with:  dart run bin/daemon.dart');
    print('');
    print('Error: $e');
    exit(1);
  }

  print('Connected to escrow daemon at $socketPath');
  print('');

  try {
    final app = CliApp(client: client);
    await app.run();
  } finally {
    await client.close();
  }
}
