import 'dart:io';

/// Returns the path to the Unix domain socket used for daemon ↔ CLI IPC.
///
/// Override with the `ESCROW_SOCKET` environment variable.
String get socketPath =>
    Platform.environment['ESCROW_SOCKET'] ??
    '${Directory.systemTemp.path}/escrow_daemon.sock';
