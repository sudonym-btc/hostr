// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'package:wallet/wallet.dart' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"error","name":"ERC1155InsufficientBalance","inputs":[{"name":"sender","type":"address","internalType":"address"},{"name":"balance","type":"uint256","internalType":"uint256"},{"name":"needed","type":"uint256","internalType":"uint256"},{"name":"tokenId","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"ERC1155InvalidApprover","inputs":[{"name":"approver","type":"address","internalType":"address"}]},{"type":"error","name":"ERC1155InvalidArrayLength","inputs":[{"name":"idsLength","type":"uint256","internalType":"uint256"},{"name":"valuesLength","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"ERC1155InvalidOperator","inputs":[{"name":"operator","type":"address","internalType":"address"}]},{"type":"error","name":"ERC1155InvalidReceiver","inputs":[{"name":"receiver","type":"address","internalType":"address"}]},{"type":"error","name":"ERC1155InvalidSender","inputs":[{"name":"sender","type":"address","internalType":"address"}]},{"type":"error","name":"ERC1155MissingApprovalForAll","inputs":[{"name":"operator","type":"address","internalType":"address"},{"name":"owner","type":"address","internalType":"address"}]}]',
  'IERC1155Errors',
);

class IERC1155Errors extends _i1.GeneratedContract {
  IERC1155Errors({
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
}
