import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:models/main.dart';

class BadgeDefinitions extends CrudUseCase<BadgeDefinition> {
  BadgeDefinitions({required super.requests})
    : super(kind: BadgeDefinition.kinds[0]);
}
