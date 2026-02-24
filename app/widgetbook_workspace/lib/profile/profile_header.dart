import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Default', type: ProfileHeaderWidget)
Widget profileHeaderDefault(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ProfileHeaderWidget(
          profile: ProfileMetadata.fromNostrEvent(MOCK_PROFILES.first),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Missing image', type: ProfileHeaderWidget)
Widget profileHeaderMissingImage(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: const ProfileHeaderWidget(profile: null),
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Loading', type: ProfileHeaderWidget)
Widget profileHeaderLoading(BuildContext context) {
  return const Scaffold(
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ProfileHeaderWidget(profile: null, isLoading: true),
      ),
    ),
  );
}
