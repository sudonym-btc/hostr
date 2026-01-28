import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

@Singleton()
class BadgeAwards extends CrudUseCase<BadgeAward> {
  BadgeAwards({required super.requests}) : super(kind: BadgeAward.kinds[0]);
}
