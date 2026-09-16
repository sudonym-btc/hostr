import 'package:marketplace_evm/ports.dart';

import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

abstract class DeterministicKeys implements EvmKeyProvider {
  @override
  Future<EthPrivateKey> getActiveEvmKey({int accountIndex = 0});
  @override
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
  Future<KeyPair> getTradeKeyPair({required int accountIndex});
}
