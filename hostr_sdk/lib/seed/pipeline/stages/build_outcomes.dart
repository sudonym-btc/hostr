import 'dart:typed_data';

import 'package:hostr_sdk/datasources/contracts/escrow/MultiEscrow.g.dart';
import 'package:hostr_sdk/usecase/payments/constants.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Stage 5: Resolve outcomes for threads based on each thread's
/// [ThreadStageSpec].
///
/// This stage mutates the [SeedThread] objects in place, filling in:
///   - [SeedThread.reservation]
///   - [SeedThread.zapReceipt]
///   - [SeedThread.paidViaEscrow]
///   - [SeedThread.escrowOutcome]
///   - [SeedThread.selfSigned]
///
/// Threads whose [ThreadStageSpec.completedRatio] causes them to be
/// skipped remain in pending state.
Future<void> buildOutcomes({
  required SeedContext ctx,
  required List<SeedThread> threads,
  required Map<String, ProfileMetadata> profileByPubkey,
  required EscrowService escrowService,
  required Map<String, EscrowTrust> trustByPubkey,
  required Map<String, EscrowMethod> methodByPubkey,
  DateTime? chainNow,
}) async {
  final sw = Stopwatch()..start();

  // Use provided chainNow or fetch from chain.
  chainNow ??= (await ctx.chainClient().getBlockInformation()).timestamp
      .toUtc();

  // ── Phase 0: Decide outcomes deterministically (preserves Random
  //    call sequence so seed data stays stable).
  final plans = <_ThreadPlan>[];
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
      _ThreadPlan(
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

  // ── Phase 1: Zap paths (no RPC, pure event construction) ──
  for (final plan in plans.where((p) => !p.useEscrow)) {
    final hostProfile = profileByPubkey[plan.thread.host.keyPair.publicKey];
    plan.thread.zapReceipt = _buildZapReceipt(
      ctx: ctx,
      threadIndex: plan.index + 1,
      commitmentHash: plan.thread.commitmentHash,
      request: plan.thread.request,
      listing: plan.thread.listing,
      host: plan.thread.host,
      guest: plan.thread.guest,
      hostProfile: hostProfile,
    );
  }

  // ── Phase 2: Create escrow trades — parallel by guest (nonce-safe) ──
  final escrowPlans = plans
      .where((p) => p.useEscrow && p.trust != null && p.method != null)
      .toList();

  print(
    '[seed][escrow] Phase 0+1 (decisions + zaps): '
    '${sw.elapsedMilliseconds} ms',
  );

  if (escrowPlans.isNotEmpty) {
    final byGuest = <String, List<_ThreadPlan>>{};
    for (final plan in escrowPlans) {
      byGuest
          .putIfAbsent(plan.thread.guest.keyPair.privateKey!, () => [])
          .add(plan);
    }

    print(
      '[seed][escrow] Creating ${escrowPlans.length} trades across '
      '${byGuest.length} guest(s) in parallel...',
    );

    await Future.wait(
      byGuest.values.map((group) async {
        for (final plan in group) {
          await _createTradeForPlan(
            ctx: ctx,
            plan: plan,
            escrowService: escrowService,
          );
        }
      }),
    );

    // ── Phase 3: Settle trades — parallel by settlement sender ──
    final toSettle = escrowPlans.where((p) => p.needsSettlement).toList();

    if (toSettle.isNotEmpty) {
      final bySettler = <String, List<_ThreadPlan>>{};
      for (final plan in toSettle) {
        final settlerKey = plan.escrowOutcome == EscrowOutcome.arbitrated
            ? MockKeys.escrow.privateKey!
            : plan.thread.host.keyPair.privateKey!;
        bySettler.putIfAbsent(settlerKey, () => []).add(plan);
      }

      print(
        '[seed][escrow] Settling ${toSettle.length} trades across '
        '${bySettler.length} sender(s) in parallel...',
      );

      await Future.wait(
        bySettler.values.map((group) async {
          for (final plan in group) {
            await _settleForPlan(
              ctx: ctx,
              plan: plan,
              escrowService: escrowService,
            );
          }
        }),
      );
    }
  }

  // Mark escrow-path threads.
  for (final plan in plans.where((p) => p.useEscrow)) {
    plan.thread.paidViaEscrow = true;
    plan.thread.escrowOutcome = plan.escrowOutcome;
  }

  // ── Phase 4: Build reservation events (no RPC) ──
  for (final plan in plans) {
    final thread = plan.thread;
    final hostProfile = profileByPubkey[thread.host.keyPair.publicKey];
    PaymentProof? proof;

    if (plan.useEscrow && plan.createTxHash != null) {
      proof = PaymentProof(
        hoster: hostProfile ?? MOCK_PROFILES.first,
        listing: thread.listing,
        zapProof: null,
        escrowProof: EscrowProof(
          txHash: plan.createTxHash!,
          escrowService: escrowService,
          hostsTrustedEscrows: plan.trust!,
          hostsEscrowMethods: plan.method!,
        ),
      );
    } else if (!plan.useEscrow) {
      proof = PaymentProof(
        hoster: hostProfile ?? MOCK_PROFILES.first,
        listing: thread.listing,
        zapProof: thread.zapReceipt != null
            ? ZapProof(receipt: Nip01EventModel.fromEntity(thread.zapReceipt!))
            : null,
        escrowProof: null,
      );
    }

    thread.selfSigned = plan.selfSigned;

    final reservation = Reservation(
      pubKey: thread.guest.keyPair.publicKey,
      tags: ReservationTags([
        [kListingRefTag, thread.listing.anchor!],
        [kThreadRefTag, thread.request.getDtag()!],
        ['d', 'seed-rsv-${plan.index + 1}'],
        [kCommitmentHashTag, thread.commitmentHash],
        if (plan.escrowOutcome != null)
          ['escrowOutcome', plan.escrowOutcome!.name],
        if (plan.selfSigned) ['selfSigned', 'true'],
      ]),
      createdAt: ctx.timestampDaysAfter(31 + plan.index + 1),
      content: ReservationContent(
        start: thread.start,
        end: thread.end,
        proof: proof,
      ),
    ).signAs(thread.guest.keyPair, Reservation.fromNostrEvent);

    thread.reservation = reservation;
  }
}

// ─── Plan model ─────────────────────────────────────────────────────────────

class _ThreadPlan {
  final int index;
  final SeedThread thread;
  final bool useEscrow;
  final EscrowOutcome? escrowOutcome;
  final bool selfSigned;
  final EscrowTrust? trust;
  final EscrowMethod? method;

  String? createTxHash;
  bool tradeAlreadyExisted = false;
  bool needsSettlement = false;

  _ThreadPlan({
    required this.index,
    required this.thread,
    required this.useEscrow,
    this.escrowOutcome,
    required this.selfSigned,
    this.trust,
    this.method,
  });
}

// ─── Escrow trade creation (phase 2) ────────────────────────────────────────

Future<void> _createTradeForPlan({
  required SeedContext ctx,
  required _ThreadPlan plan,
  required EscrowService escrowService,
}) async {
  final contract = ctx.multiEscrowContract(
    escrowService.parsedContent.contractAddress,
  );
  final request = plan.thread.request;
  final guest = plan.thread.guest;
  final host = plan.thread.host;
  final threadIndex = plan.index + 1;

  final tradeIdHex = request.getDtag() ?? '';
  final tradeId = getBytes32(tradeIdHex);
  final amountWei =
      request.parsedContent.amount.value * BigInt.from(10).pow(10);

  final guestCredentials = EthPrivateKey.fromHex(guest.keyPair.privateKey!);
  final buyer = getEvmCredentials(guest.keyPair.privateKey!).address;
  final seller = getEvmCredentials(host.keyPair.privateKey!).address;
  final arbiter = getEvmCredentials(MockKeys.escrow.privateKey!).address;

  final unlockAtSeconds =
      request.parsedContent.end.toUtc().millisecondsSinceEpoch ~/ 1000;
  final unlockAt = BigInt.from(unlockAtSeconds);

  // ── Idempotency: check if trade already exists on-chain ──
  final zeroAddress = EthereumAddress.fromHex(
    '0x0000000000000000000000000000000000000000',
  );
  final existingTrade = await contract.trades(($param13: tradeId));
  final tradeAlreadyExists = existingTrade.buyer != zeroAddress;

  if (tradeAlreadyExists) {
    plan.createTxHash = await _recoverCreateTxHash(ctx, contract, tradeId);
    plan.tradeAlreadyExisted = true;

    // Check if already settled.
    final activeCheck = await contract.activeTrade((tradeId: tradeId));
    plan.needsSettlement = activeCheck.isActive;

    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex SKIPPED createTrade '
      '(already exists, recovered fundTx=${plan.createTxHash})',
    );
  } else {
    plan.createTxHash = await contract.createTrade(
      (
        tradeId: tradeId,
        buyer: buyer,
        seller: seller,
        arbiter: arbiter,
        unlockAt: unlockAt,
        escrowFee: BigInt.zero,
      ),
      credentials: guestCredentials,
      transaction: Transaction(
        value: EtherAmount.inWei(amountWei),
        maxGas: 450000,
      ),
    );

    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex '
      'outcome=${plan.escrowOutcome!.name} '
      'fundTx=${plan.createTxHash} amountWei=$amountWei '
      'unlockAt=$unlockAtSeconds '
      'buyer=${buyer.eip55With0x} seller=${seller.eip55With0x} '
      'arbiter=${arbiter.eip55With0x}',
    );
    await _assertTxSucceeded(
      ctx,
      plan.createTxHash!,
      threadIndex,
      'createTrade',
      tradeIdHex,
    );
    // Freshly created trades are always active.
    plan.needsSettlement = true;
  }
}

