// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"IS_TEST","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"excludeArtifacts","inputs":[],"outputs":[{"name":"excludedArtifacts_","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"excludeContracts","inputs":[],"outputs":[{"name":"excludedContracts_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"excludeSelectors","inputs":[],"outputs":[{"name":"excludedSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzSelector[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"excludeSenders","inputs":[],"outputs":[{"name":"excludedSenders_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"failed","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"invariantMetadata","inputs":[],"outputs":[],"stateMutability":"view"},{"type":"function","name":"setUp","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"targetArtifactSelectors","inputs":[],"outputs":[{"name":"targetedArtifactSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzArtifactSelector[]","components":[{"name":"artifact","type":"string","internalType":"string"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetArtifacts","inputs":[],"outputs":[{"name":"targetedArtifacts_","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"targetContracts","inputs":[],"outputs":[{"name":"targetedContracts_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"targetInterfaces","inputs":[],"outputs":[{"name":"targetedInterfaces_","type":"tuple[]","internalType":"struct StdInvariant.FuzzInterface[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"artifacts","type":"string[]","internalType":"string[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetSelectors","inputs":[],"outputs":[{"name":"targetedSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzSelector[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetSenders","inputs":[],"outputs":[{"name":"targetedSenders_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"testApprove","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testApprove","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testApproveAll","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testApproveAll","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"approved","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testApproveBurn","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testApproveBurn","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testBurn","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testBurn","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailApproveUnAuthorized","inputs":[{"name":"owner","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailApproveUnAuthorized","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailApproveUnMinted","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailApproveUnMinted","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailBalanceOfZeroAddress","inputs":[],"outputs":[],"stateMutability":"view"},{"type":"function","name":"testFailBurnUnMinted","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailBurnUnMinted","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailDoubleBurn","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailDoubleBurn","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailDoubleMint","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailDoubleMint","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailMintToZero","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailMintToZero","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailOwnerOfUnminted","inputs":[],"outputs":[],"stateMutability":"view"},{"type":"function","name":"testFailOwnerOfUnminted","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"view"},{"type":"function","name":"testFailSafeMintToERC721RecipientWithWrongReturnData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToERC721RecipientWithWrongReturnData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToERC721RecipientWithWrongReturnDataWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToERC721RecipientWithWrongReturnDataWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToNonERC721Recipient","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToNonERC721Recipient","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToNonERC721RecipientWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToNonERC721RecipientWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToRevertingERC721Recipient","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToRevertingERC721Recipient","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToRevertingERC721RecipientWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeMintToRevertingERC721RecipientWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToERC721RecipientWithWrongReturnData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToERC721RecipientWithWrongReturnData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToNonERC721Recipient","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToNonERC721Recipient","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToNonERC721RecipientWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToNonERC721RecipientWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToRevertingERC721Recipient","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToRevertingERC721Recipient","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToRevertingERC721RecipientWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailSafeTransferFromToRevertingERC721RecipientWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromNotOwner","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromNotOwner","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromToZero","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromToZero","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromUnOwned","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromUnOwned","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromWrongFrom","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromWrongFrom","inputs":[{"name":"owner","type":"address","internalType":"address"},{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testMetadata","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"symbol","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testMint","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testMint","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeMintToEOA","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeMintToEOA","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeMintToERC721Recipient","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeMintToERC721Recipient","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeMintToERC721RecipientWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeMintToERC721RecipientWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeTransferFromToEOA","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeTransferFromToEOA","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeTransferFromToERC721Recipient","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeTransferFromToERC721Recipient","inputs":[{"name":"id","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeTransferFromToERC721RecipientWithData","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testSafeTransferFromToERC721RecipientWithData","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFrom","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFrom","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFromApproveAll","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFromApproveAll","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFromSelf","inputs":[{"name":"id","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFromSelf","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"log","inputs":[{"name":"","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_address","inputs":[{"name":"","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"uint256[]","indexed":false,"internalType":"uint256[]"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"int256[]","indexed":false,"internalType":"int256[]"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"log_bytes","inputs":[{"name":"","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false},{"type":"event","name":"log_bytes32","inputs":[{"name":"","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false},{"type":"event","name":"log_int","inputs":[{"name":"","type":"int256","indexed":false,"internalType":"int256"}],"anonymous":false},{"type":"event","name":"log_named_address","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256[]","indexed":false,"internalType":"uint256[]"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256[]","indexed":false,"internalType":"int256[]"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"log_named_bytes","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false},{"type":"event","name":"log_named_bytes32","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false},{"type":"event","name":"log_named_decimal_int","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256","indexed":false,"internalType":"int256"},{"name":"decimals","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_named_decimal_uint","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"decimals","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_named_int","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256","indexed":false,"internalType":"int256"}],"anonymous":false},{"type":"event","name":"log_named_string","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_named_uint","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_string","inputs":[{"name":"","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_uint","inputs":[{"name":"","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"logs","inputs":[{"name":"","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false}]',
  'MockERC721Test',
);

