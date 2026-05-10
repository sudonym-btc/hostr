import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:hostr_sdk/datasources/boltz/boltz.dart';
import 'package:hostr_sdk/datasources/boltz/boltz_chain_info.dart';
import 'package:hostr_sdk/datasources/swagger_generated/boltz.swagger.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/evm/capabilities/boltz_swap_provider.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart';
import 'package:hostr_sdk/usecase/evm/operations/funds_monitor/funds_monitor_service.dart';
import 'package:hostr_sdk/usecase/evm/operations/funds_monitor/funds_item.dart';
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator.dart';
import 'package:hostr_sdk/usecase/user_config/user_config_store.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/util/token_amount_ext.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:hostr_sdk/util/stream_status.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

void main() {
  group('FundsMonitorService dust policy', () {
    final token = Token.native(30);
    final minimum = tokenAmountFromSats(token, BigInt.from(1000));

    test('marks sub-sat balances as dust without swap limits', () {
      final balance = rbtcFromWei(BigInt.one, chainId: token.chainId);

      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(balance),
        isTrue,
      );
    });

    test('marks whole-sat balances below the Boltz minimum as dust', () {
      final balance = tokenAmountFromSats(token, BigInt.one);

      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(
          balance,
          minimumSwapOutAmount: minimum,
        ),
        isTrue,
      );
    });

    test('treats the exact Boltz minimum as sweepable', () {
      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(
          minimum,
          minimumSwapOutAmount: minimum,
        ),
        isFalse,
      );
    });

    test('treats balances above the Boltz minimum as sweepable', () {
      final balance = tokenAmountFromSats(token, BigInt.from(1001));

      expect(
        FundsMonitorService.isDustBalanceForSwapOutLimits(
          balance,
          minimumSwapOutAmount: minimum,
        ),
        isFalse,
      );
    });

    group('non-bridge ERC-20 balances', () {
      final bridgeAddress = EthereumAddress.fromHex(
        '0x1111111111111111111111111111111111111111',
      );
      final usdtAddress = EthereumAddress.fromHex(
        '0x2222222222222222222222222222222222222222',
      );
      final bridgeToken = Token(
        chainId: 412346,
        address: bridgeAddress.eip55With0x,
        decimals: 18,
      );
      final usdtToken = Token(
        chainId: 412346,
        address: usdtAddress.eip55With0x,
        decimals: 6,
      );

      test(
        'quotes into the bridge token before applying Boltz minimum',
        () async {
          final balance = TokenAmount.fromDecimal('1', usdtToken);
          final boltz = _FakeBoltzApi(
            quote: tokenAmountFromSats(
              bridgeToken,
              BigInt.from(999),
            ).value.toString(),
          );
          final swaps = _FakeBoltzSwapProvider(
            boltz: boltz,
            bridgeAddress: bridgeAddress,
            minimumSats: 1000,
          );
          final chain = _FakeEvmChain(swaps: swaps, bridgeToken: bridgeToken);
          final service = _fundsMonitorService();

          final dust = await service.isDustBalanceForTesting(chain, balance);

          expect(dust, isTrue);
          expect(boltz.quoteInCalls, hasLength(1));
          expect(boltz.quoteInCalls.single.currency, 'ARB');
          expect(boltz.quoteInCalls.single.tokenIn, usdtAddress.eip55With0x);
          expect(boltz.quoteInCalls.single.tokenOut, bridgeAddress.eip55With0x);
          expect(boltz.quoteInCalls.single.amountIn, balance.value.toString());
          expect(swaps.limitTokenAddresses.single, bridgeAddress);
        },
      );

      test('treats quoted bridge amount at minimum as sweepable', () async {
        final boltz = _FakeBoltzApi(
          quote: tokenAmountFromSats(
            bridgeToken,
            BigInt.from(1000),
          ).value.toString(),
        );
        final chain = _FakeEvmChain(
          swaps: _FakeBoltzSwapProvider(
            boltz: boltz,
            bridgeAddress: bridgeAddress,
            minimumSats: 1000,
          ),
          bridgeToken: bridgeToken,
        );
        final service = _fundsMonitorService();

        final dust = await service.isDustBalanceForTesting(
          chain,
          TokenAmount.fromDecimal('1', usdtToken),
        );

        expect(dust, isFalse);
      });
    });

    test('startup scan does not subscribe to block streams', () async {
      final chain = _FakeEvmChain(swaps: null, bridgeToken: token);
      final service = _fundsMonitorService(evm: _FakeEvm([chain]));

      await service.start();

      expect(chain.scanAllHdBalanceCalls, 1);
      expect(chain.blockListenCount, 0);

      await service.stop();
      await chain.close();
    });

    test(
      'replayed settlement events are processed sequentially with a gap',
      () async {
        final chain = _FakeEvmChain(swaps: null, bridgeToken: token);
        final contract = _FakeSupportedEscrowContract();
        final userSubscriptions = _FakeUserSubscriptions();
        final auth = _FakeAuth();
        final allocator = _FakeTradeAccountAllocator();
        final firstStarted = Completer<void>();
        final firstCanFinish = Completer<int?>();
        final secondStarted = Completer<void>();

        allocator.lookup = (tradeId) {
          if (tradeId == _tradeId(1)) {
            firstStarted.complete();
            return firstCanFinish.future;
          }
          if (tradeId == _tradeId(2)) {
            secondStarted.complete();
            return Future.value(2);
          }
          return Future.value(null);
        };

        userSubscriptions.paymentEvents$
          ..add(_arbitratedEvent(_tradeId(1), chain, contract))
          ..add(_arbitratedEvent(_tradeId(2), chain, contract));

        final service = _fundsMonitorService(
          evm: _FakeEvm([chain]),
          userSubscriptions: userSubscriptions,
          auth: auth,
          tradeAccountAllocator: allocator,
          settlementEventProcessingGap: const Duration(milliseconds: 50),
        );

        await service.start();
        await firstStarted.future.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(secondStarted.isCompleted, isFalse);

        firstCanFinish.complete(1);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(secondStarted.isCompleted, isFalse);

        await secondStarted.future.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(Duration.zero);

        expect(allocator.lookupTradeIds, [_tradeId(1), _tradeId(2)]);
        expect(auth.hd.accountIndices, [1, 2]);

        await service.stop();
        await chain.close();
      },
    );

    test('stop clears previously emitted balance snapshots', () async {
      final chain = _FakeEvmChain(swaps: null, bridgeToken: token);
      final service = _fundsMonitorService(evm: _FakeEvm([chain]));
      final keypair = EthPrivateKey.fromHex(
        '0000000000000000000000000000000000000000000000000000000000000001',
      );

      await service.start();
      final emissions = <List<FundsItem>>[];
      final sub = service.fundsStream$.listen(emissions.add);
      service.seedWalletItemForTesting(
        FundsItem(
          address: keypair.address,
          keypair: keypair,
          accountIndex: 0,
          token: token,
          balance: tokenAmountFromSats(token, BigInt.from(1000)),
          chain: chain,
          blockNumber: 0,
          isSmartAddress: false,
          dust: false,
        ),
      );

      expect(
        await service.fundsStream$.firstWhere((items) => items.isNotEmpty),
        isNotEmpty,
      );

      await service.stop();
      await pumpEventQueue();

      expect(emissions.last, isEmpty);
      await sub.cancel();
      await chain.close();
    });
  });
}

