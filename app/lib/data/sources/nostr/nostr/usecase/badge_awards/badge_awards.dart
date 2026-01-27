import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:models/main.dart';

class BadgeAwards extends CrudUseCase<BadgeAward> {
  BadgeAwards({required super.requests}) : super(kind: BadgeAward.kinds[0]);
}
