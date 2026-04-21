import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';

void main() {
  group('ThreadReplyView', () {
    testWidgets('sends when enter is pressed', (tester) async {
      var sendCount = 0;
      final controller = TextEditingController(text: 'Hello');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThreadReplyView(
              controller: controller,
              isLoading: false,
              errorText: null,
              label: null,
              hintText: 'Type a message',
              onChanged: (_) {},
              onSend: () => sendCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(sendCount, 1);
    });

    testWidgets('does not send when shift-enter is pressed', (tester) async {
      var sendCount = 0;
      final controller = TextEditingController(text: 'Hello');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThreadReplyView(
              controller: controller,
              isLoading: false,
              errorText: null,
              label: null,
              hintText: 'Type a message',
              onChanged: (_) {},
              onSend: () => sendCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(sendCount, 0);
    });
  });
}
