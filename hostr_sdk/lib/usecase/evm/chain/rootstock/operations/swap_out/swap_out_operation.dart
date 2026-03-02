import 'dart:async';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:hostr_sdk/datasources/swagger_generated/boltz.swagger.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/evm/main.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' hide params;

import '../../../../../../datasources/boltz/boltz.dart';
import '../../../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../../../util/main.dart';
import '../../rif_relay/rif_relay.dart';

@injectable
class RootstockSwapOutOperation extends SwapOutOperation {
  static const int _estimatedLockGasLimit = 200000;

  final Rootstock rootstock;
  final Nwc nwc;
  late final RifRelay rifRelay = getIt<RifRelay>(param1: rootstock.client);

  RootstockSwapOutOperation({
    required this.rootstock,
    required super.auth,
    required super.logger,
    required this.nwc,
    @factoryParam required super.params,
    super.initialState,
  });

  @override
  Future<void> execute() async {
    SwapOutData? data;
    try {
      emit(SwapOutRequestCreated());
      final quote = await _buildSwapOutQuote();

      final String invoice;
      if (nwc.getActiveConnection() == null) {
        // No NWC wallet connected – try LUD16 from user metadata first
        final lud16Invoice = await _tryCreateInvoiceFromLud16(
          quote.invoiceAmount.getInSats.toInt(),
        );

        if (lud16Invoice != null) {
          invoice = lud16Invoice;
          logger.i('Created invoice via LUD16 lightning address');
        } else {
          // No LUD16 either – ask the user to provide an invoice manually
          emit(SwapOutExternalInvoiceRequired(quote.invoiceAmount));
          logger.i(
            'No NWC or LUD16 available, emitted SwapOutExternalInvoiceRequired '
            'with amount ${quote.invoiceAmount.getInSats} sats',
          );
          externalInvoiceCompleter = Completer<String>();
          invoice = await externalInvoiceCompleter!.future;
        }
      } else {
        final makeInvoice = await nwc.makeInvoice(
          nwc.getActiveConnection()!,
          amountSats: quote.invoiceAmount.getInSats.toInt(),
          description: 'Hostr payout',
        );
        invoice = makeInvoice.invoice;
      }
      emit(SwapOutInvoiceCreated(invoice));
      logger.i('Invoice created: $invoice');

      final invoicePreimageHash = Bolt11PaymentRequest(
        invoice,
      ).tags.where((tag) => tag.type == 'payment_hash').first.data;
      final preimageHash = _decodePaymentHash(invoicePreimageHash);

      final swap = await getIt<BoltzClient>().submarine(invoice: invoice);
      logger.i('Submarine swap created: ${swap.toString()}');

      final expectedLockAmount = BitcoinAmount.fromInt(
        BitcoinUnit.sat,
        swap.expectedAmount.ceil(),
      );
      final expectedLockAmountRounded = expectedLockAmount.roundUp(
        BitcoinUnit.sat,
      );
      final gasFeeRounded = quote.estimatedGasFee.roundUp(BitcoinUnit.sat);
      final balanceRounded = quote.balance.roundDown(BitcoinUnit.sat);

      if (expectedLockAmountRounded + gasFeeRounded > balanceRounded) {
        final requiredTotal = expectedLockAmountRounded + gasFeeRounded;
        throw StateError(
          'Insufficient balance to lock swap. Need ${expectedLockAmountRounded.getInSats} sats + ${gasFeeRounded.getInSats} sats gas, total of ${requiredTotal.getInSats} sats, have ${balanceRounded.getInSats} sats.',
        );
      }

      final lockClaimAddress = _resolveSubmarineClaimAddress(swap);

      // ── Create recovery data before locking funds ──
      // Once we call lock(), our EVM funds are committed to the HTLC.
      // We MUST persist all refund parameters before that point.
      data = SwapOutData(
        boltzId: swap.id,
        invoice: invoice,
        invoicePreimageHashHex: hex.encode(preimageHash),
        claimAddress: lockClaimAddress.with0x,
        lockedAmountWeiHex: expectedLockAmountRounded.getInWei.toRadixString(
          16,
        ),
        lockerAddress: params.evmKey.address.with0x,
        timeoutBlockHeight: swap.timeoutBlockHeight.toInt(),
        chainId: rootstock.config.rootstockConfig.chainId,
        accountIndex: params.accountIndex,
      );
      emit(SwapOutAwaitingOnChain(data));
      logger.i('Swap-out data persisted for ${swap.id} before lock');

      // Subscribe to Boltz WebSocket for status updates
      final swapStatusStream = _waitForSwapOnChain(swap.id);

      // Create the args record for the lock function
      final lockArgs = (
        claimAddress: lockClaimAddress,
        preimageHash: preimageHash,
        timelock: BigInt.from(swap.timeoutBlockHeight),
      );

      final swapContract = await rootstock.getEtherSwapContract();

      // Lock the funds in the EtherSwap contract
      String tx = await swapContract.lock(
        lockArgs,
        credentials: params.evmKey,
        transaction: Transaction(
          value: expectedLockAmountRounded.toEtherAmount(),
        ),
      );

      // ── Persist lock tx hash ──
      data = data.copyWith(lockTxHash: tx, lastBoltzStatus: 'lock.broadcast');
      emit(SwapOutFunded(data));
      logger.i('Locked funds in EtherSwap: $tx');

      // Wait for Boltz to pay our Lightning invoice or report failure
      final terminalStatus = await swapStatusStream
          .where(
            (status) =>
                status.status == 'invoice.paid' ||
                status.status == 'invoice.failedToPay' ||
                status.status == 'transaction.lockupFailed' ||
                status.status == 'swap.expired',
          )
          .timeout(
            const Duration(minutes: 60),
            onTimeout: (sink) {
              sink.addError(
                TimeoutException(
                  'Timed out waiting for Boltz to pay invoice for swap ${swap.id}. '
                  'Funds are locked in EtherSwap contract. '
                  'A refund can be attempted after block ${swap.timeoutBlockHeight}.',
                ),
              );
            },
          )
          .first;

      if (terminalStatus.status == 'invoice.paid') {
        // ── SUCCESS ──
        emit(SwapOutCompleted(data.copyWith(lastBoltzStatus: 'invoice.paid')));
        logger.i('Swap-out completed: invoice paid by Boltz');
        await close();
      } else {
        // ── FAILURE: Need to refund ──
        logger.w(
          'Swap-out failed with status: ${terminalStatus.status}. '
          'Will attempt refund.',
        );
        data = data.copyWith(
          lastBoltzStatus: terminalStatus.status,
          errorMessage:
              'Boltz reported ${terminalStatus.status}. Refund required.',
        );
        emit(SwapOutFunded(data));

        // Attempt refund immediately
        await _attemptRefund(data: data, swapContract: swapContract);
      }
    } on TimeoutException catch (e, st) {
      logger.e('Timeout during swap-out: $e');
      emit(SwapOutFailed(e, data: data, stackTrace: st));
    } catch (e, st) {
      logger.e('Error during swap out operation: $e');
      emit(SwapOutFailed(e, data: data, stackTrace: st));
    }
  }

