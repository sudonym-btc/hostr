// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'package:wallet/wallet.dart' as _i2;
import 'dart:typed_data' as _i3;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"inputs":[],"name":"ClaimPeriodNotStarted","type":"error"},{"inputs":[],"name":"InvalidFactor","type":"error"},{"inputs":[],"name":"InvalidUnlockAt","type":"error"},{"inputs":[],"name":"MustSendFunds","type":"error"},{"inputs":[],"name":"NoFundsToClaim","type":"error"},{"inputs":[],"name":"NoFundsToRelease","type":"error"},{"inputs":[],"name":"OnlyArbiter","type":"error"},{"inputs":[],"name":"OnlyBuyerOrSeller","type":"error"},{"inputs":[],"name":"OnlySeller","type":"error"},{"inputs":[],"name":"TradeAlreadyActive","type":"error"},{"inputs":[],"name":"TradeIdAlreadyExists","type":"error"},{"inputs":[],"name":"TradeNotActive","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"indexed":false,"internalType":"address","name":"seller","type":"address"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"fractionForwarded","type":"uint256"}],"name":"Arbitrated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"indexed":false,"internalType":"address","name":"seller","type":"address"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Claimed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"indexed":false,"internalType":"address","name":"from","type":"address"},{"indexed":false,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"ReleasedToCounterparty","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"indexed":false,"internalType":"address","name":"seller","type":"address"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":true,"internalType":"address","name":"arbiter","type":"address"},{"indexed":false,"internalType":"uint256","name":"unlockAt","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"escrowFee","type":"uint256"}],"name":"TradeCreated","type":"event"},{"inputs":[],"name":"FACTOR_SCALE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"}],"name":"activeTrade","outputs":[{"internalType":"bool","name":"isActive","type":"bool"},{"components":[{"internalType":"address","name":"buyer","type":"address"},{"internalType":"address","name":"seller","type":"address"},{"internalType":"address","name":"arbiter","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"unlockAt","type":"uint256"},{"internalType":"uint256","name":"escrowFee","type":"uint256"}],"internalType":"struct MultiEscrow.Trade","name":"trade","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"activeTradeCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"internalType":"uint256","name":"factor","type":"uint256"}],"name":"arbitrate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"}],"name":"claim","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"internalType":"address","name":"_buyer","type":"address"},{"internalType":"address","name":"_seller","type":"address"},{"internalType":"address","name":"_arbiter","type":"address"},{"internalType":"uint256","name":"_unlockAt","type":"uint256"},{"internalType":"uint256","name":"_escrowFee","type":"uint256"}],"name":"createTrade","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"getActiveTradeIds","outputs":[{"internalType":"bytes32[]","name":"","type":"bytes32[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"offset","type":"uint256"},{"internalType":"uint256","name":"limit","type":"uint256"}],"name":"getActiveTradeIdsPage","outputs":[{"internalType":"bytes32[]","name":"ids","type":"bytes32[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"}],"name":"releaseToCounterparty","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"trades","outputs":[{"internalType":"address","name":"buyer","type":"address"},{"internalType":"address","name":"seller","type":"address"},{"internalType":"address","name":"arbiter","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"unlockAt","type":"uint256"},{"internalType":"uint256","name":"escrowFee","type":"uint256"}],"stateMutability":"view","type":"function"}]',
  'MultiEscrow',
);

class MultiEscrow extends _i1.GeneratedContract {
  MultiEscrow({
    required _i2.EthereumAddress address,
    required _i1.Web3Client client,
    int? chainId,
  }) : super(
          _i1.DeployedContract(
            _contractAbi,
            address,
          ),
          client,
          chainId,
        );

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> FACTOR_SCALE({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'a1fb6345'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<ActiveTrade> activeTrade(
    ({_i3.Uint8List tradeId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '1ca82a93'));
    final params = [args.tradeId];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return ActiveTrade(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> activeTradeCount({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'cedc4478'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> arbitrate(
    ({_i3.Uint8List tradeId, BigInt factor}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'cb2e7212'));
    final params = [
      args.tradeId,
      args.factor,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> claim(
    ({_i3.Uint8List tradeId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'bd66528a'));
    final params = [args.tradeId];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> createTrade(
    ({
      _i3.Uint8List tradeId,
      _i2.EthereumAddress buyer,
      _i2.EthereumAddress seller,
      _i2.EthereumAddress arbiter,
      BigInt unlockAt,
      BigInt escrowFee
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '369ea7fc'));
    final params = [
      args.tradeId,
      args.buyer,
      args.seller,
      args.arbiter,
      args.unlockAt,
      args.escrowFee,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i3.Uint8List>> getActiveTradeIds({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'f4298124'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i3.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i3.Uint8List>> getActiveTradeIdsPage(
    ({BigInt offset, BigInt limit}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '56c48e83'));
    final params = [
      args.offset,
      args.limit,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i3.Uint8List>();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> releaseToCounterparty(
    ({_i3.Uint8List tradeId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '7a5b8584'));
    final params = [args.tradeId];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<Trades> trades(
    ({_i3.Uint8List $param13}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '00162420'));
    final params = [args.$param13];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Trades(response);
  }

  /// Returns a live stream of all Arbitrated events emitted by this contract.
  Stream<Arbitrated> arbitratedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Arbitrated');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Arbitrated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Claimed events emitted by this contract.
  Stream<Claimed> claimedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Claimed');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Claimed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ReleasedToCounterparty events emitted by this contract.
  Stream<ReleasedToCounterparty> releasedToCounterpartyEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ReleasedToCounterparty');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return ReleasedToCounterparty(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TradeCreated events emitted by this contract.
  Stream<TradeCreated> tradeCreatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TradeCreated');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return TradeCreated(
        decoded,
        result,
      );
    });
  }
}

class ActiveTrade {
  ActiveTrade(List<dynamic> response)
      : isActive = (response[0] as bool),
        trade = (response[1] as dynamic);

  final bool isActive;

  final dynamic trade;
}

class Trades {
  Trades(List<dynamic> response)
      : buyer = (response[0] as _i2.EthereumAddress),
        seller = (response[1] as _i2.EthereumAddress),
        arbiter = (response[2] as _i2.EthereumAddress),
        amount = (response[3] as BigInt),
        unlockAt = (response[4] as BigInt),
        escrowFee = (response[5] as BigInt);

  final _i2.EthereumAddress buyer;

  final _i2.EthereumAddress seller;

  final _i2.EthereumAddress arbiter;

  final BigInt amount;

  final BigInt unlockAt;

  final BigInt escrowFee;
}

class Arbitrated {
  Arbitrated(
    List<dynamic> response,
    this.event,
  )   : tradeId = (response[0] as _i3.Uint8List),
        seller = (response[1] as _i2.EthereumAddress),
        buyer = (response[2] as _i2.EthereumAddress),
        amount = (response[3] as BigInt),
        fractionForwarded = (response[4] as BigInt);

  final _i3.Uint8List tradeId;

  final _i2.EthereumAddress seller;

  final _i2.EthereumAddress buyer;

  final BigInt amount;

  final BigInt fractionForwarded;

  final _i1.FilterEvent event;
}

class Claimed {
  Claimed(
    List<dynamic> response,
    this.event,
  )   : tradeId = (response[0] as _i3.Uint8List),
        seller = (response[1] as _i2.EthereumAddress),
        buyer = (response[2] as _i2.EthereumAddress),
        amount = (response[3] as BigInt);

  final _i3.Uint8List tradeId;

  final _i2.EthereumAddress seller;

  final _i2.EthereumAddress buyer;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class ReleasedToCounterparty {
  ReleasedToCounterparty(
    List<dynamic> response,
    this.event,
  )   : tradeId = (response[0] as _i3.Uint8List),
        from = (response[1] as _i2.EthereumAddress),
        to = (response[2] as _i2.EthereumAddress),
        amount = (response[3] as BigInt);

  final _i3.Uint8List tradeId;

  final _i2.EthereumAddress from;

  final _i2.EthereumAddress to;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class TradeCreated {
  TradeCreated(
    List<dynamic> response,
    this.event,
  )   : tradeId = (response[0] as _i3.Uint8List),
        seller = (response[1] as _i2.EthereumAddress),
        buyer = (response[2] as _i2.EthereumAddress),
        arbiter = (response[3] as _i2.EthereumAddress),
        unlockAt = (response[4] as BigInt),
        escrowFee = (response[5] as BigInt);

  final _i3.Uint8List tradeId;

  final _i2.EthereumAddress seller;

  final _i2.EthereumAddress buyer;

  final _i2.EthereumAddress arbiter;

  final BigInt unlockAt;

  final BigInt escrowFee;

  final _i1.FilterEvent event;
}