class MockERC721Test extends _i1.GeneratedContract {
  MockERC721Test({
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
  Future<bool> IS_TEST({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'fa7626d4'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> excludeArtifacts({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'b5508aa9'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<String>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i1.EthereumAddress>> excludeContracts(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'e20c9f71'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i1.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<dynamic>> excludeSelectors({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'b0464fdc'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i1.EthereumAddress>> excludeSenders(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '1ed7831c'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i1.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> failed({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'ba414fa6'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> invariantMetadata({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '727515fd'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setUp({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '0a9254e4'));
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
  Future<List<dynamic>> targetArtifactSelectors({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '66d9a9a0'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> targetArtifacts({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '85226c81'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<String>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i1.EthereumAddress>> targetContracts(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '3f7286f4'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i1.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<dynamic>> targetInterfaces({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '2ade3880'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<dynamic>> targetSelectors({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '916a17c6'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<dynamic>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i1.EthereumAddress>> targetSenders(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '3e5e3c23'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i1.EthereumAddress>();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> testApprove({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '1aeb10a6'));
    final params = [];
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
  Future<String> testApprove$2(
    ({_i1.EthereumAddress to, BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'fb44e83a'));
    final params = [
      args.to,
      args.id,
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
  Future<String> testApproveAll({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '2b56a182'));
    final params = [];
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
  Future<String> testApproveAll$2(
    ({_i1.EthereumAddress to, bool approved}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, 'f27e673e'));
    final params = [
      args.to,
      args.approved,
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
  Future<String> testApproveBurn(
    ({_i1.EthereumAddress to, BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'aa47d6f1'));
    final params = [
      args.to,
      args.id,
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
  Future<String> testApproveBurn$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'c954bdee'));
    final params = [];
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
  Future<String> testBurn(
    ({_i1.EthereumAddress to, BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, 'c368c36a'));
    final params = [
      args.to,
      args.id,
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
  Future<String> testBurn$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, 'e13aba48'));
    final params = [];
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
  Future<String> testFailApproveUnAuthorized(
    ({_i1.EthereumAddress owner, BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '148d33b3'));
    final params = [
      args.owner,
      args.id,
      args.to,
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
  Future<String> testFailApproveUnAuthorized$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '39ae635f'));
    final params = [];
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
  Future<String> testFailApproveUnMinted({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '9853f6c3'));
    final params = [];
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
  Future<String> testFailApproveUnMinted$2(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, 'a482897f'));
    final params = [
      args.id,
      args.to,
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
  Future<void> testFailBalanceOfZeroAddress({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, 'b7d0c890'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> testFailBurnUnMinted({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, '27f3f04c'));
    final params = [];
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
  Future<String> testFailBurnUnMinted$2(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '9e2b66df'));
    final params = [args.id];
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
  Future<String> testFailDoubleBurn({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '7d889065'));
    final params = [];
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
  Future<String> testFailDoubleBurn$2(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, 'cdaf6766'));
    final params = [
      args.id,
      args.to,
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
  Future<String> testFailDoubleMint({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, '29b50ffa'));
    final params = [];
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
  Future<String> testFailDoubleMint$2(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, 'dc5a2789'));
    final params = [
      args.id,
      args.to,
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
  Future<String> testFailMintToZero(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '4486127f'));
    final params = [args.id];
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
  Future<String> testFailMintToZero$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, 'f1087837'));
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
  Future<void> testFailOwnerOfUnminted({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[35];
    assert(checkSignature(function, '6135881e'));
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
  Future<void> testFailOwnerOfUnminted$2(
    ({BigInt id}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, '99c3de01'));
    final params = [args.id];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> testFailSafeMintToERC721RecipientWithWrongReturnData(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, '2a623120'));
    final params = [args.id];
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
  Future<String> testFailSafeMintToERC721RecipientWithWrongReturnData$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, '86d62156'));
    final params = [];
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
  Future<String> testFailSafeMintToERC721RecipientWithWrongReturnDataWithData({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, '0cc065c3'));
    final params = [];
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
  Future<String> testFailSafeMintToERC721RecipientWithWrongReturnDataWithData$2(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[40];
    assert(checkSignature(function, '44b7601d'));
    final params = [
      args.id,
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
  Future<String> testFailSafeMintToNonERC721Recipient(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[41];
    assert(checkSignature(function, '2ed3fc9f'));
    final params = [args.id];
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
  Future<String> testFailSafeMintToNonERC721Recipient$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[42];
    assert(checkSignature(function, '7944d88c'));
    final params = [];
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
  Future<String> testFailSafeMintToNonERC721RecipientWithData(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[43];
    assert(checkSignature(function, '453805a4'));
    final params = [
      args.id,
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
  Future<String> testFailSafeMintToNonERC721RecipientWithData$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[44];
    assert(checkSignature(function, '544702ab'));
    final params = [];
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
  Future<String> testFailSafeMintToRevertingERC721Recipient(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[45];
    assert(checkSignature(function, '00e1030c'));
    final params = [args.id];
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
  Future<String> testFailSafeMintToRevertingERC721Recipient$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[46];
    assert(checkSignature(function, '701f5a4e'));
    final params = [];
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
  Future<String> testFailSafeMintToRevertingERC721RecipientWithData({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[47];
    assert(checkSignature(function, 'e928c86a'));
    final params = [];
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
  Future<String> testFailSafeMintToRevertingERC721RecipientWithData$2(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[48];
    assert(checkSignature(function, 'f2fa5409'));
    final params = [
      args.id,
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
  Future<String> testFailSafeTransferFromToERC721RecipientWithWrongReturnData({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[49];
    assert(checkSignature(function, 'd18968cc'));
    final params = [];
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
  Future<String> testFailSafeTransferFromToERC721RecipientWithWrongReturnData$2(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[50];
    assert(checkSignature(function, 'e3c4d3aa'));
    final params = [args.id];
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
  Future<String>
      testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[51];
    assert(checkSignature(function, '288da42e'));
    final params = [];
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
  Future<String>
      testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData$2(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[52];
    assert(checkSignature(function, 'cfa5bda9'));
    final params = [
      args.id,
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
  Future<String> testFailSafeTransferFromToNonERC721Recipient({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[53];
    assert(checkSignature(function, '87dcc961'));
    final params = [];
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
  Future<String> testFailSafeTransferFromToNonERC721Recipient$2(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[54];
    assert(checkSignature(function, '8de39704'));
    final params = [args.id];
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
  Future<String> testFailSafeTransferFromToNonERC721RecipientWithData({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[55];
    assert(checkSignature(function, 'dd5e09f0'));
    final params = [];
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
  Future<String> testFailSafeTransferFromToNonERC721RecipientWithData$2(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[56];
    assert(checkSignature(function, 'feae4252'));
    final params = [
      args.id,
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
  Future<String> testFailSafeTransferFromToRevertingERC721Recipient(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[57];
    assert(checkSignature(function, '658b6eb8'));
    final params = [args.id];
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
  Future<String> testFailSafeTransferFromToRevertingERC721Recipient$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[58];
    assert(checkSignature(function, 'f8e4aa86'));
    final params = [];
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
  Future<String> testFailSafeTransferFromToRevertingERC721RecipientWithData({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[59];
    assert(checkSignature(function, '5085e2b8'));
    final params = [];
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
  Future<String> testFailSafeTransferFromToRevertingERC721RecipientWithData$2(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[60];
    assert(checkSignature(function, 'c4e2f202'));
    final params = [
      args.id,
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
  Future<String> testFailTransferFromNotOwner(
    ({_i1.EthereumAddress from, _i1.EthereumAddress to, BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[61];
    assert(checkSignature(function, '40d82510'));
    final params = [
      args.from,
      args.to,
      args.id,
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
  Future<String> testFailTransferFromNotOwner$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[62];
    assert(checkSignature(function, 'f30f95af'));
    final params = [];
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
  Future<String> testFailTransferFromToZero(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[63];
    assert(checkSignature(function, '89694511'));
    final params = [args.id];
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
  Future<String> testFailTransferFromToZero$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[64];
    assert(checkSignature(function, 'aa092fe0'));
    final params = [];
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
  Future<String> testFailTransferFromUnOwned(
    ({_i1.EthereumAddress from, _i1.EthereumAddress to, BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[65];
    assert(checkSignature(function, '279c4775'));
    final params = [
      args.from,
      args.to,
      args.id,
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
  Future<String> testFailTransferFromUnOwned$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[66];
    assert(checkSignature(function, 'db8b573d'));
    final params = [];
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
  Future<String> testFailTransferFromWrongFrom({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[67];
    assert(checkSignature(function, '6a72229b'));
    final params = [];
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
  Future<String> testFailTransferFromWrongFrom$2(
    ({
      _i1.EthereumAddress owner,
      _i1.EthereumAddress from,
      _i1.EthereumAddress to,
      BigInt id
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[68];
    assert(checkSignature(function, 'be4d293d'));
    final params = [
      args.owner,
      args.from,
      args.to,
      args.id,
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
  Future<String> testMetadata(
    ({String name, String symbol}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[69];
    assert(checkSignature(function, 'd382650b'));
    final params = [
      args.name,
      args.symbol,
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
  Future<String> testMint({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[70];
    assert(checkSignature(function, '9642ddaf'));
    final params = [];
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
  Future<String> testMint$2(
    ({_i1.EthereumAddress to, BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[71];
    assert(checkSignature(function, 'f28e093d'));
    final params = [
      args.to,
      args.id,
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
  Future<String> testSafeMintToEOA(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[72];
    assert(checkSignature(function, '486d2d7c'));
    final params = [
      args.id,
      args.to,
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
  Future<String> testSafeMintToEOA$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[73];
    assert(checkSignature(function, 'c0f28852'));
    final params = [];
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
  Future<String> testSafeMintToERC721Recipient({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[74];
    assert(checkSignature(function, 'b4e0d2f6'));
    final params = [];
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
  Future<String> testSafeMintToERC721Recipient$2(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[75];
    assert(checkSignature(function, 'c353beb4'));
    final params = [args.id];
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
  Future<String> testSafeMintToERC721RecipientWithData(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[76];
    assert(checkSignature(function, 'ded53441'));
    final params = [
      args.id,
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
  Future<String> testSafeMintToERC721RecipientWithData$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[77];
    assert(checkSignature(function, 'f802bdaf'));
    final params = [];
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
  Future<String> testSafeTransferFromToEOA(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[78];
    assert(checkSignature(function, '63375814'));
    final params = [
      args.id,
      args.to,
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
  Future<String> testSafeTransferFromToEOA$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[79];
    assert(checkSignature(function, 'c07674d7'));
    final params = [];
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
  Future<String> testSafeTransferFromToERC721Recipient({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[80];
    assert(checkSignature(function, '071b5109'));
    final params = [];
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
  Future<String> testSafeTransferFromToERC721Recipient$2(
    ({BigInt id}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[81];
    assert(checkSignature(function, '613858e7'));
    final params = [args.id];
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
  Future<String> testSafeTransferFromToERC721RecipientWithData(
    ({BigInt id, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[82];
    assert(checkSignature(function, '76b1c095'));
    final params = [
      args.id,
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
  Future<String> testSafeTransferFromToERC721RecipientWithData$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[83];
    assert(checkSignature(function, 'f93490c1'));
    final params = [];
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
  Future<String> testTransferFrom(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[84];
    assert(checkSignature(function, '1172ed5b'));
    final params = [
      args.id,
      args.to,
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
  Future<String> testTransferFrom$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[85];
    assert(checkSignature(function, '70557298'));
    final params = [];
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
  Future<String> testTransferFromApproveAll(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[86];
    assert(checkSignature(function, '82e3da6c'));
    final params = [
      args.id,
      args.to,
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
  Future<String> testTransferFromApproveAll$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[87];
    assert(checkSignature(function, 'd9dcc550'));
    final params = [];
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
  Future<String> testTransferFromSelf(
    ({BigInt id, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[88];
    assert(checkSignature(function, 'c3aba2b3'));
    final params = [
      args.id,
      args.to,
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
  Future<String> testTransferFromSelf$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[89];
    assert(checkSignature(function, 'fad356f8'));
    final params = [];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all log events emitted by this contract.
  Stream<log> logEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log');
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
      return log(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_address events emitted by this contract.
  Stream<log_address> log_addressEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_address');
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
      return log_address(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_array events emitted by this contract.
  Stream<log_array> log_arrayEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_array');
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
      return log_array(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_array$2 events emitted by this contract.
  Stream<log_array$2> log_array$2Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_array');
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
      return log_array$2(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_array$3 events emitted by this contract.
  Stream<log_array$3> log_array$3Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_array');
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
      return log_array$3(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_bytes events emitted by this contract.
  Stream<log_bytes> log_bytesEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_bytes');
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
      return log_bytes(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_bytes32 events emitted by this contract.
  Stream<log_bytes32> log_bytes32Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_bytes32');
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
      return log_bytes32(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_int events emitted by this contract.
  Stream<log_int> log_intEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_int');
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
      return log_int(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_address events emitted by this contract.
  Stream<log_named_address> log_named_addressEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_address');
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
      return log_named_address(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_array events emitted by this contract.
  Stream<log_named_array> log_named_arrayEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_array');
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
      return log_named_array(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_array$2 events emitted by this contract.
  Stream<log_named_array$2> log_named_array$2Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_array');
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
      return log_named_array$2(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_array$3 events emitted by this contract.
  Stream<log_named_array$3> log_named_array$3Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_array');
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
      return log_named_array$3(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_bytes events emitted by this contract.
  Stream<log_named_bytes> log_named_bytesEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_bytes');
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
      return log_named_bytes(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_bytes32 events emitted by this contract.
  Stream<log_named_bytes32> log_named_bytes32Events({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_bytes32');
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
      return log_named_bytes32(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_decimal_int events emitted by this contract.
  Stream<log_named_decimal_int> log_named_decimal_intEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_decimal_int');
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
      return log_named_decimal_int(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_decimal_uint events emitted by this contract.
  Stream<log_named_decimal_uint> log_named_decimal_uintEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_decimal_uint');
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
      return log_named_decimal_uint(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_int events emitted by this contract.
  Stream<log_named_int> log_named_intEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_int');
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
      return log_named_int(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_string events emitted by this contract.
  Stream<log_named_string> log_named_stringEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_string');
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
      return log_named_string(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_named_uint events emitted by this contract.
  Stream<log_named_uint> log_named_uintEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_named_uint');
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
      return log_named_uint(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_string events emitted by this contract.
  Stream<log_string> log_stringEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_string');
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
      return log_string(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all log_uint events emitted by this contract.
  Stream<log_uint> log_uintEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('log_uint');
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
      return log_uint(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all logs events emitted by this contract.
  Stream<logs> logsEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('logs');
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
      return logs(
        decoded,
        result,
      );
    });
  }
}

class log {
  log(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as String);

  final String var1;

  final _i1.FilterEvent event;
}

class log_address {
  log_address(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i1.EthereumAddress);

  final _i1.EthereumAddress var1;

  final _i1.FilterEvent event;
}

class log_array {
  log_array(
    List<dynamic> response,
    this.event,
  ) : val = (response[0] as List<dynamic>).cast<BigInt>();

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_array$2 {
  log_array$2(
    List<dynamic> response,
    this.event,
  ) : val = (response[0] as List<dynamic>).cast<BigInt>();

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_array$3 {
  log_array$3(
    List<dynamic> response,
    this.event,
  ) : val = (response[0] as List<dynamic>).cast<_i1.EthereumAddress>();

  final List<_i1.EthereumAddress> val;

  final _i1.FilterEvent event;
}

class log_bytes {
  log_bytes(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i2.Uint8List);

  final _i2.Uint8List var1;

  final _i1.FilterEvent event;
}

class log_bytes32 {
  log_bytes32(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i2.Uint8List);

  final _i2.Uint8List var1;

  final _i1.FilterEvent event;
}

class log_int {
  log_int(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as BigInt);

  final BigInt var1;

  final _i1.FilterEvent event;
}

class log_named_address {
  log_named_address(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as _i1.EthereumAddress);

  final String key;

  final _i1.EthereumAddress val;

  final _i1.FilterEvent event;
}

class log_named_array {
  log_named_array(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as List<dynamic>).cast<BigInt>();

  final String key;

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_named_array$2 {
  log_named_array$2(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as List<dynamic>).cast<BigInt>();

  final String key;

  final List<BigInt> val;

  final _i1.FilterEvent event;
}

class log_named_array$3 {
  log_named_array$3(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as List<dynamic>).cast<_i1.EthereumAddress>();

  final String key;

  final List<_i1.EthereumAddress> val;

  final _i1.FilterEvent event;
}

class log_named_bytes {
  log_named_bytes(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as _i2.Uint8List);

  final String key;

  final _i2.Uint8List val;

  final _i1.FilterEvent event;
}

class log_named_bytes32 {
  log_named_bytes32(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as _i2.Uint8List);

  final String key;

  final _i2.Uint8List val;

  final _i1.FilterEvent event;
}

class log_named_decimal_int {
  log_named_decimal_int(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt),
        decimals = (response[2] as BigInt);

  final String key;

  final BigInt val;

  final BigInt decimals;

  final _i1.FilterEvent event;
}

class log_named_decimal_uint {
  log_named_decimal_uint(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt),
        decimals = (response[2] as BigInt);

  final String key;

  final BigInt val;

  final BigInt decimals;

  final _i1.FilterEvent event;
}

class log_named_int {
  log_named_int(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt);

  final String key;

  final BigInt val;

  final _i1.FilterEvent event;
}

class log_named_string {
  log_named_string(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as String);

  final String key;

  final String val;

  final _i1.FilterEvent event;
}

class log_named_uint {
  log_named_uint(
    List<dynamic> response,
    this.event,
  )   : key = (response[0] as String),
        val = (response[1] as BigInt);

  final String key;

  final BigInt val;

  final _i1.FilterEvent event;
}

class log_string {
  log_string(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as String);

  final String var1;

  final _i1.FilterEvent event;
}

class log_uint {
  log_uint(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as BigInt);

  final BigInt var1;

  final _i1.FilterEvent event;
}

class logs {
  logs(
    List<dynamic> response,
    this.event,
  ) : var1 = (response[0] as _i2.Uint8List);

  final _i2.Uint8List var1;

  final _i1.FilterEvent event;
}
