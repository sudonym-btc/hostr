import 'package:models/main.dart';

import 'config/evm_config.dart';

/// Resolved display metadata for a token.
///
/// Used by format functions to render amounts with the correct symbol
/// and decimal precision.
class TokenDisplayInfo {
  /// Human-readable denomination (e.g. `"BTC"`, `"USD"`).
  final String denomination;

  /// Currency symbol used as prefix (e.g. `"₿"`, `"$"`).
  final String symbol;

  /// Whether amounts should be displayed as integer smallest-units
  /// (e.g. satoshis for BTC) rather than decimal major-units.
  final bool showAsSmallestUnit;

  const TokenDisplayInfo({
    required this.denomination,
    required this.symbol,
    this.showAsSmallestUnit = false,
  });

  /// BTC-family display: ₿ prefix, amounts shown in sats.
  static const btc = TokenDisplayInfo(
    denomination: 'BTC',
    symbol: '₿',
    showAsSmallestUnit: true,
  );

  /// USD-family display: $ prefix, amounts shown with 2 decimal places.
  static const usd = TokenDisplayInfo(denomination: 'USD', symbol: '\$');

  /// ETH-family display: Ξ prefix, amounts shown as decimal ether.
  static const eth = TokenDisplayInfo(denomination: 'ETH', symbol: 'Ξ');
}

/// Resolves display information for tokens using chain configuration.
///
/// Stateless — constructed from [EvmChainConfig] list. Suitable for
/// injection via provider or direct construction.
///
/// ```dart
/// final resolver = TokenDisplayResolver(evm.configuredChains.map((c) => c.config));
/// final info = resolver.resolve(someToken);
/// ```
class TokenDisplayResolver {
  final List<EvmChainConfig> _configs;

  /// Well-known denomination → display info.
  static const _knownDenominations = <String, TokenDisplayInfo>{
    'BTC': TokenDisplayInfo.btc,
    'USD': TokenDisplayInfo.usd,
    'ETH': TokenDisplayInfo.eth,
  };

  TokenDisplayResolver(Iterable<EvmChainConfig> configs)
    : _configs = configs.toList(growable: false);

  /// Resolve display info for a [Token].
  ///
  /// Resolution order:
  /// 1. Lightning / native → BTC
  /// 2. Config-based denomination lookup (by chain ID + address)
  /// 3. Fallback: unknown token with empty symbol
  TokenDisplayInfo resolve(Token token) {
    if (token.isNative) {
      for (final config in _configs) {
        if (config.chainId == token.chainId) {
          final d = config.nativeDenomination;
          return _knownDenominations[d] ??
              TokenDisplayInfo(denomination: d, symbol: '');
        }
      }
      return TokenDisplayInfo.btc; // fallback
    }

    final denomination = _denominationOf(token);
    if (denomination != null) {
      return _knownDenominations[denomination] ??
          TokenDisplayInfo(denomination: denomination, symbol: '');
    }

    return const TokenDisplayInfo(denomination: '', symbol: '');
  }

  /// Resolve display info from a denomination string directly.
  ///
  /// Useful when you already have the denomination (e.g. from
  /// [DenominatedAmount] or [AcceptedPaymentForm]).
  TokenDisplayInfo resolveFromDenomination(String denomination) {
    return _knownDenominations[denomination] ??
        TokenDisplayInfo(denomination: denomination, symbol: '');
  }

  /// Look up the denomination for a token from chain configs.
  String? _denominationOf(Token token) {
    for (final config in _configs) {
      if (config.chainId == token.chainId) {
        final tokenConfig = config.tokenByAddress(token.address);
        if (tokenConfig != null) return tokenConfig.denomination;
      }
    }
    return null;
  }
}
