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
  '[{"type":"constructor","inputs":[{"name":"domainSeparator","type":"bytes32","internalType":"bytes32"}],"stateMutability":"nonpayable"},{"type":"function","name":"DOMAIN_SEPARATOR","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"getTypedDataHash","inputs":[{"name":"message","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"hashErc20SwapClaim","inputs":[{"name":"typehash","type":"bytes32","internalType":"bytes32"},{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"destination","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"hashErc20SwapCommit","inputs":[{"name":"typehash","type":"bytes32","internalType":"bytes32"},{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"hashErc20SwapRefund","inputs":[{"name":"typehash","type":"bytes32","internalType":"bytes32"},{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"hashEtherSwapClaim","inputs":[{"name":"typehash","type":"bytes32","internalType":"bytes32"},{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"destination","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"hashEtherSwapCommit","inputs":[{"name":"typehash","type":"bytes32","internalType":"bytes32"},{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"hashEtherSwapRefund","inputs":[{"name":"typehash","type":"bytes32","internalType":"bytes32"},{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"}]',
  'SigUtils',
);

class SigUtils extends _i1.GeneratedContract {
  SigUtils({
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
  Future<_i3.Uint8List> DOMAIN_SEPARATOR({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '3644e515'));
    final params = [];
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
  Future<_i3.Uint8List> getTypedDataHash(
    ({_i3.Uint8List message}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'a981b0c5'));
    final params = [args.message];
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
  Future<_i3.Uint8List> hashErc20SwapClaim(
    ({
      _i3.Uint8List typehash,
      _i3.Uint8List preimage,
      BigInt amount,
      _i2.EthereumAddress tokenAddress,
      _i2.EthereumAddress refundAddress,
      BigInt timelock,
      _i2.EthereumAddress destination
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'ae1f2990'));
    final params = [
      args.typehash,
      args.preimage,
      args.amount,
      args.tokenAddress,
      args.refundAddress,
      args.timelock,
      args.destination,
    ];
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
  Future<_i3.Uint8List> hashErc20SwapCommit(
    ({
      _i3.Uint8List typehash,
      _i3.Uint8List preimageHash,
      BigInt amount,
      _i2.EthereumAddress tokenAddress,
      _i2.EthereumAddress claimAddress,
      _i2.EthereumAddress refundAddress,
      BigInt timelock
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '54297c12'));
    final params = [
      args.typehash,
      args.preimageHash,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.refundAddress,
      args.timelock,
    ];
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
  Future<_i3.Uint8List> hashErc20SwapRefund(
    ({
      _i3.Uint8List typehash,
      _i3.Uint8List preimageHash,
      BigInt amount,
      _i2.EthereumAddress tokenAddress,
      _i2.EthereumAddress claimAddress,
      BigInt timelock
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'dc088b7e'));
    final params = [
      args.typehash,
      args.preimageHash,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.timelock,
    ];
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
  Future<_i3.Uint8List> hashEtherSwapClaim(
    ({
      _i3.Uint8List typehash,
      _i3.Uint8List preimage,
      BigInt amount,
      _i2.EthereumAddress refundAddress,
      BigInt timelock,
      _i2.EthereumAddress destination
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'aafd5f91'));
    final params = [
      args.typehash,
      args.preimage,
      args.amount,
      args.refundAddress,
      args.timelock,
      args.destination,
    ];
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
  Future<_i3.Uint8List> hashEtherSwapCommit(
    ({
      _i3.Uint8List typehash,
      _i3.Uint8List preimageHash,
      BigInt amount,
      _i2.EthereumAddress claimAddress,
      _i2.EthereumAddress refundAddress,
      BigInt timelock
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'c8354448'));
    final params = [
      args.typehash,
      args.preimageHash,
      args.amount,
      args.claimAddress,
      args.refundAddress,
      args.timelock,
    ];
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
  Future<_i3.Uint8List> hashEtherSwapRefund(
    ({
      _i3.Uint8List typehash,
      _i3.Uint8List preimageHash,
      BigInt amount,
      _i2.EthereumAddress claimAddress,
      BigInt timelock
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'a526b998'));
    final params = [
      args.typehash,
      args.preimageHash,
      args.amount,
      args.claimAddress,
      args.timelock,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }
}
