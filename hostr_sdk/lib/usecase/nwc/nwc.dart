import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/usecases/nwc/consts/bitcoin_network.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';
import 'package:ndk/ndk.dart' hide Nwc;
import 'package:rxdart/rxdart.dart';

import '../../injection.dart';
import '../../util/custom_logger.dart';
import '../storage/storage.dart';
import 'nwc.cubit.dart';

@Singleton(env: Env.allButTestAndMock)
class Nwc {
  final CustomLogger logger;
  NwcStorage nwcStorage;
  Ndk ndk;
  List<NwcCubit> connections = [];
  final _connectionsSubject = BehaviorSubject<List<NwcCubit>>.seeded([]);
  Stream<List<NwcCubit>> get connectionsStream => _connectionsSubject.stream;

  Nwc(this.nwcStorage, this.ndk, this.logger);

  Future<void> _disposeReactiveConnection(NwcCubit reactiveConnection) =>
      logger.span('_disposeReactiveConnection', () async {
        final connection = reactiveConnection.connection;
        if (connection != null) {
          if (connection.subscription != null) {
            await ndk.requests.closeSubscription(
              connection.subscription!.requestId,
            );
          }
          await connection.close();
          reactiveConnection.connection = null;
        }
        await reactiveConnection.close();
      });

  String? _connectionUrl(NwcCubit cubit) =>
      cubit.url ?? cubit.connection?.uri.toString();

  /// User pasted/scanned a NWC from their wallet
  /// nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  Future<void> save() => logger.span('save', () async {
    // Parse the NWC string, check protocol, secret, relay
    await nwcStorage.set(
      connections.map(_connectionUrl).whereType<String>().toSet().toList(),
    );
  });

  Future<void> add(NwcCubit reactiveConnection) => logger.span('add', () async {
    final incomingUrl = _connectionUrl(reactiveConnection);
    if (incomingUrl != null &&
        connections.any(
          (existing) => _connectionUrl(existing) == incomingUrl,
        )) {
      logger.i('Skipping duplicate nwc connection $incomingUrl');
      await _disposeReactiveConnection(reactiveConnection);
      return;
    }

    logger.i(
      'Adding nwc connection ${reactiveConnection.connection!.uri.toString()}',
    );
    connections.add(reactiveConnection);
    await save();
    _connectionsSubject.add(connections);
  });

  Future<void> remove(NwcCubit reactiveConnection) => logger.span(
    'remove',
    () async {
      logger.i('Removing nwc connection ${reactiveConnection.url.toString()}');
      await _disposeReactiveConnection(reactiveConnection);
      connections.remove(reactiveConnection);
      _connectionsSubject.add(connections);
      await save();
    },
  );

  NwcConnection? getActiveConnection() =>
      logger.spanSync('getActiveConnection', () {
        for (final cubit in connections) {
          if (cubit.state is Success) {
            return cubit.connection;
          }
        }
        return null;
      });

  Future<NwcCubit> initiateAndAdd(String url) =>
      logger.span('initiateAndAdd', () async {
        final reactive = NwcCubit(nwc: this, logger: logger);
        await reactive.connect(url);
        await add(reactive);
        return reactive;
      });

  /// Create a reactive connection from a URL and add it to the list
  Future<NwcConnection> connect(String url) => logger.span('connect', () async {
    logger.d('Connecting to NWC URL: $url');
    return ndk.nwc.connect(url);
  });

  Future<GetInfoResponse> getInfo(NwcConnection connection) async {
    return ndk.nwc.getInfo(connection);
  }

  Future<PayInvoiceResponse> payInvoice(
    NwcConnection connection,
    String invoice,
  ) => logger.span('payInvoice', () async {
    logger.i('Paying invoice $invoice');
    try {
      return await ndk.nwc.payInvoice(
        connection,
        invoice: invoice,
        timeout: Duration(seconds: 20),
      );
    } catch (e, stackTrace) {
      logger.e('Error paying invoice: $e $stackTrace');
      rethrow;
    }
  });

  Future<MakeInvoiceResponse> makeInvoice(
    NwcConnection connection, {
    required int amountSats,
    String? description,
    String? descriptionHash,
    int? expiry,
  }) => logger.span('makeInvoice', () async {
    logger.i('Making invoice for $amountSats sats');
    try {
      return await ndk.nwc.makeInvoice(
        connection,
        amountSats: amountSats,
        description: description,
        descriptionHash: descriptionHash,
        expiry: expiry,
      );
    } catch (e, stackTrace) {
      logger.e('Error making invoice: $e $stackTrace');
      rethrow;
    }
  });

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

  /// Soft cleanup for logout: close all NWC cubits and clear the list,
  /// but keep the [_connectionsSubject] open so a subsequent [start] works.
  Future<void> reset() => logger.span('reset', () async {
    for (final connection in connections) {
      await _disposeReactiveConnection(connection);
    }
    connections.clear();
    _connectionsSubject.add(connections);
  });

  /// Permanent teardown — closes the subject. Only call when the Hostr
  /// instance itself is being disposed.
  Future<void> dispose() => logger.span('dispose', () async {
    await reset();
    await _connectionsSubject.close();
  });

  void start() => logger.spanSync('start', () {
    nwcStorage.get().then((urls) async {
      final seen = <String>{};
      for (var url in urls) {
        if (!seen.add(url)) {
          continue;
        }
        try {
          final reactive = NwcCubit(url: url, nwc: this, logger: logger);
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
  });
}

@Singleton(as: Nwc, env: [Env.test, Env.mock])
class MockNwc extends Nwc {
  MockNwc(super.nwcStorage, super.ndk, super.logger);

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
