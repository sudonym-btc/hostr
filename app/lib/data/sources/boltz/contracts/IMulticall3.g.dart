// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"aggregate","inputs":[{"name":"calls","type":"tuple[]","internalType":"struct IMulticall3.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"blockNumber","type":"uint256","internalType":"uint256"},{"name":"returnData","type":"bytes[]","internalType":"bytes[]"}],"stateMutability":"payable"},{"type":"function","name":"aggregate3","inputs":[{"name":"calls","type":"tuple[]","internalType":"struct IMulticall3.Call3[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"allowFailure","type":"bool","internalType":"bool"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"returnData","type":"tuple[]","internalType":"struct IMulticall3.Result[]","components":[{"name":"success","type":"bool","internalType":"bool"},{"name":"returnData","type":"bytes","internalType":"bytes"}]}],"stateMutability":"payable"},{"type":"function","name":"aggregate3Value","inputs":[{"name":"calls","type":"tuple[]","internalType":"struct IMulticall3.Call3Value[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"allowFailure","type":"bool","internalType":"bool"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"returnData","type":"tuple[]","internalType":"struct IMulticall3.Result[]","components":[{"name":"success","type":"bool","internalType":"bool"},{"name":"returnData","type":"bytes","internalType":"bytes"}]}],"stateMutability":"payable"},{"type":"function","name":"blockAndAggregate","inputs":[{"name":"calls","type":"tuple[]","internalType":"struct IMulticall3.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"blockNumber","type":"uint256","internalType":"uint256"},{"name":"blockHash","type":"bytes32","internalType":"bytes32"},{"name":"returnData","type":"tuple[]","internalType":"struct IMulticall3.Result[]","components":[{"name":"success","type":"bool","internalType":"bool"},{"name":"returnData","type":"bytes","internalType":"bytes"}]}],"stateMutability":"payable"},{"type":"function","name":"getBasefee","inputs":[],"outputs":[{"name":"basefee","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getBlockHash","inputs":[{"name":"blockNumber","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"blockHash","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"getBlockNumber","inputs":[],"outputs":[{"name":"blockNumber","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getChainId","inputs":[],"outputs":[{"name":"chainid","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getCurrentBlockCoinbase","inputs":[],"outputs":[{"name":"coinbase","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"getCurrentBlockDifficulty","inputs":[],"outputs":[{"name":"difficulty","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getCurrentBlockGasLimit","inputs":[],"outputs":[{"name":"gaslimit","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getCurrentBlockTimestamp","inputs":[],"outputs":[{"name":"timestamp","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getEthBalance","inputs":[{"name":"addr","type":"address","internalType":"address"}],"outputs":[{"name":"balance","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getLastBlockHash","inputs":[],"outputs":[{"name":"blockHash","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"tryAggregate","inputs":[{"name":"requireSuccess","type":"bool","internalType":"bool"},{"name":"calls","type":"tuple[]","internalType":"struct IMulticall3.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"returnData","type":"tuple[]","internalType":"struct IMulticall3.Result[]","components":[{"name":"success","type":"bool","internalType":"bool"},{"name":"returnData","type":"bytes","internalType":"bytes"}]}],"stateMutability":"payable"},{"type":"function","name":"tryBlockAndAggregate","inputs":[{"name":"requireSuccess","type":"bool","internalType":"bool"},{"name":"calls","type":"tuple[]","internalType":"struct IMulticall3.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"blockNumber","type":"uint256","internalType":"uint256"},{"name":"blockHash","type":"bytes32","internalType":"bytes32"},{"name":"returnData","type":"tuple[]","internalType":"struct IMulticall3.Result[]","components":[{"name":"success","type":"bool","internalType":"bool"},{"name":"returnData","type":"bytes","internalType":"bytes"}]}],"stateMutability":"payable"}]',
  'IMulticall3',
);

class IMulticall3 extends _i1.GeneratedContract {
  IMulticall3({
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
  Future<String> aggregate(
    ({List<dynamic> calls}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '252dba42'));
    final params = [args.calls];
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
  Future<String> aggregate3(
    ({List<dynamic> calls}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '82ad56cb'));
    final params = [args.calls];
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
  Future<String> aggregate3Value(
    ({List<dynamic> calls}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '174dea71'));
    final params = [args.calls];
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
  Future<String> blockAndAggregate(
    ({List<dynamic> calls}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'c3077fa9'));
    final params = [args.calls];
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
  Future<BigInt> getBasefee({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '3e64a696'));
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
  Future<_i2.Uint8List> getBlockHash(
    ({BigInt blockNumber}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'ee82ac5e'));
    final params = [args.blockNumber];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.Uint8List);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> getBlockNumber({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '42cbb15c'));
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
  Future<BigInt> getChainId({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '3408e470'));
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
  Future<_i1.EthereumAddress> getCurrentBlockCoinbase(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'a8b0574e'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i1.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> getCurrentBlockDifficulty({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '72425d9d'));
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
  Future<BigInt> getCurrentBlockGasLimit({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '86d516e8'));
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
  Future<BigInt> getCurrentBlockTimestamp({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '0f28c97d'));
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
  Future<BigInt> getEthBalance(
    ({_i1.EthereumAddress addr}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '4d2301cc'));
    final params = [args.addr];
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
  Future<_i2.Uint8List> getLastBlockHash({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '27e86d6e'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.Uint8List);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> tryAggregate(
    ({bool requireSuccess, List<dynamic> calls}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, 'bce38bd7'));
    final params = [
      args.requireSuccess,
      args.calls,
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
  Future<String> tryBlockAndAggregate(
    ({bool requireSuccess, List<dynamic> calls}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '399542e9'));
    final params = [
      args.requireSuccess,
      args.calls,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }
}