// ─── Escrow settlement (phase 3) ────────────────────────────────────────────

Future<void> _settleForPlan({
  required SeedContext ctx,
  required _ThreadPlan plan,
  required EscrowService escrowService,
}) async {
  final contract = ctx.multiEscrowContract(
    escrowService.parsedContent.contractAddress,
  );
  final request = plan.thread.request;
  final host = plan.thread.host;
  final threadIndex = plan.index + 1;

  final tradeIdHex = request.getDtag() ?? '';
  final tradeId = getBytes32(tradeIdHex);

  final hostCredentials = EthPrivateKey.fromHex(host.keyPair.privateKey!);
  final arbiterCredentials = EthPrivateKey.fromHex(MockKeys.escrow.privateKey!);

  final unlockAtSeconds =
      request.parsedContent.end.toUtc().millisecondsSinceEpoch ~/ 1000;

  // Re-check active status (may have been settled by a parallel plan
  // sharing the same trade, though unlikely with unique trade IDs).
  final activeCheck = await contract.activeTrade((tradeId: tradeId));
  if (!activeCheck.isActive) {
    if (plan.tradeAlreadyExisted) {
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex SKIPPED settlement '
        '(trade already settled)',
      );
    }
    return;
  }

  if (plan.escrowOutcome == EscrowOutcome.arbitrated) {
    final txHash = await contract.arbitrate(
      (tradeId: tradeId, factor: BigInt.from(700)),
      credentials: arbiterCredentials,
      transaction: Transaction(maxGas: 250000),
    );
    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex '
      'arbitrateTx=$txHash factor=700',
    );
    await _assertTxSucceeded(ctx, txHash, threadIndex, 'arbitrate', tradeIdHex);
  } else if (plan.escrowOutcome == EscrowOutcome.claimedByHost) {
    await ctx.waitForChainTimePast(targetEpochSeconds: unlockAtSeconds);
    final txHash = await contract.claim(
      (tradeId: tradeId),
      credentials: hostCredentials,
      transaction: Transaction(maxGas: 250000),
    );
    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex claimTx=$txHash',
    );
    await _assertTxSucceeded(ctx, txHash, threadIndex, 'claim', tradeIdHex);
  } else {
    final txHash = await contract.releaseToCounterparty(
      (tradeId: tradeId),
      credentials: hostCredentials,
      transaction: Transaction(maxGas: 250000),
    );
    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex '
      'releaseTx=$txHash',
    );
    await _assertTxSucceeded(
      ctx,
      txHash,
      threadIndex,
      'releaseToCounterparty',
      tradeIdHex,
    );
  }
}

