import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;

import '../crud.usecase.dart';
import '../identity_claims/identity_claims.dart';

@Singleton()
class Listings extends CrudUseCase<Listing> {
  final IdentityClaimsUseCase _identityClaims;

  Listings({
    required super.requests,
    required super.logger,
    required IdentityClaimsUseCase identityClaims,
  }) : _identityClaims = identityClaims,
       super(kind: Listing.kinds[0]);

  @override
  Future<List<RelayBroadcastResponse>> upsert(Listing event) async {
    await _identityClaims.ensureEvmAddress();
    return super.upsert(event);
  }
}
