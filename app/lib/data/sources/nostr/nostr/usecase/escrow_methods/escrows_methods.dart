import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

@Singleton()
class EscrowMethods extends CrudUseCase<EscrowMethod> {
  EscrowMethods({required super.requests}) : super(kind: EscrowMethod.kinds[0]);
}
