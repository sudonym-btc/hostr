import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../datasources/boltz/boltz.dart';
import '../../../injection.dart';
import '../../../util/main.dart';
import '../chain/evm_chain.dart';
import '../chain/rootstock/rif_relay/rif_relay.dart';
import 'swap_record.dart';
import 'swap_store.dart';

/// Service that runs on app start to recover pending swaps.
///
/// **Why this exists:**
/// Boltz swaps involve multi-step atomic protocols where funds are at risk
/// between steps. If the app crashes, loses network, or the user force-quits
/// mid-swap, we need to:
///
/// - **Swap-In (reverse submarine):** Re-attempt claiming on-chain funds
///   using the persisted preimage. Without this, Boltz will refund itself
///   after the timelock and the user loses their Lightning payment.
///
/// - **Swap-Out (submarine):** Re-attempt refunding locked EVM funds.
///   First tries cooperative refund (immediate, requires Boltz cooperation),
///   then falls back to timelock refund (after expiry block height).
///
/// This service should be called during app initialization, after DI is
/// configured and the EVM chain client is ready.
@injectable
class SwapRecoveryService {
  final SwapStore _swapStore;
  final BoltzClient _boltzClient;
  final CustomLogger _logger;

  SwapRecoveryService(this._swapStore, this._boltzClient, this._logger);

  /// Check for pending swaps and attempt recovery.
  ///
  /// Returns the number of swaps that were successfully resolved.
  /// This method is safe to call multiple times (idempotent).
  ///
  /// [chainResolver] maps a chainId to the [EvmChain] that can execute
  /// claim / refund transactions on that network.
  Future<int> recoverPendingSwaps({
    required EthPrivateKey evmKey,
    required Future<EvmChain> Function(int chainId) chainResolver,
  }) async {
    await _swapStore.initialize();

    // Always prune old completed/refunded records (older than 30 days)
    final pruned = await _swapStore.pruneOlderThan(const Duration(days: 30));
    if (pruned > 0) {
      _logger.d('SwapRecovery: pruned $pruned old swap records');
    }

    final pending = await _swapStore.getPendingRecovery();

    if (pending.isEmpty) {
      _logger.d('SwapRecovery: no pending swaps to recover');
      return 0;
    }

    _logger.i('SwapRecovery: found ${pending.length} swap(s) needing recovery');
    int resolved = 0;

    for (final record in pending) {
      try {
        // Resolve the EVM chain for this swap record
        if (record.chainId == null) {
          _logger.w(
            'SwapRecovery: ${record.boltzId} has no chainId — skipping.',
          );
          continue;
        }
        final chain = await chainResolver(record.chainId!);

        // Check the current Boltz status via HTTP
        final currentStatus = await _boltzClient.getSwap(id: record.boltzId);
        _logger.d(
          'SwapRecovery: ${record.boltzId} Boltz status: ${currentStatus.status}',
        );

        if (record.type == SwapType.swapIn) {
          final success = await _recoverSwapIn(
            record: record,
            boltzStatus: currentStatus.status,
            evmKey: evmKey,
            chain: chain,
          );
          if (success) resolved++;
        } else {
          final success = await _recoverSwapOut(
            record: record,
            boltzStatus: currentStatus.status,
            evmKey: evmKey,
            chain: chain,
          );
          if (success) resolved++;
        }
      } catch (e) {
        _logger.e('SwapRecovery: failed to recover ${record.boltzId}: $e');
        await _swapStore.updateStatus(
          record.id,
          SwapRecordStatus.needsAction,
          errorMessage: 'Recovery attempt failed: $e',
        );
      }
    }

    _logger.i('SwapRecovery: resolved $resolved of ${pending.length} swaps');
    return resolved;
  }

  // ── Swap-In Recovery ──────────────────────────────────────────────────

  Future<bool> _recoverSwapIn({
    required SwapRecord record,
    required String boltzStatus,
    required EthPrivateKey evmKey,
    required EvmChain chain,
  }) async {
    // If Boltz already refunded itself, the swap is lost.
    // The Lightning HTLC would have expired too, so no funds to recover.
    if (boltzStatus == 'transaction.refunded') {
      _logger.w(
        'SwapRecovery: swap-in ${record.boltzId} — Boltz refunded. '
        'Funds lost (preimage was not revealed in time).',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.failed,
        lastBoltzStatus: boltzStatus,
        errorMessage:
            'Boltz refunded the on-chain lockup. The claim window expired.',
      );
      return false;
    }

    // If swap expired without Boltz ever locking, Lightning refunds automatically.
    if (boltzStatus == 'swap.expired' || boltzStatus == 'transaction.failed') {
      _logger.i(
        'SwapRecovery: swap-in ${record.boltzId} expired/failed before lockup. '
        'Lightning payment refunded automatically.',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.failed,
        lastBoltzStatus: boltzStatus,
        errorMessage: 'Swap expired. No on-chain funds at risk.',
      );
      return true;
    }

    // If Boltz reports invoice.settled, the claim was already processed.
    if (boltzStatus == 'invoice.settled') {
      _logger.i('SwapRecovery: swap-in ${record.boltzId} already settled.');
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.completed,
        lastBoltzStatus: boltzStatus,
      );
      return true;
    }

