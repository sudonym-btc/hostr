import 'package:hostr/export.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/reservation_request/payment_status_cubit.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../escrow/escrow.dart';
import '../zaps/zaps.dart';

@Singleton()
class PaymentStatus {
  CustomLogger logger = CustomLogger();
  final EscrowUseCase escrow;
  final Zaps zaps;

  PaymentStatus({required this.escrow, required this.zaps});

  // Once we have published a reservation item, we can use the payment proof to easily track status, so if we change trusted escrows, it doesn't matter.
  PaymentStatusCubit check(Listing l, ReservationRequest reservationRequest) {
    return PaymentStatusCubit(l, reservationRequest)..sync();
  }
}
