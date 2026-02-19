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
      [kListingRefTag, '30023:host:listing-1'],
      [kCommitmentHashTag, commitmentHash],
    ]),
    content: ReservationContent(
      start: DateTime.utc(2026, 1, 1),
      end: DateTime.utc(2026, 1, 3),
    ),
  );
}

void main() {
  group('validateStream utility', () {
    test('does not emit Live before first validation snapshot completes', () async {
      final source = StreamWithStatus<Reservation>();

      final validated = validateStream(
        source: source,
        debounce: Duration.zero,
        validator: (snapshot) async {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          return snapshot.map((e) => Valid<Reservation>(e)).toList();
        },
      );

      final statuses = <StreamStatus>[];
      final statusSub = validated.status.listen(statuses.add);

      source.addStatus(StreamStatusLive());
      source.add(
        _reservation(id: 'r1', pubkey: 'guest-1', commitmentHash: 'commit-1'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(statuses.any((s) => s is StreamStatusLive), isFalse);
      expect(statuses.any((s) => s is StreamStatusQuerying), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(statuses.any((s) => s is StreamStatusLive), isTrue);
      expect(validated.list.value.length, 1);
      expect(validated.list.value.first, isA<Valid<Reservation>>());

      await statusSub.cancel();
      await validated.close();
      await source.close();
    });

    test('emits Invalid results from validator (mock RPC invalid tx details)', () async {
      final source = StreamWithStatus<Reservation>();

      final validated = validateStream(
        source: source,
        debounce: Duration.zero,
        validator: (snapshot) async {
          return snapshot
              .map(
                (e) => Invalid<Reservation>(
                  e,
                  'invalid transaction details: recipient mismatch',
                ),
              )
              .toList();
        },
      );

      source.add(
        _reservation(id: 'r2', pubkey: 'guest-2', commitmentHash: 'commit-2'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(validated.list.value.length, 1);
      final item = validated.list.value.single;
      expect(item, isA<Invalid<Reservation>>());
      expect((item as Invalid<Reservation>).reason, contains('recipient mismatch'));

      await validated.close();
      await source.close();
    });

    test('propagates validator exceptions as StreamStatusError', () async {
      final source = StreamWithStatus<Reservation>();

      final validated = validateStream(
        source: source,
        debounce: Duration.zero,
        validator: (_) async => throw StateError('validator failed'),
      );

      final errorCompleter = Completer<StreamStatusError>();
      final statusSub = validated.status.listen((status) {
        if (status is StreamStatusError && !errorCompleter.isCompleted) {
          errorCompleter.complete(status);
        }
      });

      source.add(
        _reservation(id: 'r3', pubkey: 'guest-3', commitmentHash: 'commit-3'),
      );

      final errorStatus = await errorCompleter.future.timeout(
        const Duration(milliseconds: 300),
      );
      expect(errorStatus.error.toString(), contains('validator failed'));

      await statusSub.cancel();
      await validated.close();
      await source.close();
    });
  });
}
