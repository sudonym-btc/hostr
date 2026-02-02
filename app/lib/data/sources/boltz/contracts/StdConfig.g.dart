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
  '[{"type":"constructor","inputs":[{"name":"configFilePath","type":"string","internalType":"string"},{"name":"writeToFile","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"exists","inputs":[{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"exists","inputs":[{"name":"chain_id","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"get","inputs":[{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"stateMutability":"view"},{"type":"function","name":"get","inputs":[{"name":"chain_id","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"stateMutability":"view"},{"type":"function","name":"getChainIds","inputs":[],"outputs":[{"name":"","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"view"},{"type":"function","name":"getRpcUrl","inputs":[],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"getRpcUrl","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"resolveChainId","inputs":[{"name":"aliasOrId","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"string[]","internalType":"string[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"uint256[]","internalType":"uint256[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"int256[]","internalType":"int256[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes[]","internalType":"bytes[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes[]","internalType":"bytes[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"string[]","internalType":"string[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"uint256[]","internalType":"uint256[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"int256[]","internalType":"int256[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bool[]","internalType":"bool[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"set","inputs":[{"name":"key","type":"string","internalType":"string"},{"name":"value","type":"bool[]","internalType":"bool[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeUpdatesBackToFile","inputs":[{"name":"enabled","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"error","name":"AlreadyInitialized","inputs":[{"name":"key","type":"string","internalType":"string"}]},{"type":"error","name":"ChainNotInitialized","inputs":[{"name":"chainId","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"InvalidChainKey","inputs":[{"name":"aliasOrId","type":"string","internalType":"string"}]},{"type":"error","name":"TypeMismatch","inputs":[{"name":"expected","type":"string","internalType":"string"},{"name":"actual","type":"string","internalType":"string"}]},{"type":"error","name":"UnableToParseVariable","inputs":[{"name":"key","type":"string","internalType":"string"}]},{"type":"error","name":"WriteToFileInForbiddenCtxt","inputs":[]}]',
  'StdConfig',
);

class StdConfig extends _i1.GeneratedContract {
  StdConfig({
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
  Future<bool> exists(
    ({String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '261a323e'));
    final params = [args.key];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> exists$2(
    ({BigInt chain_id, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '43d9eb7b'));
    final params = [
      args.chain_id,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> get(
    ({String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '693ec85e'));
    final params = [args.key];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> get$2(
    ({BigInt chain_id, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '805da4ad'));
    final params = [
      args.chain_id,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<BigInt>> getChainIds({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '1d776323'));
    final params = [];
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
  Future<String> getRpcUrl({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '43ec8b6a'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<String> getRpcUrl$2(
    ({BigInt chainId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '7df3ef12'));
    final params = [args.chainId];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> resolveChainId(
    ({String aliasOrId}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '3f3a7588'));
    final params = [args.aliasOrId];
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
  Future<String> set(
    ({BigInt chainId, String key, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '07d79d9a'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$2(
    ({BigInt chainId, String key, List<_i3.Uint8List> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '08f7b4b2'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$3(
    ({BigInt chainId, String key, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '22dc48fd'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$4(
    ({String key, _i3.Uint8List value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '2b29c0fa'));
    final params = [
      args.key,
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
  Future<String> set$5(
    ({String key, _i3.Uint8List value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '2e3196a5'));
    final params = [
      args.key,
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
  Future<String> set$6(
    ({String key, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '2ef8ba74'));
    final params = [
      args.key,
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
  Future<String> set$7(
    ({BigInt chainId, String key, _i3.Uint8List value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '4d85ce80'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$8(
    ({String key, List<String> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '59b39526'));
    final params = [
      args.key,
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
  Future<String> set$9(
    ({BigInt chainId, String key, _i2.EthereumAddress value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '5eba0df0'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$10(
    ({BigInt chainId, String key, List<_i2.EthereumAddress> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '61141c97'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$11(
    ({BigInt chainId, String key, String value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, '65560950'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$12(
    ({String key, List<BigInt> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '7b8fed81'));
    final params = [
      args.key,
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
  Future<String> set$13(
    ({String key, List<_i2.EthereumAddress> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '88c63d45'));
    final params = [
      args.key,
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
  Future<String> set$14(
    ({String key, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '8a42ebe9'));
    final params = [
      args.key,
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
  Future<String> set$15(
    ({BigInt chainId, String key, List<BigInt> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '8be19924'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$16(
    ({BigInt chainId, String key, List<_i3.Uint8List> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '93dbe6e0'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$17(
    ({String key, _i2.EthereumAddress value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, 'a815ff15'));
    final params = [
      args.key,
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
  Future<String> set$18(
    ({BigInt chainId, String key, bool value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, 'b3a64001'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$19(
    ({String key, bool value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, 'ba0ff22c'));
    final params = [
      args.key,
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
  Future<String> set$20(
    ({String key, List<_i3.Uint8List> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, 'c91ca7ba'));
    final params = [
      args.key,
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
  Future<String> set$21(
    ({BigInt chainId, String key, _i3.Uint8List value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, 'cf1cfa99'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$22(
    ({BigInt chainId, String key, List<String> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, 'cf72a2f3'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$23(
    ({BigInt chainId, String key, List<BigInt> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, 'db0075df'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$24(
    ({String key, List<BigInt> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, 'de0fc9b3'));
    final params = [
      args.key,
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
  Future<String> set$25(
    ({BigInt chainId, String key, List<bool> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, 'e298d00b'));
    final params = [
      args.chainId,
      args.key,
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
  Future<String> set$26(
    ({String key, List<_i3.Uint8List> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, 'e6053250'));
    final params = [
      args.key,
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
  Future<String> set$27(
    ({String key, String value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[35];
    assert(checkSignature(function, 'e942b516'));
    final params = [
      args.key,
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
  Future<String> set$28(
    ({String key, List<bool> value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, 'fa3c074a'));
    final params = [
      args.key,
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
  Future<String> writeUpdatesBackToFile(
    ({bool enabled}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, 'd6698dc4'));
    final params = [args.enabled];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }
}
