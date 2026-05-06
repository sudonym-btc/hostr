@Tags(['unit'])
library;

import 'package:hostr_sdk/datasources/boltz/boltz_chain_info.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/evm/capabilities/boltz_swap_provider.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/chain/operations/swap_out/swap_out_operation.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/evm/evm_call.dart';
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_out/swap_out_models.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_out/swap_out_operation.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_out/swap_out_state.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_out_tracker.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_quote_service.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../support/fakes/fake_boltz_client.dart';

void main() {
  late CustomLogger logger;
  late SwapOutTracker tracker;
  late List<EvmSwapOutOperation> operations;

  setUp(() async {
    await getIt.reset();
    logger = CustomLogger();
    tracker = SwapOutTracker(logger);
    operations = [];

    getIt.registerSingleton<OperationStateStore>(_FakeOperationStateStore());
    getIt.registerSingleton<SwapOutTracker>(tracker);
  });

  tearDown(() async {
    for (final operation in operations) {
      await operation.close();
    }
    await tracker.dispose();
    await getIt.reset();
  });

  test('uses cooperative refund signature when Boltz provides one', () async {
    final fixture = _buildOperation(
      logger: logger,
      status: 'invoice.failedToPay',
      cooperativeSignature: _signatureHex(),
      currentLocktimeBlock: 50,
      refundTxHash: _txHash('aa'),
    );
    operations.add(fixture.operation);

    final next = await fixture.operation.executeStep(
      SwapOutStep.awaitResolution,
    );

    expect(next, isA<SwapOutRefunding>());
    expect((next as SwapOutRefunding).data.resolutionTxHash, _txHash('aa'));
    expect(fixture.chain.sentCallNames, [
      ['cooperativeRefund'],
    ]);
    expect(fixture.chain.locktimeBlockReads, 0);
  });

  test(
    'waits for timelock when Boltz has no cooperative refund signature',
    () async {
      final fixture = _buildOperation(
        logger: logger,
        status: 'invoice.failedToPay',
        currentLocktimeBlock: 90,
        timeoutBlockHeight: 100,
      );
      operations.add(fixture.operation);

      final next = await fixture.operation.executeStep(
        SwapOutStep.awaitResolution,
      );

      expect(next, isA<SwapOutWaitingForTimelock>());
      final data = (next as SwapOutWaitingForTimelock).data;
      expect(data.resolutionTxHash, isNull);
      expect(data.errorMessage, contains('Waiting for timelock expiry'));
      expect(data.errorMessage, contains('100'));
      expect(data.errorMessage, contains('90'));
      expect(fixture.chain.sentCallNames, isEmpty);
      expect(fixture.chain.locktimeBlockReads, 1);
    },
  );

  test('broadcasts timelock refund once no cooperative signature is available '
      'and the timelock has expired', () async {
    final fixture = _buildOperation(
      logger: logger,
      status: 'invoice.failedToPay',
      currentLocktimeBlock: 100,
      timeoutBlockHeight: 100,
      refundTxHash: _txHash('bb'),
    );
    operations.add(fixture.operation);

    final next = await fixture.operation.executeStep(
      SwapOutStep.awaitResolution,
    );

    expect(next, isA<SwapOutRefunding>());
    expect((next as SwapOutRefunding).data.resolutionTxHash, _txHash('bb'));
    expect(fixture.chain.sentCallNames, [
      ['refund'],
    ]);
    expect(fixture.chain.locktimeBlockReads, 1);
  });
}

