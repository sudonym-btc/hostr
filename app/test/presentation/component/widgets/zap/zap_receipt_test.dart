import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_receipt.dart';
import 'package:ndk/ndk.dart';

void main() {
  group('ZapReceiptWidget', () {
    testWidgets('renders anonymous zap amount and comment in a surface', (
      tester,
    ) async {
      final zap = ZapReceipt.fromEvent(
        _zapReceiptEvent(amountMillisats: 12345000, comment: 'Great project'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZapReceiptWidget(zap: zap)),
        ),
      );

      expect(find.text('Anonymous'), findsOneWidget);
      expect(find.textContaining('₿'), findsOneWidget);
      expect(find.text('Great project'), findsOneWidget);
      expect(find.byType(MessageContainer), findsOneWidget);
    });

    testWidgets('renders a fallback when amount is missing', (tester) async {
      final zap = ZapReceipt.fromEvent(_zapReceiptEvent(comment: ''));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZapReceiptWidget(zap: zap)),
        ),
      );

      expect(find.text('Anonymous'), findsOneWidget);
      expect(find.text('Zap'), findsOneWidget);
      expect(find.byType(MessageContainer), findsOneWidget);
    });
  });
}

Nip01EventModel _zapReceiptEvent({
  int? amountMillisats,
  required String comment,
}) {
  final zapRequest = {
    'id': 'zap-request',
    'pubkey': '',
    'created_at': 1,
    'kind': 9734,
    'tags': [
      if (amountMillisats != null) ['amount', '$amountMillisats'],
    ],
    'content': comment,
    'sig': '',
  };

  return Nip01EventModel(
    id: 'zap-receipt',
    pubKey: 'lnurl-provider',
    createdAt: 2,
    kind: ZapReceipt.kKind,
    tags: [
      ['description', jsonEncode(zapRequest)],
      ['p', 'recipient'],
    ],
    content: '',
    sig: '',
  );
}
