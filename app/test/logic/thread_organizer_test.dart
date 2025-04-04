import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/messages/thread_organizer.cubit.dart';

void main() {
  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();

    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('new message new group', () {
    blocTest<ThreadOrganizerCubit, ThreadOrganizerState>(
      'emits new thread when new message introduced',
      build: () => ThreadOrganizerCubit(),
      act: (bloc) {
        // return bloc.sortMessage(giftWrapAndSeal(
        //     MockKeys.guest.publicKey,
        //     MockKeys.hoster,
        //     Event.fromJson({
        //       "content": 'hi',
        //       "createdAt": DateTime(2025),
        //       "kind": 14,
        //       "keyPairs": MockKeys.guest,
        //       "tags": [
        //         ['a', '1']
        //       ]
        //     })));
      },
      expect: () => [
        // isA<ThreadOrganizerState>().having(
        //   (state) => state.threads.length,
        //   'number of threads',
        //   1,
        // ),
      ],
    );
  });
}
