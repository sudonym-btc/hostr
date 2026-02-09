import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class EscrowCubit extends Cubit<EscrowState> {
  CustomLogger logger = CustomLogger();
  final EscrowFundParams params;
  EscrowCubit(this.params) : super(EscrowInitialised());

  void confirm() async {
    getIt<Hostr>().escrow.fund(params).execute().listen(emit);
  }
}
