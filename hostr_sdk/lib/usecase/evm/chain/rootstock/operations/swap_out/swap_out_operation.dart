import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/evm/main.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' hide params;

import '../../../../../../datasources/boltz/boltz.dart';
import '../../../../../../datasources/boltz/swagger_generated/boltz.swagger.dart';
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
  });

  @override
  Future<void> execute() async {
    try {
      final quote = await _buildSwapOutQuote();

      if (nwc.getActiveConnection() == null) {
        throw 'No active NWC connection';
      }

      final makeInvoice = await nwc.makeInvoice(
        nwc.getActiveConnection()!,
        amountSats: quote.invoiceAmount.getInSats.toInt(),
        description: 'Hostr swap out',
      );
      logger.i('Invoice created: ${makeInvoice.invoice}');
      final invoicePreimageHash = Bolt11PaymentRequest(
        makeInvoice.invoice,
      ).tags.where((tag) => tag.type == 'payment_hash').first.data;
      final preimageHash = _decodePaymentHash(invoicePreimageHash);
      final swap = await getIt<BoltzClient>().submarine(
        invoice: makeInvoice.invoice,
      );
      emit(SwapOutAwaitingOnChain());
      final swapStatus = _waitForSwapOnChain(swap.id);
      swapStatus
          .where(
            (status) =>
                status.status == 'transaction.confirmed' ||
                status.status == 'transaction.mempool',
          )
          .doOnData((status) {
            emit(SwapOutFunded());
          });
      final x = swapStatus
          .where((status) => status.status == 'invoice.paid')
          .doOnData((status) {
            emit(SwapOutCompleted());
          });

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
      emit(SwapOutFunded());

      await x.first;
      // String refundTx = await swapContract.refund(args, credentials: credentials)
      logger.i('Sent RBTC in: $tx');
    } catch (e, st) {
      logger.e('Error during swap out operation: $e');
      emit(SwapOutFailed(e, st));
      addError(SwapOutFailed(e, st));
      rethrow;
    } finally {
      await close();
    }
  }

  @override
  Future<SwapOutFees> estimateFees() async {
    final quote = await _buildSwapOutQuote();

    return SwapOutFees(
      estimatedGasFees: quote.estimatedGasFee,
      estimatedSwapFees: quote.estimatedSwapFee,
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
}
