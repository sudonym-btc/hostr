import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/bitcoin_network.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';
import 'package:ndk/ndk.dart' hide Nwc;
import 'package:rxdart/rxdart.dart';

@Singleton(env: Env.allButTestAndMock)
class Nwc {
  CustomLogger logger = CustomLogger();
  NwcStorage nwcStorage;
  Ndk ndk;
  List<NwcCubit> connections = [];
  final _connectionsSubject = BehaviorSubject<List<NwcCubit>>.seeded([]);
  Stream<List<NwcCubit>> get connectionsStream => _connectionsSubject.stream;

  Nwc(this.nwcStorage, this.ndk) {
    nwcStorage.get().then((urls) async {
      for (var url in urls) {
        try {
          final reactive = NwcCubit(url: url, nwc: this);
          connections.add(reactive);
          _connectionsSubject.add(connections);
          // Fetch info asynchronously and update the reactive connection
          reactive.connect(null);
        } catch (e) {
          logger.e('Failed to connect to $url: $e');
        }
      }
      logger.i('Initializing nwc connections $urls');
    });
  }

  /// User pasted/scanned a NWC from their wallet
  /// nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  Future<void> save() async {
    // Parse the NWC string, check protocol, secret, relay
    await nwcStorage.set(connections.map((c) => c.url!).toList());
  }

  Future<void> add(NwcCubit reactiveConnection) async {
    logger.i(
      'Adding nwc connection ${reactiveConnection.connection!.uri.toString()}',
    );
    connections.add(reactiveConnection);
    await save();
    _connectionsSubject.add(connections);
  }

  Future<void> remove(NwcCubit reactiveConnection) async {
    logger.i('Removing nwc connection ${reactiveConnection.url.toString()}');
    reactiveConnection.close();
    connections.remove(reactiveConnection);
    _connectionsSubject.add(connections);
    await save();
  }

  /// Create a reactive connection from a URL and add it to the list
  Future<NwcConnection> connect(String url) async {
    return ndk.nwc.connect(url);
  }

  Future<GetInfoResponse> getInfo(NwcConnection connection) async {
    return ndk.nwc.getInfo(connection);
  }

  Future<PayInvoiceResponse> payInvoice(
    NwcConnection connection,
    String invoice,
  ) async {
    logger.i('Paying invoice $invoice');
    try {
      return await ndk.nwc.payInvoice(
        connection,
        invoice: invoice,
        timeout: Duration(seconds: 20),
      );
    } catch (e, stackTrace) {
      logger.e('Error paying invoice: $e');
      logger.e('PayInvoice stack trace (from NDK): $stackTrace');
      logger.e('PayInvoice stack trace (current): ${StackTrace.current}');
      rethrow;
    }
  }

  Future<LookupInvoiceResponse> lookupInvoice(
    NwcConnection connection, {
    String? paymentHash,
    String? invoice,
  }) async {
    return ndk.nwc.lookupInvoice(
      connection,
      paymentHash: paymentHash,
      invoice: invoice,
    );
  }

  Future<void> dispose() async {
    for (final connection in connections) {
      await connection.close();
    }
    connections.clear();
    await _connectionsSubject.close();
  }
}

@Singleton(as: Nwc, env: [Env.test, Env.mock])
class MockNwc extends Nwc {
  MockNwc(super.nwcStorage, super.ndk);

  @override
  Future<NwcConnection> connect(String url) async {
    return NwcConnection(NostrWalletConnectUri.parseConnectionUri(url));
  }

  @override
  Future<GetInfoResponse> getInfo(NwcConnection connection) async {
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
    NwcConnection connection,
    String invoice,
  ) async {
    return PayInvoiceResponse(
      preimage: 'preimage',
      resultType: 'pay_invoice',
      feesPaid: 1,
    );
  }

  @override
  Future<LookupInvoiceResponse> lookupInvoice(
    NwcConnection connection, {
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
