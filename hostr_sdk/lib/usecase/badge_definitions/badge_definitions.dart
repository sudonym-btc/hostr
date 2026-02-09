import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../crud.usecase.dart';

@Singleton()
class BadgeDefinitions extends CrudUseCase<BadgeDefinition> {
  BadgeDefinitions({required super.requests, required super.logger})
    : super(kind: BadgeDefinition.kinds[0]);
}
