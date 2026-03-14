import 'dart:io';

Future<void> warmUpRelayConnection(String url) async {
  try {
    final ws = await WebSocket.connect(url);
    await ws.close();
  } catch (_) {}
}
