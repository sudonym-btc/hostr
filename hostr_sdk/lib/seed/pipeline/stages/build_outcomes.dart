import 'dart:typed_data';

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
  required double invalidReservationRate,
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
    final tradeId = plan.thread.request.getDtag() ?? '';
    plan.thread.zapReceipt = _buildZapReceipt(
      ctx: ctx,
      threadIndex: plan.index + 1,
      tradeId: tradeId,
      request: plan.thread.request,
      listing: plan.thread.listing,
      host: plan.thread.host,
      guest: plan.thread.guest,
      hostProfile: hostProfile,
    );
  }

  // ── Phase 2: Create escrow trades — parallel by guest (nonce-safe) ──
  final allEscrowPlans = plans.where((p) => p.useEscrow).toList();

  print(
    '[seed][escrow] Phase 0+1 (decisions + zaps): '
    '${sw.elapsedMilliseconds} ms',
  );

  // ── Phase 2a: Batch log scan to discover already-created and
  //    already-settled trades. Runs unconditionally so that plans
  //    originally assigned to the zap path can be promoted to escrow
  //    when a prior seed run left an on-chain trade for the same
  //    deterministic tradeId.
  final contract = ctx.multiEscrowContract(
    escrowService.parsedContent.contractAddress,
  );

  final createdTrades = <String, String>{}; // tradeIdHex → txHash
  final settledTrades = <String>{}; // tradeIdHex set

  await Future.wait([
    // Scan TradeCreated logs.
    () async {
      final event = contract.self.event('TradeCreated');
      final filter = FilterOptions.events(
        contract: contract.self,
        event: event,
        fromBlock: const BlockNum.genesis(),
      );
      final logs = await ctx.chainClient().getLogs(filter);
      for (final log in logs) {
        final decoded = event.decodeResults(log.topics!, log.data!);
        final idHex = _bytesToHex(decoded[0] as Uint8List);
        if (log.transactionHash != null) {
          createdTrades[idHex] = log.transactionHash!;
        }
      }
    }(),
    // Scan all settlement event types in parallel.
    for (final eventName in ['Claimed', 'Arbitrated', 'ReleasedToCounterparty'])
      () async {
        final event = contract.self.event(eventName);
        final filter = FilterOptions.events(
          contract: contract.self,
          event: event,
          fromBlock: const BlockNum.genesis(),
        );
        final logs = await ctx.chainClient().getLogs(filter);
        for (final log in logs) {
          final decoded = event.decodeResults(log.topics!, log.data!);
          settledTrades.add(_bytesToHex(decoded[0] as Uint8List));
        }
      }(),
  ]);

  print(
    '[seed][escrow] Log scan: ${createdTrades.length} created, '
    '${settledTrades.length} settled on-chain.',
  );

  // Mark ALL plans whose trades already exist on-chain — including
  // plans on the zap path whose tradeId has an on-chain trade from a
  // prior seed run. These get promoted to the escrow path so the
  // reservation proof matches the on-chain state.
  for (final plan in plans) {
    final tradeIdHex = plan.thread.request.getDtag() ?? '';
    final existingTxHash = createdTrades[tradeIdHex];
    if (existingTxHash != null) {
      if (!plan.useEscrow) {
        // Promote zap-path plan to escrow path — an on-chain trade
        // exists from a prior seed run.
        plan.useEscrow = true;
        plan.trust ??= trustByPubkey[plan.thread.host.keyPair.publicKey];
        plan.method ??= methodByPubkey[plan.thread.host.keyPair.publicKey];
        plan.escrowOutcome ??= settledTrades.contains(tradeIdHex)
            ? EscrowOutcome.claimedByHost
            : null;
        print(
          '[seed][escrow] thread=${plan.index + 1} '
          'tradeId=$tradeIdHex PROMOTED to escrow path '
          '(on-chain trade found from prior run, '
          'fundTx=$existingTxHash)',
        );
      }
      plan.tradeAlreadyExisted = true;
      plan.createTxHash = existingTxHash;
      // Only needs settlement if created but NOT yet settled.
      plan.needsSettlement = !settledTrades.contains(tradeIdHex);
      if (plan.useEscrow) {
        final status = plan.needsSettlement ? 'active' : 'settled';
        print(
          '[seed][escrow] thread=${plan.index + 1} '
          'tradeId=$tradeIdHex SKIPPED createTrade '
          '(already exists [$status], fundTx=$existingTxHash)',
        );
      }
    }
  }

  if (allEscrowPlans.isNotEmpty || plans.any((p) => p.useEscrow)) {
    // ── Phase 2b: Assign nonces only for plans that need a tx.
    //    Only plans with trust+method can actually send create txs.
    //    Re-compute escrowPlans to include any promoted plans.
    final activeEscrowPlans = plans
        .where((p) => p.useEscrow && p.trust != null && p.method != null)
        .toList();
    final plansToCreate = activeEscrowPlans
        .where((p) => !p.tradeAlreadyExisted)
        .toList();

    if (plansToCreate.isNotEmpty) {
      final guestNonces = <String, int>{};
      for (final plan in plansToCreate) {
        guestNonces.putIfAbsent(plan.thread.guest.keyPair.privateKey!, () => 0);
      }
      await Future.wait(
        guestNonces.keys.map((privKey) async {
          final addr = getEvmCredentials(privKey).address;
          guestNonces[privKey] = await ctx.chainClient().getTransactionCount(
            addr,
            atBlock: const BlockNum.pending(),
          );
        }),
      );
      for (final plan in plansToCreate) {
        final key = plan.thread.guest.keyPair.privateKey!;
        plan.assignedCreateNonce = guestNonces[key]!;
        guestNonces[key] = guestNonces[key]! + 1;
      }

      print(
        '[seed][escrow] Creating ${plansToCreate.length} trades across '
        '${guestNonces.length} guest(s) fully in parallel...',
      );

      await Future.wait(
        plansToCreate.map(
          (plan) => _createTradeForPlan(
            ctx: ctx,
            plan: plan,
            escrowService: escrowService,
          ),
        ),
      );
    }

    // ── Phase 3: Settle trades ──
    // Settlement status is already known from the batch log scan,
    // so no per-trade re-verification is needed.
    final actuallyToSettle = activeEscrowPlans
        .where((p) => p.needsSettlement)
        .toList();

    if (actuallyToSettle.isNotEmpty) {
      // 3b: Ensure chain time is past all claimedByHost unlock times
      //     before dispatching (one wait covers every plan).
      final claimedPlans = actuallyToSettle
          .where((p) => p.escrowOutcome == EscrowOutcome.claimedByHost)
          .toList();
      if (claimedPlans.isNotEmpty) {
        var maxUnlock = 0;
        for (final plan in claimedPlans) {
          final unlockSec =
              plan.thread.request.parsedContent.end
                  .toUtc()
                  .millisecondsSinceEpoch ~/
              1000;
          if (unlockSec > maxUnlock) maxUnlock = unlockSec;
        }
        await ctx.waitForChainTimePast(targetEpochSeconds: maxUnlock);
      }

      // 3c: Assign nonces only for plans that will actually send a tx.
      final settlerNonces = <String, int>{};
      for (final plan in actuallyToSettle) {
        final settlerKey = plan.escrowOutcome == EscrowOutcome.arbitrated
            ? MockKeys.escrow.privateKey!
            : plan.thread.host.keyPair.privateKey!;
        settlerNonces.putIfAbsent(settlerKey, () => 0);
      }
      await Future.wait(
        settlerNonces.keys.map((privKey) async {
          final addr = getEvmCredentials(privKey).address;
          settlerNonces[privKey] = await ctx.chainClient().getTransactionCount(
            addr,
            atBlock: const BlockNum.pending(),
          );
        }),
      );
      for (final plan in actuallyToSettle) {
        final settlerKey = plan.escrowOutcome == EscrowOutcome.arbitrated
            ? MockKeys.escrow.privateKey!
            : plan.thread.host.keyPair.privateKey!;
        plan.assignedSettleNonce = settlerNonces[settlerKey]!;
        settlerNonces[settlerKey] = settlerNonces[settlerKey]! + 1;
      }

      print(
        '[seed][escrow] Settling ${actuallyToSettle.length} trades across '
        '${settlerNonces.length} sender(s) fully in parallel...',
      );

      await Future.wait(
        actuallyToSettle.map(
          (plan) => _settleForPlan(
            ctx: ctx,
            plan: plan,
            escrowService: escrowService,
          ),
        ),
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
      final trust = plan.trust ?? trustByPubkey[thread.host.keyPair.publicKey];
      final method =
          plan.method ?? methodByPubkey[thread.host.keyPair.publicKey];
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

    String? invalidReason;
    final mutatedProof = _maybeCorruptPaymentProof(
      ctx: ctx,
      invalidReservationRate: invalidReservationRate,
      proof: proof,
      onInvalid: (reason) => invalidReason = reason,
    );

    final reservation = Reservation(
      pubKey: thread.guest.keyPair.publicKey,
      tags: ReservationTags([
        [kListingRefTag, thread.listing.anchor!],
        [kThreadRefTag, thread.request.getDtag()!],
        ['d', thread.request.getDtag()!],
        if (plan.escrowOutcome != null)
          ['escrowOutcome', plan.escrowOutcome!.name],
        if (plan.selfSigned) ['selfSigned', 'true'],
      ]),
      createdAt: ctx.timestampDaysAfter(31 + plan.index + 1),
      content: ReservationContent(
        start: thread.start,
        end: thread.end,
        proof: mutatedProof,
      ),
    ).signAs(thread.guest.keyPair, Reservation.fromNostrEvent);

    thread.reservation = reservation;
    thread.invalidReservationReason = invalidReason;
  }
}

// ─── Plan model ─────────────────────────────────────────────────────────────

class _ThreadPlan {
  final int index;
  final SeedThread thread;
  bool useEscrow;
  EscrowOutcome? escrowOutcome;
  final bool selfSigned;
  EscrowTrust? trust;
  EscrowMethod? method;

  String? createTxHash;
  bool tradeAlreadyExisted = false;
  bool needsSettlement = false;
  int? assignedCreateNonce;
  int? assignedSettleNonce;

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
    evmAddress: getEvmCredentials(
      MockKeys.escrow.privateKey!,
    ).address.eip55With0x,
    contractAddress: _randomHex(ctx, 40),
    contractBytecodeHash: _randomHex(ctx, 64),
    chainId: 1000 + ctx.random.nextInt(8000),
    maxDuration: const Duration(days: 365),
    type: EscrowType.EVM,
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

// ─── Escrow trade creation (phase 2) ────────────────────────────────────────

/// Only called for plans where the trade does NOT already exist on-chain.
/// Existence is pre-checked in phase 2a so nonces are gap-free.
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
      request.parsedContent.amount!.value * BigInt.from(10).pow(10);

  final guestCredentials = EthPrivateKey.fromHex(guest.keyPair.privateKey!);
  final buyer = getEvmCredentials(guest.keyPair.privateKey!).address;
  final seller = getEvmCredentials(host.keyPair.privateKey!).address;
  final arbiter = getEvmCredentials(MockKeys.escrow.privateKey!).address;

  final unlockAtSeconds =
      request.parsedContent.end.toUtc().millisecondsSinceEpoch ~/ 1000;
  final unlockAt = BigInt.from(unlockAtSeconds);

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
      nonce: plan.assignedCreateNonce,
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

// ─── Escrow settlement (phase 3) ────────────────────────────────────────────

/// Only called for plans verified as active in phase 3a.
/// Chain time is guaranteed past all unlock times by phase 3b.
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

  if (plan.escrowOutcome == EscrowOutcome.arbitrated) {
    final txHash = await contract.arbitrate(
      (tradeId: tradeId, factor: BigInt.from(700)),
      credentials: arbiterCredentials,
      transaction: Transaction(nonce: plan.assignedSettleNonce, maxGas: 250000),
    );
    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex '
      'arbitrateTx=$txHash factor=700',
    );
    await _assertTxSucceeded(ctx, txHash, threadIndex, 'arbitrate', tradeIdHex);
  } else if (plan.escrowOutcome == EscrowOutcome.claimedByHost) {
    final txHash = await contract.claim(
      (tradeId: tradeId),
      credentials: hostCredentials,
      transaction: Transaction(nonce: plan.assignedSettleNonce, maxGas: 250000),
    );
    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex claimTx=$txHash',
    );
    await _assertTxSucceeded(ctx, txHash, threadIndex, 'claim', tradeIdHex);
  } else {
    final txHash = await contract.releaseToCounterparty(
      (tradeId: tradeId),
      credentials: hostCredentials,
      transaction: Transaction(nonce: plan.assignedSettleNonce, maxGas: 250000),
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

/// Convert raw bytes to a hex string (no 0x prefix) for use as map keys.
String _bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

// ─── Zap receipt ────────────────────────────────────────────────────────────

Nip01Event _buildZapReceipt({
  required SeedContext ctx,
  required int threadIndex,
  required String tradeId,
  required Reservation request,
  required Listing listing,
  required SeedUser host,
  required SeedUser guest,
  required ProfileMetadata? hostProfile,
}) {
  final amountMsats = request.parsedContent.amount!.value * BigInt.from(1000);
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
