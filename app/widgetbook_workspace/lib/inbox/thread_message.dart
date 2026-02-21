import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/reservation_request/reservation_request.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

final _hostProfile = ProfileMetadata.fromNostrEvent(MOCK_PROFILES.first);
final _guestProfile = ProfileMetadata.fromNostrEvent(MOCK_PROFILES[1]);
final _scenario = MOCK_THREAD_SCENARIOS.first;

Message _buildTextMessage({required bool sentByHost}) {
  return Message(
    pubKey: sentByHost ? MockKeys.hoster.publicKey : MockKeys.guest.publicKey,
    tags: MessageTags([
      ['p', sentByHost ? MockKeys.guest.publicKey : MockKeys.hoster.publicKey],
      [kThreadRefTag, _scenario.threadAnchor],
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
    child: ThreadMessageWidget(
      sender: _hostProfile,
      item: message,
      isSentByMe: true,
    ),
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
    child: ThreadMessageWidget(
      sender: _guestProfile,
      item: message,
      isSentByMe: false,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Reservation request - sent',
  type: ThreadReservationRequestWidget,
)
Widget reservationRequestSent(BuildContext context) {
  final reservationMessage = _scenario.requestMessage;
  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadReservationRequestWidget(
      sender: _guestProfile,
      item: reservationMessage,
      isSentByMe: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Reservation request - received',
  type: ThreadReservationRequestWidget,
)
Widget reservationRequestReceived(BuildContext context) {
  final reservationMessage = _scenario.requestMessage;
  return Padding(
    padding: const EdgeInsets.all(16),
    child: ThreadReservationRequestWidget(
      sender: _guestProfile,
      item: reservationMessage,
      isSentByMe: false,
    ),
  );
}
