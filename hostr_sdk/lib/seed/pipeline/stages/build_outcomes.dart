import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';

import '../entity_factory.dart';
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
  required Map<String, EscrowMethod> methodByPubkey,
}) {
  final plans = <SeedOutcomePlan>[];
  for (var i = 0; i < threads.length; i++) {
    final thread = threads[i];
    final spec = thread.stageSpec;

    final orderEndedInPast = !thread.end.isAfter(chainNow);

    final isCompleted = ctx.pickByRatio(spec.completedRatio);
    if (!isCompleted) continue;

    final shouldUseEscrow =
        thread.host.hasEvm && ctx.pickByRatio(spec.paidViaEscrowRatio);

    EscrowOutcome? escrowOutcome;
    if (shouldUseEscrow) {
      escrowOutcome = _pickEscrowOutcome(
        ctx: ctx,
        spec: spec,
        allowClaimedByHost: orderEndedInPast,
      );
    }

    final isSelfSigned = ctx.pickByRatio(spec.selfSignedOrderRatio);

    plans.add(
      SeedOutcomePlan(
        index: i,
        thread: thread,
        useEscrow: shouldUseEscrow,
        escrowOutcome: escrowOutcome,
        selfSigned: isSelfSigned,
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
  required Order request,
  required Listing listing,
  required SeedUser host,
  required SeedUser guest,
  required ProfileMetadata? hostProfile,
  EntityFactory? factory,
}) {
  final f = factory ?? EntityFactory(ctx: ctx);
  final lnurl = hostProfile != null
      ? Metadata.fromEvent(hostProfile).lud16
      : null;

  return f.zapReceipt(
    hostSigner: host.keyPair,
    guestSigner: guest.keyPair,
    request: request,
    listing: listing,
    lnurl: lnurl,
    threadIndex: threadIndex,
    createdAt: ctx.timestampDaysAfter(31 + threadIndex),
  );
}

// ─── Order construction ───────────────────────────────────────────────

/// Build a signed order event for a completed outcome plan.
///
/// Call after `SeedSink.submitTrade()` / `SeedSink.settleTrade()` have
/// populated [SeedOutcomePlan.createTxHash].  This function is pure —
/// it never touches the chain.
Future<Order> buildOrderForPlan({
  required SeedContext ctx,
  required SeedOutcomePlan plan,
  required Map<String, ProfileMetadata> profileByPubkey,
  required EscrowService escrowService,
  required Map<String, EscrowMethod> methodByPubkey,
  required double invalidOrderRate,
  EntityFactory? factory,
}) async {
  final f = factory ?? EntityFactory(ctx: ctx);
  final thread = plan.thread;
  final hostProfile = profileByPubkey[thread.host.keyPair.publicKey];
  PaymentProof? proof;

  if (plan.useEscrow && plan.createTxHash != null) {
    final method = plan.method ?? methodByPubkey[thread.host.keyPair.publicKey];
    if (method != null) {
      proof = f.escrowPaymentProof(
        hostProfile: hostProfile!,
        listing: thread.listing,
        txHash: plan.createTxHash!,
        escrowService: escrowService,
        hostsEscrowMethod: method,
      );
    } else {
      print(
        '[seed][escrow] WARNING thread=${plan.index + 1}: '
        'has createTxHash but missing escrow method for host '
        '${thread.host.keyPair.publicKey} — escrow proof omitted',
      );
    }
  } else if (plan.useEscrow && plan.createTxHash == null) {
    print(
      '[seed][escrow] WARNING thread=${plan.index + 1}: '
      'useEscrow=true but createTxHash is null — no on-chain '
      'trade found and no creation was attempted '
      '(method=${plan.method != null})',
    );
  } else if (!plan.useEscrow) {
    proof = f.zapPaymentProof(
      hostProfile: hostProfile!,
      listing: thread.listing,
      zapReceiptEvent: thread.zapReceipt,
    );
  }

  thread.selfSigned = plan.selfSigned;

  final buyerSigningKey = thread.requestAuthorKeyPair;
  final orderSigner = plan.selfSigned ? buyerSigningKey : thread.host.keyPair;

  String? invalidReason;
  final mutatedProof = _maybeCorruptPaymentProof(
    ctx: ctx,
    invalidOrderRate: invalidOrderRate,
    proof: proof,
    onInvalid: (reason) => invalidReason = reason,
  );

  final order = await f.order(
    guestKeyPair: thread.guest.keyPair,
    dTag: thread.request.getDtag()!,
    listing: thread.listing,
    start: thread.start,
    end: thread.end,
    stage: OrderStage.commit,
    quantity: thread.request.quantity,
    amount: thread.request.amount,
    recipient: thread.request.recipient,
    proof: mutatedProof,
    signerOverride: orderSigner,
    extraTags: [
      if (plan.escrowOutcome != null)
        ['escrowOutcome', plan.escrowOutcome!.name],
      if (plan.selfSigned) ['selfSigned', 'true'],
    ],
    createdAt: ctx.timestampDaysAfter(31 + plan.index + 1),
  );

  thread.order = order;
  thread.invalidOrderReason = invalidReason;
  return order;
}

// ─── Proof corruption ───────────────────────────────────────────────────────

PaymentProof? _maybeCorruptPaymentProof({
  required SeedContext ctx,
  required double invalidOrderRate,
  required PaymentProof? proof,
  void Function(String reason)? onInvalid,
}) {
  if (invalidOrderRate <= 0) return proof;
  if (!ctx.pickByRatio(invalidOrderRate)) return proof;
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
    feePercent: (ctx.random.nextInt(30) + 5) / 10, // 0.5 – 3.5 %
  );

  final unsigned = EscrowService(
    pubKey: MockKeys.escrow.publicKey,
    content: content,
    tags: EventTags([
      ['d', 'bogus-escrow-service-${content.chainId}'],
    ]),
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
