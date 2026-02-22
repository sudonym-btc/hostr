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
}) async {
  for (var i = 0; i < threads.length; i++) {
    final thread = threads[i];
    final spec = thread.stageSpec;

    final chainNow = (await ctx.chainClient().getBlockInformation()).timestamp
        .toUtc();
    final reservationEndedInPast = !thread.end.isAfter(chainNow);

    final isCompleted = ctx.pickByRatio(spec.completedRatio);
    if (!isCompleted) continue;

    final shouldUseEscrow =
        thread.host.hasEvm && ctx.pickByRatio(spec.paidViaEscrowRatio);

    final hostProfile = profileByPubkey[thread.host.keyPair.publicKey];
    PaymentProof? proof;
    EscrowOutcome? escrowOutcome;

    if (shouldUseEscrow) {
      final outcome = _pickEscrowOutcome(
        ctx: ctx,
        spec: spec,
        allowClaimedByHost: reservationEndedInPast,
      );
      escrowOutcome = outcome;

      final trust = trustByPubkey[thread.host.keyPair.publicKey];
      final method = methodByPubkey[thread.host.keyPair.publicKey];

      if (trust != null && method != null) {
        final escrowProof = await _createEscrowProof(
          ctx: ctx,
          threadIndex: i + 1,
          request: thread.request,
          host: thread.host,
          guest: thread.guest,
          outcome: outcome,
          escrowService: escrowService,
          trust: trust,
          method: method,
        );

        proof = PaymentProof(
          hoster: hostProfile ?? MOCK_PROFILES.first,
          listing: thread.listing,
          zapProof: null,
          escrowProof: escrowProof,
        );
      }

      thread.paidViaEscrow = true;
      thread.escrowOutcome = escrowOutcome;
    } else {
      // Zap path.
      final zapReceipt = _buildZapReceipt(
        ctx: ctx,
        threadIndex: i + 1,
        commitmentHash: thread.commitmentHash,
        request: thread.request,
        listing: thread.listing,
        host: thread.host,
        guest: thread.guest,
        hostProfile: hostProfile,
      );
      thread.zapReceipt = zapReceipt;

      proof = PaymentProof(
        hoster: hostProfile ?? MOCK_PROFILES.first,
        listing: thread.listing,
        zapProof: ZapProof(receipt: Nip01EventModel.fromEntity(zapReceipt)),
        escrowProof: null,
      );
    }

    // Check self-signed ratio.
    final isSelfSigned = ctx.pickByRatio(spec.selfSignedReservationRatio);
    thread.selfSigned = isSelfSigned;

    final reservation = Reservation(
      pubKey: thread.guest.keyPair.publicKey,
      tags: ReservationTags([
        [kListingRefTag, thread.listing.anchor!],
        [kThreadRefTag, thread.request.getDtag()!],
        ['d', 'seed-rsv-${i + 1}'],
        [kCommitmentHashTag, thread.commitmentHash],
        if (escrowOutcome != null) ['escrowOutcome', escrowOutcome.name],
        if (isSelfSigned) ['selfSigned', 'true'],
      ]),
      createdAt: ctx.timestampDaysAfter(31 + i + 1),
      content: ReservationContent(
        start: thread.start,
        end: thread.end,
        proof: proof,
      ),
    ).signAs(thread.guest.keyPair, Reservation.fromNostrEvent);

    thread.reservation = reservation;
  }
}

// ─── Escrow proof creation ──────────────────────────────────────────────────

Future<EscrowProof> _createEscrowProof({
  required SeedContext ctx,
  required int threadIndex,
  required ReservationRequest request,
  required SeedUser host,
  required SeedUser guest,
  required EscrowOutcome outcome,
  required EscrowService escrowService,
  required EscrowTrust trust,
  required EscrowMethod method,
}) async {
  final contract = ctx.multiEscrowContract(
    escrowService.parsedContent.contractAddress,
  );
  final tradeIdHex = request.getDtag() ?? '';
  final tradeId = getBytes32(tradeIdHex);
  final amountWei =
      request.parsedContent.amount.value * BigInt.from(10).pow(10);

  final guestCredentials = EthPrivateKey.fromHex(guest.keyPair.privateKey!);
  final hostCredentials = EthPrivateKey.fromHex(host.keyPair.privateKey!);
  final arbiterCredentials = EthPrivateKey.fromHex(MockKeys.escrow.privateKey!);

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

  String createTxHash;
  if (tradeAlreadyExists) {
    // Trade already on-chain from a previous seed run.
    // Recover the original creation tx hash from TradeCreated events.
    createTxHash = await _recoverCreateTxHash(ctx, contract, tradeId);
    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex SKIPPED createTrade '
      '(already exists, recovered fundTx=$createTxHash)',
    );
  } else {
    createTxHash = await contract.createTrade(
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
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex outcome=${outcome.name} '
      'fundTx=$createTxHash amountWei=$amountWei unlockAt=$unlockAtSeconds '
      'buyer=${buyer.eip55With0x} seller=${seller.eip55With0x} '
      'arbiter=${arbiter.eip55With0x}',
    );
    await _assertTxSucceeded(
      ctx,
      createTxHash,
      threadIndex,
      'createTrade',
      tradeIdHex,
    );
  }

  // ── Only settle if the trade is still active ──
  final activeCheck = await contract.activeTrade((tradeId: tradeId));
  if (activeCheck.isActive) {
    if (outcome == EscrowOutcome.arbitrated) {
      final arbitrateTxHash = await contract.arbitrate(
        (tradeId: tradeId, factor: BigInt.from(700)),
        credentials: arbiterCredentials,
        transaction: Transaction(maxGas: 250000),
      );
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex arbitrateTx=$arbitrateTxHash factor=700',
      );
      await _assertTxSucceeded(
        ctx,
        arbitrateTxHash,
        threadIndex,
        'arbitrate',
        tradeIdHex,
      );
    } else if (outcome == EscrowOutcome.claimedByHost) {
      await ctx.waitForChainTimePast(targetEpochSeconds: unlockAtSeconds);
      final claimTxHash = await contract.claim(
        (tradeId: tradeId),
        credentials: hostCredentials,
        transaction: Transaction(maxGas: 250000),
      );
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex claimTx=$claimTxHash',
      );
      await _assertTxSucceeded(
        ctx,
        claimTxHash,
        threadIndex,
        'claim',
        tradeIdHex,
      );
    } else {
      final releaseTxHash = await contract.releaseToCounterparty(
        (tradeId: tradeId),
        credentials: hostCredentials,
        transaction: Transaction(maxGas: 250000),
      );
      print(
        '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex releaseTx=$releaseTxHash',
      );
      await _assertTxSucceeded(
        ctx,
        releaseTxHash,
        threadIndex,
        'releaseToCounterparty',
        tradeIdHex,
      );
    }
  } else if (tradeAlreadyExists) {
    print(
      '[seed][escrow] thread=$threadIndex tradeId=$tradeIdHex SKIPPED settlement '
      '(trade already settled)',
    );
  }

  return EscrowProof(
    txHash: createTxHash,
    escrowService: escrowService,
    hostsTrustedEscrows: trust,
    hostsEscrowMethods: method,
  );
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
