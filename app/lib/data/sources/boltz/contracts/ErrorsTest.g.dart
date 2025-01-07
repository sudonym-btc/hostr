// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"arithmeticError","inputs":[{"name":"a","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertionError","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"divError","inputs":[{"name":"a","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"encodeStgError","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"enumConversion","inputs":[{"name":"a","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"indexOOBError","inputs":[{"name":"a","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"intern","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"mem","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"modError","inputs":[{"name":"a","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"pop","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"someArr","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"}]',
  'ErrorsTest',
);

class ErrorsTest extends _i1.GeneratedContract {
  ErrorsTest({
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
  Future<void> arithmeticError(
    ({BigInt a}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'e0393555'));
    final params = [args.a];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertionError({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '10332977'));
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
  Future<void> divError(
    ({BigInt a}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'd810d9ed'));
    final params = [args.a];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> encodeStgError({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '95736c00'));
    final params = [];
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
  Future<void> enumConversion(
    ({BigInt a}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'bb0bfc25'));
    final params = [args.a];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> indexOOBError(
    ({BigInt a}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'b072347d'));
    final params = [args.a];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> intern({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '0f1031ec'));
    final params = [];
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
  Future<void> mem({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '85883d8c'));
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
  Future<void> modError(
    ({BigInt a}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'd4523099'));
    final params = [args.a];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> pop({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, 'a4ece52c'));
    final params = [];
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
  Future<BigInt> someArr(
    ({BigInt $param5}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '03ed6f22'));
    final params = [args.$param5];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }
}
