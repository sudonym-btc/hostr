import 'package:hostr_sdk/util/main.dart';
import 'package:logger/logger.dart';
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

    test(
      'CustomLogger includes the active trace id in emitted lines',
      () async {
        final output = _CapturingLogOutput();
        CustomLogger.configure(output: output, level: Level.info);

        await TraceContext.run('trace-log-123', () async {
          CustomLogger(tag: 'trace-test').i('hello from logger');
        });

        expect(
          output.lines.join('\n'),
          contains('[traceId=trace-log-123] hello from logger'),
        );
      },
    );
  });
}

class _CapturingLogOutput extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) {
    lines.addAll(event.lines);
  }
}
