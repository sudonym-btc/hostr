/// Named units for constructing [TokenAmount] values.
///
/// Follows the same pattern as `EtherUnit` from the `web3dart` package,
/// but generalised for any [Token]. Each variant defines a fixed number
/// of decimal places; the [TokenAmount] factories scale the input to the
/// token's actual precision.
///
/// ```dart
/// // 200 000 sats → scaled to RBTC wei (18 decimals)
/// TokenAmount.fromInt(TokenUnit.sat, 200000, rbtcToken);
///
/// // Raw wei value, no scaling
/// TokenAmount.fromBigInt(TokenUnit.wei, weiValue, rbtcToken);
/// ```
enum TokenUnit {
  /// The token's smallest indivisible unit — no scaling is applied.
  ///
  /// Equivalent to `EtherUnit.wei` for Ether. For RBTC this is wei
  /// (10⁻¹⁸), for BTC-denominated tokens this is satoshis (10⁻⁸).
  wei(0),

  /// Satoshi — 8 decimal places.
  ///
  /// The standard Bitcoin denomination. When the target token has more
  /// than 8 decimals (e.g. RBTC with 18), the value is scaled up by
  /// `10^(token.decimals − 8)`. When fewer, it is scaled down.
  sat(8),

  /// Gwei — 9 decimal places.
  ///
  /// Commonly used for EVM gas prices (10⁹ wei = 1 gwei).
  gwei(9);

  /// The number of decimal places this unit represents.
  ///
  /// A value of `0` means the input is already in the token's smallest
  /// unit and no scaling is needed.
  final int decimals;

  const TokenUnit(this.decimals);
}
