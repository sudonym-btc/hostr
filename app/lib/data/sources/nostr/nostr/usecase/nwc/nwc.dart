import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/bitcoin_network.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';
import 'package:ndk/ndk.dart' hide Nwc;
import 'package:rxdart/rxdart.dart';

Uri parseNwc(String nwcString) {
  Uri nwcUri = Uri.parse(nwcString);
  assert(nwcUri.scheme == 'nostr+walletconnect');
  assert(nwcUri.queryParameters.containsKey('relay'));

  /// Check that relay url correct as well
  Uri.parse(nwcUri.queryParameters['relay']!);
  return nwcUri;
}

@Singleton(env: Env.allButTestAndMock)
class Nwc {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();
  NwcStorage nwcStorage;
  Ndk ndk;
  List<NwcConnection> connections = [];
  final _connectionsSubject = BehaviorSubject<List<NwcConnection>>.seeded([]);
  Stream<List<NwcConnection>> get connectionsStream =>
      _connectionsSubject.stream;

  Nwc(this.nwcStorage, this.ndk) {
    nwcStorage.get().then((urls) {
      for (var url in urls) {
        ndk.nwc.connect(url).then((connection) {
          connections.add(connection);
          _connectionsSubject.add(connections);
        });
      }
      logger.i('Initializing nwc connections $urls');
      _connectionsSubject.add(connections);
    });
  }

  /// User pasted/scanned a NWC from their wallet
  /// e.g. nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  Future<void> save(NwcConnection nwcConnection) async {
    // Parse the NWC string, check protocol, secret, relay
    await nwcStorage.set(connections.map((c) => c.uri.toUri()).toList());
  }

  Future<void> add(NwcConnection nwcConnection) async {
    logger.i('Adding nwc connection ${nwcConnection.uri}');
    await save(nwcConnection);
    connections.add(nwcConnection);
    _connectionsSubject.add(connections);
  }

  Future<void> remove(NwcConnection nwcConnection) async {
    logger.i('Removing nwc connection ${nwcConnection.uri}');
    connections.remove(nwcConnection);
    _connectionsSubject.add(connections);
    await nwcStorage.set(connections.map((c) => c.uri.toUri()).toList());
  }

  Future<NwcConnection> connect(
    String url, {
    Function(String?)? onError,
  }) async {
    return ndk.nwc.connect(url);
  }

  Future<GetInfoResponse> getInfo() async {
    return ndk.nwc.getInfo(connections.first);
  }

  Future<PayInvoiceResponse> payInvoice(String invoice, int? amount) async {
    return ndk.nwc.payInvoice(connections.first, invoice: invoice);
  }

  Future<LookupInvoiceResponse> lookupInvoice({
    String? paymentHash,
    String? invoice,
  }) async {
    return ndk.nwc.lookupInvoice(
      connections.first,
      paymentHash: paymentHash,
      invoice: invoice,
    );
  }
}

@Singleton(as: Nwc, env: [Env.test, Env.mock])
class MockNwc extends Nwc {
  MockNwc(super.nwcStorage, super.ndk);

  @override
  Future<NwcConnection> connect(
    String url, {
    Function(String?)? onError,
  }) async {
    Uri uri = parseNwc(url);
    return NwcConnection(
      NostrWalletConnectUri(
        walletPubkey: uri.host,
        relays: [uri.queryParameters['relay']!],
        secret: uri.queryParameters['secret']!,
      ),
    );
  }

  @override
  Future<GetInfoResponse> getInfo() async {
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
      preimage: 'preimage',
      resultType: 'pay_invoice',
      feesPaid: 1,
    );
  }

  @override
  Future<LookupInvoiceResponse> lookupInvoice({
    String? paymentHash,
    String? invoice,
  }) async {
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
      resultType: 'lookup_invoice',
    );
  }
}
