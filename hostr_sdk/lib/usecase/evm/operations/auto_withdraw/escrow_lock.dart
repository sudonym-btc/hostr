/// A lock representing an in-flight escrow operation that is currently using
/// (or about to use) the on-chain balance.
///
/// Locks are persisted to disk so a background worker can read them even if
/// the foreground app is not running.
class EscrowLock {
  /// The unique trade identifier for the escrow operation.
  final String tradeId;

  /// Amount of on-chain funds reserved by this escrow operation, stored as
  /// a hex-encoded BigInt (wei).
  final BigInt reservedAmountWei;

  /// When the lock was first acquired.
  final DateTime acquiredAt;

  EscrowLock({
    required this.tradeId,
    required this.reservedAmountWei,
    required this.acquiredAt,
  });

  /// Deserialise from JSON (stored in [KeyValueStorage]).
  factory EscrowLock.fromJson(Map<String, dynamic> json) {
    return EscrowLock(
      tradeId: json['tradeId'] as String,
      reservedAmountWei: BigInt.parse(
        json['reservedAmountWei'] as String,
        radix: 16,
      ),
      acquiredAt: DateTime.fromMillisecondsSinceEpoch(
        json['acquiredAt'] as int,
      ),
    );
  }

  /// Serialise to JSON for disk persistence.
  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    'reservedAmountWei': reservedAmountWei.toRadixString(16),
    'acquiredAt': acquiredAt.millisecondsSinceEpoch,
  };

  @override
  String toString() =>
      'EscrowLock(tradeId: $tradeId, reservedAmountWei: $reservedAmountWei, '
      'acquiredAt: $acquiredAt)';
}
