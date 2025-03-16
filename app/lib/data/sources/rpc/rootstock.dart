import 'dart:math';

import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

abstract class Rootstock {
  CustomLogger logger = CustomLogger();
  Future<void> connectToRootstock();
  Future<double> getBalance(EthereumAddress address);
  Future<TransactionInformation?> getTransaction(String txHash);
}

@Injectable(as: Rootstock)
class RootstockImpl extends Rootstock {
  final Web3Client client =
      Web3Client(getIt<Config>().rootstockRpcUrl, Client());
  @override
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

  @override
  Future<double> getBalance(EthereumAddress address) async {
    logger.d('Getting balance for $address');
    return await client.getBalance(address).then((val) {
      logger.d('Balance for $address: ${val.getInWei}');
      return convertWeiToSatoshi(val.getInWei.toDouble());
    });
  }

  @override
  Future<TransactionInformation?> getTransaction(String txHash) async {
    logger.d('Getting transaction for $txHash');
    return await client.getTransactionByHash(txHash).then((val) {
      logger.d(
          'Transaction for $txHash: from ${val?.from} to ${val?.to} amount ${val?.value.getInWei}');
      return val;
    });
  }

  call(ContractAbi abi, EthereumAddress address, ContractFunction func,
      params) async {
    return client.call(
        contract: DeployedContract(abi, address),
        function: func,
        params: params);
  }
}

convertWeiToSatoshi(double wei) {
  return wei / pow(10, 18 - 8);
}
