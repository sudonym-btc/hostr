import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:models/main.dart';

class ReservationProvider extends DefaultEntityProvider<Reservation> {
  ReservationProvider({super.key, super.e, super.a, super.builder, super.child})
      : super(kinds: Reservation.kinds);
}
