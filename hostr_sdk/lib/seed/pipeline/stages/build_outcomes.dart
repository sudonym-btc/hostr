import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';

import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Pure outcome-planning and event-construction helpers.
///
/// **No I/O, no network, no chain.**  Everything that previously touched
/// `Web3Client`, nonce assignment, or receipt polling has been moved into
/// [Seeder] + [SeedSink] / [InfrastructureSink].

// ─── Outcome planning (Phase 0) ─────────────────────────────────────────────

/// Deterministic, synchronous outcome planning — no I/O.
///
/// Consumes [SeedContext.random] to assign each thread a planned outcome
/// (escrow vs zap, settlement type, self-signed flag).
List<SeedOutcomePlan> buildOutcomePlans({
  required SeedContext ctx,
  required List<SeedThread> threads,
  required DateTime chainNow,
  required Map<String, EscrowTrust> trustByPubkey,
  required Map<String, EscrowMethod> methodByPubkey,
}) {
  final plans = <SeedOutcomePlan>[];
  for (var i = 0; i < threads.length; i++) {
    final thread = threads[i];
    final spec = thread.stageSpec;

    final reservationEndedInPast = !thread.end.isAfter(chainNow);

    final isCompleted = ctx.pickByRatio(spec.completedRatio);
    if (!isCompleted) continue;

    final shouldUseEscrow =
        thread.host.hasEvm && ctx.pickByRatio(spec.paidViaEscrowRatio);

    EscrowOutcome? escrowOutcome;
    if (shouldUseEscrow) {
      escrowOutcome = _pickEscrowOutcome(
        ctx: ctx,
        spec: spec,
        allowClaimedByHost: reservationEndedInPast,
      );
    }

    final isSelfSigned = ctx.pickByRatio(spec.selfSignedReservationRatio);

    plans.add(
      SeedOutcomePlan(
        index: i,
        thread: thread,
        useEscrow: shouldUseEscrow,
        escrowOutcome: escrowOutcome,
        selfSigned: isSelfSigned,
        trust: shouldUseEscrow
            ? trustByPubkey[thread.host.keyPair.publicKey]
            : null,
        method: shouldUseEscrow
            ? methodByPubkey[thread.host.keyPair.publicKey]
            : null,
      ),
    );
  }
  return plans;
}

// ─── Zap receipt construction ───────────────────────────────────────────────

/// Build a deterministic zap receipt (kind 9735) for a thread.
///
/// Pure — no chain or relay interaction.
Nip01Event buildZapReceipt({
  required SeedContext ctx,
  required int threadIndex,
  required String tradeId,
  required Reservation request,
  required Listing listing,
  required SeedUser host,
  required SeedUser guest,
  required ProfileMetadata? hostProfile,
}) {
  final amountMsats = request.amount!.value * BigInt.from(1000);
  final lnurl = hostProfile != null
      ? Metadata.fromEvent(hostProfile).lud16
      : null;

  final zapRequest = Nip01Utils.signWithPrivateKey(
    privateKey: guest.keyPair.privateKey!,
    event: Nip01Event(
      pubKey: guest.keyPair.publicKey,
      kind: kNostrKindZapRequest,
      tags: [
        ['p', host.keyPair.publicKey],
        ['amount', amountMsats.toString()],
        ['e', tradeId],
        ['l', listing.anchor!],
        if (lnurl != null) ['lnurl', lnurl],
      ],
      content: 'Seed zap request',
      createdAt: ctx.timestampDaysAfter(31 + threadIndex),
    ),
  );

  return Nip01Utils.signWithPrivateKey(
    privateKey: host.keyPair.privateKey!,
    event: Nip01Event(
      pubKey: host.keyPair.publicKey,
      kind: kNostrKindZapReceipt,
      tags: [
        ['bolt11', 'lnbc-seed-$threadIndex'],
        ['preimage', 'seed-preimage-$threadIndex'],
        ['amount', amountMsats.toString()],
        ['p', host.keyPair.publicKey],
        ['P', guest.keyPair.publicKey],
        ['e', zapRequest.getEId()!],
        ['l', listing.anchor!],
        if (lnurl != null) ['lnurl', lnurl],
        ['description', Nip01EventModel.fromEntity(zapRequest).toJsonString()],
      ],
      content: 'Seed zap payment',
      createdAt: ctx.timestampDaysAfter(32 + threadIndex),
    ),
  );
}

