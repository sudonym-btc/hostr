// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"id","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"version","type":"bytes32"},{"indexed":false,"internalType":"string","name":"value","type":"string"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"}],"name":"VersionAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"id","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"version","type":"bytes32"},{"indexed":false,"internalType":"string","name":"reason","type":"string"}],"name":"VersionCanceled","type":"event"},{"inputs":[{"internalType":"bytes32","name":"id","type":"bytes32"},{"internalType":"bytes32","name":"version","type":"bytes32"},{"internalType":"string","name":"value","type":"string"}],"name":"addVersion","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"id","type":"bytes32"},{"internalType":"bytes32","name":"version","type":"bytes32"},{"internalType":"string","name":"reason","type":"string"}],"name":"cancelVersion","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'IVersionRegistry',
);

class IVersionRegistry extends _i1.GeneratedContract {
  IVersionRegistry({
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
  Future<String> addVersion(
    ({_i2.Uint8List id, _i2.Uint8List version, String value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '089eae7e'));
    final params = [
      args.id,
      args.version,
      args.value,
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
  Future<String> cancelVersion(
    ({_i2.Uint8List id, _i2.Uint8List version, String reason}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '219ae672'));
    final params = [
      args.id,
      args.version,
      args.reason,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all VersionAdded events emitted by this contract.
  Stream<VersionAdded> versionAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VersionAdded');
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
      return VersionAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all VersionCanceled events emitted by this contract.
  Stream<VersionCanceled> versionCanceledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('VersionCanceled');
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
      return VersionCanceled(
        decoded,
        result,
      );
    });
  }
}

class VersionAdded {
  VersionAdded(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as _i2.Uint8List),
        version = (response[1] as _i2.Uint8List),
        value = (response[2] as String),
        time = (response[3] as BigInt);

  final _i2.Uint8List id;

  final _i2.Uint8List version;

  final String value;

  final BigInt time;

  final _i1.FilterEvent event;
}

class VersionCanceled {
  VersionCanceled(
    List<dynamic> response,
    this.event,
  )   : id = (response[0] as _i2.Uint8List),
        version = (response[1] as _i2.Uint8List),
        reason = (response[2] as String);

  final _i2.Uint8List id;

  final _i2.Uint8List version;

  final String reason;

  final _i1.FilterEvent event;
}
