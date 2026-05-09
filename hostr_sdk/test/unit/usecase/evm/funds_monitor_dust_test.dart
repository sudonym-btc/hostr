import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:hostr_sdk/datasources/boltz/boltz.dart';
import 'package:hostr_sdk/datasources/boltz/boltz_chain_info.dart';
import 'package:hostr_sdk/datasources/swagger_generated/boltz.swagger.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
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

FundsMonitorService _fundsMonitorService({_FakeEvm? evm}) =>
    FundsMonitorService(
      evm ?? _FakeEvm(),
      _FakeUserSubscriptions(),
      _FakeAuth(),
      _FakeTradeAccountAllocator(),
      _FakeOperationStateStore(),
      _FakeUserConfigStore(),
      CustomLogger(),
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

class _FakeAuth extends Fake implements Auth {}

class _FakeTradeAccountAllocator extends Fake
    implements TradeAccountAllocator {}

class _FakeOperationStateStore extends Fake implements OperationStateStore {}

class _FakeUserConfigStore extends Fake implements UserConfigStore {}
