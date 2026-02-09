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
  '[{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"directExecute","outputs":[{"internalType":"bytes","name":"ret","type":"bytes"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"suffixData","type":"bytes32"},{"components":[{"internalType":"address","name":"relayHub","type":"address"},{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"address","name":"tokenContract","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"gas","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"tokenAmount","type":"uint256"},{"internalType":"uint256","name":"tokenGas","type":"uint256"},{"internalType":"uint256","name":"validUntilTime","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"internalType":"struct IForwarder.ForwardRequest","name":"forwardRequest","type":"tuple"},{"internalType":"address","name":"feesReceiver","type":"address"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"execute","outputs":[{"internalType":"bytes","name":"ret","type":"bytes"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes","name":"initParams","type":"bytes"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'IWalletCustomLogic',
);

class IWalletCustomLogic extends _i1.GeneratedContract {
  IWalletCustomLogic({
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

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> directExecute(
    ({_i2.EthereumAddress to, _i3.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '244f53b5'));
    final params = [
      args.to,
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
  Future<String> execute(
    ({
      _i3.Uint8List suffixData,
      dynamic forwardRequest,
      _i2.EthereumAddress feesReceiver,
      _i3.Uint8List signature
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '75a6dad7'));
    final params = [
      args.suffixData,
      args.forwardRequest,
      args.feesReceiver,
      args.signature,
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
  Future<String> initialize(
    ({_i3.Uint8List initParams}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '439fab91'));
    final params = [args.initParams];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }
}
