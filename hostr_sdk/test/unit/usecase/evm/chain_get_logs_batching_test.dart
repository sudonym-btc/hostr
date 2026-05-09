import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hostr_sdk/datasources/contracts/escrow/MultiEscrow.g.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/escrow_event_scanner.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_quote_service.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.dart';
import 'package:hostr_sdk/usecase/payments/payments.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:hostr_sdk/util/stream_status.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  test(
    'Arbitrum locktime block falls through when RPC omits l1BlockNumber',
    () async {
      final rpc = await _ArbitrumBlockRpcServer.start();
      final chain = EvmChain(
        config: EvmChainConfig(
          id: 'arbitrum',
          chainId: 42161,
          rpcUrls: rpc.urls,
          nativeDenomination: 'ETH',
        ),
        auth: _FakeAuth(),
        logger: CustomLogger(tag: 'test'),
        quoteService: _FakeSwapQuoteService(),
        nwc: _FakeNwc(),
        payments: _FakePayments(),
      );

      try {
        expect(await chain.getLocktimeBlockNumber(), 25054095);
        expect(rpc.paths, ['/missing-l1', '/with-l1']);
        expect(rpc.methods, everyElement('eth_getBlockByNumber'));
      } finally {
        await chain.dispose();
        await rpc.close();
      }
    },
  );

  test(
    'regtest Arbitrum locktime block falls back to eth_blockNumber',
    () async {
      final rpc = await _ArbitrumBlockRpcServer.start();
      final chain = EvmChain(
        config: EvmChainConfig(
          id: 'arbitrum-regtest',
          chainId: 412346,
          rpcUrls: rpc.urls.take(1).toList(),
          nativeDenomination: 'ETH',
        ),
        auth: _FakeAuth(),
        logger: CustomLogger(tag: 'test'),
        quoteService: _FakeSwapQuoteService(),
        nwc: _FakeNwc(),
        payments: _FakePayments(),
      );

      try {
        expect(await chain.getLocktimeBlockNumber(), 42);
        expect(rpc.paths, ['/missing-l1', '/missing-l1']);
        expect(rpc.methods, ['eth_getBlockByNumber', 'eth_blockNumber']);
      } finally {
        await chain.dispose();
        await rpc.close();
      }
    },
  );

  test('newBlocks shares one block poll per chain', () async {
    final rpc = _FakeRpcClient();
    final chain = _chain(rpc);

    final blocks = chain.newBlocks(interval: const Duration(milliseconds: 10));
    final first = blocks.take(2).toList();
    final second = blocks.take(2).toList();

    expect(await first, [1, 2]);
    expect(await second, [1, 2]);
    expect(rpc.blockNumberCalls, 2);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(rpc.blockNumberCalls, 2);

    await chain.dispose();
  });

  test(
    'getLogs batches matching dynamic topic requests into one RPC',
    () async {
      final rpc = _FakeRpcClient();
      final chain = _chain(rpc);
      final topics = List.generate(3, _topic);

      final results = await Future.wait([
        for (final topic in topics) _tradeLogs(chain, topic),
      ]);

      expect(rpc.getLogsCalls, 1);
      expect(rpc.getLogsTopicBatches.single, unorderedEquals(topics));
      for (var i = 0; i < topics.length; i++) {
        expect(results[i].single.topics?[1], topics[i]);
      }

      await chain.dispose();
    },
  );

  test('getLogs chunks large merged dynamic topic requests', () async {
    final rpc = _FakeRpcClient();
    final chain = _chain(rpc);
    final topics = List.generate(76, _topic);

    final results = await Future.wait([
      for (final topic in topics) _tradeLogs(chain, topic),
    ]);

    expect(rpc.getLogsCalls, 2);
    expect(rpc.getLogsTopicBatches.map((batch) => batch.length), [75, 1]);
    expect(results.expand((logs) => logs).length, 76);

    await chain.dispose();
  });

  test(
    'live escrow trade listeners share one block stream and getLogs call',
    () async {
      final chain = _FakeLiveEvmChain();
      final scanner = EscrowEventScanner(
        contract: MultiEscrow(
          address: _contractAddress,
          client: Web3Client('http://localhost:8545', _FakeRpcClient()),
        ),
        chain: chain,
        parentContract: null,
        logger: CustomLogger(tag: 'test'),
      );

      final first = scanner.allEvents(
        ContractEventsParams(tradeId: _tradeId(1)),
        null,
        ensureDeployed: () async {},
      );
      final second = scanner.allEvents(
        ContractEventsParams(tradeId: _tradeId(2)),
        null,
        ensureDeployed: () async {},
      );

      await Future.wait([
        first.status.firstWhere((status) => status is StreamStatusLive),
        second.status.firstWhere((status) => status is StreamStatusLive),
      ]);

      chain.filters.clear();
      chain.blocks.add(10);
      await Future<void>.delayed(Duration.zero);

      expect(chain.newBlocksCalls, 1);
      expect(chain.filters, hasLength(1));
      expect(chain.filters.single.topics?[1], hasLength(2));

      await first.close();
      await second.close();
      await chain.blocks.close();
    },
  );

  test(
    'live escrow mapping uses log block number without fetching tx or block',
    () async {
      final tradeId = _tradeId(1);
      final chain = _FakeLiveEvmChain();
      final scanner = EscrowEventScanner(
        contract: MultiEscrow(
          address: _contractAddress,
          client: Web3Client('http://localhost:8545', _FakeRpcClient()),
        ),
        chain: chain,
        parentContract: null,
        logger: CustomLogger(tag: 'test'),
      );

      final stream = scanner.allEvents(
        ContractEventsParams(tradeId: tradeId),
        null,
        ensureDeployed: () async {},
      );

      await stream.status.firstWhere((status) => status is StreamStatusLive);
      chain.logsToReturn = [
        _tradeCreatedLog(tradeId: tradeId, txHashByte: 1, blockNumber: 10),
      ];
      final eventFuture = stream.stream.first;
      chain.blocks.add(10);

      final event = await eventFuture;
      expect(event, isA<EscrowFundedEvent>());
      expect((event as EscrowFundedEvent).blockNum, 10);
      expect(event.block, isNull);
      expect(chain.getTransactionCalls, 0);
      expect(chain.blockInformationRequests, isEmpty);

      await stream.close();
      await chain.blocks.close();
    },
  );
}

