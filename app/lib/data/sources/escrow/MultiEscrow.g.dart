// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"indexed":false,"internalType":"address","name":"seller","type":"address"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"fractionForwarded","type":"uint256"}],"name":"Arbitrated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"indexed":false,"internalType":"address","name":"seller","type":"address"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Claimed","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"message","type":"string"}],"name":"DebugLog","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"indexed":false,"internalType":"address","name":"buyer","type":"address"},{"indexed":false,"internalType":"address","name":"seller","type":"address"},{"indexed":false,"internalType":"address","name":"arbiter","type":"address"},{"indexed":false,"internalType":"uint256","name":"timelock","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"escrowFee","type":"uint256"}],"name":"TradeCreated","type":"event"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"internalType":"uint256","name":"factor","type":"uint256"}],"name":"arbitrate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"}],"name":"claim","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"tradeId","type":"bytes32"},{"internalType":"address","name":"_buyer","type":"address"},{"internalType":"address","name":"_seller","type":"address"},{"internalType":"address","name":"_arbiter","type":"address"},{"internalType":"uint256","name":"_timelock","type":"uint256"},{"internalType":"uint256","name":"_escrowFee","type":"uint256"}],"name":"createTrade","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"trades","outputs":[{"internalType":"address","name":"buyer","type":"address"},{"internalType":"address","name":"seller","type":"address"},{"internalType":"address","name":"arbiter","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"timelock","type":"uint256"},{"internalType":"uint256","name":"escrowFee","type":"uint256"}],"stateMutability":"view","type":"function"}]',
  'MultiEscrow',
);

class MultiEscrow extends _i1.GeneratedContract {
  MultiEscrow({
    required _i1.EthereumAddress address,
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

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> arbitrate(
    ({_i2.Uint8List tradeId, BigInt factor}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
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
    ({_i2.Uint8List tradeId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
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
      _i2.Uint8List tradeId,
      _i1.EthereumAddress buyer,
      _i1.EthereumAddress seller,
      _i1.EthereumAddress arbiter,
      BigInt timelock,
      BigInt escrowFee
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '369ea7fc'));
    final params = [
      args.tradeId,
      args.buyer,
      args.seller,
      args.arbiter,
      args.timelock,
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
  Future<Trades> trades(
    ({_i2.Uint8List $param9}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '00162420'));
    final params = [args.$param9];
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

  /// Returns a live stream of all DebugLog events emitted by this contract.
  Stream<DebugLog> debugLogEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('DebugLog');
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
      return DebugLog(
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

class Trades {
  Trades(List<dynamic> response)
      : buyer = (response[0] as _i1.EthereumAddress),
        seller = (response[1] as _i1.EthereumAddress),
        arbiter = (response[2] as _i1.EthereumAddress),
        amount = (response[3] as BigInt),
        timelock = (response[4] as BigInt),
        escrowFee = (response[5] as BigInt);

  final _i1.EthereumAddress buyer;

  final _i1.EthereumAddress seller;

  final _i1.EthereumAddress arbiter;

  final BigInt amount;

  final BigInt timelock;

  final BigInt escrowFee;
}

class Arbitrated {
  Arbitrated(
    List<dynamic> response,
    this.event,
  )   : tradeId = (response[0] as _i2.Uint8List),
        seller = (response[1] as _i1.EthereumAddress),
        buyer = (response[2] as _i1.EthereumAddress),
        amount = (response[3] as BigInt),
        fractionForwarded = (response[4] as BigInt);

  final _i2.Uint8List tradeId;

  final _i1.EthereumAddress seller;

  final _i1.EthereumAddress buyer;

  final BigInt amount;

  final BigInt fractionForwarded;

  final _i1.FilterEvent event;
}

class Claimed {
  Claimed(
    List<dynamic> response,
    this.event,
  )   : tradeId = (response[0] as _i2.Uint8List),
        seller = (response[1] as _i1.EthereumAddress),
        buyer = (response[2] as _i1.EthereumAddress),
        amount = (response[3] as BigInt);

  final _i2.Uint8List tradeId;

  final _i1.EthereumAddress seller;

  final _i1.EthereumAddress buyer;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class DebugLog {
  DebugLog(
    List<dynamic> response,
    this.event,
  ) : message = (response[0] as String);

  final String message;

  final _i1.FilterEvent event;
}

class TradeCreated {
  TradeCreated(
    List<dynamic> response,
    this.event,
  )   : tradeId = (response[0] as _i2.Uint8List),
        buyer = (response[1] as _i1.EthereumAddress),
        seller = (response[2] as _i1.EthereumAddress),
        arbiter = (response[3] as _i1.EthereumAddress),
        timelock = (response[4] as BigInt),
        escrowFee = (response[5] as BigInt);

  final _i2.Uint8List tradeId;

  final _i1.EthereumAddress buyer;

  final _i1.EthereumAddress seller;

  final _i1.EthereumAddress arbiter;

  final BigInt timelock;

  final BigInt escrowFee;

  final _i1.FilterEvent event;
}