// ─── Reservation construction ───────────────────────────────────────────────

/// Build a signed reservation event for a completed outcome plan.
///
/// Call after `SeedSink.submitTrade()` / `SeedSink.settleTrade()` have
/// populated [SeedOutcomePlan.createTxHash].  This function is pure —
/// it never touches the chain.
Reservation buildReservationForPlan({
  required SeedContext ctx,
  required SeedOutcomePlan plan,
  required Map<String, ProfileMetadata> profileByPubkey,
  required EscrowService escrowService,
  required Map<String, EscrowTrust> trustByPubkey,
  required Map<String, EscrowMethod> methodByPubkey,
  required double invalidReservationRate,
}) {
  final thread = plan.thread;
  final hostProfile = profileByPubkey[thread.host.keyPair.publicKey];
  PaymentProof? proof;

  if (plan.useEscrow && plan.createTxHash != null) {
    final trust = plan.trust ?? trustByPubkey[thread.host.keyPair.publicKey];
    final method = plan.method ?? methodByPubkey[thread.host.keyPair.publicKey];
    if (trust != null && method != null) {
      proof = PaymentProof(
        hoster: hostProfile!,
        listing: thread.listing,
        zapProof: null,
        escrowProof: EscrowProof(
          txHash: plan.createTxHash!,
          escrowService: escrowService,
          hostsTrustedEscrows: trust,
          hostsEscrowMethods: method,
        ),
      );
    } else {
      print(
        '[seed][escrow] WARNING thread=${plan.index + 1}: '
        'has createTxHash but missing trust/method for host '
        '${thread.host.keyPair.publicKey} — escrow proof omitted',
      );
    }
  } else if (plan.useEscrow && plan.createTxHash == null) {
    print(
      '[seed][escrow] WARNING thread=${plan.index + 1}: '
      'useEscrow=true but createTxHash is null — no on-chain '
      'trade found and no creation was attempted '
      '(trust=${plan.trust != null}, method=${plan.method != null})',
    );
  } else if (!plan.useEscrow) {
    proof = PaymentProof(
      hoster: hostProfile!,
      listing: thread.listing,
      zapProof: thread.zapReceipt != null
          ? ZapProof(receipt: Nip01EventModel.fromEntity(thread.zapReceipt!))
          : null,
      escrowProof: null,
    );
  }

  thread.selfSigned = plan.selfSigned;

  final requestTweakMaterial = thread.request.tweakMaterial;
  final buyerSigningKey = requestTweakMaterial != null
      ? tweakKeyPair(
          privateKey: thread.guest.keyPair.privateKey!,
          salt: requestTweakMaterial.salt,
        ).keyPair
      : thread.guest.keyPair;
  final reservationSigner = plan.selfSigned
      ? buyerSigningKey
      : thread.host.keyPair;

  String? invalidReason;
  final mutatedProof = _maybeCorruptPaymentProof(
    ctx: ctx,
    invalidReservationRate: invalidReservationRate,
    proof: proof,
    onInvalid: (reason) => invalidReason = reason,
  );

  final reservation = Reservation.create(
    pubKey: reservationSigner.publicKey,
    dTag: thread.request.getDtag()!,
    listingAnchor: thread.listing.anchor!,
    threadAnchor: thread.request.getDtag()!,
    start: thread.start,
    end: thread.end,
    stage: ReservationStage.commit,
    quantity: thread.request.quantity,
    amount: thread.request.amount,
    recipient: thread.request.recipient,
    proof: mutatedProof,
    extraTags: [
      if (plan.escrowOutcome != null)
        ['escrowOutcome', plan.escrowOutcome!.name],
      if (plan.selfSigned) ['selfSigned', 'true'],
    ],
    createdAt: ctx.timestampDaysAfter(31 + plan.index + 1),
  ).signAs(reservationSigner, Reservation.fromNostrEvent);

  thread.reservation = reservation;
  thread.invalidReservationReason = invalidReason;
  return reservation;
}