Future<List<FilterEvent>> _tradeLogs(EvmChain chain, String tradeTopic) {
  return chain.getLogs(
    FilterOptions(
      address: _contractAddress,
      topics: [
        [_eventTopic],
        [tradeTopic],
      ],
      fromBlock: const BlockNum.exact(1),
      toBlock: const BlockNum.exact(2),
    ),
    batchHint: const EvmLogsBatchHint(
      requestKey: 'escrow-live-test',
      dynamicTopicIndex: 1,
    ),
  );
}

EvmChain _chain(http.Client httpClient) {
  return EvmChain(
    config: const EvmChainConfig(
      id: 'test-chain',
      chainId: 31,
      rpcUrls: ['http://localhost:8545'],
      nativeDenomination: 'BTC',
    ),
    auth: _FakeAuth(),
    logger: CustomLogger(tag: 'test'),
    quoteService: _FakeSwapQuoteService(),
    nwc: _FakeNwc(),
    payments: _FakePayments(),
    httpClient: httpClient,
  );
}

String _topic(int index) => '0x${index.toRadixString(16).padLeft(64, '0')}';

String _tradeId(int index) => index.toRadixString(16).padLeft(64, '0');

final _contractAddress = EthereumAddress.fromHex(
  '0x1000000000000000000000000000000000000001',
);
const _eventTopic =
    '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
final _arbiterAddress = EthereumAddress.fromHex(
  '0x2000000000000000000000000000000000000001',
);
final _sellerAddress = EthereumAddress.fromHex(
  '0x2000000000000000000000000000000000000002',
);
final _buyerAddress = EthereumAddress.fromHex(
  '0x2000000000000000000000000000000000000003',
);
final _tokenAddress = EthereumAddress.fromHex(
  '0x0000000000000000000000000000000000000000',
);

class _FakeRpcClient extends http.BaseClient {
  int blockNumberCalls = 0;
  int getLogsCalls = 0;
  final List<List<String>> getLogsTopicBatches = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().bytesToString();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final method = decoded['method'] as String;
    final id = decoded['id'];

    if (method == 'eth_blockNumber') {
      blockNumberCalls += 1;
      return _jsonResponse(id, '0x${blockNumberCalls.toRadixString(16)}');
    }

    if (method == 'eth_getLogs') {
      getLogsCalls += 1;
      final params = decoded['params'] as List<dynamic>;
      final filter = params.single as Map<String, dynamic>;
      final topics = filter['topics'] as List<dynamic>;
      final eventTopics = (topics[0] as List<dynamic>).cast<String>();
      final tradeTopics = (topics[1] as List<dynamic>).cast<String>();
      getLogsTopicBatches.add(tradeTopics);

      return _jsonResponse(id, [
        for (var i = 0; i < tradeTopics.length; i++)
          {
            'address': filter['address'],
            'blockHash': '0x${'b'.padLeft(64, '0')}',
            'blockNumber': '0x1',
            'data': '0x',
            'logIndex': '0x${i.toRadixString(16)}',
            'removed': false,
            'topics': [eventTopics.first, tradeTopics[i]],
            'transactionHash':
                '0x${(i + 1).toRadixString(16).padLeft(64, '0')}',
            'transactionIndex': '0x0',
          },
      ]);
    }

