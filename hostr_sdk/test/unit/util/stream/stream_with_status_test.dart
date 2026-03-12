@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/util/stream_status.dart';
import 'package:test/test.dart';

void main() {
  group('StreamWithStatus', () {
    test('starts idle, accumulates items via add, and tracks status', () async {
      final stream = StreamWithStatus<int>();
      expect(stream.status.value, isA<StreamStatusIdle>());
      expect(stream.items, isEmpty);

      stream.addStatus(StreamStatusQuerying());
      stream.add(1);
      stream.add(2);
      stream.addStatus(StreamStatusLive());
      stream.add(3);

      expect(stream.items, [1, 2, 3]);
      expect(stream.status.value, isA<StreamStatusLive>());

      await stream.close();
    });

    test('itemsStream replays latest on subscribe and emits changes', () async {
      final stream = StreamWithStatus<int>();
      stream.add(7);
      stream.add(8);

      final snapshots = <List<int>>[];
      final sub = stream.itemsStream.listen(snapshots.add);

      // BehaviorSubject replays the latest immediately
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last, [7, 8]);

      stream.add(9);
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last, [7, 8, 9]);

      await sub.cancel();
      await stream.close();
    });

    test('replayStream re-emits historical items then continues', () async {
      final stream = StreamWithStatus<int>();
      stream.add(7);
      stream.add(8);

      final replayed = <int>[];
      final sub = stream.replayStream.listen(replayed.add);

      // Wait for historical items to arrive
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should have historical items
      expect(replayed, contains(7));
      expect(replayed, contains(8));

      // New items should also arrive
      stream.add(9);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(replayed, contains(9));

      await sub.cancel();
      await stream.close();
    });

    test('propagates errors through status as StreamStatusError', () async {
      final stream = StreamWithStatus<int>();
      final completer = Completer<StreamStatusError>();

      final dataSub = stream.stream.listen((_) {}, onError: (_, stackTrace) {});

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

    test('replaceAll wholesale-replaces items', () async {
      final stream = StreamWithStatus<int>();
      stream.add(1);
      stream.add(2);
      expect(stream.items, [1, 2]);

      stream.replaceAll([10, 20, 30]);
      expect(stream.items, [10, 20, 30]);

      await stream.close();
    });

    test('reset clears items and sets idle', () async {
      final stream = StreamWithStatus<int>();
      stream.addStatus(StreamStatusLive());
      stream.add(1);

      expect(stream.items, [1]);
      expect(stream.status.value, isA<StreamStatusLive>());

      await stream.reset();

      expect(stream.items, isEmpty);
      expect(stream.status.value, isA<StreamStatusIdle>());

      await stream.close();
    });

    test('where() filters items and per-item events', () async {
      final source = StreamWithStatus<int>();
      final even = source.where((i) => i.isEven);

      source.addStatus(StreamStatusLive());
      source.add(1);
      source.add(2);
      source.add(3);
      source.add(4);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(even.items, [2, 4]);
      expect(even.status.value, isA<StreamStatusLive>());

      await even.close();
      await source.close();
    });

    test('map() transforms items', () async {
      final source = StreamWithStatus<int>();
      final doubled = source.map<int>((i) => i * 2);

      source.add(1);
      source.add(2);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(doubled.items, [2, 4]);

      await doubled.close();
      await source.close();
    });
  });

  group('StreamWithStatus.combine', () {
    test('combines items from multiple children', () async {
      final a = StreamWithStatus<String>();
      final b = StreamWithStatus<String>();

      a.addStatus(StreamStatusLive());
      a.add('a1');
      b.addStatus(StreamStatusLive());
      b.add('b1');

      final combined = StreamWithStatus.combineAll([a, b]);

      a.add('a2');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(combined.items, containsAll(['a1', 'b1', 'a2']));
      expect(combined.status.value, isA<StreamStatusLive>());

      await combined.close();
    });

    test('starts live when no sources', () async {
      final combined = StreamWithStatus.combineAll<int>([]);

      expect(combined.status.value, isA<StreamStatusLive>());

      await combined.close();
    });

    test('combine removes closed sources from status calculation', () async {
      final combined = StreamWithStatus<String>();
      final querying = StreamWithStatus<String>();
      final live = StreamWithStatus<String>();

      querying.addStatus(StreamStatusQuerying());
      live.addStatus(StreamStatusLive());

      combined.combine(querying);
      combined.combine(live);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(combined.status.value, isA<StreamStatusQuerying>());

      await querying.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(combined.status.value, isA<StreamStatusLive>());

      await live.close();
      await combined.close();
    });

    test('combineAll also detaches closed sources', () async {
      final querying = StreamWithStatus<String>();
      final live = StreamWithStatus<String>();

      querying.addStatus(StreamStatusQuerying());
      live.addStatus(StreamStatusLive());

      final combined = StreamWithStatus.combineAll([querying, live]);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(combined.status.value, isA<StreamStatusQuerying>());

      await querying.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(combined.status.value, isA<StreamStatusLive>());

      await live.close();
      await combined.close();
    });
  });

  group('StreamWithStatus<List<T>> helpers', () {
    test('latestItemsStream emits the latest snapshot contents', () async {
      final source = StreamWithStatus<List<int>>();
      final seen = <List<int>>[];

      final sub = source.latestItemsStream.listen(seen.add);

      source.add([1, 2]);
      source.add([1, 2, 3]);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(seen, isNotEmpty);
      expect(seen.last, [1, 2, 3]);

      await sub.cancel();
      await source.close();
    });

    test('currentItems exposes the latest snapshot as current items', () async {
      final source = StreamWithStatus<List<int>>();
      final current = source.currentItems();

      source.add([1, 2]);
      source.add([2, 4]);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(current.items, [2, 4]);

      await current.close();
      await source.close();
    });

    test('whereItems filters within the latest snapshot', () async {
      final source = StreamWithStatus<List<int>>();
      final even = source.whereItems((i) => i.isEven);

      source.add([1, 2, 3]);
      source.add([2, 4, 5]);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(even.items, [2, 4]);

      await even.close();
      await source.close();
    });
  });
}
