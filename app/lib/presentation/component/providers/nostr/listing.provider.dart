import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:models/main.dart';

class ListingProvider extends DefaultEntityProvider<Listing> {
  ListingProvider(
      {super.kinds = Listing.kinds,
      super.key,
      super.e,
      super.a,
      super.builder,
      super.child});
}
