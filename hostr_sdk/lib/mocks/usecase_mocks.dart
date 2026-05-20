import 'package:mockito/annotations.dart';

import '../usecase/main.dart';

@GenerateMocks([
  Auth,
  Requests,
  MetadataUseCase,
  Nwc,
  Zaps,
  Listings,
  Orders,
  EscrowUseCase,
  Escrows,
  EscrowMethods,
  BadgeDefinitions,
  BadgeAwards,
  Messaging,
  OrderRequests,
  Payments,
  Evm,
  Relays,
])
void main() {}
