import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hostr/logic/services/messages/global_gift_wrap.cubit.dart';

import '../mock/hydrated_storage.mock.dart';

void main() {
  setUp(() {
    // Reset the GetIt instance to its initial state before each test
    GetIt.I.reset();
    initHydratedStorage();
    // Re-configure services for testing
    configureInjection(Env.test);
  });

  group('Gift wrap should unpack child', () {
    blocTest<GlobalGiftWrapCubit, ListCubitState<GiftWrap>>(
      'emits new thread when new message introduced',
      build: () =>
          GlobalGiftWrapCubit(authCubit: AuthCubit(initialState: LoggedIn()))
            ..sync(),
      act: (bloc) async {
        getIt<NostrService>().events.add(giftWrapAndSeal(
            MockKeys.guest.public, MockKeys.hoster, MOCK_LISTINGS[0], null));
        // await Future.delayed(Duration(milliseconds: 50)); // Add a delay
      },
      expect: () => [
        /// Check that child kind is parsed correctly
        isA<ListCubitState>().having(
          (state) => state.results.length,
          'number of gift wraps',
          1,
        ),
      ],
      verify: (bloc) {
        assert(bloc.state.results[0].child is Listing,
            'Child is not of type Listing');
      },
    );
  });
}
