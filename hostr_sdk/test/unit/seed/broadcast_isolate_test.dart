@Tags(['unit'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/seed/broadcast_isolate.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('BroadcastIsolate', () {
    test('broadcasts raw EVENT frames and tracks relay OKs', () async {
      final relay = await _FakeRelay.start();
      final broadcaster = await BroadcastIsolate.spawn(
        relayUrl: relay.url,
        maxConcurrent: 20,
        maxAttempts: 1,
      );

      final successes = broadcaster.results
          .where((event) => event is BroadcastSuccess)
          .take(20)
          .toList();

      for (var i = 0; i < 20; i++) {
        broadcaster.submit(i, _event(i));
      }

      final finished = await broadcaster.finish();

      expect(finished.successCount, 20);
      expect(finished.failureCount, 0);
      expect(await successes, hasLength(20));
      expect(relay.eventIds, List.generate(20, _eventId));

      await relay.close();
    });

    test('retries rejected events and reports permanent failures', () async {
      final rejectedId = _eventId(3);
      final relay = await _FakeRelay.start(
        accept: (event) => event['id'] != rejectedId,
      );
      final broadcaster = await BroadcastIsolate.spawn(
        relayUrl: relay.url,
        maxConcurrent: 5,
        maxAttempts: 2,
      );

      final failures = broadcaster.results
          .where((event) => event is BroadcastFailure)
          .cast<BroadcastFailure>()
          .take(1)
          .toList();

      for (var i = 0; i < 5; i++) {
        broadcaster.submit(i, _event(i));
      }

      final finished = await broadcaster.finish();

      expect(finished.successCount, 4);
      expect(finished.failureCount, 1);
      expect((await failures).single.index, 3);
      expect(relay.attemptsById[rejectedId], 2);

      await relay.close();
    });
  });
}

Nip01Event _event(int index) => Nip01Event(
  id: _eventId(index),
  pubKey: '1'.padLeft(64, '0'),
  createdAt: 1,
  kind: 1,
  tags: const [],
  content: 'seed event $index',
  sig: '2'.padLeft(128, '0'),
);

String _eventId(int index) => index.toRadixString(16).padLeft(64, '0');

class _FakeRelay {
  _FakeRelay._({required this.server, required this.accept});

  final HttpServer server;
  final bool Function(Map<String, dynamic> event) accept;
  final List<String> eventIds = [];
  final Map<String, int> attemptsById = {};

  String get url => 'ws://${server.address.host}:${server.port}';

  static Future<_FakeRelay> start({
    bool Function(Map<String, dynamic> event)? accept,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final relay = _FakeRelay._(server: server, accept: accept ?? (_) => true);
    server.listen(relay._handleRequest);
    return relay;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    socket.listen((raw) {
      final frame = jsonDecode(raw as String) as List<dynamic>;
      if (frame.length < 2 || frame.first != 'EVENT') return;
      final event = Map<String, dynamic>.from(frame[1] as Map);
      final id = event['id'] as String;
      eventIds.add(id);
      attemptsById[id] = (attemptsById[id] ?? 0) + 1;
      final ok = accept(event);
      socket.add(jsonEncode(['OK', id, ok, ok ? '' : 'blocked']));
    });
  }

  Future<void> close() => server.close(force: true);
}