  /// Attempt to refund locked funds from the EtherSwap contract.
  ///
  /// Tries cooperative refund first (via EIP-712 signature from Boltz, available
  /// immediately when swap is in a failed state). Falls back to timelock refund
  /// if cooperative refund isn't available.
  Future<void> _attemptRefund({
    required SwapOutData data,
    required EtherSwap swapContract,
  }) async {
    final claimAddress = EthereumAddress.fromHex(data.claimAddress);

    // 1. Try cooperative refund (immediate, doesn't need timelock expiry)
    try {
      final boltz = getIt<BoltzClient>();
      final sigResponse = await boltz.getCooperativeRefundSignature(
        id: data.boltzId,
      );

      if (sigResponse != null) {
        logger.i('Got cooperative refund signature from Boltz');
        final sig = _parseEip712Signature(sigResponse.signature);

        final refundTx = await swapContract.refundCooperative$2((
          preimageHash: data.invoicePreimageHashBytes,
          amount: data.lockedAmountWei,
          claimAddress: claimAddress,
          timelock: BigInt.from(data.timeoutBlockHeight),
          v: sig.v,
          r: sig.r,
          s: sig.s,
        ), credentials: params.evmKey);

        data = data.copyWith(resolutionTxHash: refundTx);
        emit(SwapOutRefunding(data));
        logger.i('Cooperative refund broadcast: $refundTx');

        final receipt = await rootstock.awaitReceipt(refundTx);
        logger.i('Cooperative refund confirmed: $receipt');
        emit(SwapOutRefunded(data));
        return;
      }
    } catch (e) {
      logger.w('Cooperative refund failed: $e — will fall back to timelock');
    }

    // 2. Fall back to timelock refund (must wait for block height)
    try {
      final currentBlock = await rootstock.client.getBlockNumber();
      if (currentBlock < data.timeoutBlockHeight) {
        logger.w(
          'Timelock not expired yet (current: $currentBlock, timelock: ${data.timeoutBlockHeight}). '
          'Refund will be retried by SwapRecoverer.',
        );
        emit(
          SwapOutFunded(
            data.copyWith(
              errorMessage:
                  'Waiting for timelock expiry at block ${data.timeoutBlockHeight} (current: $currentBlock)',
            ),
          ),
        );
        return;
      }

      final refundTx = await swapContract.refund((
        preimageHash: data.invoicePreimageHashBytes,
        amount: data.lockedAmountWei,
        claimAddress: claimAddress,
        timelock: BigInt.from(data.timeoutBlockHeight),
      ), credentials: params.evmKey);

      data = data.copyWith(resolutionTxHash: refundTx);
      emit(SwapOutRefunding(data));
      logger.i('Timelock refund broadcast: $refundTx');

      final receipt = await rootstock.awaitReceipt(refundTx);
      logger.i('Timelock refund confirmed: $receipt');
      emit(SwapOutRefunded(data));
    } catch (e) {
      logger.e('Timelock refund failed: $e');
      emit(SwapOutFunded(data.copyWith(errorMessage: 'Refund failed: $e')));
    }
  }

