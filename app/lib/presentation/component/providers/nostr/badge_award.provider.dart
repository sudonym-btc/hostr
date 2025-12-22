import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:models/main.dart';

class BadgeAwardProvider extends DefaultEntityProvider<BadgeAward> {
  BadgeAwardProvider({super.key, super.e, super.a, super.builder, super.child})
    : super(kinds: BadgeAward.kinds);
}
