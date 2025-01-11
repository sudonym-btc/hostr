import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

class GlobalGiftWrapCubit extends ListCubit<GiftWrap> {
  GlobalGiftWrapCubit() : super(kinds: [NOSTR_KIND_GIFT_WRAP]);
}

/// Implementation should store state in local storage
@Singleton(as: GlobalGiftWrapCubit, env: Env.allButTest)
class GlobalGiftWrapCubitImpl extends GlobalGiftWrapCubit with HydratedMixin {
  GlobalGiftWrapCubitImpl() : super();
}

/// Tests should not use HydratedMixin
@Singleton(as: GlobalGiftWrapCubit, env: [Env.test])
class GlobalGiftWrapCubitTest extends GlobalGiftWrapCubit {
  GlobalGiftWrapCubitTest() : super();
}
