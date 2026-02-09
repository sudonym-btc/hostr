import 'dart:async';
import 'dart:math';

import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../util/bitcoin_amount.dart';
import '../../../util/custom_logger.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../operations/swap_in/swap_in_models.dart';
import '../operations/swap_in/swap_in_operation.dart';

abstract class EvmChain {
  final Web3Client client;
  EvmChain({required this.client});
  CustomLogger logger = CustomLogger();

  SupportedEscrowContract getSupportedEscrowContract(
    EscrowService escrowService,
  ) {
    return SupportedEscrowContractRegistry.getSupportedContract(
      'MultiEscrow', // to be replaced with ABI hash or bytecode hash
      client,
      EthereumAddress.fromHex(escrowService.parsedContent.contractAddress),
    )!;
  }

  Future<BigInt> getChainId() async {
    return await client.getChainId();
  }

  Future<BitcoinAmount> getBalance(EthereumAddress address) async {
    logger.d('Getting balance for $address');
    return await client.getBalance(address).then((val) {
      logger.d('Balance for $address: $val');
      return BitcoinAmount.inWei(val.getInWei);
    });
  }

  Stream<BitcoinAmount> subscribeBalance(EthereumAddress address) async* {
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

  Future<BitcoinAmount> getMinimumSwapIn();

  SwapInOperation swapIn(SwapInParams params);

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

double convertWeiToSatoshi(BigInt wei) {
  return wei.toDouble() / pow(10, 18 - 8);
}

double convertWeiToBTC(BigInt wei) {
  return wei.toDouble() / pow(10, 18);
}
