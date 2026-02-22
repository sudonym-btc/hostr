import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Stage 6: Build NIP-17 gift-wrapped DM messages for threads.
///
/// Each thread gets:
///   1. The reservation request message
///   2. If escrow path with completed outcome: an escrow-selected message
///   3. N filler messages based on [ThreadStageSpec.textMessageCount]
Future<List<Nip01Event>> buildMessages({
  required SeedContext ctx,
  required SeedPipelineConfig config,
  required List<SeedThread> threads,
}) async {
  final messages = <Nip01Event>[];

  final giftWrapNdk = Ndk(
    NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      engine: NdkEngine.JIT,
      defaultQueryTimeout: const Duration(seconds: 10),
      bootstrapRelays: [
        if (config.relayUrl != null && config.relayUrl!.isNotEmpty)
          config.relayUrl!,
      ],
    ),
  );

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

      // 2. Escrow-selected message (if applicable).
      if (thread.paidViaEscrow && thread.reservation != null) {
        final escrowProof =
            thread.reservation!.parsedContent.proof?.escrowProof;
        if (escrowProof != null) {
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

          final selectedEscrowWraps = await _giftWrapDmForParticipants(
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
          messages.addAll(selectedEscrowWraps);
        }
      }

      // 3. Filler text messages.
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
          content:
              'Seed message ${m + 1} for thread ${i + 1} (${thread.paidViaEscrow ? "escrow" : "zap"})',
        );
        messages.addAll(wraps);
      }
    }

    return messages;
  } finally {
    await giftWrapNdk.destroy();
  }
}

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
