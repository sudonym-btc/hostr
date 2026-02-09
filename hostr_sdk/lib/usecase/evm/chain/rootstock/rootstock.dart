import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../datasources/boltz/boltz.dart';
import '../../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../../util/bitcoin_amount.dart';
import '../../operations/swap_in/swap_in_models.dart';
import '../evm_chain.dart';
import 'operations/swap_in/swap_in_operation.dart';

@Singleton()
class Rootstock extends EvmChain {
  final HostrConfig config;
  Rootstock({required this.config})
    : super(client: Web3Client(config.rootstockConfig.rpcUrl, http.Client()));

  Future<void> swapOutAll({required KeyPair key}) async {
    /** @todo: determine how much amount is available to be swapped out */
    // Calculate the total amount of funds that can be swapped out.
    // This might involve fetching the balance from a wallet or another source.

    /** @todo: fetch invoice of current user of total amount - fees */
    // Generate or fetch an invoice for the user.
    // The invoice should be for the total amount minus any applicable fees.

    EthPrivateKey ethKey = getEvmCredentials(key.privateKey!);

    final balance = await getBalance(ethKey.address);
    if (balance == BitcoinAmount.zero()) {
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
  Future<BitcoinAmount> getMinimumSwapIn() async {
    final response = (await getIt<BoltzClient>().getSwapReserve());
    return BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      response.body["BTC"]["RBTC"]["limits"]["minimal"],
    );
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

  @override
  RootstockSwapInOperation swapIn(SwapInParams params) =>
      getIt<RootstockSwapInOperation>(param1: params);
}
