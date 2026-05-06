import 'package:hostr_sdk/util/main.dart';
import 'package:test/test.dart';

void main() {
  group('TraceContext', () {
    test('propagates trace ids through zones and headers', () async {
      expect(TraceContext.currentTraceId, isNull);
      expect(TraceContext.headers(), isEmpty);

      await TraceContext.run('trace-test-123', () async {
        expect(TraceContext.currentTraceId, 'trace-test-123');
        expect(TraceContext.headers(), {'x-trace-id': 'trace-test-123'});

        await Future<void>.delayed(Duration.zero);
        expect(TraceContext.currentTraceId, 'trace-test-123');
      });

      expect(TraceContext.currentTraceId, isNull);
    });
  });
}
