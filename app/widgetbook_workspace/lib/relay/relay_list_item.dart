import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/relay/relay_list_item.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Connected', type: RelayListItemView)
Widget relayConnected(BuildContext context) {
  return const RelayListItemView(
    title: 'Hostr Relay',
    subtitle: 'Connected',
    iconUrl: null,
    isConnected: true,
    canRemove: true,
  );
}

@widgetbook.UseCase(name: 'Disconnected', type: RelayListItemView)
Widget relayDisconnected(BuildContext context) {
  return const RelayListItemView(
    title: 'relay.example.com',
    subtitle: 'Disconnected',
    iconUrl: null,
    isConnected: false,
    canRemove: true,
  );
}

@widgetbook.UseCase(name: 'Bootstrap (not removable)', type: RelayListItemView)
Widget relayBootstrap(BuildContext context) {
  return const RelayListItemView(
    title: 'relay.hostr.development',
    subtitle: 'Connected',
    iconUrl: null,
    isConnected: true,
    canRemove: false,
  );
}
