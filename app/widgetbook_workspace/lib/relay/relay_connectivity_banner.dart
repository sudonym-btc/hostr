import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/relay/relay_connectivity_banner.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Majority disconnected (1/4)',
  type: RelayConnectivityBannerView,
)
Widget majorityDisconnected(BuildContext context) {
  return const Align(
    alignment: Alignment.bottomCenter,
    child: RelayConnectivityBannerView(
      connectedRelays: 1,
      totalRelays: 4,
    ),
  );
}

@widgetbook.UseCase(
  name: 'All disconnected (0/3)',
  type: RelayConnectivityBannerView,
)
Widget allDisconnected(BuildContext context) {
  return const Align(
    alignment: Alignment.bottomCenter,
    child: RelayConnectivityBannerView(
      connectedRelays: 0,
      totalRelays: 3,
    ),
  );
}

@widgetbook.UseCase(
  name: 'One remaining (1/5)',
  type: RelayConnectivityBannerView,
)
Widget oneRemaining(BuildContext context) {
  return const Align(
    alignment: Alignment.bottomCenter,
    child: RelayConnectivityBannerView(
      connectedRelays: 1,
      totalRelays: 5,
    ),
  );
}
