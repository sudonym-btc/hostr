import 'package:hostr/data/main.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';

class NwcProvider extends DefaultEntityProvider<NwcInfo> {
  NwcProvider(
      {super.key,
      super.e,
      super.a,
      super.builder,
      super.child,
      required pubkey})
      : super(kinds: NwcInfo.kinds);
}
