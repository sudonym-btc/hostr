import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/workflows/event_publishing_workflow.dart';
import 'package:hostr/main.dart';
import 'package:hostr/setup.dart';
import 'package:models/main.dart';

import '../mock/hydrated_storage.mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset the GetIt instance to its initial state before each test
    await GetIt.I.reset(dispose: true);
    getIt.allowReassignment = true;

    initHydratedStorage();
    configureInjection(Env.test);

    await setupMockRelay();

    await getIt<AuthService>().signup();
  });

  group('reservation', () {
    blocTest<ReservationCubit, ReservationState>(
      'emits loading then success',
      build: () {
        EventPublisherCubit ep = EventPublisherCubit(
          nostrService: getIt(),
          workflow: EventPublishingWorkflow(),
        );
        return ReservationCubit(publisher: ep, ndk: getIt());
      },
      act: (cubit) => cubit.createReservation(
        listing: MOCK_LISTINGS[0],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 1)),
        onSuccess: (String id) {},
      ),
      expect: () => [
        isA<ReservationState>().having(
          (s) => s.status,
          'status',
          ReservationStatus.loading,
        ),
        isA<ReservationState>().having(
          (s) => s.status,
          'status',
          ReservationStatus.success,
        ),
      ],
    );
  });
}
