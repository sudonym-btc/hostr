import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/operations/swap_in/swap_in_models.dart';
import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../../../../data/sources/nostr/nostr/usecase/evm/chain/evm_chain.dart';
import '../../../../../../../data/sources/nostr/nostr/usecase/evm/operations/swap_in/swap_in_state.dart';

class SwapInCubitParams<T extends EvmChain> {
  final EthPrivateKey ethKey;
  final Amount amount;
  final T evmChain;

  SwapInCubitParams({
    required this.ethKey,
    required this.amount,
    required this.evmChain,
  });
}

abstract class SwapInCubit<T extends SwapInCubitParams>
    extends Cubit<SwapInState> {
  CustomLogger logger = CustomLogger();
  final T params;
  SwapInCubit(this.params) : super(SwapInInitialised());
  void confirm() {
    params.evmChain
        .swapIn(
          SwapInParams(
            evmKey: params.ethKey,
            amount: BitcoinAmount.fromAmount(params.amount),
          ),
        )
        .execute()
        .listen(emit);
  }
}
