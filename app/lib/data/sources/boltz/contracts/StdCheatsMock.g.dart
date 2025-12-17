// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'package:wallet/wallet.dart' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"exposed_assumeNotBlacklisted","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"addr","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"view"},{"type":"function","name":"exposed_assumeNotPayable","inputs":[{"name":"addr","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"exposed_assumePayable","inputs":[{"name":"addr","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"}]',
  'StdCheatsMock',
);

class StdCheatsMock extends _i1.GeneratedContract {
  StdCheatsMock({
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
  Future<void> exposed_assumeNotBlacklisted(
    ({_i2.EthereumAddress token, _i2.EthereumAddress addr}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '95b9a383'));
    final params = [
      args.token,
      args.addr,
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
  Future<String> exposed_assumeNotPayable(
    ({_i2.EthereumAddress addr}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '17cc73a0'));
    final params = [args.addr];
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
  Future<String> exposed_assumePayable(
    ({_i2.EthereumAddress addr}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'de4a5dcd'));
    final params = [args.addr];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }
}
