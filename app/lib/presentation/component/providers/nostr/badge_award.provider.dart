import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class BadgeAwardProvider extends DefaultEntityProvider<BadgeAward> {
  BadgeAwardProvider({super.key, super.e, super.a, super.builder, super.child})
    : super(kinds: BadgeAward.kinds, crud: getIt<Hostr>().badgeAwards);
}
