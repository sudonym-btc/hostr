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
  '[{"type":"function","name":"IS_TEST","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"excludeArtifacts","inputs":[],"outputs":[{"name":"excludedArtifacts_","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"excludeContracts","inputs":[],"outputs":[{"name":"excludedContracts_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"excludeSelectors","inputs":[],"outputs":[{"name":"excludedSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzSelector[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"excludeSenders","inputs":[],"outputs":[{"name":"excludedSenders_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"failed","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"targetArtifactSelectors","inputs":[],"outputs":[{"name":"targetedArtifactSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzArtifactSelector[]","components":[{"name":"artifact","type":"string","internalType":"string"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetArtifacts","inputs":[],"outputs":[{"name":"targetedArtifacts_","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"targetContracts","inputs":[],"outputs":[{"name":"targetedContracts_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"targetInterfaces","inputs":[],"outputs":[{"name":"targetedInterfaces_","type":"tuple[]","internalType":"struct StdInvariant.FuzzInterface[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"artifacts","type":"string[]","internalType":"string[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetSelectors","inputs":[],"outputs":[{"name":"targetedSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzSelector[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetSenders","inputs":[],"outputs":[{"name":"targetedSenders_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"testFuzz_Bound","inputs":[{"name":"num","type":"uint256","internalType":"uint256"},{"name":"min","type":"uint256","internalType":"uint256"},{"name":"max","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"testFuzz_BoundInt","inputs":[{"name":"num","type":"int256","internalType":"int256"},{"name":"min","type":"int256","internalType":"int256"},{"name":"max","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"testFuzz_BoundInt_DistributionIsEven","inputs":[{"name":"min","type":"int256","internalType":"int256"},{"name":"size","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"testFuzz_Bound_DistributionIsEven","inputs":[{"name":"min","type":"uint256","internalType":"uint256"},{"name":"size","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"testFuzz_RevertIf_BoundIntMaxLessThanMin","inputs":[{"name":"num","type":"int256","internalType":"int256"},{"name":"min","type":"int256","internalType":"int256"},{"name":"max","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFuzz_RevertIf_BoundMaxLessThanMin","inputs":[{"name":"num","type":"uint256","internalType":"uint256"},{"name":"min","type":"uint256","internalType":"uint256"},{"name":"max","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"test_Bound","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BoundInt","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BoundIntInt256Max","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BoundIntInt256Min","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BoundInt_EdgeCoverage","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BoundInt_WithinRange","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BoundPrivateKey","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BoundUint256Max","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_Bound_EdgeCoverage","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_Bound_WithinRange","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_BytesToUint","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_ComputeCreate2Address","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_ComputeCreate2AddressWithDefaultDeployer","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_ComputeCreateAddress","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"test_RevertIf_BoundIntMaxLessThanMin","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"test_RevertIf_BoundMaxLessThanMin","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"test_RevertIf_BytesLengthExceeds32","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"log","inputs":[{"name":"","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_address","inputs":[{"name":"","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"uint256[]","indexed":false,"internalType":"uint256[]"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"int256[]","indexed":false,"internalType":"int256[]"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"log_bytes","inputs":[{"name":"","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false},{"type":"event","name":"log_bytes32","inputs":[{"name":"","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false},{"type":"event","name":"log_int","inputs":[{"name":"","type":"int256","indexed":false,"internalType":"int256"}],"anonymous":false},{"type":"event","name":"log_named_address","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256[]","indexed":false,"internalType":"uint256[]"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256[]","indexed":false,"internalType":"int256[]"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"log_named_bytes","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false},{"type":"event","name":"log_named_bytes32","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false},{"type":"event","name":"log_named_decimal_int","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256","indexed":false,"internalType":"int256"},{"name":"decimals","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_named_decimal_uint","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"decimals","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_named_int","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256","indexed":false,"internalType":"int256"}],"anonymous":false},{"type":"event","name":"log_named_string","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_named_uint","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_string","inputs":[{"name":"","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_uint","inputs":[{"name":"","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"logs","inputs":[{"name":"","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false}]',
  'StdUtilsTest',
);

