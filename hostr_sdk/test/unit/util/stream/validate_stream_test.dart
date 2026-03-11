@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';

Reservation _reservation({
  required String id,
  required String pubkey,
  required String tradeId,
}) {
  return Reservation.create(
    id: id,
    pubKey: pubkey,
    dTag: tradeId,
    listingAnchor: '32121:host:listing-1',
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2026, 1, 3),
  );
}

void main() {
  group('validateStream utility', () {
    test('defers Live until in-flight validation completes', () async {
      final source = StreamWithStatus<Reservation>();

      final validated = validateStream(
        source: source,
        validator: (item) async {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          return Valid<Reservation>(item);
        },
      );

      final statuses = <StreamStatus>[];
      final statusSub = validated.status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(statuses.add);

      // Item arrives first (triggering pending++), then Live arrives while
      // the async validator is still running — asyncMap defers it.
      source.add(
        _reservation(id: 'r1', pubkey: 'guest-1', tradeId: 'commit-1'),
      );
      source.addStatus(StreamStatusLive());

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(statuses.any((s) => s is StreamStatusLive), isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(statuses.any((s) => s is StreamStatusLive), isTrue);
      expect(validated.items.length, 1);
      expect(validated.items.first, isA<Valid<Reservation>>());

      await statusSub.cancel();
      await validated.close();
      await source.close();
    });

    test(
      'emits Invalid results from validator (mock RPC invalid tx details)',
      () async {
        final source = StreamWithStatus<Reservation>();

        final validated = validateStream(
          source: source,
          validator: (item) async {
            return Invalid<Reservation>(
              item,
              'invalid transaction details: recipient mismatch',
            );
          },
        );

        source.add(
          _reservation(id: 'r2', pubkey: 'guest-2', tradeId: 'commit-2'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(validated.items.length, 1);
        final item = validated.items.single;
        expect(item, isA<Invalid<Reservation>>());
        expect(
          (item as Invalid<Reservation>).reason,
          contains('recipient mismatch'),
        );

        await validated.close();
        await source.close();
      },
    );

    test('propagates validator exceptions as StreamStatusError', () async {
      final source = StreamWithStatus<Reservation>();

      final validated = validateStream(
        source: source,
        validator: (_) async => throw StateError('validator failed'),
      );

      final errorCompleter = Completer<StreamStatusError>();
      final statusSub = validated.status.listen((status) {
        if (status is StreamStatusError && !errorCompleter.isCompleted) {
          errorCompleter.complete(status);
        }
      });

      source.add(
        _reservation(id: 'r3', pubkey: 'guest-3', tradeId: 'commit-3'),
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
