import 'package:models/main.dart';
import 'package:wallet/wallet.dart';

import '../../../util/token_amount_ext.dart';

/// A request descriptor for a single JSON-RPC call.
typedef RpcRequest = ({String method, List<dynamic> params});

/// A typed handle to results within an [RpcBatch].
///
/// Access [value] after [EvmChain.executeBatch] completes.
/// Throws [StateError] if read before the batch has been executed.
class BatchResult<T> {
  T? _value;

  /// The parsed result. Only available after [RpcBatch.resolve] runs.
  T get value => _value ?? (throw StateError('Batch not yet executed'));
}

/// Accumulates heterogeneous JSON-RPC requests with self-contained parsers.
///
/// Each `get*` method appends N raw RPC requests **and** a resolver that
/// knows how to parse the corresponding N responses back into a typed
/// [BatchResult]. After a single `executeBatch` call all handles are
/// populated — no manual slice-tracking or static parse methods needed.
///
/// ```dart
/// final batch = RpcBatch();
/// final balances = batch.getBalances(addresses, chainId: 42);
/// final nonces   = batch.getTransactionCounts(addresses);
/// await chain.executeBatch(batch);
/// print(balances.value); // Map<EthereumAddress, TokenAmount>
/// print(nonces.value);   // List<int>
/// ```
class RpcBatch {
  final List<RpcRequest> _requests = [];
  final List<Future<void> Function(List<dynamic> raw)> _resolvers = [];

  /// All accumulated requests — passed to [EvmChain.batchRpc] internally.
  List<RpcRequest> get requests => List.unmodifiable(_requests);

  /// Number of requests accumulated so far.
  int get length => _requests.length;

  /// Whether no requests have been added yet.
  bool get isEmpty => _requests.isEmpty;

  /// Populate every [BatchResult] handle from the raw RPC responses.
  ///
  /// Called internally by [EvmChain.executeBatch]; you should not need
  /// to call this directly.
  Future<void> resolve(List<dynamic> rawResults) async {
    for (final r in _resolvers) {
      await r(rawResults);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // eth_getBalance
  // ══════════════════════════════════════════════════════════════════════

  /// Queue `eth_getBalance` for each address.
  ///
  /// Returns a [BatchResult] that will contain a map from address →
  /// [TokenAmount] once the batch is executed.
  BatchResult<Map<EthereumAddress, TokenAmount>> getBalances(
    List<EthereumAddress> addresses, {
    required int chainId,
  }) {
    final result = BatchResult<Map<EthereumAddress, TokenAmount>>();
    final offset = _requests.length;

    for (final a in addresses) {
      _requests.add((
        method: 'eth_getBalance',
        params: <dynamic>[a.eip55With0x, 'latest'],
      ));
    }

    _resolvers.add((raw) async {
      final map = <EthereumAddress, TokenAmount>{};
      for (var i = 0; i < addresses.length; i++) {
        final hex = raw[offset + i] as String?;
        if (hex == null) continue;
        final wei = BigInt.parse(
          hex.startsWith('0x') ? hex.substring(2) : hex,
          radix: 16,
        );
        map[addresses[i]] = rbtcFromWei(wei, chainId: chainId);
      }
      result._value = map;
    });

    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  // eth_getTransactionCount
  // ══════════════════════════════════════════════════════════════════════

  /// Queue `eth_getTransactionCount` for each address.
  ///
  /// Returns a [BatchResult] containing a list of nonce values
  /// (parallel to [addresses]).
  BatchResult<List<int>> getTransactionCounts(List<EthereumAddress> addresses) {
    final result = BatchResult<List<int>>();
    final offset = _requests.length;

    for (final a in addresses) {
      _requests.add((
        method: 'eth_getTransactionCount',
        params: <dynamic>[a.eip55With0x, 'latest'],
      ));
    }

    _resolvers.add((raw) async {
      result._value = [
        for (var i = 0; i < addresses.length; i++)
          _parseHexInt(raw[offset + i] as String?),
      ];
    });

    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  // eth_call — ERC-20 balanceOf
  // ══════════════════════════════════════════════════════════════════════

  /// ERC-20 `balanceOf(address)` function selector.
  static const _balanceOfSelector = '70a08231';

  /// Queue `eth_call` for ERC-20 `balanceOf` on each (owner, token) pair.
  ///
  /// [tokenResolver] is called at parse-time to look up [Token] metadata;
  /// it should be cheap / cached after the first call.
  ///
  /// Returns a [BatchResult] containing a list parallel to [pairs],
  /// with `null` for any sub-request that failed.
  BatchResult<List<TokenAmount?>> getERC20Balances(
    List<({EthereumAddress owner, EthereumAddress token})> pairs, {
    required Future<Token> Function(String address) tokenResolver,
  }) {
    final result = BatchResult<List<TokenAmount?>>();
    final offset = _requests.length;

    for (final p in pairs) {
      final ownerHex = p.owner.eip55With0x
          .toLowerCase()
          .replaceFirst('0x', '')
          .padLeft(64, '0');
      final calldata = '0x$_balanceOfSelector$ownerHex';
      _requests.add((
        method: 'eth_call',
        params: <dynamic>[
          {'to': p.token.eip55With0x, 'data': calldata},
          'latest',
        ],
      ));
    }

    _resolvers.add((raw) async {
      final out = <TokenAmount?>[];
      for (var i = 0; i < pairs.length; i++) {
        final hex = raw[offset + i] as String?;
        if (hex == null || hex == '0x') {
          out.add(null);
          continue;
        }
        final value = BigInt.parse(
          hex.startsWith('0x') ? hex.substring(2) : hex,
          radix: 16,
        );
        final token = await tokenResolver(pairs[i].token.eip55With0x);
        out.add(TokenAmount(value: value, token: token));
      }
      result._value = out;
    });

    return result;
  }

  // ══════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════

  static int _parseHexInt(String? hex) {
    if (hex == null || hex.isEmpty) return 0;
    return int.parse(hex.startsWith('0x') ? hex.substring(2) : hex, radix: 16);
  }
}
