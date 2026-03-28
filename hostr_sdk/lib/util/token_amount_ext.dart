import 'package:models/main.dart';
import 'package:wallet/wallet.dart';

import '../usecase/evm/config/evm_config.dart';

/// SDK-layer extensions on [TokenAmount] that require the `wallet` package
/// (e.g. [EtherAmount]).
///
/// These live here (not in the models package) because the models package
/// must remain EVM-agnostic.
extension TokenAmountEvmExt on TokenAmount {
  /// Convert to the `wallet` package's [EtherAmount].
  ///
  /// Only valid for EVM tokens (native or ERC-20).
  /// Throws [UnsupportedError] for Lightning BTC.
  EtherAmount toEtherAmount() => EtherAmount.inWei(asEvm);

  /// The raw value in satoshis (8-decimal units).
  ///
  /// For an RBTC token (18 decimals), this divides out the 10^10 factor.
  /// For a BTC Lightning token (8 decimals), this returns `value` directly.
  BigInt get inSats {
    if (token.decimals == 8) return value;
    // Convert from higher-precision to 8-decimal sats.
    final factor = BigInt.from(10).pow(token.decimals - 8);
    return value ~/ factor;
  }

  /// Alias for [inSats] — backward-compatible with `BitcoinAmount.getInSats`.
  BigInt get getInSats => inSats;

  /// Raw wei value — backward-compatible with `BitcoinAmount.getInWei`.
  BigInt get getInWei => value;

  /// The value in millisatoshis (1 sat = 1 000 msats).
  ///
  /// For 8-decimal tokens (BTC Lightning): `value × 1000`.
  /// For ≥ 11-decimal tokens (RBTC): `value ÷ 10^(decimals−11)`.
  BigInt get getInMSats {
    if (token.decimals >= 11) {
      return value ~/ BigInt.from(10).pow(token.decimals - 11);
    }
    // For 8–10 decimals, go through sats first.
    return inSats * BigInt.from(1000);
  }

  /// Round down to satoshi precision (nearest multiple of 10^(decimals−8)).
  ///
  /// No-op for tokens with ≤ 8 decimals.
  TokenAmount roundDownToSats() {
    if (token.decimals <= 8) return this;
    final factor = BigInt.from(10).pow(token.decimals - 8);
    final remainder = value.remainder(factor);
    if (remainder == BigInt.zero) return this;
    final rounded = value >= BigInt.zero
        ? value - remainder
        : value - (factor + remainder);
    return TokenAmount(value: rounded, token: token);
  }

  /// Round up to satoshi precision (nearest multiple of 10^(decimals−8)).
  ///
  /// No-op for tokens with ≤ 8 decimals.
  TokenAmount roundUpToSats() {
    if (token.decimals <= 8) return this;
    final factor = BigInt.from(10).pow(token.decimals - 8);
    final remainder = value.remainder(factor);
    if (remainder == BigInt.zero) return this;
    final rounded = value >= BigInt.zero
        ? value + (factor - remainder)
        : value - remainder;
    return TokenAmount(value: rounded, token: token);
  }
}

// ── Convenience constants ──────────────────────────────────────────────

/// The RBTC token for Rootstock mainnet (chainId 30).
final rbtc = Token.native(30);

/// 1 sat = 10^10 wei on RBTC (18 - 8 = 10 decimal difference).
final _satToWei = BigInt.from(10).pow(10);

// ── Free-standing factories ────────────────────────────────────────────

/// Construct an RBTC [TokenAmount] from a raw wei value.
TokenAmount rbtcFromWei(BigInt wei) => TokenAmount(value: wei, token: rbtc);

/// Construct an RBTC [TokenAmount] from a count of satoshis.
///
/// If [chainId] is provided, the token will use that chain ID instead of
/// the default Rootstock mainnet (30).
TokenAmount rbtcFromSats(BigInt sats, {int? chainId}) => TokenAmount(
  value: sats * _satToWei,
  token: chainId != null ? Token.native(chainId) : rbtc,
);

/// Construct an RBTC [TokenAmount] from an integer count of satoshis.
///
/// If [chainId] is provided, the token will use that chain ID instead of
/// the default Rootstock mainnet (30).
TokenAmount rbtcFromSatsInt(int sats, {int? chainId}) =>
    rbtcFromSats(BigInt.from(sats), chainId: chainId);

/// Construct a [TokenAmount] from an on-chain EVM token address and raw value.
///
/// If [tokenAddress] is the zero address, this returns a native-token amount
/// for the given [chainId].
///
/// For ERC-20 tokens, decimals are resolved from [tokenDecimals] when
/// provided, otherwise from [knownTokens] denomination heuristics, or
/// falling back to 18.
TokenAmount tokenAmountFromEvm(
  String tokenAddress,
  BigInt value, {
  required int chainId,
  int? tokenDecimals,
  Map<String, TokenConfig> knownTokens = const {},
}) {
  final normalized = tokenAddress.toLowerCase();
  if (normalized == '0x0000000000000000000000000000000000000000') {
    return TokenAmount(value: value, token: Token.native(chainId));
  }
  // Prefer explicitly provided decimals, then fall back to 18.
  final decimals = tokenDecimals ?? 18;
  final token = Token(
    chainId: chainId,
    address: tokenAddress,
    decimals: decimals,
  );
  return TokenAmount(value: value, token: token);
}
