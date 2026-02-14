import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/entity/entity.cubit.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_view.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Scenario', type: ThreadView)
Widget threadViewScenario(BuildContext context) {
  final scenarioId = context.knobs.list(
    label: 'Scenario',
    options: MOCK_THREAD_SCENARIOS.map((s) => s.id).toList(),
  );
  final scenario = MOCK_THREAD_SCENARIOS.firstWhere((s) => s.id == scenarioId);

  final thread = Thread(
    scenario.threadAnchor,
    messaging: getIt<Hostr>().messaging,
    logger: CustomLogger(),
    auth: getIt<Hostr>().auth,
  );
  thread.messages.add(scenario.requestMessage);

  final reservationsStream = StreamWithStatus<Reservation>();
  for (final reservation in scenario.reservations) {
    reservationsStream.add(reservation);
  }
  reservationsStream.addStatus(StreamStatusLive());

  final listingCubit = EntityCubit<Listing>(
    filter: null,
    crud: getIt<Hostr>().listings,
  )..emit(EntityCubitState(data: scenario.listing, active: false));

  final counterpartyMetadata = ProfileMetadata.fromNostrEvent(
    scenario.reservationRequest.pubKey == MockKeys.guest.publicKey
        ? MOCK_PROFILES.first
        : MOCK_PROFILES[1],
  );
  final profileCubit = ProfileCubit(metadataUseCase: getIt<Hostr>().metadata)
    ..emit(
      EntityCubitState<ProfileMetadata>(
        data: counterpartyMetadata,
        active: false,
      ),
    );

  return BlocProvider<ThreadCubit>(
    create: (_) => ThreadCubit(thread: thread),
    child: const ThreadView(),
  );
}
