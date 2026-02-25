import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../seed_context.dart';
import '../seed_pipeline_models.dart';

/// Stage 6: Build NIP-17 gift-wrapped DM messages for threads.
///
/// Each thread gets:
///   1. The reservation request message
///   2. N filler messages based on [ThreadStageSpec.textMessageCount]
///
/// Escrow-selected messages (which depend on outcome data) are built
/// separately via [buildEscrowSelectedMessages].
Future<List<Nip01Event>> buildMessages({
  required SeedContext ctx,
  required List<SeedThread> threads,
}) async {
  final messages = <Nip01Event>[];
  var wrapCount = 0;
  var lastLoggedPct = -1;
  final sw = Stopwatch()..start();

  // Each thread produces 2 wraps per message (one per participant):
  //   1 reservation-request + textMessageCount filler messages.
  var totalExpected = 0;
  for (final thread in threads) {
    totalExpected += 2 * (1 + thread.stageSpec.textMessageCount);
  }

  void _logProgress({bool force = false}) {
    final pct = totalExpected > 0 ? (wrapCount * 100 ~/ totalExpected) : 100;
    if (force || (pct ~/ 5) > (lastLoggedPct ~/ 5)) {
      print(
        '[seed][giftwrap] buildMessages: $pct% '
        '($wrapCount/$totalExpected giftwraps, '
        '${sw.elapsedMilliseconds} ms)',
      );
      lastLoggedPct = pct;
    }
  }

  final giftWrapNdk = _createGiftWrapNdk();

  try {
    for (var i = 0; i < threads.length; i++) {
      final thread = threads[i];
      final threadAnchor = thread.request.getDtag()!;

      // 1. Reservation request message.
      final requestMessageWraps = await _giftWrapDmForParticipants(
        ndk: giftWrapNdk,
        sender: thread.guest,
        recipient: thread.host,
        tags: [
          [kThreadRefTag, threadAnchor],
          ['p', thread.host.keyPair.publicKey],
        ],
        createdAt: ctx.timestampDaysAfter(40 + i),
        content: thread.request.toString(),
      );
      messages.addAll(requestMessageWraps);
      wrapCount += requestMessageWraps.length;
      _logProgress();

      // 2. Filler text messages.
      final msgCount = thread.stageSpec.textMessageCount;
      for (var m = 0; m < msgCount; m++) {
        final fromGuest = m.isEven;
        final sender = fromGuest ? thread.guest : thread.host;
        final recipient = fromGuest ? thread.host : thread.guest;

        final wraps = await _giftWrapDmForParticipants(
          ndk: giftWrapNdk,
          sender: sender,
          recipient: recipient,
          tags: [
            [kThreadRefTag, threadAnchor],
            ['p', recipient.keyPair.publicKey],
          ],
          createdAt: ctx.timestampDaysAfter(41 + i + m),
          content: 'Seed message ${m + 1} for thread ${i + 1}',
        );
        messages.addAll(wraps);
        wrapCount += wraps.length;
        _logProgress();
      }

      // Yield to the event loop every 10 threads so that concurrent
      // async work (e.g. chain HTTP calls in buildOutcomes) can make
      // progress. Gift-wrapping is CPU-heavy and would otherwise
      // starve the single-threaded Dart event loop.
      if (i % 10 == 9) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    _logProgress(force: true);
    return messages;
  } finally {
    await giftWrapNdk.destroy();
  }
}

/// Build escrow-selected DM messages for threads that completed via escrow.
///
/// Must run **after** [buildOutcomes] so that [SeedThread.paidViaEscrow]
/// and [SeedThread.reservation] are populated.
Future<List<Nip01Event>> buildEscrowSelectedMessages({
  required SeedContext ctx,
  required List<SeedThread> threads,
}) async {
  final messages = <Nip01Event>[];
  var wrapCount = 0;
  var lastLoggedPct = -1;
  final sw = Stopwatch()..start();

  // 2 wraps per qualifying escrow thread.
  var totalExpected = 0;
  for (final thread in threads) {
    if (!thread.paidViaEscrow || thread.reservation == null) continue;
    if (thread.reservation!.parsedContent.proof?.escrowProof == null) continue;
    totalExpected += 2;
  }

  void _logProgress({bool force = false}) {
    final pct = totalExpected > 0 ? (wrapCount * 100 ~/ totalExpected) : 100;
    if (force || (pct ~/ 5) > (lastLoggedPct ~/ 5)) {
      print(
        '[seed][giftwrap] buildEscrowSelectedMessages: $pct% '
        '($wrapCount/$totalExpected giftwraps, '
        '${sw.elapsedMilliseconds} ms)',
      );
      lastLoggedPct = pct;
    }
  }

  final giftWrapNdk = _createGiftWrapNdk();

  try {
    for (var i = 0; i < threads.length; i++) {
      final thread = threads[i];
      if (!thread.paidViaEscrow || thread.reservation == null) continue;

      final escrowProof = thread.reservation!.parsedContent.proof?.escrowProof;
      if (escrowProof == null) continue;

      final threadAnchor = thread.request.getDtag()!;

      final selectedEscrow = EscrowServiceSelected(
        pubKey: thread.guest.keyPair.publicKey,
        tags: EscrowServiceSelectedTags([
          [kListingRefTag, thread.listing.anchor!],
          [kThreadRefTag, threadAnchor],
          ['p', thread.host.keyPair.publicKey],
          ['d', 'seed-escrow-selected-${i + 1}'],
        ]),
        createdAt: ctx.timestampDaysAfter(40 + i),
        content: EscrowServiceSelectedContent(
          service: escrowProof.escrowService,
          sellerTrusts: escrowProof.hostsTrustedEscrows,
          sellerMethods: escrowProof.hostsEscrowMethods,
        ),
      ).signAs(thread.guest.keyPair, EscrowServiceSelected.fromNostrEvent);

      final wraps = await _giftWrapDmForParticipants(
        ndk: giftWrapNdk,
        sender: thread.guest,
        recipient: thread.host,
        tags: [
          [kThreadRefTag, threadAnchor],
          ['p', thread.host.keyPair.publicKey],
        ],
        createdAt: ctx.timestampDaysAfter(41 + i),
        content: selectedEscrow.toString(),
      );
      messages.addAll(wraps);
      wrapCount += wraps.length;
      _logProgress();
    }

    _logProgress(force: true);
    return messages;
  } finally {
    await giftWrapNdk.destroy();
  }
}

Ndk _createGiftWrapNdk() => Ndk(
  NdkConfig(
    eventVerifier: Bip340EventVerifier(),
    cache: MemCacheManager(),
    engine: NdkEngine.JIT,
    bootstrapRelays: [], // No relay needed — gift-wrapping is local crypto.
  ),
);

// ─── Gift-wrap helpers ──────────────────────────────────────────────────────

Future<List<Nip01Event>> _giftWrapDmForParticipants({
  required Ndk ndk,
  required SeedUser sender,
  required SeedUser recipient,
  required List<List<String>> tags,
  required int createdAt,
  required String content,
}) async {
  _ensureLoggedInAsSender(ndk: ndk, sender: sender);

  final rumor = Nip01Event(
    pubKey: sender.keyPair.publicKey,
    kind: kNostrKindDM,
    tags: tags,
    createdAt: createdAt,
    content: content,
  );

  final toRecipient = await ndk.giftWrap.toGiftWrap(
    rumor: rumor,
    recipientPubkey: recipient.keyPair.publicKey,
  );
  final toSender = await ndk.giftWrap.toGiftWrap(
    rumor: rumor,
    recipientPubkey: sender.keyPair.publicKey,
  );

  return [toRecipient, toSender];
}

void _ensureLoggedInAsSender({required Ndk ndk, required SeedUser sender}) {
  final pubkey = sender.keyPair.publicKey;
  final privkey = sender.keyPair.privateKey!;

  if (ndk.accounts.hasAccount(pubkey)) {
    ndk.accounts.switchAccount(pubkey: pubkey);
    return;
  }

  ndk.accounts.loginPrivateKey(pubkey: pubkey, privkey: privkey);
}
