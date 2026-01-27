import 'package:hostr/core/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart' show Ndk;
import 'package:rxdart/rxdart.dart';

import 'usecase/badge_awards/badge_awards.dart';
import 'usecase/badge_definitions/badge_definitions.dart';
import 'usecase/escrows/escrows.dart';
import 'usecase/listings/listings.dart';
import 'usecase/messaging/messaging.dart';
import 'usecase/requests/requests.dart';
import 'usecase/reservation_requests/reservation_requests.dart';
import 'usecase/reservations/reservations.dart';

abstract class NostrService {
  NostrService({required Ndk ndk}) {
    requests = Requests(ndk: ndk);
    listings = Listings(requests: requests);
    reservations = Reservations(requests: requests);
    reservationRequests = ReservationRequests(requests: requests, ndk: ndk);
    escrows = Escrows(requests: requests);
    messaging = Messaging(ndk, requests);
    badgeDefinitions = BadgeDefinitions(requests: requests);
    badgeAwards = BadgeAwards(requests: requests);
  }

  CustomLogger logger = CustomLogger();
  ReplaySubject<Nip01Event> events = ReplaySubject<Nip01Event>();
  late final Requests requests;
  late final Listings listings;
  late final Reservations reservations;
  late final Escrows escrows;
  late final BadgeDefinitions badgeDefinitions;
  late final BadgeAwards badgeAwards;
  late final Messaging messaging;
  late final ReservationRequests reservationRequests;
}

@Singleton(as: NostrService)
class ProdNostrService extends NostrService {
  ProdNostrService(Ndk ndk) : super(ndk: ndk);
}
