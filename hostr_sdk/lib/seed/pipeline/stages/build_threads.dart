import 'package:models/main.dart';
import 'package:models/stubs/main.dart';

import '../../../util/deterministic_key_derivation.dart';
import '../entity_factory.dart';
import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Stage 4: Build threads in "pending" state — order requests created,
/// but no outcomes (escrow/zap) yet.
///
/// Each guest generates [SeedPipelineConfig.orderRequestsPerGuest]
/// threads (or the per-user override [SeedUserSpec.threadCount]).
///
/// The returned [SeedThread] objects carry their resolved [ThreadStageSpec]
/// so the outcome stage knows how far to progress each one.
///
/// When [now] is provided it is used as the reference timestamp for
/// order date calculations.
Future<List<SeedThread>> buildThreads({
  required SeedContext ctx,
  required SeedPipelineConfig config,
  required List<SeedUser> hosts,
  required List<SeedUser> guests,
  required List<Listing> listings,
  required DateTime now,
  EntityFactory? factory,
}) async {
  final f = factory ?? EntityFactory(ctx: ctx);
  final threads = <SeedThread>[];
  var threadIndex = 0;

  final chainNow = now;

  for (final guest in guests) {
    final threadCount = guest.spec?.threadCount ?? config.orderRequestsPerGuest;
    final stageSpec = guest.spec?.threadStages ?? config.threadStages;
    var guestTradeIndex = 0;

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

      final isFutureOrder = ctx.pickByRatio(0.5);
      final stayDays = 1 + ctx.random.nextInt(6);
      late final DateTime start;
      late final DateTime end;
      if (isFutureOrder) {
        final rawStart = chainNow.add(
          Duration(days: 3 + ctx.random.nextInt(180)),
        );
        start = DateTime.utc(rawStart.year, rawStart.month, rawStart.day);
        end = start.add(Duration(days: stayDays));
      } else {
        final rawEnd = chainNow.subtract(
          Duration(days: 1 + ctx.random.nextInt(180)),
        );
        end = DateTime.utc(rawEnd.year, rawEnd.month, rawEnd.day);
        start = end.subtract(Duration(days: stayDays));
      }

      final requestAuthorKeyPair = await deriveTradeKeyPair(
        guest.keyPair.privateKey!,
        accountIndex: guestTradeIndex,
      );
      final request = await f.order(
        guestKeyPair: guest.keyPair,
        listing: listing,
        start: start,
        end: end,
        stage: OrderStage.negotiate,
        accountIndex: guestTradeIndex,
        createdAt: ctx.timestampDaysAfter(30 + threadIndex),
      );
      final tradeId = request.getDtag()!;
      guestTradeIndex++;

      threads.add(
        SeedThread(
          host: host,
          guest: guest,
          listing: listing,
          request: request,
          guestTradeAccountIndex: guestTradeIndex - 1,
          requestAuthorKeyPair: requestAuthorKeyPair,
          id: tradeId,
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
