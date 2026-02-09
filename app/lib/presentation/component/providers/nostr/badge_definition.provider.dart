import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
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
         crud: getIt<Hostr>().badgeDefinitions,
       );
}
