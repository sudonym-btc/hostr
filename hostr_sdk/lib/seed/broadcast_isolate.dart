/// Runs raw Nostr EVENT broadcasting in a dedicated isolate so that heavy
/// EVM / anvil work on the main isolate cannot starve the WebSocket ACK loop.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:ndk/ndk.dart';

// ──────────────────────────────────────────────────────────────────────
// Message protocol between main ↔ broadcast isolate
// ──────────────────────────────────────────────────────────────────────

/// Sent from main → isolate to request a broadcast.
class _BroadcastRequest {
  final int index;
  final Map<String, dynamic> eventJson;
  const _BroadcastRequest(this.index, this.eventJson);
}

/// Sent from isolate → main when a broadcast succeeds.
class BroadcastSuccess {
  final int index;
  const BroadcastSuccess(this.index);
}

/// Sent from isolate → main when a broadcast fails permanently.
class BroadcastFailure {
  final int index;
  final String message;
  const BroadcastFailure(this.index, this.message);
}

/// Sent from isolate → main for log messages.
class BroadcastLog {
  final String message;
  const BroadcastLog(this.message);
}

/// Sent from isolate → main when it is ready to receive events.
class BroadcastReady {
  final SendPort sendPort;
  const BroadcastReady(this.sendPort);
}

/// Sentinel sent from main → isolate to signal no more events.
class _BroadcastDone {
  const _BroadcastDone();
}

/// Sent from isolate → main once all queued events are finished.
class BroadcastFinished {
  final int successCount;
  final int failureCount;
  const BroadcastFinished(this.successCount, this.failureCount);
}

// ──────────────────────────────────────────────────────────────────────
// Public API — used from main isolate
// ──────────────────────────────────────────────────────────────────────

/// A handle to a running broadcast isolate.
///
/// Usage:
/// ```dart
/// final broadcaster = await BroadcastIsolate.spawn(relayUrl: '...');
/// broadcaster.submit(0, event0);
/// broadcaster.submit(1, event1);
/// // ... listen to broadcaster.results for BroadcastSuccess / BroadcastFailure
/// await broadcaster.finish(); // waits for all queued events
/// ```
class BroadcastIsolate {
  final Isolate _isolate;
  final SendPort _sendPort;
  final Stream<Object> results;
  final StreamSubscription<Object> _subscription;
  final StreamController<Object> _controller;

  BroadcastIsolate._({
    required Isolate isolate,
    required SendPort sendPort,
    required StreamController<Object> controller,
    required StreamSubscription<Object> subscription,
  }) : _isolate = isolate,
       _sendPort = sendPort,
       _controller = controller,
       _subscription = subscription,
       results = controller.stream;

  /// Spawns the broadcast isolate and waits until it has connected to
  /// the relay and is ready to accept events.
  static Future<BroadcastIsolate> spawn({
    required String relayUrl,
    int maxConcurrent = 200,
    int maxAttempts = 6,
  }) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateArgs(
        sendPort: receivePort.sendPort,
        relayUrl: relayUrl,
        maxConcurrent: maxConcurrent,
        maxAttempts: maxAttempts,
      ),
      debugName: 'broadcast-isolate',
    );

    final controller = StreamController<Object>.broadcast();
    final completer = Completer<SendPort>();

    final subscription = receivePort.cast<Object>().listen((message) {
      if (message is BroadcastReady) {
        completer.complete(message.sendPort);
      } else if (message is BroadcastLog) {
        // Forward logs to main isolate stdout
        print(message.message);
      } else {
        controller.add(message);
      }
    });

    final sendPort = await completer.future;

    return BroadcastIsolate._(
      isolate: isolate,
      sendPort: sendPort,
      controller: controller,
      subscription: subscription,
    );
  }

  /// Queue an event for broadcast. Returns immediately.
  void submit(int index, Nip01Event event) {
    final json = <String, dynamic>{
      'id': event.id,
      'pubkey': event.pubKey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': event.tags,
      'content': event.content,
      'sig': event.sig,
    };
    _sendPort.send(_BroadcastRequest(index, json));
  }

  /// Signals no more events and waits for the isolate to finish
  /// broadcasting everything in its queue.
  ///
  /// Returns the [BroadcastFinished] summary.
  Future<BroadcastFinished> finish() async {
    _sendPort.send(const _BroadcastDone());
    final finished = await results.firstWhere((m) => m is BroadcastFinished);
    await _subscription.cancel();
    _isolate.kill(priority: Isolate.beforeNextEvent);
    await _controller.close();
    return finished as BroadcastFinished;
  }
}

// ──────────────────────────────────────────────────────────────────────
// Isolate internals
// ──────────────────────────────────────────────────────────────────────

class _IsolateArgs {
  final SendPort sendPort;
  final String relayUrl;
  final int maxConcurrent;
  final int maxAttempts;

  const _IsolateArgs({
    required this.sendPort,
    required this.relayUrl,
    required this.maxConcurrent,
    required this.maxAttempts,
  });
}

