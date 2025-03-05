import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/bitcoin_network.dart';
import 'package:ndk/ndk.dart';

Uri parseNwc(String nwcString) {
  Uri nwcUri = Uri.parse(nwcString);
  assert(nwcUri.scheme == 'nostr+walletconnect');
  assert(nwcUri.queryParameters.containsKey('relay'));

  /// Check that relay url correct as well
  Uri.parse(nwcUri.queryParameters['relay']!);
  return nwcUri;
}

String parseSecret(Uri nwc) {
  return nwc.queryParameters['secret']!;
}

String parsePubkey(Uri nwc) {
  return nwc.host;
}

@Injectable(env: Env.allButTestAndMock)
class NwcService {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();
  NwcStorage nwcStorage = getIt<NwcStorage>();
  Ndk nostr = getIt<Ndk>();

  /// User pasted/scanned a NWC from their wallet
  /// e.g. nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  save(String uri) async {
    // Parse the NWC string, check protocol, secret, relay
    parseNwc(uri);
    await nwcStorage.set([uri.toString()]);
  }

  Future<GetInfoResponse> getInfo(String nwc) async {
    logger.i('Connecting to NWC: $nwc');
    return nostr.nwc.getInfo(await nostr.nwc.connect(nwc));
  }

  Future<PayInvoiceResponse> payInvoice(String invoice, int? amount) async {
    return nostr.nwc.payInvoice(
        await nostr.nwc.connect((await nwcStorage.get())[0]),
        invoice: invoice);
  }

  Future<MakeInvoiceResponse> makeInvoice(int amountSats) async {
    return nostr.nwc.makeInvoice(
        await nostr.nwc.connect((await nwcStorage.get())[0]),
        amountSats: amountSats);
  }

  Future<LookupInvoiceResponse> lookupInvoice(
      {String? paymentHash, String? invoice}) async {
    return nostr.nwc.lookupInvoice(
        await nostr.nwc.connect((await nwcStorage.get())[0]),
        paymentHash: paymentHash,
        invoice: invoice);
  }
}

@Injectable(as: NwcService, env: [Env.test, Env.mock])
class MockNostrWalletConnectService extends NwcService {
  @override
  Future<GetInfoResponse> getInfo(String nwc) async {
    return GetInfoResponse(
      alias: 'Wallet of Satoshi',
      color: '#FFFF00',
      pubkey: 'npub34324237789797987',
      resultType: 'get_info',
      network: BitcoinNetwork.mainnet,
      blockHeight: 800000,
      blockHash: '',
      methods: ["pay_invoice", "lookup_invoice", "make_invoice"],
      notifications: [],
    );
  }

  @override
  Future<PayInvoiceResponse> payInvoice(String invoice, int? amount) async {
    return PayInvoiceResponse(
        preimage: 'preimage', resultType: 'pay_invoice', feesPaid: 1);
  }

  @override
  Future<LookupInvoiceResponse> lookupInvoice(
      {String? paymentHash, String? invoice}) async {
    return LookupInvoiceResponse(
        type: 'incoming',
        invoice: 'lnbc1fonerjfneroj',
        description: '',
        descriptionHash: '',
        preimage: '',
        paymentHash: paymentHash ?? '',
        amount: 1000,
        feesPaid: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        settledAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        resultType: 'lookup_invoice');
  }
}
