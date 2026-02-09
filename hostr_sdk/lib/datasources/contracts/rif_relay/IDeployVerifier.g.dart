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
  '[{"inputs":[{"components":[{"components":[{"internalType":"address","name":"relayHub","type":"address"},{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"address","name":"tokenContract","type":"address"},{"internalType":"address","name":"recoverer","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"tokenAmount","type":"uint256"},{"internalType":"uint256","name":"tokenGas","type":"uint256"},{"internalType":"uint256","name":"validUntilTime","type":"uint256"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"internalType":"struct IForwarder.DeployRequest","name":"request","type":"tuple"},{"components":[{"internalType":"uint256","name":"gasPrice","type":"uint256"},{"internalType":"address","name":"feesReceiver","type":"address"},{"internalType":"address","name":"callForwarder","type":"address"},{"internalType":"address","name":"callVerifier","type":"address"}],"internalType":"struct EnvelopingTypes.RelayData","name":"relayData","type":"tuple"}],"internalType":"struct EnvelopingTypes.DeployRequest","name":"relayRequest","type":"tuple"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"verifyRelayedCall","outputs":[{"internalType":"bytes","name":"context","type":"bytes"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"versionVerifier","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]',
  'IDeployVerifier',
);

class IDeployVerifier extends _i1.GeneratedContract {
  IDeployVerifier({
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
  Future<String> verifyRelayedCall(
    ({dynamic relayRequest, _i3.Uint8List signature}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '3739d456'));
    final params = [
      args.relayRequest,
      args.signature,
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
  Future<String> versionVerifier({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '1dac0746'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }
}
