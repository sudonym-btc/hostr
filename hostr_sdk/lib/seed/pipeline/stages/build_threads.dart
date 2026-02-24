import 'package:models/main.dart';
import 'package:models/stubs/main.dart';

import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Stage 4: Build threads in "pending" state — reservation requests created,
/// but no outcomes (escrow/zap) yet.
///
/// Each guest generates [SeedPipelineConfig.reservationRequestsPerGuest]
/// threads (or the per-user override [SeedUserSpec.threadCount]).
///
/// The returned [SeedThread] objects carry their resolved [ThreadStageSpec]
/// so the outcome stage knows how far to progress each one.
///
/// When [now] is provided it is used as the reference timestamp for
/// reservation date calculations, avoiding the need for a live chain
/// connection.  If omitted the stage falls back to
/// `ctx.chainClient().getBlockInformation()`.
Future<List<SeedThread>> buildThreads({
  required SeedContext ctx,
  required SeedPipelineConfig config,
  required List<SeedUser> hosts,
  required List<SeedUser> guests,
  required List<Listing> listings,
  DateTime? now,
}) async {
  final threads = <SeedThread>[];
  var threadIndex = 0;

  // Use the caller-supplied timestamp when available so that tests
  // can run without a live EVM node.
  final chainNow =
      now ?? (await ctx.chainClient().getBlockInformation()).timestamp.toUtc();

  for (final guest in guests) {
    final threadCount =
        guest.spec?.threadCount ?? config.reservationRequestsPerGuest;
    final stageSpec = guest.spec?.threadStages ?? config.threadStages;

    for (var i = 0; i < threadCount; i++) {
      threadIndex++;
      final listing = listings[ctx.random.nextInt(listings.length)];
      final host =
          _findUserByPubkey(listing.pubKey, hosts) ??
          SeedUser(
            index: -1,
            keyPair: MockKeys.hoster,
            isHost: true,
            hasEvm: true,
          );

      // Skip self-booking.
      if (host.keyPair.publicKey == guest.keyPair.publicKey) {
        continue;
      }

      final isFutureReservation = ctx.pickByRatio(0.5);
      final stayDays = 1 + ctx.random.nextInt(6);
      late final DateTime start;
      late final DateTime end;
      if (isFutureReservation) {
        start = chainNow.add(Duration(days: 3 + ctx.random.nextInt(180)));
        end = start.add(Duration(days: stayDays));
      } else {
        end = chainNow.subtract(Duration(days: 1 + ctx.random.nextInt(180)));
        start = end.subtract(Duration(days: stayDays));
      }

      final salt = 'seed-${ctx.seed}-thread-$threadIndex';
      final commitmentHash = ParticipationProof.computeCommitmentHash(
        guest.keyPair.publicKey,
        salt,
      );

      final request = ReservationRequest(
        pubKey: guest.keyPair.publicKey,
        tags: ReservationRequestTags([
          [kListingRefTag, listing.anchor!],
          ['d', commitmentHash],
        ]),
        createdAt: ctx.timestampDaysAfter(30 + threadIndex),
        content: ReservationRequestContent(
          start: start,
          end: end,
          quantity: 1,
          amount: listing.cost(start, end),
          salt: salt,
        ),
      ).signAs(guest.keyPair, ReservationRequest.fromNostrEvent);

      threads.add(
        SeedThread(
          host: host,
          guest: guest,
          listing: listing,
          request: request,
          salt: salt,
          commitmentHash: commitmentHash,
          start: start,
          end: end,
          stageSpec: stageSpec,
        ),
      );
    }
  }

  return threads;
}

SeedUser? _findUserByPubkey(String pubkey, List<SeedUser> users) {
  for (final user in users) {
    if (user.keyPair.publicKey == pubkey) return user;
  }
  return null;
}