// ─── Proof corruption ───────────────────────────────────────────────────────

PaymentProof? _maybeCorruptPaymentProof({
  required SeedContext ctx,
  required double invalidReservationRate,
  required PaymentProof? proof,
  void Function(String reason)? onInvalid,
}) {
  if (invalidReservationRate <= 0) return proof;
  if (!ctx.pickByRatio(invalidReservationRate)) return proof;
  if (proof == null) {
    onInvalid?.call('missing_payment_proof');
    return null;
  }

  final shouldDropProof = proof.escrowProof == null || ctx.random.nextBool();
  if (shouldDropProof) {
    onInvalid?.call('missing_payment_proof');
    return null;
  }

  onInvalid?.call('bogus_escrow_proof');
  return PaymentProof(
    hoster: proof.hoster,
    listing: proof.listing,
    zapProof: proof.zapProof,
    escrowProof: _buildBogusEscrowProof(ctx: ctx, original: proof.escrowProof!),
  );
}

EscrowProof _buildBogusEscrowProof({
  required SeedContext ctx,
  required EscrowProof original,
}) {
  return EscrowProof(
    txHash: _randomHex(ctx, 64),
    escrowService: _buildBogusEscrowService(ctx),
    hostsTrustedEscrows: original.hostsTrustedEscrows,
    hostsEscrowMethods: original.hostsEscrowMethods,
  );
}

EscrowService _buildBogusEscrowService(SeedContext ctx) {
  final content = EscrowServiceContent(
    pubkey: MockKeys.escrow.publicKey,
    evmAddress: _randomHex(ctx, 40),
    contractAddress: _randomHex(ctx, 40),
    contractBytecodeHash: _randomHex(ctx, 64),
    chainId: 1000 + ctx.random.nextInt(8000),
    maxDuration: const Duration(days: 365),
    type: EscrowType.EVM,
    feeBase: 50 + ctx.random.nextInt(200),
    feePercent: (ctx.random.nextInt(30) + 5) / 10, // 0.5 – 3.5 %
    minAmount: 1000 + ctx.random.nextInt(9000),
  );

  final unsigned = EscrowService(
    pubKey: MockKeys.escrow.publicKey,
    content: content,
    tags: EventTags([]),
    createdAt: ctx.timestampDaysAfter(60 + ctx.random.nextInt(30)),
  );

  return unsigned.signAs(MockKeys.escrow, EscrowService.fromNostrEvent);
}

String _randomHex(SeedContext ctx, int length) {
  const alphabet = '0123456789abcdef';
  final buffer = StringBuffer('0x');
  for (var i = 0; i < length; i++) {
    buffer.write(alphabet[ctx.random.nextInt(alphabet.length)]);
  }
  return buffer.toString();
}

// ─── Helpers ────────────────────────────────────────────────────────────────

EscrowOutcome _pickEscrowOutcome({
  required SeedContext ctx,
  required ThreadStageSpec spec,
  required bool allowClaimedByHost,
}) {
  final value = ctx.random.nextDouble();
  if (value < spec.paidViaEscrowArbitrateRatio) {
    return EscrowOutcome.arbitrated;
  }
  if (!allowClaimedByHost) {
    return EscrowOutcome.releaseToCounterparty;
  }
  if (value <
      spec.paidViaEscrowArbitrateRatio + spec.paidViaEscrowClaimedRatio) {
    return EscrowOutcome.claimedByHost;
  }
  return EscrowOutcome.releaseToCounterparty;
}
