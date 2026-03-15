import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

abstract class DeterministicKeys {
  Future<EthPrivateKey> getActiveEvmKey({int accountIndex = 0});
  Future<bip.EthereumAddress> getEvmAddress({int accountIndex = 0});
  Future<int?> tryFindEvmAccountIndex(
    bip.EthereumAddress address, {
    int maxScan = 20,
  });
  Future<int> findEvmAccountIndex(
    bip.EthereumAddress address, {
    int maxScan = 20,
  });
  Future<List<String>> getEvmMnemonic();
  Future<String> getTradeId({required int accountIndex});
  Future<String> getTradeSalt({required int accountIndex});
}
