import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/default_entity.provider.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class ReservationProvider extends DefaultEntityProvider<Order> {
  ReservationProvider({super.key, super.e, super.a, super.builder, super.child})
    : super(kinds: Order.kinds, crud: getIt<Hostr>().orders);
}
