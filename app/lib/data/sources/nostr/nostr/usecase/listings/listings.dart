import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:models/main.dart';

class Listings extends CrudUseCase<Listing> {
  Listings({required super.requests}) : super(kind: Listing.kinds[0]);
}
