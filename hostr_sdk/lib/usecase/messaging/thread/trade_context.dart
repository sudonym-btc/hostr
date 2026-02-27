import 'package:models/main.dart';

/// Role of the local user in a trade.
enum ThreadPartyRole { host, guest }

/// Derives the local party's role from the listing's host pubkey.
ThreadPartyRole getRole({
  required String hostPubkey,
  required String ourPubkey,
}) {
  return hostPubkey == ourPubkey ? ThreadPartyRole.host : ThreadPartyRole.guest;
}

/// Immutable context resolved once before trade subscriptions start.
/// Contains everything that depends on the listing fetch, so downstream
/// classes (TradeSubscriptions, ThreadPaymentProofOrchestrator) can be
/// constructed synchronously once context is available.
class TradeContext {
  final Listing listing;
  final ProfileMetadata profile;
  final ThreadPartyRole role;

  const TradeContext({
    required this.listing,
    required this.profile,
    required this.role,
  });
}
