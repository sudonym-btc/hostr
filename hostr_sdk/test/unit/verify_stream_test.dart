import 'dart:async';

import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';

Reservation _reservation({
  required String id,
  required String pubkey,
  required String commitmentHash,
}) {
  return Reservation(
    id: id,
    pubKey: pubkey,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      [kListingRefTag, '32121:host:listing-1'],
      [kCommitmentHashTag, commitmentHash],
    ]),
    content: ReservationContent(
      start: DateTime.utc(2026, 1, 1),
      end: DateTime.utc(2026, 1, 3),
    ),
  );
}

/// Trivial "deps" for testing — just mirrors the commitment hash.
class _TestDeps {
  final String commitmentHash;
  const _TestDeps(this.commitmentHash);
}

void main() {
  group('verifyStream', () {
    test('verifies items as they arrive via per-item resolve+verify', () async {
      final source = StreamWithStatus<Reservation>();

      final verified = verifyStream<Reservation, _TestDeps>(
        source: source,
        debounce: Duration.zero,
        resolve: (item) async {
          return _TestDeps(item.parsedTags.commitmentHash);
        },
        verify: (item, deps) {
          return deps.commitmentHash == 'good'
              ? Valid(item)
              : Invalid(item, 'bad commitment');
        },
      );

      source.addStatus(StreamStatusLive());
      source.add(
        _reservation(id: 'r1', pubkey: 'guest', commitmentHash: 'good'),
      );
      source.add(
        _reservation(id: 'r2', pubkey: 'guest', commitmentHash: 'bad'),
      );

      // Wait for resolve futures to complete.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final snapshot = verified.list.value;
      expect(snapshot, hasLength(2));

      final valid = snapshot.whereType<Valid<Reservation>>().toList();
      final invalid = snapshot.whereType<Invalid<Reservation>>().toList();
      expect(valid, hasLength(1));
      expect(valid.first.event.id, 'r1');
      expect(invalid, hasLength(1));
      expect(invalid.first.event.id, 'r2');
      expect(invalid.first.reason, 'bad commitment');

      await verified.close();
      await source.close();
    });

    test('defers Live status until all pending verifications drain', () async {
      final source = StreamWithStatus<Reservation>();

      final resolveCompleter = Completer<void>();

      final verified = verifyStream<Reservation, _TestDeps>(
        source: source,
        debounce: Duration.zero,
        resolve: (item) async {
          // Block until we manually release.
          await resolveCompleter.future;
          return _TestDeps(item.parsedTags.commitmentHash);
        },
        verify: (item, deps) => Valid(item),
      );

      final statuses = <StreamStatus>[];
      final statusSub = verified.status.listen(statuses.add);

      source.addStatus(StreamStatusQuerying());
      source.add(_reservation(id: 'r1', pubkey: 'guest', commitmentHash: 'c1'));
      source.addStatus(StreamStatusLive());

      // Give the debounce + resolve kickoff time to start.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Live should be deferred because resolve hasn't completed.
      expect(statuses.any((s) => s is StreamStatusLive), isFalse);
      expect(statuses.any((s) => s is StreamStatusQuerying), isTrue);

      // Release the resolve.
      resolveCompleter.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Now Live should have been forwarded.
      expect(statuses.any((s) => s is StreamStatusLive), isTrue);
      expect(verified.list.value, hasLength(1));

      await statusSub.cancel();
      await verified.close();
      await source.close();
    });

    test('resolve errors result in Invalid, not a crash', () async {
      final source = StreamWithStatus<Reservation>();

      final verified = verifyStream<Reservation, _TestDeps>(
        source: source,
        debounce: Duration.zero,
        resolve: (item) async {
          throw StateError('network failure');
        },
        verify: (item, deps) => Valid(item),
      );

      source.addStatus(StreamStatusLive());
      source.add(_reservation(id: 'r1', pubkey: 'guest', commitmentHash: 'c1'));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final snapshot = verified.list.value;
      expect(snapshot, hasLength(1));
      expect(snapshot.first, isA<Invalid<Reservation>>());
      expect(
        (snapshot.first as Invalid<Reservation>).reason,
        contains('network failure'),
      );

      await verified.close();
      await source.close();
    });

    test('only processes new items on subsequent snapshot emissions', () async {
      final source = StreamWithStatus<Reservation>();
      var resolveCount = 0;

      final verified = verifyStream<Reservation, _TestDeps>(
        source: source,
        debounce: Duration.zero,
        resolve: (item) async {
          resolveCount++;
          return _TestDeps(item.parsedTags.commitmentHash);
        },
        verify: (item, deps) => Valid(item),
      );

      source.addStatus(StreamStatusLive());
      source.add(_reservation(id: 'r1', pubkey: 'guest', commitmentHash: 'c1'));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(resolveCount, 1);
      expect(verified.list.value, hasLength(1));

      // Add a second item — r1 should not be re-resolved.
      source.add(_reservation(id: 'r2', pubkey: 'guest', commitmentHash: 'c2'));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(resolveCount, 2); // Only r2 was resolved.
      expect(verified.list.value, hasLength(2));

      await verified.close();
      await source.close();
    });

    test('propagates source errors', () async {
      final source = StreamWithStatus<Reservation>();

      final verified = verifyStream<Reservation, _TestDeps>(
        source: source,
        debounce: Duration.zero,
        resolve: (item) async => _TestDeps('x'),
        verify: (item, deps) => Valid(item),
      );

      final errorCompleter = Completer<StreamStatusError>();
      final statusSub = verified.status.listen((status) {
        if (status is StreamStatusError && !errorCompleter.isCompleted) {
          errorCompleter.complete(status);
        }
      });

      source.addStatus(
        StreamStatusError(StateError('relay died'), StackTrace.current),
      );

      final error = await errorCompleter.future.timeout(
        const Duration(milliseconds: 200),
      );
      expect(error.error.toString(), contains('relay died'));

      await statusSub.cancel();
      await verified.close();
      await source.close();
    });

    test('closes source when closeSourceOnClose is true', () async {
      final source = StreamWithStatus<Reservation>();
      var sourceClosed = false;
      source.onClose = () async {
        sourceClosed = true;
      };

      final verified = verifyStream<Reservation, _TestDeps>(
        source: source,
        debounce: Duration.zero,
        closeSourceOnClose: true,
        resolve: (item) async => _TestDeps('x'),
        verify: (item, deps) => Valid(item),
      );

      await verified.close();
      expect(sourceClosed, isTrue);
    });
  });
}
