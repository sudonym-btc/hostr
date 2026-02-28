import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../seed_context.dart';
import '../seed_pipeline_models.dart';

/// Seeded conversation templates.
///
/// Each entry is one coherent back-and-forth exchange. Messages alternate
/// guest → host → guest → host …, so even indices are always from the
/// guest and odd indices are always from the host — matching the `m.isEven`
/// sender logic in [buildMessages].
const _conversations = [
  // 1. Availability check
  [
    'Is this still available for those dates?',
    "Yes, it's available — feel free to book!",
    'Brilliant, just going to confirm with my partner first.',
    'Of course, no rush at all!',
  ],
  // 2. Capacity question
  [
    'How many people does this sleep?',
    'It sleeps up to four comfortably.',
    'Great, it\'s just the two of us so that works perfectly.',
    'Wonderful — you\'ll have lots of space to spread out.',
  ],
  // 3. Dog-walking
  [
    "What's the nearest park for walking dogs?",
    "There's a great dog-friendly park just five minutes away.",
    'Oh perfect, we\'re bringing our spaniel.',
    'Lovely! Dogs are very welcome here.',
  ],
  // 4. Cancellation
  [
    "I'm so sorry, but I need to cancel our stay.",
    'Oh no, I hope everything\'s okay. I\'ll process the cancellation now.',
    'Thank you for understanding — it was a last-minute change of plans.',
    'No problem at all — hope to host you another time!',
  ],
  // 5. Check-in logistics
  [
    'Just confirming — what time can we check in?',
    'Check-in is from 3pm, but I can do noon if you need.',
    'Noon would be amazing, thank you!',
    "Great, I'll leave the keys in the lockbox. Code is on the app.",
  ],
  // 6. Remote work / wifi
  [
    "What's the wifi like? I'll be working remotely.",
    'Fast fibre — you\'ll have no trouble with video calls.',
    "That's exactly what I needed to know, thanks.",
    "There's also a quiet desk in the spare room if that helps.",
  ],
  // 7. Local restaurants
  [
    'Are there any good restaurants nearby?',
    "There's a great Italian place around the corner and a farmers market on Saturdays.",
    'The farmers market sounds amazing!',
    "It really is — I'd recommend getting there early.",
  ],
  // 8. Pets
  [
    'Is the place pet-friendly? We have a small dog.',
    'Absolutely — well-behaved dogs are very welcome!',
    "Wonderful, she's very well-trained.",
    "I'm sure she'll love the garden.",
  ],
  // 9. Parking
  [
    'Do you have parking available?',
    "Yes, there's a private driveway with space for two cars.",
    "Perfect, we're driving up from London.",
    "Safe travels — the drive should be lovely this time of year.",
  ],
  // 10. Discount
  [
    "We're hoping to stay for two weeks — is a discount possible?",
    "Happy to offer 15% off for a two-week stay.",
    "That's very generous, thank you!",
    "My pleasure — I love having longer-term guests.",
  ],
];

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
          content: _conversations[i % _conversations.length][m % 4],
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
