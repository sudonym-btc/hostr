import 'package:injectable/injectable.dart' hide Order;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

import '../../util/custom_logger.dart';
import '../../util/deterministic_key_derivation.dart';
import '../auth/auth.dart';
import 'account_seed_store.dart';
import 'deterministic_keys.dart';

@Singleton(as: DeterministicKeys)
class DeterministicKeysImpl implements DeterministicKeys {
  final Auth _auth;
  final AccountSeedStore _seedStore;
  final CustomLogger _logger;
  final Map<String, DeterministicKeyDerivation> _derivationCache = {};

  DeterministicKeysImpl({
    required Auth auth,
    required AccountSeedStore seedStore,
    required CustomLogger logger,
  }) : _auth = auth,
       _seedStore = seedStore,
       _logger = logger.scope('deterministic_keys');

  Future<DeterministicKeyDerivation> _activeDerivation() async {
    final seedHex = await _seedStore.getActiveSeedHex(
      pubkey: _auth.activePubkey,
    );
    return _derivationCache.putIfAbsent(
      seedHex,
      () => DeterministicKeyDerivation(seedHex),
    );
  }

  @override
  Future<EthPrivateKey> getActiveEvmKey({int accountIndex = 0}) {
    return _logger.span('getActiveEvmKeyAsync', () async {
      final derivation = await _activeDerivation();
      return derivation.deriveEvmKey(accountIndex: accountIndex);
    });
  }

  @override
  Future<bip.EthereumAddress> getEvmAddress({int accountIndex = 0}) {
    return _logger.span('getEvmAddressAsync', () async {
      final derivation = await _activeDerivation();
      return derivation.deriveEvmAddress(accountIndex: accountIndex);
    });
  }

  @override
  Future<int?> tryFindEvmAccountIndex(
    bip.EthereumAddress address, {
    int maxScan = 20,
  }) async {
    final upperBound = _scanUpperBound(maxScan);
    for (var i = 0; i < upperBound; i++) {
      final derived = await getEvmAddress(accountIndex: i);
      if (derived == address) return i;
    }
    return null;
  }

  @override
  Future<int> findEvmAccountIndex(
    bip.EthereumAddress address, {
    int maxScan = 20,
  }) => _logger.span('findEvmAccountIndex', () async {
    final index = await tryFindEvmAccountIndex(address, maxScan: maxScan);
    if (index != null) {
      return index;
    }
    final upperBound = _scanUpperBound(maxScan);
    throw StateError(
      'No HD account index (0..$upperBound) matches address '
      '${address.eip55With0x}',
    );
  });

  @override
  Future<List<String>> getEvmMnemonic() {
    return _logger.span('getEvmMnemonicAsync', () async {
      final derivation = await _activeDerivation();
      return derivation.deriveAccountMnemonicWords();
    });
  }

  @override
  Future<String> getTradeId({required int accountIndex}) {
    return _logger.span('getTradeIdAsync', () async {
      final derivation = await _activeDerivation();
      return derivation.deriveTradeId(accountIndex: accountIndex);
    });
  }

  @override
  Future<KeyPair> getTradeKeyPair({required int accountIndex}) {
    return _logger.span('getTradeKeyPairAsync', () async {
      final derivation = await _activeDerivation();
      return derivation.deriveTradeKeyPair(accountIndex: accountIndex);
    });
  }

  int _scanUpperBound(int maxScan) {
    final maxAccountIndex = _auth.storedMaxAccountIndex;
    final maxReserved = maxAccountIndex >= 0 ? maxAccountIndex + 1 : 0;
    return maxScan > maxReserved ? maxScan : maxReserved + 1;
  }
}
