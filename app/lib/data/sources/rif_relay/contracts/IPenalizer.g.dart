// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"inputs":[{"internalType":"bytes","name":"unsignedTx1","type":"bytes"},{"internalType":"bytes","name":"signature1","type":"bytes"},{"internalType":"bytes","name":"unsignedTx2","type":"bytes"},{"internalType":"bytes","name":"signature2","type":"bytes"},{"internalType":"contract IRelayHub","name":"hub","type":"address"}],"name":"penalizeRepeatedNonce","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"versionPenalizer","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]',
  'IPenalizer',
);

class IPenalizer extends _i1.GeneratedContract {
  IPenalizer({
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
  Future<String> penalizeRepeatedNonce(
    ({
      _i2.Uint8List unsignedTx1,
      _i2.Uint8List signature1,
      _i2.Uint8List unsignedTx2,
      _i2.Uint8List signature2,
      _i1.EthereumAddress hub
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'f913fe3e'));
    final params = [
      args.unsignedTx1,
      args.signature1,
      args.unsignedTx2,
      args.signature2,
      args.hub,
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
  Future<String> versionPenalizer({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'a0313657'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }
}
