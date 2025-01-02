import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/models/main.dart';
import 'package:injectable/injectable.dart';

import 'base.repository.dart';

abstract class ListingRepository extends BaseRepository<Listing> {
  ListingRepository() : super() {
    creator = (NostrEvent event) {
      return Listing.fromNostrEvent(event);
    };
  }
  @override
  NostrFilter get eventTypeFilter => NostrFilter(kinds: [NOSTR_KIND_LISTING]);
}

@Injectable(as: ListingRepository)
class ProdListingRepository extends ListingRepository {}
