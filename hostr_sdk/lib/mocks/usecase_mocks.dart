import 'package:mockito/annotations.dart';

import '../usecase/main.dart';

@GenerateMocks([
  Auth,
  Requests,
  MetadataUseCase,
  Nwc,
  Zaps,
  Listings,
  Reservations,
  EscrowUseCase,
  Escrows,
  EscrowTrusts,
  EscrowMethods,
  BadgeDefinitions,
  BadgeAwards,
  Messaging,
  ReservationRequests,
  Payments,
  Evm,
  Relays,
])
void main() {}