FundsMonitorService _fundsMonitorService({
  _FakeEvm? evm,
  _FakeUserSubscriptions? userSubscriptions,
  _FakeAuth? auth,
  _FakeTradeAccountAllocator? tradeAccountAllocator,
  Duration? settlementEventProcessingGap,
}) => FundsMonitorService(
  evm ?? _FakeEvm(),
  userSubscriptions ?? _FakeUserSubscriptions(),
  auth ?? _FakeAuth(),
  tradeAccountAllocator ?? _FakeTradeAccountAllocator(),
  _FakeOperationStateStore(),
  _FakeUserConfigStore(),
  CustomLogger(),
  null,
  null,
  settlementEventProcessingGap,
);

class _FakeBoltzApi extends Fake implements Boltz {
  final String quote;
  final List<
    ({String? currency, String? tokenIn, String? tokenOut, String? amountIn})
  >
  quoteInCalls = [];

  _FakeBoltzApi({required this.quote});

  @override
  Future<chopper.Response<List<TokenQuote>>> quoteCurrencyInGet({
    required String? currency,
    required String? tokenIn,
    required String? tokenOut,
    required String? amountIn,
  }) async {
    quoteInCalls.add((
      currency: currency,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      amountIn: amountIn,
    ));
    return chopper.Response(http.Response('', 200), [
      TokenQuote(quote: quote, data: const {}),
    ]);
  }
}

class _FakeBoltzClient extends Fake implements BoltzClient {
  @override
  Boltz gBoltzCli;

  _FakeBoltzClient(this.gBoltzCli);
}

class _FakeBoltzSwapProvider extends Fake implements BoltzSwapProvider {
  @override
  final BoltzClient boltzClient;

  @override
  final BoltzChainInfo chainInfo;

  @override
  final String? nativeCurrency;

  final int minimumSats;
  final List<EthereumAddress?> limitTokenAddresses = [];

  _FakeBoltzSwapProvider({
    required _FakeBoltzApi boltz,
    required EthereumAddress bridgeAddress,
    required this.minimumSats,
  }) : boltzClient = _FakeBoltzClient(boltz),
       nativeCurrency = 'ARB',
       chainInfo = BoltzChainInfo(
         chainKey: 'arbitrum',
         chainId: 412346,
         etherSwap: EthereumAddress.fromHex(
           '0x3333333333333333333333333333333333333333',
         ),
         erc20Swap: EthereumAddress.fromHex(
           '0x4444444444444444444444444444444444444444',
         ),
         tokens: {'TBTC': bridgeAddress},
       );

