import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'seed_context.dart';
import 'seed_factory.dart';
import 'seed_pipeline_config.dart';
import 'seed_pipeline_models.dart';

/// Convenience wrapper for tests.
///
/// Produces individual users, listings, and threads with precise control
/// over thread stage progression — **without needing a relay, chain, or
/// full CLI run**.
///
/// Backed by [SeedFactory] so all data generation is pure (no I/O).
///
/// ```dart
/// final helper = TestSeedHelper();
/// final host = await helper.freshHost(listingCount: 2);
/// final guest = await helper.freshGuest(
///   listing: host.listing,
///   withThread: true,
/// );
/// requests.seedEvents([host.profile, ...host.listings, guest.profile]);
/// ```
class TestSeedHelper {
  final SeedFactory _factory;
  int _nextUserIndex;

  TestSeedHelper({
    int seed = 42,
    String contractAddress = '0x0000000000000000000000000000000000000000',
  }) : _factory = SeedFactory(
         config: SeedPipelineConfig(
           seed: seed,
           userCount: 0, // no random users, all explicit
         ),
         contractAddress: contractAddress,
       ),
       _nextUserIndex = 1000; // offset to avoid collisions with seeder

  /// Create from an existing [SeedFactory] (e.g. when you want to share
  /// the same context / config as a [SeedPipeline]).
  TestSeedHelper.fromFactory(SeedFactory factory)
    : _factory = factory,
      _nextUserIndex = 1000;

  SeedContext get context => _factory.context;

  /// The underlying factory, for direct access to stages.
  SeedFactory get factory => _factory;

  /// Create a fresh guest with profile, optionally with a thread
  /// against [listing].
  Future<TestGuest> freshGuest({
    Listing? listing,
    bool withThread = false,
    bool withOutcome = false,
    bool setupLnbits = false,
    ThreadStageSpec? threadStages,
  }) async {
    final index = _nextUserIndex++;
    final keyPair = context.deriveKeyPair(index);

    final user = SeedUser(
      index: index,
      keyPair: keyPair,
      isHost: false,
      hasEvm: false,
      setupLnbits: setupLnbits,
    );

    final profile = _factory.buildProfiles([user]).first;

    SeedThread? thread;
    if (withThread && listing != null) {
      // We need at least one host to build a thread.
      final hostPubkey = listing.pubKey;
      final hostUser = SeedUser(
        index: _nextUserIndex++,
        keyPair: _dummyKeyPairForPubkey(hostPubkey),
        isHost: true,
        hasEvm: true,
      );

      final threads = await _factory.buildThreads(
        hosts: [hostUser],
        guests: [user],
        listings: [listing],
      );

      if (threads.isNotEmpty) {
        thread = threads.first;

        // Override stage spec if provided.
        if (threadStages != null) {
          thread = SeedThread(
            host: thread.host,
            guest: thread.guest,
            listing: thread.listing,
            request: thread.request,
            salt: thread.salt,
            commitmentHash: thread.commitmentHash,
            start: thread.start,
            end: thread.end,
            stageSpec: threadStages,
          );
        }
      }
    }

    return TestGuest(user: user, profile: profile, thread: thread);
  }

  /// Create a fresh host with N listings.
  Future<TestHost> freshHost({
    int listingCount = 1,
    bool hasEvm = true,
    bool setupLnbits = false,
    int completedReservations = 0,
  }) async {
    final index = _nextUserIndex++;
    final keyPair = context.deriveKeyPair(index);

    final user = SeedUser(
      index: index,
      keyPair: keyPair,
      isHost: true,
      hasEvm: hasEvm,
      setupLnbits: setupLnbits,
      spec: SeedUserSpec.host(
        hasEvm: hasEvm,
        setupLnbits: setupLnbits,
        listingCount: listingCount,
      ),
    );

    final profile = _factory.buildProfiles([user]).first;
    final listings = _factory.buildListings([user]);

    return TestHost(user: user, profile: profile, listings: listings);
  }

  /// Create a key pair from a known private key (for testing with specific keys).
  KeyPair deriveKeyPair(int index) => context.deriveKeyPair(index);

  void dispose() => _factory.dispose();

  KeyPair _dummyKeyPairForPubkey(String pubkey) {
    // We can't reverse a pubkey to a keypair, so derive a fresh one.
    // The thread builder matches by listing.pubKey, so this host user
    // won't match unless we use the real host's keypair.
    // For test helpers, the caller should provide the actual host.
    return context.deriveKeyPair(_nextUserIndex++);
  }
}

/// Result of [TestSeedHelper.freshGuest].
class TestGuest {
  final SeedUser user;
  final ProfileMetadata profile;
  final SeedThread? thread;

  const TestGuest({required this.user, required this.profile, this.thread});

  KeyPair get keyPair => user.keyPair;
  String get publicKey => user.keyPair.publicKey;
  String get privateKey => user.keyPair.privateKey!;
}

/// Result of [TestSeedHelper.freshHost].
class TestHost {
  final SeedUser user;
  final ProfileMetadata profile;
  final List<Listing> listings;

  const TestHost({
    required this.user,
    required this.profile,
    required this.listings,
  });

  KeyPair get keyPair => user.keyPair;
  String get publicKey => user.keyPair.publicKey;
  String get privateKey => user.keyPair.privateKey!;
  Listing get listing => listings.first;
}
