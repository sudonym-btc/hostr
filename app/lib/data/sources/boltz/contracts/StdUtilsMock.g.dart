// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"exposed_bound","inputs":[{"name":"num","type":"uint256","internalType":"uint256"},{"name":"min","type":"uint256","internalType":"uint256"},{"name":"max","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"exposed_bound","inputs":[{"name":"num","type":"int256","internalType":"int256"},{"name":"min","type":"int256","internalType":"int256"},{"name":"max","type":"int256","internalType":"int256"}],"outputs":[{"name":"","type":"int256","internalType":"int256"}],"stateMutability":"pure"},{"type":"function","name":"exposed_bytesToUint","inputs":[{"name":"b","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"exposed_getTokenBalances","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"addresses","type":"address[]","internalType":"address[]"}],"outputs":[{"name":"balances","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"nonpayable"}]',
  'StdUtilsMock',
);

class StdUtilsMock extends _i1.GeneratedContract {
  StdUtilsMock({
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
  Future<BigInt> exposed_bound(
    ({BigInt num, BigInt min, BigInt max}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'a788f236'));
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
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> exposed_bound$2(
    ({BigInt num, BigInt min, BigInt max}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'c20e95eb'));
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
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> exposed_bytesToUint(
    ({_i2.Uint8List b}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'd680beeb'));
    final params = [args.b];
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
  Future<String> exposed_getTokenBalances(
    ({_i1.EthereumAddress token, List<_i1.EthereumAddress> addresses}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'c49b5b56'));
    final params = [
      args.token,
      args.addresses,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }
}
