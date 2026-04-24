/// Pre-computed deterministic seed data for all widgetbook use cases.
///
/// Initialised once via [initSeedData] in `main()` before `runApp`.
/// Use cases then access the top-level getters synchronously.
library;

import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/requests/in_memory.requests.dart';
import 'package:models/main.dart';

export 'package:models/stubs/keypairs.dart' show MockKeys;

// ─── Lazy-initialised state ─────────────────────────────────────────────────

late final SeedPipelineData _data;
late final SeedFactory _factory;
late final List<ThreadScenario> _threadScenarios;

/// Call once in `main()` before `runApp`.
Future<void> initSeedData() async {
  _factory = SeedFactory(
    config: SeedPipelineConfig(
      seed: 1,
      userCount: 2,
      hostRatio: 0.5,
      hostHasEvmRatio: 0,
      setupLnbits: false,
      listingsPerHostAvg: 1.0,
      reservationRequestsPerGuest: 1,
      threadStages: const ThreadStageSpec.pendingOnly(textMessageCount: 1),
    ),
  );
  _data = await _factory.buildAll();

  final requests = getIt<Hostr>().requests;
  if (requests is InMemoryRequests) {
    requests.seedEvents(_data.allEvents);
  }

  // Build mock reservations for threads that have outcomes.
  final hostProfileByPubkey = <String, ProfileMetadata>{
    for (final p in _data.profiles) p.pubKey: p,
  };

  _threadScenarios = _data.threads.map((thread) {
    final hostProfile = hostProfileByPubkey[thread.host.keyPair.publicKey];
    Reservation? reservation;
    if (hostProfile != null) {
      reservation = _factory.buildMockReservation(
        thread,
        hostProfile: hostProfile,
      );
    }

    return ThreadScenario(
      id: thread.request.getDtag()!,
      thread: thread,
      reservation: reservation,
    );
  }).toList();

  _factory.dispose();
}

// ─── Public accessors ───────────────────────────────────────────────────────

/// All generated seed data.
SeedPipelineData get seedData => _data;

/// Deterministic listings from the seed factory.
List<Listing> get mockListings => _data.listings;

/// Deterministic profile metadata events.
List<ProfileMetadata> get mockProfiles => _data.profiles;

/// Deterministic reservations (one per thread, mock-signed).
List<Reservation> get mockReservations => _threadScenarios
    .where((s) => s.reservation != null)
    .map((s) => s.reservation!)
    .toList();

/// Thread scenarios with all the fields widgetbook use cases expect.
List<ThreadScenario> get mockThreadScenarios => _threadScenarios;

// ─── Thread scenario adapter ────────────────────────────────────────────────

/// Wraps a [SeedThread] with the API that widgetbook use cases expect:
///
/// - [id] — unique scenario identifier (d-tag of the reservation request)
/// - [threadAnchor] — the Nostr thread anchor string
/// - [requestMessage] — the reservation request wrapped as a [Message]
/// - [listing] — the listing this thread references
/// - [reservationRequest] — the negotiate-stage reservation event
/// - [reservations] — list with the mock reservation (if any)
class ThreadScenario {
  final String id;
  final SeedThread thread;
  final Reservation? reservation;

  const ThreadScenario({
    required this.id,
    required this.thread,
    this.reservation,
  });

  String get threadAnchor => thread.request.getDtag() ?? id;

  Message get requestMessage =>
      Message.fromNostrEvent(thread.request, thread.request);

  Listing get listing => thread.listing;

  Reservation get reservationRequest => thread.request;

  List<Reservation> get reservations =>
      reservation != null ? [reservation!] : [];
}
