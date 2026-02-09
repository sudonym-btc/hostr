import 'package:hostr_sdk/usecase/main.dart';
import 'package:mockito/annotations.dart';

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
