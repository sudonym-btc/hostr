import 'dart:math';

import 'package:models/main.dart';

import '../entity_factory.dart';
import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Returns a deterministic, per-listing [Random] that is seeded exclusively
/// from [seed] and [listingIndex].
///
/// This isolation means that changing [SeedPipelineConfig.userCount] (which
/// shifts the global [SeedContext.random] stream via [buildUsers]) cannot
/// alter listing content such as the daily price.  The same pattern is used
/// by [SeedContext.deriveKeyPair].
Random _listingRng(int seed, int listingIndex) =>
    Random(seed * 10000 + listingIndex);

/// Per-host isolated [Random] used only to decide how many listings a host
/// produces.  Seeded from [seed] and [hostIndex] so the count is stable
/// even when the global RNG stream shifts.
Random _hostRng(int seed, int hostIndex) =>
    Random(seed * 100000 + hostIndex * 1000 + 77777);

/// Like [SeedContext.sampleAverage] but operates on a caller-supplied [Random]
/// so it does not consume the shared [SeedContext.random] stream.
int _sampleAverage(Random r, double avg) {
  if (avg <= 0) return 0;
  final base = avg.floor();
  final remainder = avg - base;
  return base + (r.nextDouble() < remainder ? 1 : 0);
}

/// Stage 3: Build listing events (kind 32121) for host users.
///
/// Respects per-user [SeedUserSpec.listingCount] overrides and falls back
/// to the global [SeedPipelineConfig.listingsPerHostAvg].
///
/// All per-listing randomness is drawn from an isolated [_listingRng] seeded
/// by `(ctx.seed, listingIndex)`, so listing content — especially the daily
/// price used for on-chain escrow deposits — is stable across re-runs even
/// when [SeedPipelineConfig.userCount] changes.
List<Listing> buildListings({
  required SeedContext ctx,
  required SeedPipelineConfig config,
  required List<SeedUser> hosts,
  EntityFactory? factory,
}) {
  final f = factory ?? EntityFactory(ctx: ctx);
  final listings = <Listing>[];
  var listingIndex = 0;

  for (var hostIndex = 0; hostIndex < hosts.length; hostIndex++) {
    final host = hosts[hostIndex];

    // Use a per-host isolated RNG so the listing count for each host is
    // stable regardless of shifts in the global ctx.random stream.
    final hr = _hostRng(ctx.seed, hostIndex);
    final count =
        host.spec?.listingCount ??
        _sampleAverage(hr, config.listingsPerHostAvg);

    for (var i = 0; i < count; i++) {
      listingIndex++;

      // Isolated per-listing RNG – all content drawn from here so that
      // changing userCount (which shifts ctx.random via buildUsers) cannot
      // alter listing prices or other on-chain-relevant attributes.
      final lr = _listingRng(ctx.seed, listingIndex);

      final instantBook =
          host.hasEvm &&
          lr.nextDouble() < config.threadStages.paidViaEscrowRatio;

      // Build the price list — always include a BTC price, and add a USDT
      // price for ~25% of listings when a USDT contract address is configured.
      final dailySats = 50 * 1000 + lr.nextInt(200 * 1000);
      final addUsdt = config.usdtAddress != null && lr.nextDouble() < 0.25;
      // $20–$149 per day expressed in USDT micro-units (config.usdtDecimals).
      final usdtDailyUnits = addUsdt
          ? (20 + lr.nextInt(130)) * pow(10, config.usdtDecimals).toInt()
          : 0;

      final listing = f.listing(
        signer: host.keyPair,
        dTag: 'seed-listing-$listingIndex',
        seed: listingIndex,
        price: [
          Price(
            amount: DenominatedAmount(
              value: BigInt.from(dailySats),
              denomination: 'BTC',
              decimals: 8,
            ),
            frequency: Frequency.daily,
          ),
          if (addUsdt)
            Price(
              amount: DenominatedAmount(
                value: BigInt.from(usdtDailyUnits),
                denomination: 'USD',
                decimals: config.usdtDecimals,
              ),
              frequency: Frequency.daily,
            ),
        ],
        quantity: 1 + lr.nextInt(2),
        instantBook: instantBook,
        extraTags: [
          ['d', count.toString()],
        ],
        createdAt: ctx.timestampDaysAfter(listingIndex),
        rng: lr,
      );

      listings.add(listing);
    }
  }
  return listings;
}