class StdUtilsTest extends _i1.GeneratedContract {
  StdUtilsTest({
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
  Future<bool> IS_TEST({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'fa7626d4'));
    final params = [];
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
  Future<List<String>> excludeArtifacts({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'b5508aa9'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<String>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> excludeContracts(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'e20c9f71'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<dynamic>> excludeSelectors({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'b0464fdc'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> excludeSenders(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '1ed7831c'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> failed({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'ba414fa6'));
    final params = [];
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
  Future<List<dynamic>> targetArtifactSelectors({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '66d9a9a0'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> targetArtifacts({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '85226c81'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<String>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> targetContracts(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '3f7286f4'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<dynamic>> targetInterfaces({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '2ade3880'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<dynamic>> targetSelectors({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '916a17c6'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> targetSenders(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '3e5e3c23'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> testFuzz_Bound(
    ({BigInt num, BigInt min, BigInt max}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '996bb0ce'));
    final params = [
      args.num,
      args.min,
      args.max,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> testFuzz_BoundInt(
    ({BigInt num, BigInt min, BigInt max}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, 'dc798340'));
    final params = [
      args.num,
      args.min,
      args.max,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> testFuzz_BoundInt_DistributionIsEven(
    ({BigInt min, BigInt size}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '860a6a26'));
    final params = [
      args.min,
      args.size,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> testFuzz_Bound_DistributionIsEven(
    ({BigInt min, BigInt size}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '91ba67cd'));
    final params = [
      args.min,
      args.size,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> testFuzz_RevertIf_BoundIntMaxLessThanMin(
    ({BigInt num, BigInt min, BigInt max}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '70f45fb3'));
    final params = [
      args.num,
      args.min,
      args.max,
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
  Future<String> testFuzz_RevertIf_BoundMaxLessThanMin(
    ({BigInt num, BigInt min, BigInt max}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '8404d3eb'));
    final params = [
      args.num,
      args.min,
      args.max,
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
  Future<void> test_Bound({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '006fe30b'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BoundInt({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'c3692e82'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BoundIntInt256Max({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, 'd2b68a17'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BoundIntInt256Min({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, 'df987741'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BoundInt_EdgeCoverage({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '1fbde34c'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BoundInt_WithinRange({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '099fe57f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BoundPrivateKey({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '599967fb'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BoundUint256Max({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, '66c4341a'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_Bound_EdgeCoverage({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, '435f8438'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_Bound_WithinRange({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, 'c42b27cc'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_BytesToUint({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '0d2bf636'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_ComputeCreate2Address({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, 'fe7d54bb'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_ComputeCreate2AddressWithDefaultDeployer(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '4f13245a'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> test_ComputeCreateAddress({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, 'cc754e07'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> test_RevertIf_BoundIntMaxLessThanMin({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, '6354452c'));
    final params = [];
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
  Future<String> test_RevertIf_BoundMaxLessThanMin({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '2f88f2e3'));
    final params = [];
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
  Future<String> test_RevertIf_BytesLengthExceeds32({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, '499c4727'));
    final params = [];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all log events emitted by this contract.
  Stream<log> logEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log');
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
      return log(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_address events emitted by this contract.
  Stream<log_address> log_addressEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_address');
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
      return log_address(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_array events emitted by this contract.
  Stream<log_array> log_arrayEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_array');
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
      return log_array(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_array$2 events emitted by this contract.
  Stream<log_array$2> log_array$2Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_array');
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
      return log_array$2(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_array$3 events emitted by this contract.
  Stream<log_array$3> log_array$3Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_array');
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
      return log_array$3(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_bytes events emitted by this contract.
  Stream<log_bytes> log_bytesEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_bytes');
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
      return log_bytes(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_bytes32 events emitted by this contract.
  Stream<log_bytes32> log_bytes32Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_bytes32');
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
      return log_bytes32(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_int events emitted by this contract.
  Stream<log_int> log_intEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_int');
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
      return log_int(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_address events emitted by this contract.
  Stream<log_named_address> log_named_addressEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_address');
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
      return log_named_address(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_array events emitted by this contract.
  Stream<log_named_array> log_named_arrayEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_array');
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
      return log_named_array(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_array$2 events emitted by this contract.
  Stream<log_named_array$2> log_named_array$2Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_array');
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
      return log_named_array$2(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_array$3 events emitted by this contract.
  Stream<log_named_array$3> log_named_array$3Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_array');
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
      return log_named_array$3(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_bytes events emitted by this contract.
  Stream<log_named_bytes> log_named_bytesEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_bytes');
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
      return log_named_bytes(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_bytes32 events emitted by this contract.
  Stream<log_named_bytes32> log_named_bytes32Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_bytes32');
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
      return log_named_bytes32(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_decimal_int events emitted by this contract.
  Stream<log_named_decimal_int> log_named_decimal_intEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_decimal_int');
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
      return log_named_decimal_int(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_decimal_uint events emitted by this contract.
  Stream<log_named_decimal_uint> log_named_decimal_uintEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_decimal_uint');
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
      return log_named_decimal_uint(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_int events emitted by this contract.
  Stream<log_named_int> log_named_intEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_int');
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
      return log_named_int(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_string events emitted by this contract.
  Stream<log_named_string> log_named_stringEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_string');
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
      return log_named_string(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_uint events emitted by this contract.
  Stream<log_named_uint> log_named_uintEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_uint');
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
      return log_named_uint(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_string events emitted by this contract.
  Stream<log_string> log_stringEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_string');
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
      return log_string(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_uint events emitted by this contract.
  Stream<log_uint> log_uintEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_uint');
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
      return log_uint(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all logs events emitted by this contract.
  Stream<logs> logsEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('logs');
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
      return logs(
        decoded,
        result,
      );
    });
  }
}

class log {
  log(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as String);

  final String var1;

  final _i1.FilterEvent event;
}

class log_address {
  log_address(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i2.EthereumAddress);

  final _i2.EthereumAddress var1;

  final _i1.FilterEvent event;
}

class log_array {
  log_array(
    List<dynamic> response,
    this.event,
  ) : val = (response[0] as List<dynamic>).cast<BigInt>();

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_array$2 {
  log_array$2(
    List<dynamic> response,
    this.event,
  ) : val = (response[0] as List<dynamic>).cast<BigInt>();

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_array$3 {
  log_array$3(
    List<dynamic> response,
    this.event,
  ) : val = (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();

  final List<_i2.EthereumAddress> val;

  final _i1.FilterEvent event;
}

class log_bytes {
  log_bytes(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i3.Uint8List);

  final _i3.Uint8List var1;

  final _i1.FilterEvent event;
}

class log_bytes32 {
  log_bytes32(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i3.Uint8List);

  final _i3.Uint8List var1;

  final _i1.FilterEvent event;
}

class log_int {
  log_int(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as BigInt);

  final BigInt var1;

  final _i1.FilterEvent event;
}

class log_named_address {
  log_named_address(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as _i2.EthereumAddress);

  final String key;

  final _i2.EthereumAddress val;

  final _i1.FilterEvent event;
}

class log_named_array {
  log_named_array(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as List<dynamic>).cast<BigInt>();

  final String key;

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_named_array$2 {
  log_named_array$2(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as List<dynamic>).cast<BigInt>();

  final String key;

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_named_array$3 {
  log_named_array$3(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as List<dynamic>).cast<_i2.EthereumAddress>();

  final String key;

  final List<_i2.EthereumAddress> val;

  final _i1.FilterEvent event;
}

class log_named_bytes {
  log_named_bytes(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as _i3.Uint8List);

  final String key;

  final _i3.Uint8List val;

  final _i1.FilterEvent event;
}

class log_named_bytes32 {
  log_named_bytes32(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as _i3.Uint8List);

  final String key;

  final _i3.Uint8List val;

  final _i1.FilterEvent event;
}

class log_named_decimal_int {
  log_named_decimal_int(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt),
        decimals = (response[2] as BigInt);

  final String key;

  final BigInt val;

  final BigInt decimals;

  final _i1.FilterEvent event;
}

class log_named_decimal_uint {
  log_named_decimal_uint(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt),
        decimals = (response[2] as BigInt);

  final String key;

  final BigInt val;

  final BigInt decimals;

  final _i1.FilterEvent event;
}

class log_named_int {
  log_named_int(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt);

  final String key;

  final BigInt val;

  final _i1.FilterEvent event;
}

class log_named_string {
  log_named_string(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as String);

  final String key;

  final String val;

  final _i1.FilterEvent event;
}

class log_named_uint {
  log_named_uint(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt);

  final String key;

  final BigInt val;

  final _i1.FilterEvent event;
}

class log_string {
  log_string(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as String);

  final String var1;

  final _i1.FilterEvent event;
}

class log_uint {
  log_uint(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as BigInt);

  final BigInt var1;

  final _i1.FilterEvent event;
}

class logs {
  logs(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i3.Uint8List);

  final _i3.Uint8List var1;

  final _i1.FilterEvent event;
}