  @override
  Future<bool> recover() async {
    final currentState = state;
    final data = currentState.data;
    if (data == null) return false; // Never committed on-chain
    if (currentState.isTerminal) return true; // Already resolved

    try {
      // Fetch current Boltz status
      final boltzResponse = await getIt<BoltzClient>().getSwap(
        id: data.boltzId,
      );
      final boltzStatus = boltzResponse.status;

      // Boltz already paid the invoice — swap succeeded!
      if (boltzStatus == 'invoice.paid' ||
          boltzStatus == 'transaction.claimed') {
        logger.i(
          'SwapRecovery: swap-out ${data.boltzId} completed '
          '(Boltz status: $boltzStatus).',
        );
        emit(SwapOutCompleted(data.copyWith(lastBoltzStatus: boltzStatus)));
        return true;
      }

      // Swap was created but we never locked funds — safe to abandon.
      if (data.lockTxHash == null) {
        if (boltzStatus == 'swap.expired' || boltzStatus == 'swap.created') {
          logger.i(
            'SwapRecovery: swap-out ${data.boltzId} never funded, safe to abandon.',
          );
          emit(
            SwapOutFailed(
              'Swap abandoned — funds were never locked.',
              data: data.copyWith(lastBoltzStatus: boltzStatus),
            ),
          );
          return true;
        }
      }

      // These states mean Boltz failed to pay the invoice and we need to refund.
      if (boltzStatus == 'invoice.failedToPay' ||
          boltzStatus == 'transaction.lockupFailed' ||
          boltzStatus == 'swap.expired') {
        return await _attemptRecoveryRefund(
          data.copyWith(lastBoltzStatus: boltzStatus),
        );
      }

      // Swap is still in progress (Boltz is trying to pay) — wait.
      if (boltzStatus == 'invoice.pending' ||
          boltzStatus == 'transaction.mempool' ||
          boltzStatus == 'transaction.confirmed') {
        logger.d(
          'SwapRecovery: swap-out ${data.boltzId} still in progress '
          '($boltzStatus). Will check again later.',
        );
        emit(SwapOutFunded(data.copyWith(lastBoltzStatus: boltzStatus)));
        return false;
      }

      logger.d(
        'SwapRecovery: swap-out ${data.boltzId} in status $boltzStatus — '
        'no action taken.',
      );
      return false;
    } catch (e) {
      logger.e('SwapRecovery: error recovering ${data.boltzId}: $e');
      return false;
    }
  }

