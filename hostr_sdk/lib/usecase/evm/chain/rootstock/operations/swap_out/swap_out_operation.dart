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
          description: 'Hostr swap out',
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
