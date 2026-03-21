/// Unambiguous identity for any asset (native RBTC, ERC-20, or Lightning BTC).
///
/// Serialized to Nostr tags as [tagId]:
/// - BTC Lightning → `"BTC"`
/// - On-chain tokens → `"chainId:address"` (e.g. `"30:0xdAC17..."`)
class Token {
  final int chainId;

  /// Checksummed EIP-55 address for ERC-20 tokens.
  /// `"0x0000000000000000000000000000000000000000"` for native RBTC.
  /// `"lightning"` sentinel for Lightning-Network BTC.
  final String address;

  /// Number of decimal places for the token's smallest unit.
  /// Resolved from a known-token registry or an on-chain `decimals()` call.
  final int decimals;

  const Token({
    required this.chainId,
    required this.address,
    required this.decimals,
  });

  // ── Well-known constants ──────────────────────────────────────────

  /// BTC over Lightning Network (off-chain). 8 decimals (satoshis).
  static const btcLightning = Token(
    chainId: 0,
    address: 'lightning',
    decimals: 8,
  );

  /// Native RBTC on a given EVM chain. 18 decimals (wei).
  static Token rbtc(int chainId) => Token(
        chainId: chainId,
        address: _zeroAddress,
        decimals: 18,
      );

  static const _zeroAddress = '0x0000000000000000000000000000000000000000';

  // ── Predicates ────────────────────────────────────────────────────

  bool get isLightning => address == 'lightning';
  bool get isNative => !isLightning && address.toLowerCase() == _zeroAddress;
  bool get isERC20 => !isLightning && !isNative;

  // ── Serialization ─────────────────────────────────────────────────

  /// Compact string used in Nostr tags.
  ///
  /// - `"BTC"` for Lightning
  /// - `"30:0xdAC17..."` for on-chain tokens (chainId:address)
  String get tagId => isLightning ? 'BTC' : '$chainId:$address';

  /// Parse a [tagId] string back into a [Token].
  ///
  /// Requires [decimals] because tag IDs don't carry precision info.
  /// Use the known-token registry or an on-chain call to resolve decimals.
  static Token fromTagId(String tagId, {required int decimals}) {
    if (tagId == 'BTC') return btcLightning;
    final sep = tagId.indexOf(':');
    if (sep == -1) {
      throw FormatException('Invalid token tag ID: $tagId');
    }
    final chainId = int.parse(tagId.substring(0, sep));
    final address = tagId.substring(sep + 1);
    return Token(chainId: chainId, address: address, decimals: decimals);
  }

  // ── JSON ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'chainId': chainId,
        'address': address,
        'decimals': decimals,
      };

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        chainId: json['chainId'] as int,
        address: json['address'] as String,
        decimals: json['decimals'] as int,
      );

  // ── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          chainId == other.chainId &&
          address.toLowerCase() == other.address.toLowerCase();

  @override
  int get hashCode => chainId.hashCode ^ address.toLowerCase().hashCode;

  @override
  String toString() => 'Token($tagId, decimals: $decimals)';
}