    // Boltz has locked on-chain, we need to claim.
    // This is the critical path — we have the preimage and must use it.
    if (boltzStatus == 'transaction.mempool' ||
        boltzStatus == 'transaction.confirmed' ||
        record.status == SwapRecordStatus.funded ||
        record.status == SwapRecordStatus.claiming) {
      return await _attemptClaim(record: record, evmKey: evmKey, chain: chain);
    }

    _logger.d(
      'SwapRecovery: swap-in ${record.boltzId} in status $boltzStatus — '
      'no action needed yet.',
    );
    return false;
  }

  Future<bool> _attemptClaim({
    required SwapRecord record,
    required EthPrivateKey evmKey,
    required EvmChain chain,
  }) async {
    final preimageBytes = record.preimageBytes;
    if (preimageBytes == null) {
      _logger.e(
        'SwapRecovery: CRITICAL — swap-in ${record.boltzId} needs claim but '
        'preimage is missing from storage. Funds may be unrecoverable.',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.failed,
        errorMessage: 'Preimage lost. Contact support with swap ID.',
      );
      return false;
    }

    final onchainAmountSat = record.onchainAmountSat;
    final refundAddressHex = record.refundAddress;
    final timelock = record.timeoutBlockHeight;

    if (onchainAmountSat == null || timelock == null) {
      _logger.e(
        'SwapRecovery: swap-in ${record.boltzId} missing claim parameters.',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.needsAction,
        errorMessage: 'Missing on-chain amount or timelock for claim.',
      );
      return false;
    }

    // If we don't have the refund address from the lockup tx, we can't claim
    // with the standard method. We'd need to scan contract logs.
    if (refundAddressHex == null) {
      _logger.w(
        'SwapRecovery: swap-in ${record.boltzId} missing refund address. '
        'Will attempt to find from contract events.',
      );
      // TODO: Scan EtherSwap Lockup events for this preimage hash to get refundAddress
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.needsAction,
        errorMessage: 'Missing refund address from lockup transaction.',
      );
      return false;
    }

    try {
      final amountWei = BitcoinAmount.fromBigInt(
        BitcoinUnit.sat,
        BigInt.from(onchainAmountSat),
      ).getInWei;

      final swapContract = await chain.getEtherSwapContract();
      final rifRelay = getIt<RifRelay>(param1: chain.client);

      final tx = await rifRelay.relayClaimTransaction(
        signer: evmKey,
        etherSwap: swapContract,
        preimage: preimageBytes,
        amountWei: amountWei,
        refundAddress: EthereumAddress.fromHex(refundAddressHex),
        timeoutBlockHeight: BigInt.from(timelock),
      );

      _logger.i('SwapRecovery: claim broadcast for ${record.boltzId}: $tx');
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.claiming,
        resolutionTxHash: tx,
      );

      await chain.awaitReceipt(tx);
      _logger.i('SwapRecovery: claim confirmed for ${record.boltzId}');
      await _swapStore.updateStatus(record.id, SwapRecordStatus.completed);
      return true;
    } catch (e) {
      _logger.e('SwapRecovery: claim failed for ${record.boltzId}: $e');
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.needsAction,
        errorMessage: 'Claim failed: $e',
      );
      return false;
    }
  }

  // ── Swap-Out Recovery ─────────────────────────────────────────────────

  Future<bool> _recoverSwapOut({
    required SwapRecord record,
    required String boltzStatus,
    required EthPrivateKey evmKey,
    required EvmChain chain,
  }) async {
    // Boltz already paid the invoice — swap succeeded!
    if (boltzStatus == 'invoice.paid' || boltzStatus == 'transaction.claimed') {
      _logger.i(
        'SwapRecovery: swap-out ${record.boltzId} completed '
        '(Boltz status: $boltzStatus).',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.completed,
        lastBoltzStatus: boltzStatus,
      );
      return true;
    }

    // Swap was created but we never locked funds — safe to abandon.
    if (record.status == SwapRecordStatus.created &&
        record.lockTxHash == null) {
      if (boltzStatus == 'swap.expired' || boltzStatus == 'swap.created') {
        _logger.i(
          'SwapRecovery: swap-out ${record.boltzId} never funded, safe to abandon.',
        );
        await _swapStore.updateStatus(
          record.id,
          SwapRecordStatus.failed,
          lastBoltzStatus: boltzStatus,
          errorMessage: 'Swap abandoned — funds were never locked.',
        );
        return true;
      }
    }

    // These states mean Boltz failed to pay the invoice and we need to refund.
    if (boltzStatus == 'invoice.failedToPay' ||
        boltzStatus == 'transaction.lockupFailed' ||
        boltzStatus == 'swap.expired' ||
        record.status == SwapRecordStatus.needsAction) {
      return await _attemptRefund(record: record, evmKey: evmKey, chain: chain);
    }

    // Swap is still in progress (Boltz is trying to pay) — wait.
    if (boltzStatus == 'invoice.pending' ||
        boltzStatus == 'transaction.mempool' ||
        boltzStatus == 'transaction.confirmed') {
      _logger.d(
        'SwapRecovery: swap-out ${record.boltzId} still in progress '
        '($boltzStatus). Will check again later.',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.funded,
        lastBoltzStatus: boltzStatus,
      );
      return false;
    }

    _logger.d(
      'SwapRecovery: swap-out ${record.boltzId} in status $boltzStatus — '
      'no action taken.',
    );
    return false;
  }

  Future<bool> _attemptRefund({
    required SwapRecord record,
    required EthPrivateKey evmKey,
    required EvmChain chain,
  }) async {
    final preimageHashBytes = record.invoicePreimageHashBytes;
    final claimAddr = record.claimAddress;
    final lockedWei = record.lockedAmountWei;
    final timelock = record.timeoutBlockHeight;

    if (preimageHashBytes == null ||
        claimAddr == null ||
        lockedWei == null ||
        timelock == null) {
      _logger.e(
        'SwapRecovery: cannot refund ${record.boltzId} — missing parameters. '
        'Try recovering from EtherSwap contract logs.',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.needsAction,
        errorMessage: 'Missing refund parameters.',
      );
      return false;
    }

    final claimAddress = EthereumAddress.fromHex(claimAddr);
    final swapContract = await chain.getEtherSwapContract();

    // 1. Try cooperative refund first (immediate, no timelock wait)
    try {
      final sigResponse = await _boltzClient.getCooperativeRefundSignature(
        id: record.boltzId,
      );
      if (sigResponse != null) {
        _logger.i(
          'SwapRecovery: got cooperative refund sig for ${record.boltzId}',
        );
        final sig = _parseEip712Signature(sigResponse.signature);

        final refundTx = await swapContract.refundCooperative$2((
          preimageHash: preimageHashBytes,
          amount: lockedWei,
          claimAddress: claimAddress,
          timelock: BigInt.from(timelock),
          v: sig.v,
          r: sig.r,
          s: sig.s,
        ), credentials: evmKey);

        await _swapStore.updateStatus(
          record.id,
          SwapRecordStatus.refunding,
          resolutionTxHash: refundTx,
        );
        _logger.i('SwapRecovery: cooperative refund broadcast: $refundTx');

        await chain.awaitReceipt(refundTx);
        await _swapStore.updateStatus(record.id, SwapRecordStatus.refunded);
        _logger.i(
          'SwapRecovery: cooperative refund confirmed for ${record.boltzId}',
        );
        return true;
      }
    } catch (e) {
      _logger.w(
        'SwapRecovery: cooperative refund failed for ${record.boltzId}: $e',
      );
    }

    // 2. Fall back to timelock refund
    try {
      final currentBlock = await chain.client.getBlockNumber();
      if (currentBlock < timelock) {
        _logger.w(
          'SwapRecovery: timelock not expired for ${record.boltzId} '
          '(current: $currentBlock, expires: $timelock). '
          'Will retry on next recovery pass.',
        );
        await _swapStore.updateStatus(
          record.id,
          SwapRecordStatus.needsAction,
          errorMessage:
              'Waiting for timelock at block $timelock (current: $currentBlock).',
        );
        return false;
      }

      final refundTx = await swapContract.refund((
        preimageHash: preimageHashBytes,
        amount: lockedWei,
        claimAddress: claimAddress,
        timelock: BigInt.from(timelock),
      ), credentials: evmKey);

      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.refunding,
        resolutionTxHash: refundTx,
      );
      _logger.i(
        'SwapRecovery: timelock refund broadcast for ${record.boltzId}: $refundTx',
      );

      await chain.awaitReceipt(refundTx);
      await _swapStore.updateStatus(record.id, SwapRecordStatus.refunded);
      _logger.i(
        'SwapRecovery: timelock refund confirmed for ${record.boltzId}',
      );
      return true;
    } catch (e) {
      _logger.e(
        'SwapRecovery: timelock refund failed for ${record.boltzId}: $e',
      );
      await _swapStore.updateStatus(
        record.id,
        SwapRecordStatus.needsAction,
        errorMessage: 'Timelock refund failed: $e',
      );
      return false;
    }
  }

  ({BigInt v, Uint8List r, Uint8List s}) _parseEip712Signature(String sigHex) {
    final normalized = sigHex.startsWith('0x') ? sigHex.substring(2) : sigHex;
    final sigBytes = hex.decode(normalized);
    if (sigBytes.length != 65) {
      throw StateError(
        'Expected 65-byte EIP-712 signature, got ${sigBytes.length} bytes',
      );
    }
    return (
      r: Uint8List.fromList(sigBytes.sublist(0, 32)),
      s: Uint8List.fromList(sigBytes.sublist(32, 64)),
      v: BigInt.from(sigBytes[64]),
    );
  }
}
