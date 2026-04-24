import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_view.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

@widgetbook.UseCase(name: 'Scenario', type: ThreadView)
Widget threadViewScenario(BuildContext context) {
  final scenarioId = context.knobs.object.dropdown<String>(
    label: 'Scenario',
    options: mockThreadScenarios.map((s) => s.id).toList(),
  );
  final scenario = mockThreadScenarios.firstWhere((s) => s.id == scenarioId);

  final thread = Thread(
    scenario.threadAnchor,
    messaging: getIt<Hostr>().messaging,
    logger: CustomLogger(),
    auth: getIt<Hostr>().auth,
    userSubscriptions: getIt<Hostr>().userSubscriptions,
  );
  thread.process(scenario.requestMessage);

  return const ThreadView();
}