Future<void> _assertTxSucceeded(
  SeedContext ctx,
  String txHash,
  int threadIndex,
  String stage,
  String tradeIdHex,
) async {
  final receipt = await _waitForReceipt(ctx, txHash);
  if (receipt == null) {
    final tx = await ctx.chainClient().getTransactionByHash(txHash);
    throw Exception(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex stage=$stage tx=$txHash has no receipt '
      '(txKnown=${tx != null})',
    );
  }
  if (receipt.status != true) {
    throw Exception(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex stage=$stage tx=$txHash failed (status=${receipt.status})',
    );
  }
}

Future<dynamic> _waitForReceipt(SeedContext ctx, String txHash) async {
  const maxAttempts = 30;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final receipt = await ctx.chainClient().getTransactionReceipt(txHash);
    if (receipt != null) return receipt;
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  return null;
}

/// Recover the tx hash that originally created a trade by scanning
/// `TradeCreated` event logs. Falls back to a synthetic placeholder if the
/// log search fails (e.g. pruned node).
Future<String> _recoverCreateTxHash(
  SeedContext ctx,
  MultiEscrow contract,
  Uint8List tradeId,
) async {
  try {
    final event = contract.self.event('TradeCreated');
    final filter = FilterOptions.events(
      contract: contract.self,
      event: event,
      fromBlock: const BlockNum.genesis(),
    );
    final logs = await ctx.chainClient().getLogs(filter);
    for (final log in logs) {
      final decoded = event.decodeResults(log.topics!, log.data!);
      final logTradeId = decoded[0] as Uint8List;
      if (_bytesEqual(logTradeId, tradeId) && log.transactionHash != null) {
        return log.transactionHash!;
      }
    }
  } catch (e) {
    print('[seed][escrow] Warning: failed to recover createTx from logs: $e');
  }
  // Fallback: return a zero-hash placeholder. The seed data is for
  // development only, so this is acceptable when logs aren't available.
  return '0x${'0' * 64}';
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ─── Zap receipt ────────────────────────────────────────────────────────────

Nip01Event _buildZapReceipt({
  required SeedContext ctx,
  required int threadIndex,
  required String commitmentHash,
  required ReservationRequest request,
  required Listing listing,
  required SeedUser host,
  required SeedUser guest,
  required ProfileMetadata? hostProfile,
}) {
  final amountMsats = request.parsedContent.amount.value * BigInt.from(1000);
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
        ['e', commitmentHash],
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
