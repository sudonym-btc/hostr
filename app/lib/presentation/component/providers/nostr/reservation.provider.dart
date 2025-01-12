import 'package:hostr/data/main.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';

class ReservationProvider extends DefaultEntityProvider<Reservation> {
  ReservationProvider({super.key, super.e, super.a, super.builder, super.child})
      : super(kinds: Reservation.kinds);
}
