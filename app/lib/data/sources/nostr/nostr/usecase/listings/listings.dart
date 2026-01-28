import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

@Singleton()
class Listings extends CrudUseCase<Listing> {
  Listings({required super.requests}) : super(kind: Listing.kinds[0]);
}
