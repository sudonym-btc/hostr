import 'package:hostr_sdk/util/stream_status.dart';
import 'package:test/test.dart';

void main() {
  test(
    'replayStream emits query items collected before listener attaches',
    () async {
      final source = StreamWithStatus<int>.query(
        query: () => Stream<int>.fromIterable([1]),
      );

      await source.status.firstWhere(
        (status) => status is StreamStatusQueryComplete,
      );

      await expectLater(source.replayStream.take(1), emits(1));
      await source.close();
    },
  );
}
