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
  '[{"type":"function","name":"DOMAIN_SEPARATOR","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"invalidateUnorderedNonces","inputs":[{"name":"wordPos","type":"uint256","internalType":"uint256"},{"name":"mask","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"nonceBitmap","inputs":[{"name":"","type":"address","internalType":"address"},{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"permitTransferFrom","inputs":[{"name":"permit","type":"tuple","internalType":"struct ISignatureTransfer.PermitTransferFrom","components":[{"name":"permitted","type":"tuple","internalType":"struct ISignatureTransfer.TokenPermissions","components":[{"name":"token","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}]},{"name":"nonce","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"transferDetails","type":"tuple","internalType":"struct ISignatureTransfer.SignatureTransferDetails","components":[{"name":"to","type":"address","internalType":"address"},{"name":"requestedAmount","type":"uint256","internalType":"uint256"}]},{"name":"owner","type":"address","internalType":"address"},{"name":"signature","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"permitTransferFrom","inputs":[{"name":"permit","type":"tuple","internalType":"struct ISignatureTransfer.PermitBatchTransferFrom","components":[{"name":"permitted","type":"tuple[]","internalType":"struct ISignatureTransfer.TokenPermissions[]","components":[{"name":"token","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}]},{"name":"nonce","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"transferDetails","type":"tuple[]","internalType":"struct ISignatureTransfer.SignatureTransferDetails[]","components":[{"name":"to","type":"address","internalType":"address"},{"name":"requestedAmount","type":"uint256","internalType":"uint256"}]},{"name":"owner","type":"address","internalType":"address"},{"name":"signature","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"permitWitnessTransferFrom","inputs":[{"name":"permit","type":"tuple","internalType":"struct ISignatureTransfer.PermitTransferFrom","components":[{"name":"permitted","type":"tuple","internalType":"struct ISignatureTransfer.TokenPermissions","components":[{"name":"token","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}]},{"name":"nonce","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"transferDetails","type":"tuple","internalType":"struct ISignatureTransfer.SignatureTransferDetails","components":[{"name":"to","type":"address","internalType":"address"},{"name":"requestedAmount","type":"uint256","internalType":"uint256"}]},{"name":"owner","type":"address","internalType":"address"},{"name":"witness","type":"bytes32","internalType":"bytes32"},{"name":"witnessTypeString","type":"string","internalType":"string"},{"name":"signature","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"permitWitnessTransferFrom","inputs":[{"name":"permit","type":"tuple","internalType":"struct ISignatureTransfer.PermitBatchTransferFrom","components":[{"name":"permitted","type":"tuple[]","internalType":"struct ISignatureTransfer.TokenPermissions[]","components":[{"name":"token","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}]},{"name":"nonce","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"transferDetails","type":"tuple[]","internalType":"struct ISignatureTransfer.SignatureTransferDetails[]","components":[{"name":"to","type":"address","internalType":"address"},{"name":"requestedAmount","type":"uint256","internalType":"uint256"}]},{"name":"owner","type":"address","internalType":"address"},{"name":"witness","type":"bytes32","internalType":"bytes32"},{"name":"witnessTypeString","type":"string","internalType":"string"},{"name":"signature","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"UnorderedNonceInvalidation","inputs":[{"name":"owner","type":"address","indexed":true,"internalType":"address"},{"name":"word","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"mask","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"error","name":"InvalidAmount","inputs":[{"name":"maxAmount","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"LengthMismatch","inputs":[]}]',
  'ISignatureTransfer',
);

class ISignatureTransfer extends _i1.GeneratedContract {
  ISignatureTransfer({
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
    final function = self.abi.functions[0];
    assert(checkSignature(function, '3644e515'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> invalidateUnorderedNonces(
    ({BigInt wordPos, BigInt mask}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '3ff9dcb1'));
    final params = [
      args.wordPos,
      args.mask,
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
  Future<BigInt> nonceBitmap(
    ({_i2.EthereumAddress $param2, BigInt $param3}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '4fe02b44'));
    final params = [
      args.$param2,
      args.$param3,
    ];
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
  Future<String> permitTransferFrom(
    ({
      dynamic permit,
      dynamic transferDetails,
      _i2.EthereumAddress owner,
      _i3.Uint8List signature
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '30f28b7a'));
    final params = [
      args.permit,
      args.transferDetails,
      args.owner,
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
  Future<String> permitTransferFrom$2(
    ({
      dynamic permit,
      List<dynamic> transferDetails,
      _i2.EthereumAddress owner,
      _i3.Uint8List signature
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'edd9444b'));
    final params = [
      args.permit,
      args.transferDetails,
      args.owner,
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
  Future<String> permitWitnessTransferFrom(
    ({
      dynamic permit,
      dynamic transferDetails,
      _i2.EthereumAddress owner,
      _i3.Uint8List witness,
      String witnessTypeString,
      _i3.Uint8List signature
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '137c29fe'));
    final params = [
      args.permit,
      args.transferDetails,
      args.owner,
      args.witness,
      args.witnessTypeString,
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
  Future<String> permitWitnessTransferFrom$2(
    ({
      dynamic permit,
      List<dynamic> transferDetails,
      _i2.EthereumAddress owner,
      _i3.Uint8List witness,
      String witnessTypeString,
      _i3.Uint8List signature
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'fe8ec1a7'));
    final params = [
      args.permit,
      args.transferDetails,
      args.owner,
      args.witness,
      args.witnessTypeString,
      args.signature,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all UnorderedNonceInvalidation events emitted by this contract.
  Stream<UnorderedNonceInvalidation> unorderedNonceInvalidationEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('UnorderedNonceInvalidation');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return UnorderedNonceInvalidation(
        decoded,
        result,
      );
    });
  }
}

class UnorderedNonceInvalidation {
  UnorderedNonceInvalidation(
    List<dynamic> response,
    this.event,
  )   : owner = (response[0] as _i2.EthereumAddress),
        word = (response[1] as BigInt),
        mask = (response[2] as BigInt);

  final _i2.EthereumAddress owner;

  final BigInt word;

  final BigInt mask;

  final _i1.FilterEvent event;
}
