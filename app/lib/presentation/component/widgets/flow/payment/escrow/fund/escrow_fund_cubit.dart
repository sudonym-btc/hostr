import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:hostr/data/sources/nostr/nostr/hostr.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/operations/fund/escrow_fund_models.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/operations/fund/escrow_fund_state.dart';
import 'package:hostr/injection.dart';
import 'package:wallet/wallet.dart';

class EscrowFundCubit extends Cubit<EscrowFundState> {
  CustomLogger logger = CustomLogger();
  final EscrowFundParams params;
  late EtherAmount value;
  late MultiEscrow contract;
  EscrowFundCubit(this.params) : super(EscrowFundInitialised());

  void confirm() async {
    getIt<Hostr>().escrow.fund(params).execute().listen(emit);
  }
}
