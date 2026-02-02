import 'dart:math';

import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

abstract class EvmChain {
  final Web3Client client;
  EvmChain({required this.client});
  CustomLogger logger = CustomLogger();
  Future<void> connectToRootstock() async {
    try {
      final blockNumber = await client.getBlockNumber();
      logger.d("Current block number: $blockNumber");
    } catch (e) {
      logger.d("Error: $e");
    } finally {
      client.dispose();
    }
  }

  Future<BigInt> getChainId() async {
    return await client.getChainId();
  }

  Future<double> getBalance(EthereumAddress address) async {
    logger.d('Getting balance for $address');
    return await client.getBalance(address).then((val) {
      logger.d('Balance for $address: ${val.getInWei}');
      return convertWeiToSatoshi(val.getInWei.toDouble());
    });
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

  Future<EtherSwap> getEtherSwapContract();

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
