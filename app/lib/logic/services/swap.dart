import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/data/sources/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/boltz.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

BigInt satoshiWeiFactor = BigInt.from(10).pow(10);

@Injectable(env: Env.allButTestAndMock)
class SwapService {
  CustomLogger logger = CustomLogger();
  Rootstock rootstock = getIt<Rootstock>();
  BoltzClient boltzClient = getIt<BoltzClient>();
  Config config = getIt<Config>();
  KeyStorage keyStorage = getIt<KeyStorage>();

  Future<EtherSwap> getRootstockEtherSwap() async {
    // Fetch RBTC contracts
    final rbtcContracts = await boltzClient.rbtcContracts();
    final rbtcSwapContract = rbtcContracts['swapContracts']['EtherSwap'];

    // Initialize Web3 client
    final Web3Client client =
        Web3Client(getIt<Config>().rootstockRpcUrl, Client());

    // Initialize EtherSwap contract
    return EtherSwap(address: rbtcSwapContract, client: client);
  }

  swapOutAll() async {
    /** @todo: determine how much amount is available to be swapped out */
    // Calculate the total amount of funds that can be swapped out.
    // This might involve fetching the balance from a wallet or another source.

    /** @todo: fetch invoice of current user of total amount - fees */
    // Generate or fetch an invoice for the user.
    // The invoice should be for the total amount minus any applicable fees.

    NostrKeyPairs? key = await keyStorage.getActiveKeyPair();
    EthPrivateKey ethKey = getEthCredentials(key!.private);

    // Example invoice for demonstration purposes
    final invoice =
        "lnbcrt1m1pnkl4sppp5vc2zmdw9x2xr63nngr73da6u863kfhmxc68nm7eycarwq760xgdqdqqcqzzsxqyz5vqsp5vz26y0ckx205lrm2d3mz23ynkp26kshumn0zjvc7xgkjtfh7l8mq9qxpqysgqn45lz8rn990f77ftrk3rvg03dlmnj9ze2ue9p3eypzau84w3wluz2g25ydj94kefur0v8ln6e4f76n29jsqjraatpq0mdazrl5klpdcp5v4dg8";
    String invoicePreimageHash = Bolt11PaymentRequest(invoice).paymentRequest;

    // Convert invoice amount to satoshis
    int invoiceAmount =
        (Bolt11PaymentRequest(invoice).amount.toDouble() * pow(10, 8)) as int;

    try {
      // await boltz.LibBoltz.init();

      // Initialize Boltz library
      // final fees = await boltz.Fees(boltzUrl: config.boltzUrl).chain();
      // Uncomment and use the above line to fetch the fees from the Boltz API.

      // Create a submarine swap
      final swap = await boltzClient.submarine(invoice: invoice);
      // swap."expectedAmount" is set

      // Create the args record for the lock function
      final lockArgs = (
        claimAddress: EthereumAddress.fromHex(swap.claimAddress),
        preimageHash: Uint8List.fromList(invoicePreimageHash.codeUnits),
        timelock: BigInt.from(swap.timeoutBlockHeight),
      );

      EtherSwap swapContract = await getRootstockEtherSwap();

      // Lock the funds in the EtherSwap contract
      Future<String> tx = swapContract.lock(lockArgs, credentials: ethKey);

      logger.i('Sent RBTC in: ${tx}');
    } catch (e) {
      // Handle errors and print the error message
      print('\n\nERRRR: ' + e.toString() + '\n\n');
    }
  }

  swapIn(int amountSats) async {
    NostrKeyPairs? key = await keyStorage.getActiveKeyPair();
    EthPrivateKey ethKey = getEthCredentials(key!.private);

    String preimage = NostrKeyPairs.generate().private;
    String preimageHash = sha256.convert(utf8.encode(preimage)).toString();

    // Create a submarine swap
    final swap = await boltzClient.reverseSubmarine(
        invoiceAmount: amountSats,
        claimAddress: ethKey.address.hex,
        preimageHash: preimageHash);

    EtherSwap swapContract = await getRootstockEtherSwap();

    // Create the args record for the claim function
    final claimArgs = (
      amount: BigInt.from(swap.onchainAmount * satoshiWeiFactor),
      preimage: Uint8List.fromList(preimage.codeUnits),
      refundAddress: EthereumAddress.fromHex(swap.refundAddress),
      timelock: BigInt.from(swap.timeoutBlockHeight),
    );

    // Lock the funds in the EtherSwap contract
    Future<String> tx = swapContract.claim(claimArgs, credentials: ethKey);

    logger.i('Sent RBTC in: ${tx}');
  }
}
