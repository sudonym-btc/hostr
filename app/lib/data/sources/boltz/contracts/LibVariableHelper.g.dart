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
  '[{"type":"function","name":"assertEq","inputs":[{"name":"t1","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"t2","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertExists","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"toAddress","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"toAddressArray","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"pure"},{"type":"function","name":"toBool","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"pure"},{"type":"function","name":"toBoolArray","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"bool[]","internalType":"bool[]"}],"stateMutability":"pure"},{"type":"function","name":"toBytes","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"toBytes32","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"toBytes32Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"bytes32[]","internalType":"bytes32[]"}],"stateMutability":"pure"},{"type":"function","name":"toBytesArray","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"bytes[]","internalType":"bytes[]"}],"stateMutability":"pure"},{"type":"function","name":"toInt128","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int128","internalType":"int128"}],"stateMutability":"pure"},{"type":"function","name":"toInt128Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int128[]","internalType":"int128[]"}],"stateMutability":"pure"},{"type":"function","name":"toInt16","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int16","internalType":"int16"}],"stateMutability":"pure"},{"type":"function","name":"toInt16Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int16[]","internalType":"int16[]"}],"stateMutability":"pure"},{"type":"function","name":"toInt256","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int256","internalType":"int256"}],"stateMutability":"pure"},{"type":"function","name":"toInt256Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int256[]","internalType":"int256[]"}],"stateMutability":"pure"},{"type":"function","name":"toInt32","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int32","internalType":"int32"}],"stateMutability":"pure"},{"type":"function","name":"toInt32Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int32[]","internalType":"int32[]"}],"stateMutability":"pure"},{"type":"function","name":"toInt64","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int64","internalType":"int64"}],"stateMutability":"pure"},{"type":"function","name":"toInt64Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int64[]","internalType":"int64[]"}],"stateMutability":"pure"},{"type":"function","name":"toInt8","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int8","internalType":"int8"}],"stateMutability":"pure"},{"type":"function","name":"toInt8Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"int8[]","internalType":"int8[]"}],"stateMutability":"pure"},{"type":"function","name":"toString","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toStringArray","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"string[]","internalType":"string[]"}],"stateMutability":"pure"},{"type":"function","name":"toUint128","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint128","internalType":"uint128"}],"stateMutability":"pure"},{"type":"function","name":"toUint128Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint128[]","internalType":"uint128[]"}],"stateMutability":"pure"},{"type":"function","name":"toUint16","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint16","internalType":"uint16"}],"stateMutability":"pure"},{"type":"function","name":"toUint16Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint16[]","internalType":"uint16[]"}],"stateMutability":"pure"},{"type":"function","name":"toUint256","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"toUint256Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"pure"},{"type":"function","name":"toUint32","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint32","internalType":"uint32"}],"stateMutability":"pure"},{"type":"function","name":"toUint32Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint32[]","internalType":"uint32[]"}],"stateMutability":"pure"},{"type":"function","name":"toUint64","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint64","internalType":"uint64"}],"stateMutability":"pure"},{"type":"function","name":"toUint64Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint64[]","internalType":"uint64[]"}],"stateMutability":"pure"},{"type":"function","name":"toUint8","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"pure"},{"type":"function","name":"toUint8Array","inputs":[{"name":"v","type":"tuple","internalType":"struct Variable","components":[{"name":"ty","type":"tuple","internalType":"struct Type","components":[{"name":"kind","type":"uint8","internalType":"enum TypeKind"},{"name":"isArray","type":"bool","internalType":"bool"}]},{"name":"data","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"","type":"uint8[]","internalType":"uint8[]"}],"stateMutability":"pure"},{"type":"error","name":"NotInitialized","inputs":[]},{"type":"error","name":"TypeMismatch","inputs":[{"name":"expected","type":"string","internalType":"string"},{"name":"actual","type":"string","internalType":"string"}]},{"type":"error","name":"UnsafeCast","inputs":[{"name":"message","type":"string","internalType":"string"}]}]',
  'LibVariableHelper',
);

class LibVariableHelper extends _i1.GeneratedContract {
  LibVariableHelper({
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
  Future<void> assertEq(
    ({dynamic t1, dynamic t2}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '0e9318b6'));
    final params = [
      args.t1,
      args.t2,
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
  Future<void> assertExists(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'ada9f824'));
    final params = [args.v];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> toAddress(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '33571846'));
    final params = [args.v];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.EthereumAddress>> toAddressArray(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'e80f9114'));
    final params = [args.v];
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
  Future<bool> toBool(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '1b8c25c7'));
    final params = [args.v];
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
  Future<List<bool>> toBoolArray(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '28924b56'));
    final params = [args.v];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<bool>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i3.Uint8List> toBytes(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'e31d23e5'));
    final params = [args.v];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i3.Uint8List> toBytes32(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'a29eeb79'));
    final params = [args.v];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i3.Uint8List>> toBytes32Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'a5e1f792'));
    final params = [args.v];
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
  Future<List<_i3.Uint8List>> toBytesArray(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, 'a9cc756b'));
    final params = [args.v];
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
  Future<BigInt> toInt128(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, 'f7b41074'));
    final params = [args.v];
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
  Future<List<BigInt>> toInt128Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '73dea9ff'));
    final params = [args.v];
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
  Future<BigInt> toInt16(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '2f509313'));
    final params = [args.v];
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
  Future<List<BigInt>> toInt16Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, 'a59ecfd6'));
    final params = [args.v];
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
  Future<BigInt> toInt256(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '5d0dbfd4'));
    final params = [args.v];
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
  Future<List<BigInt>> toInt256Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'ebd42628'));
    final params = [args.v];
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
  Future<BigInt> toInt32(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '56cd3b68'));
    final params = [args.v];
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
  Future<List<BigInt>> toInt32Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '938b79b1'));
    final params = [args.v];
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
  Future<BigInt> toInt64(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'fb50451a'));
    final params = [args.v];
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
  Future<List<BigInt>> toInt64Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'cd8ceaad'));
    final params = [args.v];
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
  Future<BigInt> toInt8(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '3fb5872b'));
    final params = [args.v];
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
  Future<List<BigInt>> toInt8Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '04f33e37'));
    final params = [args.v];
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
  Future<String> toString(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '361b7eb6'));
    final params = [args.v];
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
  Future<List<String>> toStringArray(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '198c44fc'));
    final params = [args.v];
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
  Future<BigInt> toUint128(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '713c108f'));
    final params = [args.v];
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
  Future<List<BigInt>> toUint128Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, '26927920'));
    final params = [args.v];
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
  Future<BigInt> toUint16(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, '296a2f41'));
    final params = [args.v];
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
  Future<List<BigInt>> toUint16Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, 'e374b6ac'));
    final params = [args.v];
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
  Future<BigInt> toUint256(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '718651b8'));
    final params = [args.v];
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
  Future<List<BigInt>> toUint256Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '01a9fdf3'));
    final params = [args.v];
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
  Future<BigInt> toUint32(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '8ec7637b'));
    final params = [args.v];
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
  Future<List<BigInt>> toUint32Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, '825b7bfd'));
    final params = [args.v];
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
  Future<BigInt> toUint64(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, '476e1e48'));
    final params = [args.v];
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
  Future<List<BigInt>> toUint64Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '18b6d849'));
    final params = [args.v];
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
  Future<BigInt> toUint8(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, '79948884'));
    final params = [args.v];
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
  Future<List<BigInt>> toUint8Array(
    ({dynamic v}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[35];
    assert(checkSignature(function, 'f3283fb7'));
    final params = [args.v];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }
}
