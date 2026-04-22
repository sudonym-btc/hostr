import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/component/widgets/amount/amount_input.dart';
import 'package:models/main.dart';

void main() {
  group('AmountInputWidget', () {
    testWidgets('accepts numpad digits while focused', (tester) async {
      final fieldKey = GlobalKey<FormFieldState<DenominatedAmount>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmountInputWidget(
              key: fieldKey,
              initialValue: DenominatedAmount.zero('BTC', 8),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad3);
      await tester.pump();

      expect(fieldKey.currentState?.value?.value, BigInt.from(123));
    });

    testWidgets('accepts top-row digits and backspace', (tester) async {
      final fieldKey = GlobalKey<FormFieldState<DenominatedAmount>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmountInputWidget(
              key: fieldKey,
              initialValue: DenominatedAmount.zero('BTC', 8),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(fieldKey.currentState?.value?.value, BigInt.from(4));
    });

    testWidgets('still accepts tap input', (tester) async {
      final fieldKey = GlobalKey<FormFieldState<DenominatedAmount>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmountInputWidget(
              key: fieldKey,
              initialValue: DenominatedAmount.zero('BTC', 8),
            ),
          ),
        ),
      );

      await tester.tap(find.text('7'));
      await tester.pump();

      expect(fieldKey.currentState?.value?.value, BigInt.from(7));
    });
  });

  group('AmountEditorBottomSheet', () {
    testWidgets('saves and closes when numpad enter is pressed', (
      tester,
    ) async {
      DenominatedAmount? result;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await AmountEditorBottomSheet.show(
                      context,
                      initialAmount: DenominatedAmount.zero('BTC', 8),
                    );
                  },
                  child: const Text('Open amount'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open amount'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.numpad8);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pumpAndSettle();

      expect(result?.value, BigInt.from(8));
      expect(find.byType(AmountEditorBottomSheet), findsNothing);
    });
  });
}
