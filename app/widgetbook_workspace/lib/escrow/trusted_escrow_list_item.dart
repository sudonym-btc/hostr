import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/escrow/trusted_escrow_list_item.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'With profile', type: TrustedEscrowListItemWidget)
Widget trustedEscrowWithProfile(BuildContext context) {
  return TrustedEscrowListItemWidget(
    profile: ProfileMetadata.fromNostrEvent(MOCK_PROFILES[2]),
  );
}

@widgetbook.UseCase(name: 'Missing profile', type: TrustedEscrowListItemWidget)
Widget trustedEscrowMissingProfile(BuildContext context) {
  return const TrustedEscrowListItemWidget(profile: null);
}
