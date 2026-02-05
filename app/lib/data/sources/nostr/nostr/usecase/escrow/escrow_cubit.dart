import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../evm/evm_chain.dart';
import '../payments/constants.dart';
import '../swap/swap_cubit.dart';

sealed class EscrowState {}

class EscrowInitialised extends EscrowState {}

class EscrowSwapProgress extends EscrowState {
  final SwapCubit swap;
  EscrowSwapProgress(this.swap);
}

class EscrowCompleted extends EscrowState {
  String txHash;
  EscrowCompleted({required this.txHash});
}

class EscrowFailed extends EscrowState {
  final dynamic error;
  final StackTrace? stackTrace;

  EscrowFailed(this.error, [this.stackTrace]);
}

class EscrowCubitParams {
  final EthPrivateKey ethKey;
  final String eventId;
  final Amount amount;
  final String sellerEvmAddress;
  final String escrowEvmAddress;
  final String escrowContractAddress;
  final int timelock;
  final EvmChain evmChain;

  EscrowCubitParams({
    required this.ethKey,
    required this.eventId,
    required this.amount,
    required this.sellerEvmAddress,
    required this.escrowEvmAddress,
    required this.escrowContractAddress,
    required this.timelock,
    required this.evmChain,
  });
}

class EscrowCubit extends Cubit<EscrowState> {
  CustomLogger logger = CustomLogger();
  final EscrowCubitParams params;
  EscrowCubit(this.params) : super(EscrowInitialised());

  Future<void> _swapInIfRequired() async {
    final balance = await params.evmChain.getBalance(params.ethKey.address);
    logger.i('Escrow sender balance: $balance RBTC');
    final requiredAmountInBtc = params.amount.value - balance;
    if (requiredAmountInBtc > 0) {
      logger.e('Insufficient balance for escrow deposit. Have $balance RBTC');
      final requiredAmountForSwap = _ceilTo8Decimals(
        max(
          await params.evmChain.getMinimumSwapInSats() / btcSatoshiFactor,
          requiredAmountInBtc,
        ).toDouble(),
      );
      SwapCubit swapCubit = params.evmChain.swapIn(
        key: params.ethKey,
        amount: Amount(currency: Currency.BTC, value: requiredAmountForSwap),
      );
      emit(EscrowSwapProgress(swapCubit));
      await swapCubit.confirm();
    }
  }

  void confirm() async {
    try {
      await _swapInIfRequired();

      MultiEscrow e = MultiEscrow(
        address: EthereumAddress.fromHex(params.escrowContractAddress),
        client: params.evmChain.client,
      );
      final tuple = (
        tradeId: getBytes32(params.eventId),
        timelock: BigInt.from(params.timelock),

        /// Arbiter public key from their nostr advertisement
        arbiter: EthereumAddress.fromHex(params.escrowEvmAddress),

        /// Seller address derived from their nostr pubkey
        seller: EthereumAddress.fromHex(params.sellerEvmAddress),

        /// Our address derived from our nostr private key
        buyer: params.ethKey.address,
        escrowFee: BigInt.from(100),
      );
      logger.i(
        'Creating escrow for ${params.eventId} at ${params.escrowContractAddress}',
      );
      logger.i(tuple);
      String escrowTx = await e.createTrade(
        tuple,
        credentials: params.ethKey,
        transaction: Transaction(
          value: EtherAmount.fromBigInt(
            EtherUnit.wei,
            BigInt.from(params.amount.value * btcSatoshiFactor) *
                satoshiWeiFactor,
          ),
        ),
      );
      emit(EscrowCompleted(txHash: escrowTx));
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowFailed(error, stackTrace);
      emit(e);
      throw e;
    }
  }
}

double _ceilTo8Decimals(double value) {
  return (value * btcSatoshiFactor).ceil() / btcSatoshiFactor;
}
