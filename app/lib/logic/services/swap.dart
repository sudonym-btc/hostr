import 'dart:math';
import 'dart:typed_data';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/boltz/contracts/EtherSwap.g.dart';
import 'package:hostr/data/sources/boltz/swagger_generated/boltz.swagger.dart';
import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

BigInt satoshiWeiFactor = BigInt.from(10).pow(10);
num btcSatoshiFactor = pow(10, 8);
num btcMilliSatoshiFactor = pow(10, 11);

@Singleton()
class SwapService {
  CustomLogger logger = CustomLogger();
  Web3Client client;
  Config config;
  SwapService(this.config)
      : client = Web3Client(config.rootstockRpcUrl, Client());

  Future<EtherSwap> getRootstockEtherSwap() async {
    // Fetch RBTC contracts
    final rbtcContracts = await getIt<BoltzClient>().rbtcContracts();
    final rbtcSwapContract = rbtcContracts.swapContracts.etherSwap;

    logger.i('RBTC Swap contract: $rbtcSwapContract');
    // Initialize EtherSwap contract
    return EtherSwap(
        address: EthereumAddress.fromHex(rbtcSwapContract!), client: client);
  }

  swapOutAll() async {
    /** @todo: determine how much amount is available to be swapped out */
    // Calculate the total amount of funds that can be swapped out.
    // This might involve fetching the balance from a wallet or another source.

    /** @todo: fetch invoice of current user of total amount - fees */
    // Generate or fetch an invoice for the user.
    // The invoice should be for the total amount minus any applicable fees.

    KeyPair? key = await getIt<KeyStorage>().getActiveKeyPair();
    EthPrivateKey ethKey = getEthCredentials(key!.privateKey!);
    Rootstock r = getIt<Rootstock>();

    double balance =
        await r.getBalance(getEthCredentials(key.privateKey!).address);
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

    // Convert invoice amount to satoshis
    int invoiceAmount =
        (Bolt11PaymentRequest(invoice).amount.toDouble() * pow(10, 8)) as int;

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

      EtherSwap swapContract = await getRootstockEtherSwap();

      // Lock the funds in the EtherSwap contract
      String tx = await swapContract.lock(lockArgs, credentials: ethKey);
      // String refundTx = await swapContract.refund(args, credentials: credentials)
      logger.i('Sent RBTC in: $tx');
    } catch (e) {
      // Handle errors and print the error message
      logger.e('\n\nERRRR: $e\n\n');
    }
  }

  // rif() {
  //   Forwarder
  // }

  listEvents() async {
    KeyPair? key = await getIt<KeyStorage>().getActiveKeyPair();
    EthPrivateKey ethKey = getEthCredentials(key!.privateKey!);

    MultiEscrow e = MultiEscrow(
        address: EthereumAddress.fromHex(
            '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512'),
        client: client);
    logger.i('listing for events');
    logger.i(e.self.events.map((x) => x.name));
    // List past events
    final filter = FilterOptions.events(
      contract: e.self,
      event: e.self.events.firstWhere((x) => x.name == 'DebugLog'),
      fromBlock: BlockNum.exact(449),
      toBlock: BlockNum.current(),
    );

    final logs = await client.getLogs(filter);
    logger.i(logs);
    for (var log in logs) {
      logger.i('Past Trade created: $log');
    }

    // e.tradeCreatedEvents(fromBlock: BlockNum.genesis()).listen((event) {
    //   logger.i('Trade created: $event');
    // });
  }

  escrow(
      {required String eventId,
      required Amount amount,
      required String sellerPubkey,
      required String escrowPubkey,
      required String escrowContractAddress,
      required int timelock}) async {
    KeyPair? key = await getIt<KeyStorage>().getActiveKeyPair();
    EthPrivateKey ethKey = getEthCredentials(key!.privateKey!);

    MultiEscrow e = MultiEscrow(
        address: EthereumAddress.fromHex(escrowContractAddress),
        client: client);
    var tuple = (
      tradeId: getBytes32(eventId),
      timelock: BigInt.from(timelock),

      /// Arbiter public key from their nostr advertisement
      arbiter: getEthAddressFromPublicKey(escrowPubkey),

      /// Seller address derived from their nostr pubkey
      seller: getEthAddressFromPublicKey(sellerPubkey),

      /// Our address derived from our nostr private key
      buyer: ethKey.address,
      escrowFee: BigInt.from(100),
    );
    logger.i('Creating escrow for $eventId');
    logger.i(tuple);
    String escrowTx = await e.createTrade(tuple,
        credentials: ethKey,
        transaction: Transaction(
            value: EtherAmount.fromBigInt(
                EtherUnit.wei,
                BigInt.from(amount.value * btcSatoshiFactor) *
                    satoshiWeiFactor)));

    final receipt = await client.getTransactionReceipt(escrowTx);
    logger.i(receipt);
  }

  swapIn(int amountSats) async {
    /// Check that NWC is connected first
    Uri? nwc = await getIt<NwcStorage>().getUri();
    if (nwc == null) {
      throw Exception('No NWC URI found');
    }

    KeyPair? key = await getIt<KeyStorage>().getActiveKeyPair();
    EthPrivateKey ethKey = getEthCredentials(key!.privateKey!);

    /// We generate the preimage for the invoice we will pay
    /// This prevents swapper from being able to claim the HTLC
    /// until we reveil the preimage to make the claim transaction
    /// Has to be 32 bytes for the claim txn to pass
    var random = Random.secure();
    List<int> preimage = List<int>.generate(32, (i) => random.nextInt(256));
    String preimageHash = sha256.convert(preimage).toString();
    logger.i("Preimage: $preimage, ${preimage.length}");

    /// Create a reverse submarine swap
    final swap = await getIt<BoltzClient>().reverseSubmarine(
        invoiceAmount: amountSats.toDouble(),
        claimAddress: ethKey.address.hexEip55,
        preimageHash: preimageHash);
    String invoiceToPay = swap.invoice;

    EtherSwap swapContract = await getRootstockEtherSwap();

    Bolt11PaymentRequest pr = Bolt11PaymentRequest(invoiceToPay);

    logger.i(
        'Invoice to pay: ${pr.amount.toDouble() * btcSatoshiFactor} against $amountSats planned, hash: ${pr.tags.firstWhere((t) => t.type == 'payment_hash').data} against planned $preimageHash');

    /// Before paying, check that the invoice swapper generated is for the correct amount
    assert(pr.amount.toDouble() * btcSatoshiFactor == amountSats.toDouble());

    /// Before paying, check that the invoice hash is equivalent to the preimage hash we generated
    /// Ensures we know the invoice can't be settled until we reveal it in the claim txn
    assert(pr.tags.firstWhere((t) => t.type == 'payment_hash').data ==
        preimageHash);

    /// Pay the invoice, though it won't complete until we reveal the preimage in the claim txn
    PaymentCubit paymentCubit = PaymentsManager().create(
        Bolt11PaymentParameters(
            amount: Amount(
                currency: Currency.BTC,
                value: amountSats.toDouble() / btcSatoshiFactor),
            to: invoiceToPay));

    paymentCubit.execute();

    while (true) {
      SwapStatus swapStatus = await getIt<BoltzClient>().getSwap(id: swap.id);
      // ReverseResponse swap = await getIt<BoltzClient>().getSwap
      logger.i('Swap status: ${swapStatus.status}, $swapStatus');

      if (swapStatus.status == 'transaction.mempool' ||
          swapStatus.status == 'transaction.confirmed') {
        /// Fetch the from address of the lockup transaction to use as refund address
        TransactionInformation? lockupTx =
            await client.getTransactionByHash(swapStatus.transaction!.id!);

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
        );

        logger.i('Claim can be unlocked with arguments: $claimArgs');

        /// Withdraw the funds to our own address, providing swapper with preimage to settle lightning
        /// Must send via RIF if no previous balance exists
        String tx = await swapContract.claim(claimArgs, credentials: ethKey);
        logger.i('Sent RBTC in: $tx');
        break;
      }
      await Future.delayed(Duration(milliseconds: 1000));
    }
  }

  Stream<TradeCreated> checkEscrowStatus(String reservationRequestId) async* {
    logger.i('Checking escrow status for reservation: $reservationRequestId');
    Uint8List idBytes32 = getBytes32(reservationRequestId);
    String hexTopic = getTopicHex(idBytes32);

    Nip51List? trustedEscrows = await getIt<NostrService>().trustedEscrows();
    if (trustedEscrows == null) {
      return;
    }
    for (Nip51ListElement item in trustedEscrows.elements) {
      List<Escrow> escrowServices =
          await getIt<NostrService>().startRequestAsync(filters: [
        Filter(kinds: [NOSTR_KIND_ESCROW], authors: [item.value])
      ]);
      for (var escrow in escrowServices) {
        logger.i(
            'Searching for events from escrow: ${escrow.parsedContent.contractAddress}');
        MultiEscrow e = MultiEscrow(
            address:
                EthereumAddress.fromHex(escrow.parsedContent.contractAddress),
            client: client);

        Trades x = await e.trades(($param9: idBytes32));
        logger.i('Current trade: $x');
        final tradeCreatedEvent =
            e.self.events.firstWhere((x) => x.name == 'TradeCreated');
        final sig = bytesToHex(tradeCreatedEvent.signature,
            padToEvenLength: true, include0x: true);
        logger.i('Log sig $sig');
        final filter = FilterOptions(
          topics: [
            [
              // TODO include other event type signatures
              sig
            ], // Topic 0: event signature.
            // Topic 1: tradeId indexed parameter.
            [hexTopic],
          ],
          fromBlock: BlockNum.exact(0),
          toBlock: BlockNum.exact(await client.getBlockNumber()),
        );

        final logs = await client.getLogs(filter);
        logger.i('Filtered logs: ${logs.length} for hexTopic $hexTopic');

        List<TradeCreated> tradeCreated = logs.map((FilterEvent result) {
          logger.i('trade log topics: ${result.topics}');
          final decoded = tradeCreatedEvent.decodeResults(
            result.topics!,
            result.data!,
          );
          return TradeCreated(
            decoded,
            result,
          );
        }).toList();
      }
    }
  }
}

Uint8List getBytes32(String eventId) {
  return Uint8List.fromList(hex.decode(eventId));
}

getTopicHex(Uint8List idBytes32) {
  return bytesToHex(idBytes32, padToEvenLength: true, include0x: true);
}