    return _jsonError(id, -32601, 'Method not found: $method');
  }

  http.StreamedResponse _jsonResponse(dynamic id, Object? result) {
    return _response({'jsonrpc': '2.0', 'id': id, 'result': result});
  }

  http.StreamedResponse _jsonError(dynamic id, int code, String message) {
    return _response({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    });
  }

  http.StreamedResponse _response(Map<String, dynamic> body) {
    final bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _ArbitrumBlockRpcServer {
  final HttpServer _server;
  final List<String> paths = [];
  final List<String> methods = [];

  _ArbitrumBlockRpcServer._(this._server);

  List<String> get urls => [
    'http://${_server.address.host}:${_server.port}/missing-l1',
    'http://${_server.address.host}:${_server.port}/with-l1',
  ];

  static Future<_ArbitrumBlockRpcServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final rpc = _ArbitrumBlockRpcServer._(server);
    server.listen(rpc._handle);
    return rpc;
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final id = decoded['id'];
    final method = decoded['method'] as String;
    paths.add(request.uri.path);
    methods.add(method);

    if (method == 'eth_blockNumber') {
      _writeJson(request, {'jsonrpc': '2.0', 'id': id, 'result': '0x2a'});
      return;
    }

    if (method != 'eth_getBlockByNumber') {
      _writeJson(request, {
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': -32601, 'message': 'Method not found: $method'},
      });
      return;
    }

    final result = <String, dynamic>{'number': '0x1b77eaf0'};
    if (request.uri.path == '/with-l1') {
      result['l1BlockNumber'] = '0x17e4b8f';
    }

    _writeJson(request, {'jsonrpc': '2.0', 'id': id, 'result': result});
  }

  void _writeJson(HttpRequest request, Map<String, dynamic> body) {
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    unawaited(request.response.close());
  }
}

class _FakeLiveEvmChain extends Fake implements EvmChain {
  final blocks = StreamController<int>.broadcast();
  final filters = <FilterOptions>[];
  final blockInformationRequests = <String>[];
  List<FilterEvent> logsToReturn = const [];
  int newBlocksCalls = 0;
  int getTransactionCalls = 0;

  @override
  EvmChainConfig get config => const EvmChainConfig(
    id: 'test-chain',
    chainId: 31,
    rpcUrls: ['http://localhost:8545'],
    nativeDenomination: 'BTC',
  );

  @override
  Stream<int> newBlocks({Duration interval = const Duration(seconds: 15)}) {
    newBlocksCalls += 1;
    return blocks.stream;
  }

  @override
  Future<List<FilterEvent>> getLogs(
    FilterOptions filter, {
    bool batch = true,
    EvmLogsBatchHint? batchHint,
  }) async {
    filters.add(filter);
    return logsToReturn;
  }

  @override
  Future<TransactionInformation?> getTransaction(String txHash) async {
    getTransactionCalls += 1;
    return null;
  }

  @override
  Future<BlockInformation> getBlockInformation({
    required String blockNumber,
  }) async {
    blockInformationRequests.add(blockNumber);
    return BlockInformation(
      baseFeePerGas: null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
    );
  }
}

FilterEvent _tradeCreatedLog({
  required String tradeId,
  required int txHashByte,
  required int blockNumber,
}) {
  final event = MultiEscrow(
    address: _contractAddress,
    client: Web3Client('http://localhost:8545', _FakeRpcClient()),
  ).self.events.firstWhere((event) => event.name == 'TradeCreated');

  return FilterEvent(
    address: _contractAddress,
    blockHash: '0x${'b'.padLeft(64, '0')}',
    blockNum: blockNumber,
    data: bytesToHex(_encodeTradeCreatedData(), include0x: true),
    logIndex: 0,
    topics: [
      bytesToHex(event.signature, padToEvenLength: true, include0x: true),
      '0x$tradeId',
      _indexedAddressTopic(_tokenAddress),
      _indexedAddressTopic(_arbiterAddress),
    ],
    transactionHash: '0x${txHashByte.toRadixString(16).padLeft(64, '0')}',
    transactionIndex: 0,
  );
}

String _indexedAddressTopic(EthereumAddress address) =>
    '0x${address.without0x.padLeft(64, '0')}';

Uint8List _encodeTradeCreatedData() {
  final sink = LengthTrackingByteSink();
  const TupleType([
    AddressType(),
    AddressType(),
    UintType(),
    UintType(),
    UintType(),
    UintType(),
  ]).encode([
    _sellerAddress,
    _buyerAddress,
    BigInt.from(100),
    BigInt.zero,
    BigInt.zero,
    BigInt.zero,
  ], sink);
  return sink.asBytes();
}

class _FakeAuth extends Fake implements Auth {}

class _FakeSwapQuoteService extends Fake implements SwapQuoteService {}

class _FakeNwc extends Fake implements Nwc {}

class _FakePayments extends Fake implements Payments {}