/// Entry point for the broadcast isolate.
Future<void> _isolateEntry(_IsolateArgs args) async {
  // Accept self-signed certs inside the isolate too.
  HttpOverrides.global = _PermissiveHttpOverrides();

  final mainPort = args.sendPort;
  final relayUrl = args.relayUrl;
  final maxConcurrent = args.maxConcurrent;
  final maxAttempts = args.maxAttempts;

  void log(String msg) => mainPort.send(BroadcastLog(msg));

  // ── Verify relay reachable (dedicated event-loop, won't be starved) ──
  log('[isolate] Verifying relay reachable at $relayUrl ...');
  final reachSw = Stopwatch()..start();
  while (reachSw.elapsed < const Duration(seconds: 60)) {
    try {
      final ws = await WebSocket.connect(
        relayUrl,
      ).timeout(const Duration(seconds: 10));
      await ws.close();
      log(
        '[isolate] Relay verified reachable. [${reachSw.elapsedMilliseconds} ms]',
      );
      break;
    } catch (e) {
      log('[isolate] Relay not reachable yet ($e), retrying in 2 s...');
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  log('[isolate] Waiting for relay connectivity...');
  final connSw = Stopwatch()..start();
  final socket = await WebSocket.connect(
    relayUrl,
  ).timeout(const Duration(seconds: 30));
  log('[isolate] Relay connected. [${connSw.elapsedMilliseconds} ms]');

  // ── Set up receive port for incoming requests ──
  final receivePort = ReceivePort();
  mainPort.send(BroadcastReady(receivePort.sendPort));

  int successCount = 0;
  int failureCount = 0;
  final pending = <Future<void>>[];

  // Semaphore for maxConcurrent
  int inFlight = 0;
  final slotAvailable = StreamController<void>.broadcast();
  final ackTracker = _RelayAckTracker(socket, log: log);

  Future<void> broadcastOne(int index, Map<String, dynamic> json) async {
    // Wait for a slot
    while (inFlight >= maxConcurrent) {
      await slotAvailable.stream.first;
    }
    inFlight++;

    try {
      String? lastMsg;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          if (attempt > 1) {
            log('[isolate] Retrying event index=$index attempt #$attempt');
          }

          final ack = await ackTracker.publish(json);
          if (ack.accepted) {
            successCount++;
            mainPort.send(BroadcastSuccess(index));
            return;
          }
          lastMsg = ack.message;
        } catch (e) {
          lastMsg = e.toString();
        }

        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }

      failureCount++;
      mainPort.send(
        BroadcastFailure(
          index,
          'Failed to broadcast event index=$index '
          '(kind=${json['kind']}): ${lastMsg ?? 'no response'}',
        ),
      );
    } finally {
      inFlight--;
      slotAvailable.add(null);
    }
  }

  await for (final message in receivePort) {
    if (message is _BroadcastRequest) {
      pending.add(broadcastOne(message.index, message.eventJson));
    } else if (message is _BroadcastDone) {
      break;
    }
  }

  // Wait for all pending broadcasts to finish.
  await Future.wait(pending);

  log('[isolate] Finished: $successCount succeeded, $failureCount failed.');
  mainPort.send(BroadcastFinished(successCount, failureCount));

  await ackTracker.close();
  receivePort.close();
  slotAvailable.close();
}

class _RelayAck {
  const _RelayAck({required this.accepted, this.message});

  final bool accepted;
  final String? message;
}

class _RelayAckTracker {
  _RelayAckTracker(this._socket, {required void Function(String) log})
    : _log = log {
    _subscription = _socket.listen(
      _handleMessage,
      onError: (Object error, StackTrace stackTrace) {
        _failAll('relay socket error: $error');
      },
      onDone: () {
        _failAll('relay socket closed');
      },
      cancelOnError: false,
    );
  }

  final WebSocket _socket;
  final void Function(String) _log;
  final Map<String, Completer<_RelayAck>> _pending = {};
  late final StreamSubscription<dynamic> _subscription;

  Future<_RelayAck> publish(Map<String, dynamic> eventJson) async {
    final id = eventJson['id'] as String;
    final completer = Completer<_RelayAck>();
    _pending[id] = completer;
    _socket.add(jsonEncode(['EVENT', eventJson]));

    try {
      return await completer.future.timeout(
        _ackTimeout,
        onTimeout: () {
          _pending.remove(id);
          return const _RelayAck(
            accepted: false,
            message: 'timed out waiting for relay OK',
          );
        },
      );
    } finally {
      _pending.remove(id);
    }
  }

  static const _ackTimeout = Duration(seconds: 60);

  void _handleMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! List || decoded.length < 3 || decoded.first != 'OK') {
        return;
      }

      final id = decoded[1] as String?;
      if (id == null) return;

      final completer = _pending.remove(id);
      if (completer == null) {
        _log('[isolate] Ignoring late relay OK for $id');
        return;
      }

      final accepted = decoded[2] == true;
      final message = decoded.length > 3 ? decoded[3]?.toString() : null;
      if (!completer.isCompleted) {
        completer.complete(_RelayAck(accepted: accepted, message: message));
      }
    } catch (error) {
      _log('[isolate] Ignoring malformed relay frame: $error');
    }
  }

  void _failAll(String message) {
    final pending = List<Completer<_RelayAck>>.from(_pending.values);
    _pending.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) {
        completer.complete(_RelayAck(accepted: false, message: message));
      }
    }
  }

  Future<void> close() async {
    _failAll('broadcast isolate closing');
    await _subscription.cancel();
    await _socket.close();
  }
}

// ── Self-signed cert support for the isolate ──
class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    return client;
  }
}
