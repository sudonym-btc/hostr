import 'package:hostr/data/main.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';

class ListingProvider extends DefaultEntityProvider<Listing> {
  ListingProvider({super.key, super.e, super.a, super.builder, super.child})
      : super(kinds: Listing.kinds);
}
