import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;

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
  Future<List<RelayBroadcastResponse>> upsert(Listing event) async {
    await _metadata.ensureSellerConfig(event.pubKey);
    return super.upsert(event);
  }
}