_SwapOutRefundFixture _buildOperation({
  required CustomLogger logger,
  required String status,
  String? cooperativeSignature,
  int currentLocktimeBlock = 0,
  int timeoutBlockHeight = 100,
  String? refundTxHash,
}) {
  const boltzId = 'swap-refund-transition';
  final boltz = FakeBoltzClient()..swapStatuses[boltzId] = status;
  if (cooperativeSignature != null) {
    boltz.cooperativeRefundSignatures[boltzId] = cooperativeSignature;
  }

  final chain = _FakeEvmChain(
    logger: logger,
    currentLocktimeBlock: currentLocktimeBlock,
    nextTxHash: refundTxHash ?? _txHash('cc'),
  );
  chain.swaps = BoltzSwapProvider(
    boltzClient: boltz,
    chainInfo: BoltzChainInfo(
      chainKey: 'test',
      chainId: chain.config.chainId,
      etherSwap: EthereumAddress.fromHex(
        '0x1000000000000000000000000000000000000001',
      ),
      erc20Swap: EthereumAddress.fromHex(
        '0x1000000000000000000000000000000000000002',
      ),
    ),
    chain: chain,
    logger: logger,
    nativeCurrency: 'RBTC',
  );

  final evmKey = EthPrivateKey.fromHex('1'.padLeft(64, '0'));
  final data = SwapOutData(
    boltzId: boltzId,
    invoice: 'lnbc-test',
    invoicePreimageHashHex: _repeatByte('12', 32),
    claimAddress: '0x1000000000000000000000000000000000000003',
    lockedAmountWeiHex: BigInt.from(1000).toRadixString(16),
    lockerAddress: evmKey.address.eip55With0x,
    timeoutBlockHeight: timeoutBlockHeight,
    chainId: chain.config.chainId,
    accountIndex: 0,
    creationBlockHeight: 0,
    lockTxHash: _txHash('dd'),
  );

  final operation = EvmSwapOutOperation(
    chain: chain,
    auth: MockAuth(),
    logger: logger,
    nwc: MockNwc(),
    quoteService: SwapQuoteService(logger: logger),
    payments: MockPayments(),
    params: SwapOutParams(evmKey: evmKey, accountIndex: 0),
    initialState: SwapOutFunded(data),
    store: getIt<OperationStateStore>(),
    tracker: getIt<SwapOutTracker>(),
  );

  return _SwapOutRefundFixture(operation: operation, chain: chain);
}

String _repeatByte(String byteHex, int count) =>
    List.filled(count, byteHex).join();

String _signatureHex() =>
    '0x${_repeatByte('11', 32)}${_repeatByte('22', 32)}1b';

String _txHash(String byteHex) => '0x${_repeatByte(byteHex, 32)}';

class _SwapOutRefundFixture {
  final EvmSwapOutOperation operation;
  final _FakeEvmChain chain;

  const _SwapOutRefundFixture({required this.operation, required this.chain});
}

class _FakeOperationStateStore extends Fake implements OperationStateStore {}

class _FakeWeb3Client extends Fake implements Web3Client {
  @override
  Future<List<FilterEvent>> getLogs(FilterOptions options) async => const [];
}

class _FakeEvmChain extends Fake implements EvmChain {
  _FakeEvmChain({
    required this.logger,
    required this.currentLocktimeBlock,
    required this.nextTxHash,
  });

  @override
  final CustomLogger logger;

  @override
  final EvmChainConfig config = const EvmChainConfig(
    id: 'test-chain',
    chainId: 31,
    rpcUrl: 'http://localhost:8545',
    nativeDenomination: 'BTC',
    boltzCurrency: 'RBTC',
  );

  @override
  final Web3Client client = _FakeWeb3Client();

  @override
  BoltzSwapProvider? swaps;

  int currentLocktimeBlock;
  String nextTxHash;
  int locktimeBlockReads = 0;
  final List<Map<String, Call>> sentCalls = [];

  List<List<String>> get sentCallNames =>
      sentCalls.map((calls) => calls.keys.toList()).toList();

  @override
  Future<int> getLocktimeBlockNumber() async {
    locktimeBlockReads++;
    return currentLocktimeBlock;
  }

  @override
  Future<String> sendCalls(
    EthPrivateKey signer,
    Map<String, Call> calls,
  ) async {
    sentCalls.add(calls);
    return nextTxHash;
  }
}
