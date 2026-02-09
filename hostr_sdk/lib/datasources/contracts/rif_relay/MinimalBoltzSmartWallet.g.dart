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
  '[{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"feesReceiver","type":"address"},{"internalType":"uint256","name":"feesAmount","type":"uint256"},{"internalType":"uint256","name":"feesGas","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]',
  'MinimalBoltzSmartWallet',
);

class MinimalBoltzSmartWallet extends _i1.GeneratedContract {
  MinimalBoltzSmartWallet({
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
  Future<String> initialize(
    ({
      _i2.EthereumAddress owner,
      _i2.EthereumAddress feesReceiver,
      BigInt feesAmount,
      BigInt feesGas,
      _i2.EthereumAddress to,
      _i3.Uint8List data
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '3d326736'));
    final params = [
      args.owner,
      args.feesReceiver,
      args.feesAmount,
      args.feesGas,
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
}
