import 'dart:async';
import 'dart:math';

import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/logic/cubit/payment/payment.cubit.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

sealed class SwapState {
  const SwapState();
}

final class SwapInitiated extends SwapState {
  const SwapInitiated();
}

final class SwapPaymentCreated extends SwapState {
  final PaymentCubit paymentCubit;
  const SwapPaymentCreated({required this.paymentCubit});
}

final class SwapPaymentInFlight extends SwapPaymentCreated {
  SwapPaymentInFlight({required super.paymentCubit});
}

final class SwapAwaitingOnChain extends SwapState {
  const SwapAwaitingOnChain();
}

final class SwapFunded extends SwapState {
  const SwapFunded();
}

final class SwapClaimed extends SwapState {
  const SwapClaimed();
}

final class SwapCompleted extends SwapState {
  const SwapCompleted();
}

final class SwapFailed extends SwapState {
  const SwapFailed(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}

abstract class EvmChain {
  final Web3Client client;
  EvmChain({required this.client});
  CustomLogger logger = CustomLogger();

  Future<BigInt> getChainId() async {
    return await client.getChainId();
  }

  Future<double> getBalance(EthereumAddress address) async {
    logger.d('Getting balance for $address');
    return await client.getBalance(address).then((val) {
      logger.d('Balance for $address: ${val.getInWei}');
      logger.d('${convertWeiToBTC(val.getInWei.toDouble())}');
      return convertWeiToBTC(val.getInWei.toDouble());
    });
  }

  Stream<double> subscribeBalance(EthereumAddress address) async* {
    try {
      yield await getBalance(address);
    } catch (e) {
      logger.w('Failed initial balance fetch: $e');
    }

    await for (final _ in client.addedBlocks()) {
      try {
        yield await getBalance(address);
      } catch (e) {
        logger.w('Failed to fetch balance on new block: $e');
      }
    }
  }

  Future<TransactionInformation?> getTransaction(String txHash) async {
    logger.d('Getting transaction for $txHash');
    return await client.getTransactionByHash(txHash).then((val) {
      logger.d(
        'Transaction for $txHash: from ${val?.from} to ${val?.to} amount ${val?.value.getInWei}',
      );
      return val;
    });
  }

  Future<TransactionInformation> awaitTransaction(String txHash) async {
    /// Fetch the from address of the lockup transaction to use as refund address
    TransactionInformation? lockupTx = await getTransaction(txHash);

    // Make sure our RPC node sees the swap funding transaction as well
    while (true) {
      if (lockupTx == null) {
        logger.i('Lockup transaction not found');
        await Future.delayed(Duration(milliseconds: 500));
        continue;
      }
      logger.i('Lockup transaction: $lockupTx');

      break;
    }
    return lockupTx;
  }

  Future<TransactionReceipt> awaitReceipt(String txHash) async {
    while (true) {
      final receipt = await client.getTransactionReceipt(txHash);
      if (receipt != null) return receipt;
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<EtherSwap> getEtherSwapContract();

  Future<int> getMinimumSwapIn();
  Stream<SwapState> swapIn({required KeyPair key, required int amountSats});

  swapOutAll({required KeyPair key});

  Future<List<dynamic>> call(
    ContractAbi abi,
    EthereumAddress address,
    ContractFunction func,
    params,
  ) {
    return client.call(
      contract: DeployedContract(abi, address),
      function: func,
      params: params,
    );
  }
}

double convertWeiToSatoshi(double wei) {
  return wei / pow(10, 18 - 8);
}

double convertWeiToBTC(double wei) {
  return wei / pow(10, 18);
}
