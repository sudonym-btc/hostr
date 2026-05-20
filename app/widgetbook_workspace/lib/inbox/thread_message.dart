import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/reservation_request/reservation_request.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

final _scenario = mockThreadScenarios.first;

TextMessage _buildTextMessage({required bool sentByHost}) {
  return TextMessage(
    pubKey: sentByHost ? MockKeys.hoster.publicKey : MockKeys.guest.publicKey,
    tags: MessageTags([
      ['p', sentByHost ? MockKeys.guest.publicKey : MockKeys.hoster.publicKey],
      [kConversationTag, _scenario.threadAnchor],
    ]),
    content: sentByHost
        ? 'Thanks for reaching out. Check-in details are in the app.'
        : 'Hi! Is early check-in possible?',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

@widgetbook.UseCase(name: 'Thread message - sent', type: ThreadMessageWidget)
Widget threadMessageSent(BuildContext context) {
  final message = _buildTextMessage(sentByHost: true);
  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadMessageWidget(item: message, isSentByMe: true),
  );
}

@widgetbook.UseCase(
  name: 'Thread message - received',
  type: ThreadMessageWidget,
)
Widget threadMessageReceived(BuildContext context) {
  final message = _buildTextMessage(sentByHost: false);
  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadMessageWidget(item: message, isSentByMe: false),
  );
}

@widgetbook.UseCase(
  name: 'Order request - sent',
  type: ThreadReservationRequestWidget,
)
Widget reservationRequestSent(BuildContext context) {
  final reservationMessage = _buildTextMessage(sentByHost: true);
  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadReservationRequestWidget(
      item: reservationMessage,
      isSentByMe: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Order request - received',
  type: ThreadReservationRequestWidget,
)
Widget reservationRequestReceived(BuildContext context) {
  final reservationMessage = _buildTextMessage(sentByHost: false);
  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadReservationRequestWidget(
      item: reservationMessage,
      isSentByMe: false,
    ),
  );
}
