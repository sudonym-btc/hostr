import 'package:models/main.dart';

import '../crud.usecase.dart';

class Reservations extends CrudUseCase<Reservation> {
  Reservations({required super.requests}) : super(kind: Reservation.kinds[0]);
}
