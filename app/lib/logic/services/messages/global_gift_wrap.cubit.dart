import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class GlobalGiftWrapCubit extends ListCubit<GiftWrap> with HydratedMixin {
  final AuthCubit authCubit;
  GlobalGiftWrapCubit({required this.authCubit})
      : super(
          kinds: [NOSTR_KIND_GIFT_WRAP],
        ) {
    hydrate();
    _setupListeners();
  }
  void _setupListeners() {
    authCubit.stream.listen((state) async {
      if (state is LoggedIn) {
        logger.i(
            'Synching gift wraps ${(await getIt<KeyStorage>().getActiveKeyPair())!.public}');
        filter = NostrFilter(additionalFilters: {
          'p': [(await getIt<KeyStorage>().getActiveKeyPair())!.public]
        });
        sync();
      } else if (state is LoggedOut) {
        logger.i('Clearing gift wraps');
        clear();
      }
    });
  }
}

// /// Implementation should store state in local storage
// @Injectable(as: GlobalGiftWrapCubit, env: Env.allButTest)
// class GlobalGiftWrapCubitImpl extends GlobalGiftWrapCubit with HydratedMixin {
//   GlobalGiftWrapCubitImpl();
// }

// /// Tests should not use HydratedMixin
// @Injectable(as: GlobalGiftWrapCubit, env: [Env.test])
// class GlobalGiftWrapCubitTest extends GlobalGiftWrapCubit {
//   GlobalGiftWrapCubitTest() {
//     this.h
//   }
// }
