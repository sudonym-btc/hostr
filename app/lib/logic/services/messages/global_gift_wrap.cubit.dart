import 'package:hostr/data/main.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';

class GlobalGiftWrapCubit extends ListCubit<Event> with HydratedMixin {
  final AuthCubit authCubit;
  final NostrService nostrService;
  GlobalGiftWrapCubit({required this.authCubit, required this.nostrService})
    : super(nostrService: nostrService, kinds: [NOSTR_KIND_GIFT_WRAP]) {
    hydrate();
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
