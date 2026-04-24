import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/inbox/inbox_item.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

final ProfileMetadata _hostProfile = ProfileMetadata.fromNostrEvent(
  mockProfiles.first,
);
final ProfileMetadata _guestProfile = ProfileMetadata.fromNostrEvent(
  mockProfiles[1],
);

@widgetbook.UseCase(name: 'Sent - normal message', type: InboxItemView)
Widget inboxItemSentNormal(BuildContext context) {
  return InboxItemView(
    counterparties: [_guestProfile.pubKey],
    subtitle: 'You: See you at check-in',
    lastDateTime: DateTime.now().subtract(const Duration(minutes: 3)),
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Received - normal message', type: InboxItemView)
Widget inboxItemReceivedNormal(BuildContext context) {
  return InboxItemView(
    counterparties: [_guestProfile.pubKey],
    subtitle: 'Thanks! That works for me.',
    lastDateTime: DateTime.now().subtract(const Duration(hours: 1)),
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Sent - reservation request', type: InboxItemView)
Widget inboxItemSentReservationRequest(BuildContext context) {
  return InboxItemView(
    counterparties: [_hostProfile.pubKey],
    subtitle: 'You: Reservation Request',
    lastDateTime: DateTime.now().subtract(const Duration(days: 1)),
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Received - reservation request', type: InboxItemView)
Widget inboxItemReceivedReservationRequest(BuildContext context) {
  return InboxItemView(
    counterparties: [_guestProfile.pubKey],
    subtitle: 'Reservation Request',
    lastDateTime: DateTime.now().subtract(const Duration(minutes: 45)),
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Missing counterparty profile', type: InboxItemView)
Widget inboxItemMissingCounterparty(BuildContext context) {
  return InboxItemView(
    counterparties: const [],
    subtitle: 'Reservation Request',
    lastDateTime: DateTime.now().subtract(const Duration(days: 2)),
    onTap: () {},
  );
}
