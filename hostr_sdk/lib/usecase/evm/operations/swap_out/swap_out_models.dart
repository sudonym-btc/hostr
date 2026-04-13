import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../evm_call.dart';

class SwapOutParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
  final TokenAmount? amount;

  /// Extra [Call]s to prepend before the lock calls in a single UserOp.
  ///
  /// When non-null the swap operation merges these calls ahead of the
  /// built lock calls (approve + lock) and broadcasts atomically.
  /// For example, an escrow withdraw call is prepended so that
  /// withdraw + lock happen in one transaction.
  ///
  /// Persisted on [SwapOutData] for crash recovery — no callback
  /// reconstruction needed.
  ///
  /// Non-final so that [SwapQuoteService] can append DEX swap calls when
  /// the user holds a non-Boltz token (e.g. USDT).
  Map<String, Call>? preLockCalls;

  /// The Boltz-side token address to use for the submarine swap.
  ///
  /// When [amount] refers to a non-Boltz token (e.g. USDT), [SwapQuoteService]
  /// performs a DEX hop (USDT → tBTC) and sets this to the bridge token
  /// address (tBTC).  All Boltz API calls must use this address rather than
  /// the address derived from [amount.token] so the pair id resolves to
  /// `TBTC/BTC` instead of the non-existent `USDT/BTC`.
  ///
  /// Null when no DEX hop is needed (amount is already the bridge token or
  /// the chain's native asset).
  EthereumAddress? boltzTokenAddress;

  SwapOutParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amount,
    this.preLockCalls,
    this.boltzTokenAddress,
  });
}
