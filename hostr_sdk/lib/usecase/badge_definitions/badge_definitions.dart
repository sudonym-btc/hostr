import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../crud.usecase.dart';

@Singleton()
class BadgeDefinitions extends CrudUseCase<BadgeDefinition> {
  BadgeDefinitions({required super.requests})
    : super(kind: BadgeDefinition.kinds[0]);
}
