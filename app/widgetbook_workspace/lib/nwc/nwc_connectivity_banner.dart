import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/nostr_wallet_connect/nwc_connectivity_banner.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'All wallets failed (0/1)',
  type: NwcConnectivityBannerView,
)
Widget allFailed(BuildContext context) {
  return const Align(
    alignment: Alignment.bottomCenter,
    child: NwcConnectivityBannerView(
      connectedCount: 0,
      totalConnections: 1,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Multiple wallets failed (0/3)',
  type: NwcConnectivityBannerView,
)
Widget multipleFailed(BuildContext context) {
  return const Align(
    alignment: Alignment.bottomCenter,
    child: NwcConnectivityBannerView(
      connectedCount: 0,
      totalConnections: 3,
    ),
  );
}
