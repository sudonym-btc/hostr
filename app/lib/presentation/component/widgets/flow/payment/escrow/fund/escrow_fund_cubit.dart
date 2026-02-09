import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class EscrowFundCubit extends Cubit<EscrowFundState> {
  CustomLogger logger = CustomLogger();
  final EscrowFundParams params;
  EscrowFundCubit(this.params) : super(EscrowFundInitialised());

  void confirm() async {
    getIt<Hostr>().escrow.fund(params).execute().listen(emit);
  }
}
