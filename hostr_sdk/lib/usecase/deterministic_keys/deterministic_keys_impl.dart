import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

import '../../util/custom_logger.dart';
import '../../util/deterministic_key_derivation.dart';
import '../auth/auth.dart';
import '../evm/evm.dart';
import '../reservations/reservations.dart';
import 'deterministic_keys.dart';

@Singleton(as: DeterministicKeys)
class DeterministicKeysImpl implements DeterministicKeys {
  final Auth _auth;
  final Evm _evm;
  final Reservations _reservations;
  final CustomLogger _logger;

  DeterministicKeysImpl({
    required Auth auth,
    required Evm evm,
    required Reservations reservations,
    required CustomLogger logger,
  }) : _auth = auth,
       _evm = evm,
       _reservations = reservations,
       _logger = logger;

  @override
  EthPrivateKey getActiveEvmKey({int accountIndex = 0}) {
    return deriveEvmKey(
      _auth.getActiveKey().privateKey!,
      accountIndex: accountIndex,
    );
  }

  @override
  bip.EthereumAddress getEvmAddress({int accountIndex = 0}) {
    return getActiveEvmKey(accountIndex: accountIndex).address;
  }

  @override
  int? tryFindEvmAccountIndex(bip.EthereumAddress address, {int maxScan = 20}) {
    final upperBound = _scanUpperBound(maxScan);
    for (var i = 0; i < upperBound; i++) {
      final derived = getEvmAddress(accountIndex: i);
      if (derived == address) return i;
    }
    return null;
  }

  @override
  int findEvmAccountIndex(bip.EthereumAddress address, {int maxScan = 20}) =>
      _logger.spanSync('findEvmAccountIndex', () {
        final index = tryFindEvmAccountIndex(address, maxScan: maxScan);
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
  List<String> getEvmMnemonic() => _logger.spanSync('getEvmMnemonic', () {
    return deriveEvmMnemonicWords(_auth.getActiveKey().privateKey!);
  });

  @override
  String getTradeId({required int accountIndex}) =>
      _logger.spanSync('getTradeId', () {
        return deriveTradeId(
          _auth.getActiveKey().privateKey!,
          accountIndex: accountIndex,
        );
      });

  @override
  String getTradeSalt({required int accountIndex}) =>
      _logger.spanSync('getTradeSalt', () {
        return deriveTradeSalt(
          _auth.getActiveKey().privateKey!,
          accountIndex: accountIndex,
        );
      });

  @override
  Future<int> reserveNextTradeIndex() =>
      _logger.span('reserveNextTradeIndex', () async {
        final record = await _loadTradeIndexRecord();
        var accountIndex = record.maxAccountIndex + 1;

        while (true) {
          final tradeId = getTradeId(accountIndex: accountIndex);
          final evmAddress = getEvmAddress(accountIndex: accountIndex);
          final tradeExists = await _tradeExists(tradeId);
          final addressUsed = await _evmAddressIsUsed(evmAddress);

          if (!tradeExists && !addressUsed) {
            break;
          }

          accountIndex++;
        }

        if (accountIndex > record.maxAccountIndex) {
          final updatedRecord = record.copyWith(maxAccountIndex: accountIndex);
          await _auth.authStorage.set([jsonEncode(updatedRecord.toJson())]);
          await _auth.init();
        }

        return accountIndex;
      });

  @override
  int findTradeAccountIndexByTradeId(String tradeId, {int maxScan = 128}) =>
      _logger.spanSync('findTradeAccountIndexByTradeId', () {
        final index = tryFindTradeAccountIndexByTradeId(
          tradeId,
          maxScan: maxScan,
        );
        if (index != null) {
          return index;
        }
        throw StateError('No trade account index matches tradeId $tradeId');
      });

  @override
  int? tryFindTradeAccountIndexByTradeId(String tradeId, {int maxScan = 128}) {
    final candidates = getReservedTradeIndices();
    for (final index in candidates) {
      if (getTradeId(accountIndex: index) == tradeId) {
        return index;
      }
    }
    return null;
  }

  @override
  int findTradeAccountIndexBySalt(String salt, {int maxScan = 128}) =>
      _logger.spanSync('findTradeAccountIndexBySalt', () {
        final index = tryFindTradeAccountIndexBySalt(salt, maxScan: maxScan);
        if (index != null) {
          return index;
        }
        throw StateError('No trade account index matches salt $salt');
      });

  @override
  int? tryFindTradeAccountIndexBySalt(String salt, {int maxScan = 128}) {
    final candidates = getReservedTradeIndices();
    for (final index in candidates) {
      if (getTradeSalt(accountIndex: index) == salt) {
        return index;
      }
    }
    return null;
  }

  @override
  List<int> getReservedTradeIndices() {
    final activeIdentity = _auth.activeIdentity;
    if (activeIdentity == null) {
      return const [];
    }
    final maxAccountIndex = _cachedMaxAccountIndex();
    if (maxAccountIndex < 0) {
      return const [];
    }
    return List<int>.unmodifiable(
      List<int>.generate(maxAccountIndex + 1, (index) => index),
    );
  }

  Future<_TradeIndexRecord> _loadTradeIndexRecord() async {
    final raw = await _auth.authStorage.get();
    return _TradeIndexRecord.fromStorage(raw);
  }

  int _cachedMaxAccountIndex() => _auth.storedMaxAccountIndex;

  int _scanUpperBound(int maxScan) {
    final maxAccountIndex = _cachedMaxAccountIndex();
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

class _TradeIndexRecord {
  final Map<String, dynamic> rawRecord;
  final int maxAccountIndex;

  const _TradeIndexRecord({
    required this.rawRecord,
    required this.maxAccountIndex,
  });

  _TradeIndexRecord copyWith({int? maxAccountIndex}) => _TradeIndexRecord(
    rawRecord: rawRecord,
    maxAccountIndex: maxAccountIndex ?? this.maxAccountIndex,
  );

  Map<String, dynamic> toJson() => {
    ...rawRecord,
    'maxAccountIndex': maxAccountIndex,
  };

  static _TradeIndexRecord fromStorage(List<String> raw) {
    if (raw.isEmpty) {
      throw StateError('No active auth record');
    }

    final first = raw.first;
    try {
      final decoded = jsonDecode(first);
      if (decoded is Map<String, dynamic>) {
        final reservedTradeIndices =
            (decoded['reservedTradeIndices'] as List<dynamic>? ?? const [])
                .map((e) => e as int)
                .toList(growable: false);
        return _TradeIndexRecord(
          rawRecord: Map<String, dynamic>.from(decoded),
          maxAccountIndex:
              decoded['maxAccountIndex'] as int? ??
              (reservedTradeIndices.isEmpty
                  ? -1
                  : reservedTradeIndices.reduce((a, b) => a > b ? a : b)),
        );
      }
    } catch (_) {
      // fall through to legacy raw-key migration
    }

    return _TradeIndexRecord(
      rawRecord: {
        'version': 1,
        'credentialType': 'private_key',
        'secret': first,
      },
      maxAccountIndex: -1,
    );
  }
}
