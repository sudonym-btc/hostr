import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/requests/in_memory.requests.dart';
import 'package:ndk/ndk.dart' show Nip01Event;

/// Convenience helpers for seeding [InMemoryRequests] with deterministic
/// data from [SeedFactory] / [TestSeedHelper].
///
/// ## Quick start — bulk seed
///
/// ```dart
/// final seeder = AppTestSeeder();
/// final data = await seeder.seedAll(requests);
/// // requests is now populated with profiles, listings, threads, etc.
/// ```
///
/// ## Surgical — specific entities
///
/// ```dart
/// final seeder = AppTestSeeder();
/// final host = await seeder.helper.freshHost(listingCount: 2);
/// final guest = await seeder.helper.freshGuest(
///   listing: host.listing,
///   withThread: true,
/// );
/// seeder.injectEvents(requests, [
///   host.profile,
///   ...host.listings,
///   guest.profile,
///   if (guest.thread != null) guest.thread!.request,
/// ]);
/// ```
class AppTestSeeder {
  /// The underlying helper for creating individual entities.
  final TestSeedHelper helper;

  /// The underlying factory for running full stages.
  SeedFactory get factory => helper.factory;

  AppTestSeeder({int seed = 42}) : helper = TestSeedHelper(seed: seed);

  /// Create from a custom [SeedPipelineConfig].
  AppTestSeeder.withConfig(SeedPipelineConfig config)
    : helper = TestSeedHelper.fromFactory(SeedFactory(config: config));

  /// Build all pure-data stages and inject into [requests].
  ///
  /// Returns the [SeedPipelineData] for assertions / further use.
  Future<SeedPipelineData> seedAll(
    InMemoryRequests requests, {
    DateTime? now,
  }) async {
    final data = await factory.buildAll(now: now);
    requests.seedEvents(data.allEvents);
    return data;
  }

  /// Build all stages with a custom [SeedPipelineConfig] and inject.
  static Future<SeedPipelineData> seedWithConfig(
    InMemoryRequests requests,
    SeedPipelineConfig config, {
    DateTime? now,
  }) async {
    final factory = SeedFactory(config: config);
    try {
      final data = await factory.buildAll(now: now);
      requests.seedEvents(data.allEvents);
      return data;
    } finally {
      factory.dispose();
    }
  }

  /// Inject a list of events into [requests].
  void injectEvents(InMemoryRequests requests, List<Nip01Event> events) {
    requests.seedEvents(events);
  }

  void dispose() => helper.dispose();
}
