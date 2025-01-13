import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
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
    authCubit.stream.listen((state) {
      if (state is LoggedIn) {
        sync();
      } else if (state is LoggedOut) {
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
