import 'package:hostr/data/main.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';

class ProfileProvider extends DefaultEntityProvider<Profile> {
  ProfileProvider({super.key, super.e, super.a, super.builder, super.child})
      : super(kinds: Profile.kinds);
}
