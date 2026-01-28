import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../crud.usecase.dart';

@Singleton()
class Reservations extends CrudUseCase<Reservation> {
  Reservations({required super.requests}) : super(kind: Reservation.kinds[0]);

  Future<List<Reservation>> getListingReservations({
    required String listingAnchor,
  }) {
    return list(Filter(aTags: [listingAnchor]));
  }
}
