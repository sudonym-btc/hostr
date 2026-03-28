import 'package:models/main.dart';
import 'package:wallet/wallet.dart';

/// A balance update for a single tracked address.
///
/// Emitted by [EvmBalanceMonitor] whenever a native or ERC-20 balance is
/// first fetched or changes.
class BalanceUpdate {
  /// The address whose balance changed.
  final EthereumAddress address;

  /// The token — either native (zero-address) or an ERC-20 contract.
  final Token token;

  /// The new balance.
  final TokenAmount balance;

  /// The block number at which this balance was observed.
  final int blockNumber;

  const BalanceUpdate({
    required this.address,
    required this.token,
    required this.balance,
    required this.blockNumber,
  });

  /// Cache key for dedup / diff.
  (String, String) get cacheKey =>
      (address.eip55With0x.toLowerCase(), token.address.toLowerCase());

  @override
  String toString() =>
      'BalanceUpdate(${address.eip55With0x}, ${token.address}, '
      '${balance.value}, block=$blockNumber)';
}

/// Identifies a tracked address and what to monitor for it.
class TrackedAddress {
  final EthereumAddress address;

  /// When set, an identifier for why this address is tracked (e.g. trade ID).
  /// Useful for logging and debugging.
  final String? reason;

  const TrackedAddress({required this.address, this.reason});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedAddress &&
          address.eip55With0x.toLowerCase() ==
              other.address.eip55With0x.toLowerCase();

  @override
  int get hashCode => address.eip55With0x.toLowerCase().hashCode;
}

/// The status of the monitor's connection / processing state.
enum MonitorMode {
  /// Idle — nothing being tracked.
  idle,

  /// Performing initial snapshot for newly tracked addresses/tokens.
  syncing,

  /// Actively processing block ticks.
  live,

  /// The monitor has been stopped.
  stopped,
}