  @override
  Future<({DenominatedAmount max, DenominatedAmount min})> getSwapOutLimits({
    EthereumAddress? tokenAddress,
  }) async {
    limitTokenAddresses.add(tokenAddress);
    return (
      min: DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(minimumSats),
        decimals: 8,
      ),
      max: DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(10_000_000),
        decimals: 8,
      ),
    );
  }
}

class _FakeEvmChain extends Fake implements EvmChain {
  @override
  final EvmChainConfig config = const EvmChainConfig(
    id: 'arbitrum-regtest',
    chainId: 412346,
    rpcUrls: ['http://localhost:8545'],
    nativeDenomination: 'ETH',
  );

  @override
  BoltzSwapProvider? swaps;

  final Token bridgeToken;
  final StreamController<int> _blocks = StreamController<int>.broadcast();
  int blockListenCount = 0;
  int scanAllHdBalanceCalls = 0;

  _FakeEvmChain({required this.swaps, required this.bridgeToken});

  @override
  Stream<int> newBlocks({Duration interval = const Duration(seconds: 15)}) {
    blockListenCount++;
    return _blocks.stream;
  }

  @override
  Future<
    ({
      List<
        ({
          EthereumAddress address,
          EthPrivateKey keypair,
          int accountIndex,
          TokenAmount balance,
          bool isSmartAddress,
        })
      >
      nativeFunded,
      List<
        ({
          EthereumAddress address,
          EthPrivateKey keypair,
          int accountIndex,
          TokenAmount balance,
          String tokenName,
          EthereumAddress tokenAddress,
          bool isSmartAddress,
        })
      >
      tokenFunded,
    })
  >
  scanAllHDBalances({Map<String, EthereumAddress> tokens = const {}}) async {
    scanAllHdBalanceCalls++;
    return (
      nativeFunded:
          <
            ({
              EthereumAddress address,
              EthPrivateKey keypair,
              int accountIndex,
              TokenAmount balance,
              bool isSmartAddress,
            })
          >[],
      tokenFunded:
          <
            ({
              EthereumAddress address,
              EthPrivateKey keypair,
              int accountIndex,
              TokenAmount balance,
              String tokenName,
              EthereumAddress tokenAddress,
              bool isSmartAddress,
            })
          >[],
    );
  }

  @override
  Future<Token> resolveToken(String address) async {
    if (address.toLowerCase() == bridgeToken.address.toLowerCase()) {
      return bridgeToken;
    }
    throw StateError('Unexpected token resolution in test: $address');
  }

  Future<void> close() => _blocks.close();
}

class _FakeEvm extends Fake implements Evm {
  @override
  final List<EvmChain> configuredChains;

  _FakeEvm([this.configuredChains = const []]);
}

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {
  @override
  final StreamWithStatus<PaymentEvent> paymentEvents$ = StreamWithStatus();
}

class _FakeAuth extends Fake implements Auth {
  @override
  final _FakeDeterministicKeys hd = _FakeDeterministicKeys();
}

class _FakeTradeAccountAllocator extends Fake implements TradeAccountAllocator {
  Future<int?> Function(String tradeId)? lookup;
  final List<String> lookupTradeIds = [];

  @override
  Future<int?> tryFindTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 20,
  }) {
    lookupTradeIds.add(tradeId);
    return lookup?.call(tradeId) ?? Future.value(null);
  }
}

class _FakeDeterministicKeys extends Fake implements DeterministicKeys {
  final List<int> accountIndices = [];

  @override
  Future<EthPrivateKey> getActiveEvmKey({int accountIndex = 0}) async {
    accountIndices.add(accountIndex);
    return EthPrivateKey.fromHex(
      accountIndex.toRadixString(16).padLeft(64, '0'),
    );
  }
}

class _FakeSupportedEscrowContract extends Fake
    implements SupportedEscrowContract {
  @override
  final EthereumAddress address = EthereumAddress.fromHex(
    '0x5555555555555555555555555555555555555555',
  );

  @override
  Future<Map<EthereumAddress, BigInt>> allBalances({
    required EthereumAddress beneficiary,
  }) async {
    return {};
  }
}

class _FakeOperationStateStore extends Fake implements OperationStateStore {}

class _FakeUserConfigStore extends Fake implements UserConfigStore {}

String _tradeId(int index) => index.toRadixString(16).padLeft(64, '0');

EscrowArbitratedEvent _arbitratedEvent(
  String tradeId,
  EvmChain chain,
  SupportedEscrowContract contract,
) => EscrowArbitratedEvent(
  tradeId: tradeId,
  transactionHash: '0x${tradeId.substring(0, 64)}',
  blockNum: 1,
  block: null,
  chainId: chain.config.chainId,
  contractAddress: contract.address.eip55With0x,
  transactionIndex: 0,
  logIndex: 0,
  chain: chain,
  contract: contract,
  paymentForwarded: 0,
  bondForwarded: 0,
);
