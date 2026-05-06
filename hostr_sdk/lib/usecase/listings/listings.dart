import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../crud.usecase.dart';
import '../metadata/metadata.dart';

@Singleton()
class Listings extends CrudUseCase<Listing> {
  final MetadataUseCase _metadata;

  Listings({
    required super.requests,
    required super.logger,
    required MetadataUseCase metadata,
  }) : _metadata = metadata,
       super(kind: Listing.kinds[0]);

  @override
  Future<List<Listing>> list(Filter f, {String? name}) =>
      logger.span('list', () async {
        return requests
            .query<Listing>(
              filter: kindFilter(f),
              name: 'Listing-list${name != null ? '-$name' : ''}',
              cacheRead: false,
            )
            .toList();
      });

  @override
  Future<void> beforeUpsert(Listing event) async {
    await _metadata.ensureSellerConfig(event.pubKey);
  }
}