  /// Attempt to refund locked funds during recovery.
  ///
  /// Tries cooperative refund first, then falls back to timelock refund.
  Future<bool> _attemptRecoveryRefund(SwapOutData data) async {
    final claimAddress = EthereumAddress.fromHex(data.claimAddress);
    final swapContract = await rootstock.getEtherSwapContract();

    // 1. Try cooperative refund first (immediate, no timelock wait)
    try {
      final boltz = getIt<BoltzClient>();
      final sigResponse = await boltz.getCooperativeRefundSignature(
        id: data.boltzId,
      );
      if (sigResponse != null) {
        logger.i(
          'SwapRecovery: got cooperative refund sig for ${data.boltzId}',
        );
        final sig = _parseEip712Signature(sigResponse.signature);

        final refundTx = await swapContract.refundCooperative$2((
          preimageHash: data.invoicePreimageHashBytes,
          amount: data.lockedAmountWei,
          claimAddress: claimAddress,
          timelock: BigInt.from(data.timeoutBlockHeight),
          v: sig.v,
          r: sig.r,
          s: sig.s,
        ), credentials: params.evmKey);

        data = data.copyWith(resolutionTxHash: refundTx);
        emit(SwapOutRefunding(data));
        logger.i('SwapRecovery: cooperative refund broadcast: $refundTx');

        await rootstock.awaitReceipt(refundTx);
        emit(SwapOutRefunded(data));
        logger.i(
          'SwapRecovery: cooperative refund confirmed for ${data.boltzId}',
        );
        return true;
      }
    } catch (e) {
      logger.w(
        'SwapRecovery: cooperative refund failed for ${data.boltzId}: $e',
      );
    }

    // 2. Fall back to timelock refund
    try {
      final currentBlock = await rootstock.client.getBlockNumber();
      if (currentBlock < data.timeoutBlockHeight) {
        logger.w(
          'SwapRecovery: timelock not expired for ${data.boltzId} '
          '(current: $currentBlock, expires: ${data.timeoutBlockHeight}). '
          'Will retry on next recovery pass.',
        );
        emit(
          SwapOutFunded(
            data.copyWith(
              errorMessage:
                  'Waiting for timelock at block ${data.timeoutBlockHeight} (current: $currentBlock).',
            ),
          ),
        );
        return false;
      }

      final refundTx = await swapContract.refund((
        preimageHash: data.invoicePreimageHashBytes,
        amount: data.lockedAmountWei,
        claimAddress: claimAddress,
        timelock: BigInt.from(data.timeoutBlockHeight),
      ), credentials: params.evmKey);

      data = data.copyWith(resolutionTxHash: refundTx);
      emit(SwapOutRefunding(data));
      logger.i(
        'SwapRecovery: timelock refund broadcast for ${data.boltzId}: $refundTx',
      );

      await rootstock.awaitReceipt(refundTx);
      emit(SwapOutRefunded(data));
      logger.i('SwapRecovery: timelock refund confirmed for ${data.boltzId}');
      return true;
    } catch (e) {
      logger.e('SwapRecovery: timelock refund failed for ${data.boltzId}: $e');
      emit(
        SwapOutFunded(
          data.copyWith(errorMessage: 'Timelock refund failed: $e'),
        ),
      );
      return false;
    }
  }

