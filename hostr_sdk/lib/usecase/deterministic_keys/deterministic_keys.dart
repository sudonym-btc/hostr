import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

abstract class DeterministicKeys {
  EthPrivateKey getActiveEvmKey({int accountIndex = 0});
  bip.EthereumAddress getEvmAddress({int accountIndex = 0});
  int? tryFindEvmAccountIndex(bip.EthereumAddress address, {int maxScan = 20});
  int findEvmAccountIndex(bip.EthereumAddress address, {int maxScan = 20});
  List<String> getEvmMnemonic();
  String getTradeId({required int accountIndex});
  String getTradeSalt({required int accountIndex});
  Future<int> reserveNextTradeIndex();
  int findTradeAccountIndexByTradeId(String tradeId, {int maxScan = 128});
  int? tryFindTradeAccountIndexByTradeId(String tradeId, {int maxScan = 128});
  int findTradeAccountIndexBySalt(String salt, {int maxScan = 128});
  int? tryFindTradeAccountIndexBySalt(String salt, {int maxScan = 128});
  List<int> getReservedTradeIndices();
}
