/// Runs NDK event broadcasting in a dedicated isolate so that heavy
/// EVM / anvil work on the main isolate cannot starve the WebSocket
/// event-loop and cause spurious 4 s timeouts.
library;

import 'dart:async';
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
    int maxConcurrent = 50,
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

  // ── Create a fresh NDK in this isolate ──
  final ndk = Ndk(
    NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relayUrl],
    ),
  );

  log('[isolate] Waiting for relay connectivity...');
  final connSw = Stopwatch()..start();
  await ndk.relays.seedRelaysConnected.timeout(const Duration(seconds: 30));
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

  Future<void> broadcastOne(int index, Map<String, dynamic> json) async {
    // Wait for a slot
    while (inFlight >= maxConcurrent) {
      await slotAvailable.stream.first;
    }
    inFlight++;

    try {
      final event = Nip01Event(
        id: json['id'] as String,
        pubKey: json['pubkey'] as String,
        createdAt: json['created_at'] as int,
        kind: json['kind'] as int,
        tags: (json['tags'] as List)
            .map((t) => (t as List).cast<String>().toList())
            .toList(),
        content: json['content'] as String,
        sig: json['sig'] as String? ?? '',
      );

      String? lastMsg;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          log('[isolate] Broadcasting event index=$index attempt #$attempt');
          final broadcastResult = await ndk.broadcast
              .broadcast(nostrEvent: event, specificRelays: [relayUrl])
              .broadcastDoneFuture;

          if (broadcastResult.isEmpty) {
            await ndk.relays.seedRelaysConnected.timeout(
              const Duration(seconds: 15),
              onTimeout: () async {},
            );
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }

          final successful = broadcastResult.any((r) => r.broadcastSuccessful);
          if (successful) {
            successCount++;
            mainPort.send(BroadcastSuccess(index));
            return;
          }

          lastMsg = broadcastResult.isNotEmpty
              ? broadcastResult.first.msg
              : null;
        } catch (e) {
          lastMsg = e.toString();
          await ndk.relays.seedRelaysConnected.timeout(
            const Duration(seconds: 15),
            onTimeout: () async {},
          );
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

  await ndk.destroy();
  receivePort.close();
  slotAvailable.close();
}

// ── Self-signed cert support for the isolate ──
class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}
