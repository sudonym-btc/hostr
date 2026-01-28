import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:models/main.dart';

class ListingProvider extends DefaultEntityProvider<Listing> {
  ListingProvider({
    super.kinds = Listing.kinds,
    super.key,
    super.e,
    super.onDone,
    super.a,
    super.builder,
    super.child,
  }) : super(crud: getIt<Hostr>().listings);
}