  /// Parse an EIP-712 signature string (hex) into (v, r, s) components.
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

  @override
  Future<SwapOutFees> estimateFees() async {
    final quote = await _buildSwapOutQuote();

    return SwapOutFees(
      estimatedGasFees: quote.estimatedGasFee,
      estimatedSwapFees: quote.estimatedSwapFee,
      balance: quote.balance,
      invoiceAmount: quote.invoiceAmount,
    );
  }

  Future<
    ({
      BitcoinAmount balance,
      BitcoinAmount invoiceAmount,
      BitcoinAmount estimatedGasFee,
      BitcoinAmount estimatedSwapFee,
    })
  >
  _buildSwapOutQuote() async {
    final balance = await rootstock.getBalance(params.evmKey.address);
    final balanceRounded = balance.roundDown(BitcoinUnit.sat);
    final estimatedGasFee = (await _estimateLockGasFee()).roundUp(
      BitcoinUnit.sat,
    );
    final pair = await _getSubmarinePair(from: 'RBTC', to: 'BTC');

    final minInvoice = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      pair.limits.minimal.ceil(),
    );
    final maxInvoiceByPair = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      pair.limits.maximal.floor(),
    );

    final percentage = pair.fees.percentage;
    final minerFeesSatsRoundedUp = pair.fees.minerFees.ceil();
    final spendableAfterGasSats =
        balanceRounded.getInSats.toDouble() -
        estimatedGasFee.getInSats.toDouble();

    if (spendableAfterGasSats <= 0) {
      throw StateError(
        'Balance ${balance.getInSats} sats is not enough to cover estimated gas ${estimatedGasFee.getInSats} sats.',
      );
    }

    final denom = 1 + (percentage / 100.0);
    final maxInvoiceByBalanceSats =
        ((spendableAfterGasSats - minerFeesSatsRoundedUp) / denom).floor();

    if (maxInvoiceByBalanceSats <= 0) {
      throw StateError(
        'Balance after gas cannot cover submarine swap fees. Spendable: ${spendableAfterGasSats.floor()} sats, fixed miner fee: $minerFeesSatsRoundedUp sats.',
      );
    }

    final maxInvoiceByBalance = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      maxInvoiceByBalanceSats,
    );
    final maxInvoice = BitcoinAmount.max(
      BitcoinAmount.zero(),
      maxInvoiceByBalance < maxInvoiceByPair
          ? maxInvoiceByBalance
          : maxInvoiceByPair,
    );

    final invoiceAmount = (params.amount ?? maxInvoice).roundDown(
      BitcoinUnit.sat,
    );

    if (invoiceAmount < minInvoice) {
      throw StateError(
        'Invoice amount ${invoiceAmount.getInSats} sats is below Boltz minimum ${minInvoice.getInSats} sats.',
      );
    }
    if (invoiceAmount > maxInvoiceByPair) {
      throw StateError(
        'Invoice amount ${invoiceAmount.getInSats} sats exceeds Boltz maximum ${maxInvoiceByPair.getInSats} sats.',
      );
    }
    if (invoiceAmount > maxInvoiceByBalance) {
      throw StateError(
        'Invoice amount ${invoiceAmount.getInSats} sats exceeds affordable maximum ${maxInvoiceByBalance.getInSats} sats after gas+swap fees.',
      );
    }

    final estimatedSwapFeeSats =
        invoiceAmount.getInSats.toDouble() * (percentage / 100.0) +
        minerFeesSatsRoundedUp;
    final estimatedSwapFee = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      estimatedSwapFeeSats.ceil(),
    ).roundUp(BitcoinUnit.sat);

    return (
      balance: balanceRounded,
      invoiceAmount: invoiceAmount,
      estimatedGasFee: estimatedGasFee,
      estimatedSwapFee: estimatedSwapFee,
    );
  }

  Future<BitcoinAmount> _estimateLockGasFee() async {
    final gasPrice = await rootstock.client.getGasPrice();
    final feeWei = gasPrice.getInWei * BigInt.from(_estimatedLockGasLimit);
    return BitcoinAmount.inWei(feeWei);
  }

  Future<SubmarinePair> _getSubmarinePair({
    required String from,
    required String to,
  }) async {
    final response = await getIt<BoltzClient>().getSwapSubmarine();
    if (!response.isSuccessful || response.body == null) {
      throw StateError('Failed to fetch submarine swap pairs from Boltz');
    }

    final body = response.body;
    if (body is! Map) {
      throw StateError('Unexpected Boltz submarine pairs response shape');
    }

    final fromMap = body[from];
    if (fromMap is! Map) {
      throw StateError('Boltz submarine source currency not found: $from');
    }

    final pairRaw = fromMap[to];
    if (pairRaw is! Map) {
      throw StateError('Boltz submarine pair not found: $from->$to');
    }

    final pairJson = Map<String, dynamic>.from(
      pairRaw.map((key, value) => MapEntry(key.toString(), value)),
    );
    return SubmarinePair.fromJson(pairJson);
  }

  Uint8List _decodePaymentHash(String paymentHash) {
    final normalized = paymentHash.startsWith('0x')
        ? paymentHash.substring(2)
        : paymentHash;

    if (normalized.length != 64) {
      throw StateError(
        'Expected payment_hash to be 32 bytes (64 hex chars), got ${normalized.length} chars: $paymentHash',
      );
    }

    return Uint8List.fromList(hex.decode(normalized));
  }

  EthereumAddress _resolveSubmarineClaimAddress(SubmarineResponse swap) {
    final raw = swap.claimPublicKey;
    if (raw == null || raw.isEmpty) {
      throw StateError(
        'Boltz submarine response did not include a claim address. '
        'Received: ${swap.toString()}',
      );
    }

    try {
      return EthereumAddress.fromHex(raw);
    } catch (_) {
      throw StateError(
        'Invalid submarine claim address format: $raw. Response: ${swap.toString()}',
      );
    }
  }

  Stream<SwapStatus> _waitForSwapOnChain(String id) {
    return getIt<BoltzClient>().subscribeToSwap(id: id).doOnData((swapStatus) {
      logger.i('Swap status update: ${swapStatus.status}, $swapStatus');
    });
  }

  /// Attempts to create an invoice from the current user's LUD16 lightning
  /// address. Returns the bolt11 invoice string on success, or `null` if the
  /// user has no LUD16 set or the LNURL flow fails.
  Future<String?> _tryCreateInvoiceFromLud16(int amountSats) async {
    try {
      final pubkey = auth.activeKeyPair?.publicKey;
      if (pubkey == null) return null;

      final profile = await getIt<MetadataUseCase>().loadMetadata(pubkey);
      final lud16 = profile?.metadata.lud16;
      if (lud16 == null || lud16.isEmpty) {
        logger.d('No LUD16 set on user metadata');
        return null;
      }

      final lud16Link = Lnurl.getLud16LinkFromLud16(lud16);
      if (lud16Link == null) {
        logger.w('Failed to parse LUD16 address: $lud16');
        return null;
      }

      final lnurl = Lnurl(
        transport: LnurlTransportHttpImpl(HttpRequestDS(http.Client())),
      );
      final lnurlResponse = await lnurl.getLnurlResponse(lud16Link);
      if (lnurlResponse == null || lnurlResponse.callback == null) {
        logger.w('LNURL response invalid for $lud16');
        return null;
      }

      final invoiceResponse = await lnurl.fetchInvoice(
        lnurlResponse: lnurlResponse,
        amountSats: amountSats,
      );
      if (invoiceResponse == null || invoiceResponse.invoice.isEmpty) {
        logger.w('Failed to fetch invoice from LUD16 $lud16');
        return null;
      }

      logger.i('Successfully created invoice via LUD16 ($lud16)');
      return invoiceResponse.invoice;
    } catch (e) {
      logger.w('Error creating invoice from LUD16: $e');
      return null;
    }
  }
}
