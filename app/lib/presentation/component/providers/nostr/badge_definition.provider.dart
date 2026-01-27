import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:models/main.dart';

class BadgeDefinitionProvider extends DefaultEntityProvider<BadgeDefinition> {
  BadgeDefinitionProvider({
    super.key,
    super.e,
    super.a,
    super.builder,
    super.child,
  }) : super(
         kinds: BadgeDefinition.kinds,
         crud: getIt<NostrService>().badgeDefinitions,
       );
}
