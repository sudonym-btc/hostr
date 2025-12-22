import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/nwc.cubit.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/bitcoin_network.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

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

@Singleton(env: Env.allButTestAndMock)
class NwcService {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();
  NwcStorage nwcStorage;
  Ndk nostr;
  List<NwcCubit> connections = [];
  final _connectionsSubject = BehaviorSubject<List<NwcCubit>>.seeded([]);
  Stream<List<NwcCubit>> get connectionsStream => _connectionsSubject.stream;

  NwcService(this.nwcStorage, this.nostr) {
    nwcStorage.get().then((urls) {
      for (var url in urls) {
        connections.add(
          NwcCubit(url: url, nwcService: getIt<NwcService>())..connect(url),
        );
      }
      logger.i('Initializing nwc connections $urls');
      _connectionsSubject.add(connections);
    });
  }

  /// User pasted/scanned a NWC from their wallet
  /// e.g. nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  save(NwcCubit cubit) async {
    // Parse the NWC string, check protocol, secret, relay
    parseNwc(cubit.url!);
    await nwcStorage.set([cubit.url!]);
  }

  Future<NwcConnection> connect(String url, {Function(String?)? onError}) {
    parseNwc(url);
    logger.i('Connecting to NWC $url');
    return nostr.nwc
        .connect(url, doGetInfoMethod: true, onError: onError)
        .timeout(Duration(seconds: 5));
  }

  Future<GetInfoResponse> getInfo(NwcConnection nwc) async {
    logger.i('Getting info for NWC $nwc');
    return nostr.nwc.getInfo(nwc);
  }

  Future<PayInvoiceResponse> payInvoice(
    NwcConnection nwc,
    String invoice,
    int? amount,
  ) async {
    logger.i('Paying invoice $invoice $nwc');

    return nostr.nwc.payInvoice(nwc, invoice: invoice);
  }

  Future<MakeInvoiceResponse> makeInvoice(
    NwcConnection nwc,
    int amountSats,
  ) async {
    return nostr.nwc.makeInvoice(nwc, amountSats: amountSats);
  }

  Future<LookupInvoiceResponse> lookupInvoice(
    NwcConnection nwc, {
    String? paymentHash,
    String? invoice,
  }) async {
    return nostr.nwc.lookupInvoice(
      nwc,
      paymentHash: paymentHash,
      invoice: invoice,
    );
  }

  add(NwcCubit nwcCubit) async {
    logger.i('Adding nwc connection ${nwcCubit.url}');
    await save(nwcCubit);
    connections.add(nwcCubit);
    _connectionsSubject.add(connections);
  }

  void remove(NwcCubit connection) async {
    logger.i('Removing nwc connection ${connection.url}');
    connections.remove(connection);
    _connectionsSubject.add(connections);
    await nwcStorage.set([connection.url!]);
  }

  zap({required lnurl, required amountSats, String? a, String? e}) {
    return getIt<Ndk>().zaps.zap(
      nwcConnection: connections[0].connection!,
      lnurl: lnurl,
      eventId: e,
      // addressableId: a,
      amountSats: amountSats,
    );
  }
}

@Singleton(as: NwcService, env: [Env.test, Env.mock])
class MockNostrWalletConnectService extends NwcService {
  MockNostrWalletConnectService(super.nwcStorage, super.nostr);

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
  Future<GetInfoResponse> getInfo(NwcConnection nwc) async {
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
  Future<PayInvoiceResponse> payInvoice(
    NwcConnection nwc,
    String invoice,
    int? amount,
  ) async {
    return PayInvoiceResponse(
      preimage: 'preimage',
      resultType: 'pay_invoice',
      feesPaid: 1,
    );
  }

  @override
  Future<LookupInvoiceResponse> lookupInvoice(
    NwcConnection nwc, {
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
