// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"IS_TEST","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"excludeArtifacts","inputs":[],"outputs":[{"name":"excludedArtifacts_","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"excludeContracts","inputs":[],"outputs":[{"name":"excludedContracts_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"excludeSelectors","inputs":[],"outputs":[{"name":"excludedSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzSelector[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"excludeSenders","inputs":[],"outputs":[{"name":"excludedSenders_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"failed","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"invariantMetadata","inputs":[],"outputs":[],"stateMutability":"view"},{"type":"function","name":"setUp","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"targetArtifactSelectors","inputs":[],"outputs":[{"name":"targetedArtifactSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzArtifactSelector[]","components":[{"name":"artifact","type":"string","internalType":"string"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetArtifacts","inputs":[],"outputs":[{"name":"targetedArtifacts_","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"targetContracts","inputs":[],"outputs":[{"name":"targetedContracts_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"targetInterfaces","inputs":[],"outputs":[{"name":"targetedInterfaces_","type":"tuple[]","internalType":"struct StdInvariant.FuzzInterface[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"artifacts","type":"string[]","internalType":"string[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetSelectors","inputs":[],"outputs":[{"name":"targetedSelectors_","type":"tuple[]","internalType":"struct StdInvariant.FuzzSelector[]","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"selectors","type":"bytes4[]","internalType":"bytes4[]"}]}],"stateMutability":"view"},{"type":"function","name":"targetSenders","inputs":[],"outputs":[{"name":"targetedSenders_","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"testApprove","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testApprove","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testBurn","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"mintAmount","type":"uint256","internalType":"uint256"},{"name":"burnAmount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testBurn","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailBurnInsufficientBalance","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"mintAmount","type":"uint256","internalType":"uint256"},{"name":"burnAmount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitBadDeadline","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitBadDeadline","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitBadNonce","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"},{"name":"nonce","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitBadNonce","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitPastDeadline","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitPastDeadline","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitReplay","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailPermitReplay","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromInsufficientAllowance","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromInsufficientAllowance","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"approval","type":"uint256","internalType":"uint256"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromInsufficientBalance","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"mintAmount","type":"uint256","internalType":"uint256"},{"name":"sendAmount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferFromInsufficientBalance","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferInsufficientBalance","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"mintAmount","type":"uint256","internalType":"uint256"},{"name":"sendAmount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testFailTransferInsufficientBalance","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testInfiniteApproveTransferFrom","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testMetadata","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"symbol","type":"string","internalType":"string"},{"name":"decimals","type":"uint8","internalType":"uint8"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testMint","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testMint","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testPermit","inputs":[{"name":"privKey","type":"uint248","internalType":"uint248"},{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testPermit","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransfer","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransfer","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFrom","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"testTransferFrom","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"approval","type":"uint256","internalType":"uint256"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"log","inputs":[{"name":"","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_address","inputs":[{"name":"","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"uint256[]","indexed":false,"internalType":"uint256[]"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"int256[]","indexed":false,"internalType":"int256[]"}],"anonymous":false},{"type":"event","name":"log_array","inputs":[{"name":"val","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"log_bytes","inputs":[{"name":"","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false},{"type":"event","name":"log_bytes32","inputs":[{"name":"","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false},{"type":"event","name":"log_int","inputs":[{"name":"","type":"int256","indexed":false,"internalType":"int256"}],"anonymous":false},{"type":"event","name":"log_named_address","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256[]","indexed":false,"internalType":"uint256[]"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256[]","indexed":false,"internalType":"int256[]"}],"anonymous":false},{"type":"event","name":"log_named_array","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"log_named_bytes","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false},{"type":"event","name":"log_named_bytes32","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false},{"type":"event","name":"log_named_decimal_int","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256","indexed":false,"internalType":"int256"},{"name":"decimals","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_named_decimal_uint","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"decimals","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_named_int","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"int256","indexed":false,"internalType":"int256"}],"anonymous":false},{"type":"event","name":"log_named_string","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_named_uint","inputs":[{"name":"key","type":"string","indexed":false,"internalType":"string"},{"name":"val","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"log_string","inputs":[{"name":"","type":"string","indexed":false,"internalType":"string"}],"anonymous":false},{"type":"event","name":"log_uint","inputs":[{"name":"","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"logs","inputs":[{"name":"","type":"bytes","indexed":false,"internalType":"bytes"}],"anonymous":false}]',
  'MockERC20Test',
);

