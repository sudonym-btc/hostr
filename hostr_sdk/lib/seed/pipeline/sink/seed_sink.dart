import 'package:ndk/ndk.dart';

import '../seed_pipeline_models.dart';

// ─── Intent types ───────────────────────────────────────────────────────────

/// Result of a chain operation (trade creation or settlement).
class TradeResult {
  final String txHash;
  final bool alreadyExisted;

  const TradeResult({required this.txHash, this.alreadyExisted = false});
}

/// Intent to submit a new escrow trade on-chain.
class SubmitTrade {
  final String tradeId;
  final String buyerPrivateKey;
  final String sellerPrivateKey;
  final String arbiterPrivateKey;
  final BigInt amountWei;
  final BigInt unlockAt;

  const SubmitTrade({
    required this.tradeId,
    required this.buyerPrivateKey,
    required this.sellerPrivateKey,
    required this.arbiterPrivateKey,
    required this.amountWei,
    required this.unlockAt,
  });
}

/// Intent to settle an existing escrow trade (claim / arbitrate / release).
class SettleTrade {
  final String tradeId;
  final EscrowOutcome outcome;

  /// Private key of the settler (host for claim/release, arbiter for arbitrate).
  final String settlerPrivateKey;

  const SettleTrade({
    required this.tradeId,
    required this.outcome,
    required this.settlerPrivateKey,
  });
}

/// Intent to fund an EVM address.
class FundWallet {
  final String address;
  final BigInt amountWei;

  const FundWallet({required this.address, required this.amountWei});
}

/// Intent to register a NIP-05 / LUD-16 identity.
class RegisterIdentity {
  final String username;
  final String domain;
  final String pubkey;

  const RegisterIdentity({
    required this.username,
    required this.domain,
    required this.pubkey,
  });
}

// ─── Port ───────────────────────────────────────────────────────────────────

/// The port through which the seeder pushes side effects.
///
/// Every method takes a single instruction. The implementation decides
/// whether to execute immediately, buffer, rate-limit, etc.
///
/// Chain-op methods return a [TradeResult] because the seeder needs
/// feedback (tx hash) to build downstream events. Event/identity/fund
/// methods are fire-and-forget from the seeder's perspective (the sink
/// may still await delivery internally).
abstract class SeedSink {
  /// Publish a single Nostr event.
  Future<void> publish(Nip01Event event);

  /// Submit a new trade to the escrow contract. Returns the tx hash.
  Future<TradeResult> submitTrade(SubmitTrade intent);

  /// Settle an existing trade (claim / arbitrate / release).
  Future<TradeResult> settleTrade(SettleTrade intent);

  /// Fund an EVM address.
  Future<void> fund(FundWallet intent);

  /// Register a NIP-05 / LUD-16 identity.
  Future<void> registerIdentity(RegisterIdentity intent);
}
