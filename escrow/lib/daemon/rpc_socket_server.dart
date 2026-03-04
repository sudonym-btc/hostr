import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';

/// A JSON-RPC 2.0 server that listens on a Unix domain socket.
///
/// Each connecting client gets its own [json_rpc.Server] instance, so multiple
/// SSH sessions (each running `escrow_cli`) can talk to the daemon
/// simultaneously.
class RpcSocketServer {
  final String socketPath;
  final void Function(json_rpc.Server server) registerMethods;

  ServerSocket? _serverSocket;
  final List<json_rpc.Server> _clients = [];

  RpcSocketServer({
    required this.socketPath,
    required this.registerMethods,
  });

  /// Bind to [socketPath] and begin accepting connections.
  Future<void> start() async {
    // Remove a stale socket file from a previous run.
    final file = File(socketPath);
    if (file.existsSync()) file.deleteSync();

    _serverSocket = await ServerSocket.bind(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );

    print('[rpc] Listening on $socketPath');

    _serverSocket!.listen(
      _onClient,
      onError: (e) => print('[rpc] Server socket error: $e'),
    );
  }

  void _onClient(Socket socket) {
    print('[rpc] Client connected');

    // Wrap the raw socket in a StreamChannel<String> for json_rpc_2.
    //
    // Protocol: newline-delimited JSON — each JSON-RPC message is one line.
    final incoming = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();

    final outgoing = StreamController<String>();
    outgoing.stream.listen(
      (line) {
        try {
          socket.write('$line\n');
        } catch (_) {
          // Socket already closed — ignore.
        }
      },
      onError: (_) {},
    );

    final channel = StreamChannel<String>(incoming, outgoing.sink);
    final server = json_rpc.Server(channel);

    registerMethods(server);

    _clients.add(server);

    server.listen().then((_) {
      print('[rpc] Client disconnected');
      _clients.remove(server);
    });
  }

  /// Shut down the server and close all client connections.
  Future<void> stop() async {
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    await _serverSocket?.close();
    // Clean up the socket file.
    final file = File(socketPath);
    if (file.existsSync()) file.deleteSync();
  }
}
