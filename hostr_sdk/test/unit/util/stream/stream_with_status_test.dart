@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/util/stream_status.dart';
import 'package:test/test.dart';

void main() {
  group('StreamWithStatus', () {
    test('emits query -> queryComplete -> live and accumulates list', () async {
      final stream = StreamWithStatus<int>(
        queryFn: () => Stream<int>.fromIterable([1, 2]),
        liveFn: () => Stream<int>.fromIterable([3]),
      );

      final statuses = <StreamStatus>[];
      final statusSub = stream.status.listen(statuses.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(stream.list.value, [1, 2, 3]);
      expect(statuses.any((s) => s is StreamStatusQuerying), isTrue);
      expect(statuses.any((s) => s is StreamStatusQueryComplete), isTrue);
      expect(statuses.any((s) => s is StreamStatusLive), isTrue);

      await statusSub.cancel();
      await stream.close();
    });

    test('replay re-emits historical items to late subscribers', () async {
      final stream = StreamWithStatus<int>();
      stream.add(7);
      stream.add(8);

      final replayed = await stream.replay.take(2).toList();
      expect(replayed, [7, 8]);

      await stream.close();
    });

    test('propagates errors through status as StreamStatusError', () async {
      final stream = StreamWithStatus<int>();
      final completer = Completer<StreamStatusError>();

      final dataSub = stream.stream.listen((_) {}, onError: (_, __) {});

      final sub = stream.status.listen((status) {
        if (status is StreamStatusError && !completer.isCompleted) {
          completer.complete(status);
        }
      });

      stream.addError(Exception('boom'), StackTrace.current);
      final statusError = await completer.future.timeout(
        const Duration(milliseconds: 200),
      );

      expect(statusError.error.toString(), contains('boom'));

      await sub.cancel();
      await dataSub.cancel();
      await stream.close();
    });
  });
}
