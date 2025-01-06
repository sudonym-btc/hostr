import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentCubit extends Cubit<PaymentState> {
  // final NwcService nwcService = getIt<NwcService>();

  PaymentCubit() : super(PaymentInitial());

  Future<void> payInvoice(String invoice) async {
    emit(PaymentInProgress());
    try {
      // final response = await nwcService.payInvoice(invoice);
      emit(PaymentSuccess('Done'));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }
}

// States
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentInProgress extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final String response;
  PaymentSuccess(this.response);
}

class PaymentFailure extends PaymentState {
  final String error;
  PaymentFailure(this.error);
}
