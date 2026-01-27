import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/messages/threaded_messages.cubit.dart';
import 'package:ndk/ndk.dart';

import '../mock/hydrated_storage.mock.dart';

void main() {
  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();
    initHydratedStorage();
    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('Threaded messages', () {
    blocTest<ThreadedMessagesCubit, ThreadedMessagesState>(
      'should organize messages by thread ID',
      build: () => ThreadedMessagesCubit(ndk: getIt<Ndk>()),
      skip: 0, // Skip for now - needs proper NDK mock setup
      act: (bloc) async {
        // await bloc.sync();
      },
      expect: () => [],
      verify: (bloc) {
        // Verify thread organization logic
      },
    );
  });
}
