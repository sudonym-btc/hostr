import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:crypto/crypto.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/data/sources/boltz/swagger_generated/boltz.swagger.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../auth/auth.dart';
import '../evm/evm_chain.dart';
import '../payments/constants.dart';

enum SwapProgress {
  initiated,
  paymentCreated,
  paymentInFlight,
  waitingOnchain,
  claimed,
  completed,
  failed,
}

@Singleton()
class Swap {
  final CustomLogger logger = CustomLogger();
  final Auth auth;

  Swap({required this.auth});

  Future<void> swapOutAll(EvmChain evmChain) async {
    /** @todo: determine how much amount is available to be swapped out */
    // Calculate the total amount of funds that can be swapped out.
    // This might involve fetching the balance from a wallet or another source.

    /** @todo: fetch invoice of current user of total amount - fees */
    // Generate or fetch an invoice for the user.
    // The invoice should be for the total amount minus any applicable fees.

    KeyPair? key = auth.activeKeyPair;
    EthPrivateKey ethKey = getEthCredentials(key!.privateKey!);
    EvmChain r = evmChain;

    double balance = await r.getBalance(
      getEthCredentials(key.privateKey!).address,
    );
    if (balance == 0) {
      logger.i('No balance to swap out');
      return;
    }

    // NwcMethodResponse? response = await getIt<NwcService>().makeInvoice(
    //     NwcMethodMakeInvoiceParams(
    //         amount: (balance.toInt() / satoshiWeiFactor.toDouble()).toInt()));

    // Example invoice for demonstration purposes
    final invoice = "";
    String invoicePreimageHash = Bolt11PaymentRequest(invoice).paymentRequest;

    // Convert invoice amount to satoshis (not used in current flow)
    // final int invoiceAmount =
    //     (Bolt11PaymentRequest(invoice).amount.toDouble() * pow(10, 8)) as int;

    try {
      // Initialize Boltz library
      // final fees = await boltz.Fees(boltzUrl: config.boltzUrl).chain();
      // Uncomment and use the above line to fetch the fees from the Boltz API.

      // Create a submarine swap
      final swap = await getIt<BoltzClient>().submarine(invoice: invoice);
      // swap."expectedAmount" is set

      // Create the args record for the lock function
      final lockArgs = (
        claimAddress: EthereumAddress.fromHex(swap.claimPublicKey!),
        preimageHash: Uint8List.fromList(invoicePreimageHash.codeUnits),
        timelock: BigInt.from(swap.timeoutBlockHeight),
      );

      EtherSwap swapContract = await evmChain.getEtherSwapContract();

      // Lock the funds in the EtherSwap contract
      String tx = await swapContract.lock(lockArgs, credentials: ethKey);
      // String refundTx = await swapContract.refund(args, credentials: credentials)
      logger.i('Sent RBTC in: $tx');
    } catch (e) {
      // Handle errors and print the error message
      logger.e('\n\nERRRR: $e\n\n');
    }
  }

  Future<void> swapIn(
    int amountSats, {
    void Function(SwapProgress progress)? onProgress,
    void Function(String paymentId)? onPaymentCreated,
    required EvmChain evmChain,
  }) async {
    /// Check that NWC is connected first
    Uri? nwc = await getIt<NwcStorage>().getUri();
    if (nwc == null) {
      throw Exception('No NWC URI found');
    }

    KeyPair? key = auth.activeKeyPair;
    EthPrivateKey ethKey = getEthCredentials(key!.privateKey!);

    /// We generate the preimage for the invoice we will pay
    /// This prevents swapper from being able to claim the HTLC
    /// until we reveil the preimage to make the claim transaction
    /// Has to be 32 bytes for the claim txn to pass
    var random = Random.secure();
    List<int> preimage = List<int>.generate(32, (i) => random.nextInt(256));
    String preimageHash = sha256.convert(preimage).toString();
    logger.i("Preimage: $preimage, ${preimage.length}");
    onProgress?.call(SwapProgress.initiated);

    /// Create a reverse submarine swap
    final swap = await getIt<BoltzClient>().reverseSubmarine(
      invoiceAmount: amountSats.toDouble(),
      claimAddress: ethKey.address.eip55With0x, // Check with 0x or not
      preimageHash: preimageHash,
    );
    String invoiceToPay = swap.invoice;

    EtherSwap swapContract = await evmChain.getEtherSwapContract();

    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoiceToPay);

    logger.i(
      'Invoice to pay: ${pr.amount.toDouble() * btcSatoshiFactor} against $amountSats planned, hash: ${pr.tags.firstWhere((t) => t.type == 'payment_hash').data} against planned $preimageHash',
    );

    /// Before paying, check that the invoice swapper generated is for the correct amount
    assert(pr.amount.toDouble() * btcSatoshiFactor == amountSats.toDouble());

    /// Before paying, check that the invoice hash is equivalent to the preimage hash we generated
    /// Ensures we know the invoice can't be settled until we reveal it in the claim txn
    assert(
      pr.tags.firstWhere((t) => t.type == 'payment_hash').data == preimageHash,
    );

    /// Pay the invoice, though it won't complete until we reveal the preimage in the claim txn
    final start = getIt<PaymentsManager>().startPayment(
      Bolt11PaymentParameters(
        amount: Amount(
          currency: Currency.BTC,
          value: amountSats.toDouble() / btcSatoshiFactor,
        ),
        to: invoiceToPay,
      ),
    );
    onPaymentCreated?.call(start.id);
    onProgress?.call(SwapProgress.paymentCreated);
    start.cubit.execute();
    onProgress?.call(SwapProgress.paymentInFlight);

    while (true) {
      SwapStatus swapStatus = await getIt<BoltzClient>().getSwap(id: swap.id);
      // ReverseResponse swap = await getIt<BoltzClient>().getSwap
      logger.i('Swap status: ${swapStatus.status}, $swapStatus');

      if (swapStatus.status == 'transaction.mempool' ||
          swapStatus.status == 'transaction.confirmed') {
        onProgress?.call(SwapProgress.waitingOnchain);

        /// Fetch the from address of the lockup transaction to use as refund address
        TransactionInformation? lockupTx = await evmChain.getTransaction(
          swapStatus.transaction!.id!,
        );

        if (lockupTx == null) {
          logger.i('Lockup transaction not found');
          await Future.delayed(Duration(milliseconds: 500));
          continue;
        }

        logger.i('Lockup transaction: $lockupTx');

        /// Create the args record for the claim function
        final claimArgs = (
          amount: BigInt.from(swap.onchainAmount!) * satoshiWeiFactor,
          preimage: Uint8List.fromList(preimage),

          /// Why is swap.refundPublicKey null in the response
          refundAddress:
              lockupTx.from, //EthereumAddress.fromHex(swap.refundPublicKey!),

          timelock: BigInt.from(swap.timeoutBlockHeight),

          /// EIP-712 signature parts from the claim address (placeholder zeros until wired up)
          v: BigInt.zero,
          r: Uint8List(32),
          s: Uint8List(32),
        );

        logger.i('Claim can be unlocked with arguments: $claimArgs');

        /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
        /// Must send via RIF if no previous balance exists
        String tx = await swapContract.claim(claimArgs, credentials: ethKey);
        onProgress?.call(SwapProgress.claimed);
        logger.i('Sent RBTC in: $tx');
        onProgress?.call(SwapProgress.completed);
        break;
      }
      await Future.delayed(Duration(milliseconds: 1000));
    }
  }
}