class MockERC20Test extends _i1.GeneratedContract {
  MockERC20Test({
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
    ({_i1.EthereumAddress to, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'fb44e83a'));
    final params = [
      args.to,
      args.amount,
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
  Future<String> testBurn(
    ({_i1.EthereumAddress from, BigInt mintAmount, BigInt burnAmount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '1037c205'));
    final params = [
      args.from,
      args.mintAmount,
      args.burnAmount,
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
    final function = self.abi.functions[17];
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
  Future<String> testFailBurnInsufficientBalance(
    ({_i1.EthereumAddress to, BigInt mintAmount, BigInt burnAmount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '4ef2a28d'));
    final params = [
      args.to,
      args.mintAmount,
      args.burnAmount,
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
  Future<String> testFailPermitBadDeadline(
    ({
      BigInt privateKey,
      _i1.EthereumAddress to,
      BigInt amount,
      BigInt deadline
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, '6a6b2181'));
    final params = [
      args.privateKey,
      args.to,
      args.amount,
      args.deadline,
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
  Future<String> testFailPermitBadDeadline$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, 'f2b2a116'));
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
  Future<String> testFailPermitBadNonce(
    ({
      BigInt privateKey,
      _i1.EthereumAddress to,
      BigInt amount,
      BigInt deadline,
      BigInt nonce
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, 'd9e7fb9e'));
    final params = [
      args.privateKey,
      args.to,
      args.amount,
      args.deadline,
      args.nonce,
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
  Future<String> testFailPermitBadNonce$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, 'fd13e047'));
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
  Future<String> testFailPermitPastDeadline(
    ({
      BigInt privateKey,
      _i1.EthereumAddress to,
      BigInt amount,
      BigInt deadline
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '0d438c46'));
    final params = [
      args.privateKey,
      args.to,
      args.amount,
      args.deadline,
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
  Future<String> testFailPermitPastDeadline$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '7f6072fc'));
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
  Future<String> testFailPermitReplay(
    ({
      BigInt privateKey,
      _i1.EthereumAddress to,
      BigInt amount,
      BigInt deadline
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, '4b870ef3'));
    final params = [
      args.privateKey,
      args.to,
      args.amount,
      args.deadline,
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
  Future<String> testFailPermitReplay$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, '81b19f2d'));
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
  Future<String> testFailTransferFromInsufficientAllowance({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, 'b1bebfb8'));
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
  Future<String> testFailTransferFromInsufficientAllowance$2(
    ({_i1.EthereumAddress to, BigInt approval, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, 'ce90007c'));
    final params = [
      args.to,
      args.approval,
      args.amount,
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
  Future<String> testFailTransferFromInsufficientBalance(
    ({_i1.EthereumAddress to, BigInt mintAmount, BigInt sendAmount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '75e990ae'));
    final params = [
      args.to,
      args.mintAmount,
      args.sendAmount,
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
  Future<String> testFailTransferFromInsufficientBalance$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '76af74f9'));
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
  Future<String> testFailTransferInsufficientBalance(
    ({_i1.EthereumAddress to, BigInt mintAmount, BigInt sendAmount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, '6ba96baf'));
    final params = [
      args.to,
      args.mintAmount,
      args.sendAmount,
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
  Future<String> testFailTransferInsufficientBalance$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, 'ee2276e3'));
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
  Future<String> testInfiniteApproveTransferFrom({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '18eab016'));
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
  Future<String> testMetadata(
    ({String name, String symbol, BigInt decimals}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, '764e1ba2'));
    final params = [
      args.name,
      args.symbol,
      args.decimals,
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
    final function = self.abi.functions[35];
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
    ({_i1.EthereumAddress from, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, 'f28e093d'));
    final params = [
      args.from,
      args.amount,
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
  Future<String> testPermit(
    ({
      BigInt privKey,
      _i1.EthereumAddress to,
      BigInt amount,
      BigInt deadline
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, '70a016f0'));
    final params = [
      args.privKey,
      args.to,
      args.amount,
      args.deadline,
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
  Future<String> testPermit$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, 'ec032b64'));
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
  Future<String> testTransfer(
    ({_i1.EthereumAddress from, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, 'a0e70267'));
    final params = [
      args.from,
      args.amount,
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
  Future<String> testTransfer$2({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[40];
    assert(checkSignature(function, 'd591221f'));
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
  Future<String> testTransferFrom({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[41];
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
  Future<String> testTransferFrom$2(
    ({_i1.EthereumAddress to, BigInt approval, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[42];
    assert(checkSignature(function, 'f19f90dd'));
    final params = [
      args.to,
      args.approval,
      args.amount,
    ];
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
