import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:crypto/crypto.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/sources/boltz/boltz.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/data/sources/boltz/swagger_generated/boltz.swagger.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/evm/rif_relay/rif_relay.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/payments/payments.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../payments/constants.dart';
import 'evm_chain.dart';

@Singleton()
class Rootstock extends EvmChain {
  late final RifRelay rifRelay = getIt<RifRelay>(param1: client);
  final Config config;
  Rootstock({required this.config})
    : super(client: Web3Client(config.rootstock.rpcUrl, http.Client()));

  Future<ReverseResponse> generateSwapRequest({
    required EthPrivateKey ethKey,
    required int amountSats,
    required String preimageHash,
  }) async {
    final smartWalletInfo = await rifRelay.getSmartWalletAddress(ethKey);
    final claimAddress = smartWalletInfo.address.eip55With0x;
    logger.i('Using RIF smart wallet as claim address: $claimAddress');
    return getIt<BoltzClient>().reverseSubmarine(
      invoiceAmount: amountSats.toDouble(),
      claimAddress: claimAddress,
      preimageHash: preimageHash,
    );
  }

  PaymentCubit paySwapInvoice({
    required String invoice,
    required amountSats,
    required String preimageHash,
  }) {
    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoice);

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
    final payment = getIt<Payments>().pay(
      Bolt11PaymentParameters(
        amount: Amount(
          currency: Currency.BTC,
          value: amountSats.toDouble() / btcSatoshiFactor,
        ),
        to: invoice,
      ),
    );
    payment.execute();
    return payment;
  }

  generateClaimArgs({
    required TransactionInformation lockupTx,
    required ReverseResponse swap,
    required List<int> preimage,
  }) {
    return (
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
  }

  Future<String> claim({
    required EthPrivateKey ethKey,
    required claimArgs,
  }) async {
    EtherSwap swapContract = await getEtherSwapContract();
    return rifRelay.relayClaimTransaction(
      signer: ethKey,
      etherSwap: swapContract,
      preimage: claimArgs.preimage,
      amountWei: claimArgs.amount,
      refundAddress: claimArgs.refundAddress,
      timeoutBlockHeight: claimArgs.timelock,
    );
  }

  /// We generate the preimage for the invoice we will pay
  /// This prevents swapper from being able to claim the HTLC
  /// until we reveil the preimage to make the claim transaction
  /// Has to be 32 bytes for the claim txn to pass
  ({List<int> preimage, String hash}) _newPreimage() {
    final random = Random.secure();
    final preimage = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = sha256.convert(preimage).toString();
    return (preimage: preimage, hash: hash);
  }

  Future<SwapStatus> _waitForSwapOnChain(String id) {
    return getIt<BoltzClient>()
        .subscribeToSwap(id: id)
        .doOnData((swapStatus) {
          logger.i('Swap status update: ${swapStatus.status}, $swapStatus');
        })
        .firstWhere(
          (swapStatus) =>
              swapStatus.status == 'transaction.confirmed' ||
              swapStatus.status == 'transaction.mempool',
        );
  }

  @override
  Future<int> getMinimumSwapIn() async {
    final response = (await getIt<BoltzClient>().getSwapReserve());
    return response.body["BTC"]["RBTC"]["limits"]["minimal"];
  }

  @override
  Stream<SwapState> swapIn({
    required KeyPair key,
    required int amountSats,
  }) async* {
    EthPrivateKey ethKey = getEvmCredentials(key.privateKey!);

    final preimageData = _newPreimage();
    logger.i("Preimage: ${preimageData.hash}, ${preimageData.preimage.length}");

    /// Create a reverse submarine swap
    final swap = await generateSwapRequest(
      amountSats: amountSats,
      ethKey: ethKey,
      preimageHash: preimageData.hash,
    );
    yield SwapInitiated();

    logger.d('Swap ${swap.toString()}');
    PaymentCubit p = paySwapInvoice(
      invoice: swap.invoice,
      amountSats: amountSats,
      preimageHash: preimageData.hash,
    );
    yield SwapPaymentCreated(paymentCubit: p);
    SwapStatus swapStatus = await _waitForSwapOnChain(swap.id);

    yield SwapAwaitingOnChain();

    TransactionInformation lockupTx = await awaitTransaction(
      swapStatus.transaction!.id!,
    );
    yield SwapFunded();

    /// Create the args record for the claim function
    final claimArgs = generateClaimArgs(
      lockupTx: lockupTx,
      swap: swap,
      preimage: preimageData.preimage,
    );

    logger.i('Claim can be unlocked with arguments: $claimArgs');

    /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
    /// Must send via RIF if no previous balance exists
    String tx = await claim(ethKey: ethKey, claimArgs: claimArgs);
    yield SwapClaimed();
    final receipt = await awaitReceipt(tx);
    logger.i('Claim receipt: $receipt');
    yield SwapCompleted();
    logger.i('Sent RBTC in: $tx');
  }

  Future<void> swapOutAll({required KeyPair key}) async {
    /** @todo: determine how much amount is available to be swapped out */
    // Calculate the total amount of funds that can be swapped out.
    // This might involve fetching the balance from a wallet or another source.

    /** @todo: fetch invoice of current user of total amount - fees */
    // Generate or fetch an invoice for the user.
    // The invoice should be for the total amount minus any applicable fees.

    EthPrivateKey ethKey = getEvmCredentials(key.privateKey!);

    double balance = await getBalance(ethKey.address);
    if (balance == 0) {
      logger.i('No balance to swap out');
      return;
    }

    // NwcMethodResponse? response = await getIt<NwcService>().makeInvoice(
    //     NwcMethodMakeInvoiceParams(
    //         amount: (balance.toInt() / satoshiWeiFactor.toDouble()).toInt()));

    // Example invoice for demonstration purposes
    // final invoice = payments.nwc.getInvoice(amount: balance - fees);
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

      EtherSwap swapContract = await getEtherSwapContract();

      // Lock the funds in the EtherSwap contract
      String tx = await swapContract.lock(lockArgs, credentials: ethKey);
      // String refundTx = await swapContract.refund(args, credentials: credentials)
      logger.i('Sent RBTC in: $tx');
    } catch (e) {
      // Handle errors and print the error message
      logger.e('\n\nERRRR: $e\n\n');
    }
  }

  @override
  Future<EtherSwap> getEtherSwapContract() async {
    // Fetch RBTC contracts
    final rbtcContracts = await getIt<BoltzClient>().rbtcContracts();
    final rbtcSwapContract = rbtcContracts.swapContracts.etherSwap;

    logger.i('RBTC Swap contract: $rbtcSwapContract');
    // Initialize EtherSwap contract
    return EtherSwap(
      address: EthereumAddress.fromHex(rbtcSwapContract!),
      client: client,
    );
  }
}
