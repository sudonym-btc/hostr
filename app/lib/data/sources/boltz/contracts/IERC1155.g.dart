// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"balanceOf","inputs":[{"name":"_owner","type":"address","internalType":"address"},{"name":"_id","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"balanceOfBatch","inputs":[{"name":"_owners","type":"address[]","internalType":"address[]"},{"name":"_ids","type":"uint256[]","internalType":"uint256[]"}],"outputs":[{"name":"","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"view"},{"type":"function","name":"isApprovedForAll","inputs":[{"name":"_owner","type":"address","internalType":"address"},{"name":"_operator","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"safeBatchTransferFrom","inputs":[{"name":"_from","type":"address","internalType":"address"},{"name":"_to","type":"address","internalType":"address"},{"name":"_ids","type":"uint256[]","internalType":"uint256[]"},{"name":"_values","type":"uint256[]","internalType":"uint256[]"},{"name":"_data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"safeTransferFrom","inputs":[{"name":"_from","type":"address","internalType":"address"},{"name":"_to","type":"address","internalType":"address"},{"name":"_id","type":"uint256","internalType":"uint256"},{"name":"_value","type":"uint256","internalType":"uint256"},{"name":"_data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setApprovalForAll","inputs":[{"name":"_operator","type":"address","internalType":"address"},{"name":"_approved","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"supportsInterface","inputs":[{"name":"interfaceID","type":"bytes4","internalType":"bytes4"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"event","name":"ApprovalForAll","inputs":[{"name":"_owner","type":"address","indexed":true,"internalType":"address"},{"name":"_operator","type":"address","indexed":true,"internalType":"address"},{"name":"_approved","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"event","name":"TransferBatch","inputs":[{"name":"_operator","type":"address","indexed":true,"internalType":"address"},{"name":"_from","type":"address","indexed":true,"internalType":"address"},{"name":"_to","type":"address","indexed":true,"internalType":"address"},{"name":"_ids","type":"uint256[]","indexed":false,"internalType":"uint256[]"},{"name":"_values","type":"uint256[]","indexed":false,"internalType":"uint256[]"}],"anonymous":false},{"type":"event","name":"TransferSingle","inputs":[{"name":"_operator","type":"address","indexed":true,"internalType":"address"},{"name":"_from","type":"address","indexed":true,"internalType":"address"},{"name":"_to","type":"address","indexed":true,"internalType":"address"},{"name":"_id","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"_value","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"URI","inputs":[{"name":"_value","type":"string","indexed":false,"internalType":"string"},{"name":"_id","type":"uint256","indexed":true,"internalType":"uint256"}],"anonymous":false}]',
  'IERC1155',
);

class IERC1155 extends _i1.GeneratedContract {
  IERC1155({
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> balanceOf(
    ({_i1.EthereumAddress owner, BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '00fdd58e'));
    final params = [
      args.owner,
      args.id,
    ];
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
  Future<List<BigInt>> balanceOfBatch(
    ({List<_i1.EthereumAddress> owners, List<BigInt> ids}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '4e1273f4'));
    final params = [
      args.owners,
      args.ids,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isApprovedForAll(
    ({_i1.EthereumAddress owner, _i1.EthereumAddress operator}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'e985e9c5'));
    final params = [
      args.owner,
      args.operator,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> safeBatchTransferFrom(
    ({
      _i1.EthereumAddress from,
      _i1.EthereumAddress to,
      List<BigInt> ids,
      List<BigInt> values,
      _i2.Uint8List data
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '2eb2c2d6'));
    final params = [
      args.from,
      args.to,
      args.ids,
      args.values,
      args.data,
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
  Future<String> safeTransferFrom(
    ({
      _i1.EthereumAddress from,
      _i1.EthereumAddress to,
      BigInt id,
      BigInt value,
      _i2.Uint8List data
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'f242432a'));
    final params = [
      args.from,
      args.to,
      args.id,
      args.value,
      args.data,
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
  Future<String> setApprovalForAll(
    ({_i1.EthereumAddress operator, bool approved}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'a22cb465'));
    final params = [
      args.operator,
      args.approved,
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
  Future<bool> supportsInterface(
    ({_i2.Uint8List interfaceID}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '01ffc9a7'));
    final params = [args.interfaceID];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// Returns a live stream of all ApprovalForAll events emitted by this contract.
  Stream<ApprovalForAll> approvalForAllEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ApprovalForAll');
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
      return ApprovalForAll(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TransferBatch events emitted by this contract.
  Stream<TransferBatch> transferBatchEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TransferBatch');
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
      return TransferBatch(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TransferSingle events emitted by this contract.
  Stream<TransferSingle> transferSingleEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TransferSingle');
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
      return TransferSingle(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all URI events emitted by this contract.
  Stream<URI> uRIEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('URI');
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
      return URI(
        decoded,
        result,
      );
    });
  }
}

class ApprovalForAll {
  ApprovalForAll(
    List<dynamic> response,
    this.event,
  )   : owner = (response[0] as _i1.EthereumAddress),
        operator = (response[1] as _i1.EthereumAddress),
        approved = (response[2] as bool);

  final _i1.EthereumAddress owner;

  final _i1.EthereumAddress operator;

  final bool approved;

  final _i1.FilterEvent event;
}

class TransferBatch {
  TransferBatch(
    List<dynamic> response,
    this.event,
  )   : operator = (response[0] as _i1.EthereumAddress),
        from = (response[1] as _i1.EthereumAddress),
        to = (response[2] as _i1.EthereumAddress),
        ids = (response[3] as List<dynamic>).cast<BigInt>(),
        values = (response[4] as List<dynamic>).cast<BigInt>();

  final _i1.EthereumAddress operator;

  final _i1.EthereumAddress from;

  final _i1.EthereumAddress to;

  final List<BigInt> ids;

  final List<BigInt> values;

  final _i1.FilterEvent event;
}

class TransferSingle {
  TransferSingle(
    List<dynamic> response,
    this.event,
  )   : operator = (response[0] as _i1.EthereumAddress),
        from = (response[1] as _i1.EthereumAddress),
        to = (response[2] as _i1.EthereumAddress),
        id = (response[3] as BigInt),
        value = (response[4] as BigInt);

  final _i1.EthereumAddress operator;

  final _i1.EthereumAddress from;

  final _i1.EthereumAddress to;

  final BigInt id;

  final BigInt value;

  final _i1.FilterEvent event;
}

class URI {
  URI(
    List<dynamic> response,
    this.event,
  )   : value = (response[0] as String),
        id = (response[1] as BigInt);

  final String value;

  final BigInt id;

  final _i1.FilterEvent event;
}
