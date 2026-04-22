import 'package:models/main.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../datasources/contracts/escrow/MultiEscrow.g.dart';
import '../../../util/main.dart';
import '../../evm/chain/evm_chain.dart';
import '../../payments/constants.dart';
import 'escrow_eip712_signer.dart';
import 'escrow_event_scanner.dart';
import 'supported_escrow_contract.dart';

class MultiEscrowContractException implements Exception {
  final String selector;
  final String errorName;
  final String message;
  final Object? originalError;

  MultiEscrowContractException({
    required this.selector,
    required this.errorName,
    required this.message,
    this.originalError,
  });

  @override
  String toString() =>
      'MultiEscrowContractException($errorName, selector: $selector): $message';
}

class MultiEscrowWrapper extends SupportedEscrowContract<MultiEscrow> {
  static const Map<String, String> _customErrorSelectors = {
    '0x916da0d1': 'ClaimPeriodNotStarted',
    '0xdff46e2b': 'NoFundsToClaim',
    '0xb95c5dfc': 'TradeNotActive',
    '0x85d1f726': 'OnlySeller',
    '0x39fc5e0a': 'OnlyBuyerOrSeller',
    '0xe598e3ce': 'OnlyArbiter',
    '0x7505eadc': 'TradeIdAlreadyExists',
    '0xca4b8ad6': 'TradeAlreadyActive',
    '0x29ce3ded': 'MustSendFunds',
    '0xb7cc22bc': 'NoFundsToRelease',
    '0x3fb86fe2': 'InvalidFactor',
    '0xf4b3b1bc': 'NativeTransferFailed',
  };

  final CustomLogger logger;
  final EvmChain chain;
  late final EscrowEventScanner _eventScanner;

  MultiEscrowWrapper({
    required super.address,
    required this.chain,
    required CustomLogger logger,
  }) : logger = logger.scope('multi-escrow'),
       super(
         client: chain.client,
         contract: MultiEscrow(address: address, client: chain.client),
       ) {
    _eventScanner = EscrowEventScanner(
      contract: contract,
      chain: chain,
      parentContract: this,
      logger: logger,
    );
  }

  @override
  Future<void> ensureDeployed() async {
    final code = await chain.getCode(contract.self.address);
    if (code.isEmpty) {
      throw StateError(
        'Escrow contract not deployed at ${contract.self.address}. '
        'This address appears to be an EOA or empty address. '
        'Funding can succeed with no logs in that case because no contract code executes.',
      );
    }
  }

  EscrowEip712Signer get _signer {
    return EscrowEip712Signer(
      chainId: chain.config.chainId,
      verifyingContract: address,
    );
  }

  @override
  Call fund(FundArgs args) => logger.spanSync('fund', () {
    final isERC20 = args.token != null && args.token!.isERC20;
    final tokenAddress = isERC20
        ? EthereumAddress.fromHex(args.token!.address)
        : SupportedEscrowContract.zeroAddress;

    final bondAmountEvm = args.bondAmount?.asEvm ?? BigInt.zero;
    final totalValue = args.amount.asEvm + bondAmountEvm;

    return buildCall(
      functionName: 'createTrade',
      args: [
        getBytes32(args.tradeId),
        args.ethKey.address,
        EthereumAddress.fromHex(args.sellerEvmAddress),
        EthereumAddress.fromHex(args.arbiterEvmAddress),
        tokenAddress,
        args.amount.asEvm,
        bondAmountEvm,
        BigInt.from(args.unlockAt),
        args.escrowFee?.asEvm ?? BigInt.zero,
      ],
      value: isERC20 ? null : totalValue,
    );
  });

  @override
  Call claim({
    required String tradeId,
    required EthPrivateKey ethKey,
  }) => logger.spanSync('claim', () {
    final tradeIdBytes = getBytes32(tradeId);
    final signature = _signer.signClaim(tradeId: tradeIdBytes, signer: ethKey);
    return buildCall(functionName: 'claim', args: [tradeIdBytes, signature]);
  });

