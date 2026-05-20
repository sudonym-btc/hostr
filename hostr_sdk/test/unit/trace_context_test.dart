import 'package:hostr_sdk/util/main.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  group('TraceContext', () {
    tearDown(CustomLogger.clearAccountContext);

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

    test('CustomLogger includes account context in emitted lines', () {
      final output = _CapturingLogOutput();
      CustomLogger.configure(output: output, level: Level.info);
      CustomLogger.setAccountContext(
        pubkey:
            '01b74905ebe5c42f557e75c3dfa2f23984ffa822feae75e8eccedd346553929a',
        npub: 'npub1qxm5jp0tuhzz74t7whpalghj8xz0l2pzl6h8t68vemwnge2nj2dqse0znr',
      );

      CustomLogger(tag: 'trace-test').i('hello from account logger');

      final lines = output.lines.join('\n');
      expect(
        lines,
        contains(
          'hostr.user.pubkey=01b74905ebe5c42f557e75c3dfa2f23984ffa822feae75e8eccedd346553929a',
        ),
      );
      expect(
        lines,
        contains(
          'hostr.user.npub=npub1qxm5jp0tuhzz74t7whpalghj8xz0l2pzl6h8t68vemwnge2nj2dqse0znr',
        ),
      );
      expect(lines, contains('hello from account logger'));
    });

    test('CustomLogger includes account context in span log lines', () {
      final output = _CapturingLogOutput();
      CustomLogger.configure(output: output, level: Level.trace);
      CustomLogger.setAccountContext(
        pubkey:
            '01b74905ebe5c42f557e75c3dfa2f23984ffa822feae75e8eccedd346553929a',
        npub: 'npub1qxm5jp0tuhzz74t7whpalghj8xz0l2pzl6h8t68vemwnge2nj2dqse0znr',
      );

      CustomLogger(tag: 'trace-test').spanSync('accounted', () {});

      final lines = output.lines.join('\n');
      expect(
        lines,
        contains(
          'hostr.user.pubkey=01b74905ebe5c42f557e75c3dfa2f23984ffa822feae75e8eccedd346553929a',
        ),
      );
      expect(
        lines,
        contains(
          'hostr.user.npub=npub1qxm5jp0tuhzz74t7whpalghj8xz0l2pzl6h8t68vemwnge2nj2dqse0znr',
        ),
      );
      expect(lines, contains('span start: trace-test.accounted'));
      expect(lines, isNot(contains('attrs={hostr.user.pubkey:')));
    });
  });
}

class _CapturingLogOutput extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) {
    lines.addAll(event.lines);
  }
}
