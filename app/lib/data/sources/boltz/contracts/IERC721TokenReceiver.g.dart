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
  '[{"type":"function","name":"onERC721Received","inputs":[{"name":"_operator","type":"address","internalType":"address"},{"name":"_from","type":"address","internalType":"address"},{"name":"_tokenId","type":"uint256","internalType":"uint256"},{"name":"_data","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"","type":"bytes4","internalType":"bytes4"}],"stateMutability":"nonpayable"}]',
  'IERC721TokenReceiver',
);

class IERC721TokenReceiver extends _i1.GeneratedContract {
  IERC721TokenReceiver({
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
  Future<String> onERC721Received(
    ({
      _i2.EthereumAddress operator,
      _i2.EthereumAddress from,
      BigInt tokenId,
      _i3.Uint8List data
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '150b7a02'));
    final params = [
      args.operator,
      args.from,
      args.tokenId,
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
