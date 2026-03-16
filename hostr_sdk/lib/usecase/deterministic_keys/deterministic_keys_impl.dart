import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

import '../../util/custom_logger.dart';
import '../../util/deterministic_key_derivation.dart';
import '../auth/auth.dart';
import 'deterministic_keys.dart';

@Singleton(as: DeterministicKeys)
class DeterministicKeysImpl implements DeterministicKeys {
  final Auth _auth;
  final CustomLogger _logger;
  final Map<String, DeterministicKeyDerivation> _derivationCache = {};

  DeterministicKeysImpl({required Auth auth, required CustomLogger logger})
    : _auth = auth,
      _logger = logger.scope('deterministic_keys');

  DeterministicKeyDerivation _activeDerivation() {
    final privateKey = _auth.getActiveKey().privateKey!;
    return _derivationCache.putIfAbsent(
      privateKey,
      () => DeterministicKeyDerivation(privateKey),
    );
  }

  @override
  Future<EthPrivateKey> getActiveEvmKey({int accountIndex = 0}) {
    return _logger.span('getActiveEvmKeyAsync', () async {
      return _activeDerivation().deriveEvmKey(accountIndex: accountIndex);
    });
  }

  @override
  Future<bip.EthereumAddress> getEvmAddress({int accountIndex = 0}) {
    return _logger.span('getEvmAddressAsync', () async {
      return _activeDerivation().deriveEvmAddress(accountIndex: accountIndex);
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
      return _activeDerivation().deriveAccountMnemonicWords();
    });
  }

  @override
  Future<String> getTradeId({required int accountIndex}) {
    return _logger.span('getTradeIdAsync', () async {
      return _activeDerivation().deriveTradeId(accountIndex: accountIndex);
    });
  }

  @override
  Future<String> getTradeSalt({required int accountIndex}) {
    return _logger.span('getTradeSaltAsync', () async {
      return _activeDerivation().deriveTradeSalt(accountIndex: accountIndex);
    });
  }

  int _scanUpperBound(int maxScan) {
    final maxAccountIndex = _auth.storedMaxAccountIndex;
    final maxReserved = maxAccountIndex >= 0 ? maxAccountIndex + 1 : 0;
    return maxScan > maxReserved ? maxScan : maxReserved + 1;
  }
}
