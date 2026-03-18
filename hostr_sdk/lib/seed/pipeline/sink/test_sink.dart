import 'package:ndk/ndk.dart';

import '../fake/fake_escrow_ledger.dart';
import '../fake/fake_identity_registry.dart';
import 'seed_sink.dart';

/// In-memory [SeedSink] for unit / widget / screenshot tests.
///
/// Stores every published event in [events] and delegates chain ops
/// to [FakeEscrowLedger] + [FakeIdentityRegistry].
///
/// After `Seeder.seed(sink)` completes, inject the collected events
/// into your test's request store:
///
/// ```dart
/// final sink = TestSink();
/// final data = await seeder.seed(sink);
/// requests.seedEvents(sink.events);
/// ```
class TestSink implements SeedSink {
  /// In-memory escrow state.
  final FakeEscrowLedger escrow;

  /// In-memory identity mappings.
  final FakeIdentityRegistry identities;

  /// Every [Nip01Event] that was published through this sink.
  final List<Nip01Event> events = [];

  /// Optional callback fired for each publish — useful for assertions
  /// that need to observe publication order.
  final void Function(Nip01Event)? onPublish;

  TestSink({
    FakeEscrowLedger? escrow,
    FakeIdentityRegistry? identities,
    this.onPublish,
  }) : escrow = escrow ?? FakeEscrowLedger(),
       identities = identities ?? FakeIdentityRegistry();

  @override
  Future<void> publish(Nip01Event event) async {
    events.add(event);
    onPublish?.call(event);
  }

  @override
  Future<TradeResult> submitTrade(SubmitTrade intent) async {
    return escrow.createTrade(intent);
  }

  @override
  Future<TradeResult> settleTrade(SettleTrade intent) async {
    return escrow.settle(intent);
  }

  @override
  Future<void> fund(FundWallet intent) async {
    escrow.setBalance(intent.address, intent.amountWei);
  }

  @override
  Future<void> registerIdentity(RegisterIdentity intent) async {
    identities.register(
      username: intent.username,
      domain: intent.domain,
      pubkey: intent.pubkey,
    );
  }

  /// Reset all stored state (events, escrow, identities).
  void reset() {
    events.clear();
    escrow.reset();
    identities.reset();
  }
}
