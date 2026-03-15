import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart' as bip;

import '../../util/custom_logger.dart';
import '../auth/auth.dart';
import '../deterministic_keys/deterministic_keys.dart';
import '../evm/evm.dart';
import '../reservations/reservations.dart';
import 'trade_account_allocator.dart';

@Singleton(as: TradeAccountAllocator)
class TradeAccountAllocatorImpl implements TradeAccountAllocator {
  final Auth _auth;
  final DeterministicKeys _hd;
  final Evm _evm;
  final Reservations _reservations;
  final CustomLogger _logger;

  TradeAccountAllocatorImpl({
    required Auth auth,
    required DeterministicKeys hd,
    required Evm evm,
    required Reservations reservations,
    required CustomLogger logger,
  }) : _auth = auth,
       _hd = hd,
       _evm = evm,
       _reservations = reservations,
       _logger = logger.scope('trade_account_allocator');

  @override
  Future<int> reserveNextTradeIndex() => _logger.span(
    'reserveNextTradeIndex',
    () async {
      var accountIndex = _auth.storedMaxAccountIndex + 1;

      while (true) {
        final tradeId = await _hd.getTradeId(accountIndex: accountIndex);
        final evmAddress = await _hd.getEvmAddress(accountIndex: accountIndex);
        final tradeExists = await _tradeExists(tradeId);
        final addressUsed = await _evmAddressIsUsed(evmAddress);

        if (!tradeExists && !addressUsed) {
          break;
        }

        accountIndex++;
      }

      await _auth.updateMaxAccountIndex(accountIndex);
      return accountIndex;
    },
  );

  @override
  Future<int> findTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 128,
  }) => _logger.span('findTradeAccountIndexByTradeId', () async {
    final index = await tryFindTradeAccountIndexByTradeId(
      tradeId,
      maxScan: maxScan,
    );
    if (index != null) {
      return index;
    }
    throw StateError('No trade account index matches tradeId $tradeId');
  });

  @override
  Future<int?> tryFindTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 128,
  }) async {
    final upperBound = _scanUpperBound(maxScan);
    for (var index = 0; index < upperBound; index++) {
      if (await _hd.getTradeId(accountIndex: index) == tradeId) {
        return index;
      }
    }
    return null;
  }

  @override
  Future<int> findTradeAccountIndexBySalt(String salt, {int maxScan = 128}) =>
      _logger.span('findTradeAccountIndexBySalt', () async {
        final index = await tryFindTradeAccountIndexBySalt(
          salt,
          maxScan: maxScan,
        );
        if (index != null) {
          return index;
        }
        throw StateError('No trade account index matches salt $salt');
      });

  @override
  Future<int?> tryFindTradeAccountIndexBySalt(
    String salt, {
    int maxScan = 128,
  }) async {
    final upperBound = _scanUpperBound(maxScan);
    for (var index = 0; index < upperBound; index++) {
      if (await _hd.getTradeSalt(accountIndex: index) == salt) {
        return index;
      }
    }
    return null;
  }

  @override
  List<int> getReservedTradeIndices() {
    if (_auth.activeKeyPair == null) {
      return const [];
    }
    final maxAccountIndex = _auth.storedMaxAccountIndex;
    if (maxAccountIndex < 0) {
      return const [];
    }
    return List<int>.unmodifiable(
      List<int>.generate(maxAccountIndex + 1, (index) => index),
    );
  }

  int _scanUpperBound(int maxScan) {
    final maxAccountIndex = _auth.storedMaxAccountIndex;
    final maxReserved = maxAccountIndex >= 0 ? maxAccountIndex + 1 : 0;
    return maxScan > maxReserved ? maxScan : maxReserved + 1;
  }

  Future<bool> _tradeExists(String tradeId) async {
    final reservations = await _reservations.getByTradeId(tradeId);
    return reservations.isNotEmpty;
  }

  Future<bool> _evmAddressIsUsed(bip.EthereumAddress address) async {
    for (final chain in _evm.supportedEvmChains) {
      final nonce = await chain.client.getTransactionCount(address);
      final balance = await chain.client.getBalance(address);
      if (nonce > 0 || balance.getInWei > BigInt.zero) {
        return true;
      }
    }
    return false;
  }
}