  @override
  Call arbitrate({
    required String tradeId,
    required double paymentForward,
    required double bondForward,
    required EthPrivateKey ethKey,
  }) => logger.spanSync('arbitrate', () {
    final tradeIdBytes = getBytes32(tradeId);
    final paymentFactor = BigInt.from((paymentForward * 1000).round());
    final bondFactor = BigInt.from((bondForward * 1000).round());
    final signature = _signer.signArbitrate(
      tradeId: tradeIdBytes,
      paymentFactor: paymentFactor,
      bondFactor: bondFactor,
      signer: ethKey,
    );
    final function = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'arbitrate',
    );
    return callFromEncoded(
      to: contract.self.address,
      data: function.encodeCall([
        tradeIdBytes,
        paymentFactor,
        bondFactor,
        signature,
      ]),
    );
  });

  @override
  Call release(ReleaseArgs args) => logger.spanSync('release', () {
    final actor = args.actor ?? args.ethKey.address;
    final tradeIdBytes = getBytes32(args.tradeId);
    final signature = _signer.signRelease(
      tradeId: tradeIdBytes,
      actor: actor,
      signer: args.ethKey,
    );
    return buildCall(
      functionName: 'releaseToCounterparty',
      args: [tradeIdBytes, actor, signature],
    );
  });

  @override
  Call withdraw(WithdrawArgs args) => logger.spanSync('withdraw', () {
    final tokenAddress = args.token;
    final signature = _signer.signWithdraw(
      token: tokenAddress,
      destination: args.destination,
      signer: args.ethKey,
    );
    return buildCall(
      functionName: 'withdraw',
      args: [tokenAddress, args.beneficiary, args.destination, signature],
    );
  });

  @override
  Future<BigInt> balanceOf({
    required EthereumAddress beneficiary,
    required EthereumAddress token,
  }) => logger.span('balanceOf', () async {
    await ensureDeployed();
    return _withDecodedCustomError(() {
      return contract.balances(($param6: beneficiary, $param7: token));
    });
  });

  @override
  Future<Map<EthereumAddress, BigInt>> allBalances({
    required EthereumAddress beneficiary,
  }) => logger.span('allBalances', () async {
    await ensureDeployed();
    final result = await _withDecodedCustomError(() {
      return contract.balanceOf((user: beneficiary));
    });
    final map = <EthereumAddress, BigInt>{};
    for (var i = 0; i < result.tokens.length; i++) {
      final amount = result.amounts[i];
      if (amount > BigInt.zero) {
        map[result.tokens[i]] = amount;
      }
    }
    return map;
  });

  @override
  Future<OnChainTrade?> getTrade(String tradeId) =>
      logger.span('getTrade', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(tradeId)));
        });

        if (!activeTrade.isActive) return null;

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) return null;

        return OnChainTrade(
          isActive: true,
          buyer: trade.buyer,
          seller: trade.seller,
          arbiter: trade.arbiter,
          token: trade.token,
          paymentAmount: trade.paymentAmount,
          bondAmount: trade.bondAmount,
          unlockAt: trade.unlockAt,
          escrowFee: trade.escrowFee,
        );
      });

  @override
  Future<bool> canClaim({required String tradeId}) =>
      logger.span('canClaim', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(tradeId)));
        });

        if (!activeTrade.isActive) {
          return false;
        }

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) {
          logger.w('Could not decode active trade for $tradeId');
          return false;
        }

        return DateTime.now().millisecondsSinceEpoch ~/ 1000 >
            trade.unlockAt.toInt();
      });

  @override
  Future<bool> canRelease(ReleaseArgs args) =>
      logger.span('canRelease', () async {
        await ensureDeployed();
        final activeTrade = await _withDecodedCustomError(() {
          return contract.activeTrade((tradeId: getBytes32(args.tradeId)));
        });

        if (!activeTrade.isActive) {
          return false;
        }

        final trade = _extractTrade(activeTrade.trade);
        if (trade == null) {
          logger.w('Could not decode active trade for ${args.tradeId}');
          return false;
        }

        final actor = args.ethKey.address;
        return actor == trade.buyer || actor == trade.seller;
      });

  @override
  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow, {
    bool includeLive = true,
    bool batch = true,
  }) => _eventScanner.allEvents(
    params,
    selectedEscrow,
    includeLive: includeLive,
    batch: batch,
    ensureDeployed: ensureDeployed,
  );

  Trades? _extractTrade(dynamic trade) => logger.spanSync('_extractTrade', () {
    if (trade is Trades) {
      return trade;
    }
    if (trade is List<dynamic>) {
      try {
        return Trades(trade);
      } catch (_) {
        return null;
      }
    }
    return null;
  });

  Future<T> _withDecodedCustomError<T>(Future<T> Function() action) =>
      logger.span('_withDecodedCustomError', () async {
        try {
          return await action();
        } catch (error) {
          final decoded = _decodeCustomError(error);
          if (decoded != null) {
            logger.w(decoded.toString());
            throw decoded;
          }
          rethrow;
        }
      });

  @override
  Object decodeWriteError(Object error) {
    final decoded = _decodeCustomError(error);
    if (decoded != null) {
      logger.w(decoded.toString());
      return decoded;
    }
    return error;
  }

  MultiEscrowContractException? _decodeCustomError(Object error) =>
      logger.spanSync('_decodeCustomError', () {
        final text = error.toString();
        final match = RegExp(
          r'custom error\s*:??\s*(0x[a-fA-F0-9]{8})',
          caseSensitive: false,
        ).firstMatch(text);

        if (match == null) {
          return null;
        }

        final selector = match.group(1)!.toLowerCase();
        final errorName =
            _customErrorSelectors[selector] ?? 'UnknownCustomError';
        return MultiEscrowContractException(
          selector: selector,
          errorName: errorName,
          message: text,
          originalError: error,
        );
      });
}
