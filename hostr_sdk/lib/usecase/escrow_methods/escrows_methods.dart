import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../crud.usecase.dart';

@Singleton()
class EscrowMethods extends CrudUseCase<EscrowMethod> {
  EscrowMethods({required super.requests, required super.logger})
    : super(kind: EscrowMethod.kinds[0]);
}
