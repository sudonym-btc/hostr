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
  '[{"type":"constructor","inputs":[{"name":"swapContract","type":"address","internalType":"address"},{"name":"erc20SwapContract","type":"address","internalType":"address"},{"name":"permit2Contract","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"receive","stateMutability":"payable"},{"type":"function","name":"DOMAIN_SEPARATOR","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"ERC20_SWAP_CONTRACT","inputs":[],"outputs":[{"name":"","type":"address","internalType":"contract ERC20Swap"}],"stateMutability":"view"},{"type":"function","name":"PERMIT2","inputs":[],"outputs":[{"name":"","type":"address","internalType":"contract ISignatureTransfer"}],"stateMutability":"view"},{"type":"function","name":"SWAP_CONTRACT","inputs":[],"outputs":[{"name":"","type":"address","internalType":"contract EtherSwap"}],"stateMutability":"view"},{"type":"function","name":"TYPEHASH_CLAIM","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"TYPEHASH_CLAIM_CALL","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"TYPEHASH_CLAIM_SEND","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"TYPEHASH_EXECUTE_LOCK_ERC20","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"TYPEHASH_SEND_DATA","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"TYPESTRING_EXECUTE_LOCK_ERC20","inputs":[],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"VERSION","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"claimCall","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"callee","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimCall","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"callee","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimERC20Call","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Erc20Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"callee","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimERC20Call","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Erc20Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"callee","type":"address","internalType":"address"},{"name":"callData","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimERC20Execute","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Erc20Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]},{"name":"token","type":"address","internalType":"address"},{"name":"minAmountOut","type":"uint256","internalType":"uint256"},{"name":"destination","type":"address","internalType":"address"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimERC20Execute","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Erc20Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]},{"name":"token","type":"address","internalType":"address"},{"name":"minAmountOut","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimERC20ExecuteOft","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Erc20Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]},{"name":"token","type":"address","internalType":"address"},{"name":"oft","type":"address","internalType":"address"},{"name":"sendData","type":"tuple","internalType":"struct Router.SendData","components":[{"name":"dstEid","type":"uint32","internalType":"uint32"},{"name":"to","type":"bytes32","internalType":"bytes32"},{"name":"extraOptions","type":"bytes","internalType":"bytes"},{"name":"composeMsg","type":"bytes","internalType":"bytes"},{"name":"oftCmd","type":"bytes","internalType":"bytes"}]},{"name":"auth","type":"tuple","internalType":"struct Router.ClaimSendAuthorization","components":[{"name":"minAmountLd","type":"uint256","internalType":"uint256"},{"name":"lzTokenFee","type":"uint256","internalType":"uint256"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]}],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"claimExecute","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]},{"name":"token","type":"address","internalType":"address"},{"name":"minAmountOut","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimExecute","inputs":[{"name":"claim","type":"tuple","internalType":"struct Router.Claim","components":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}]},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]},{"name":"token","type":"address","internalType":"address"},{"name":"minAmountOut","type":"uint256","internalType":"uint256"},{"name":"destination","type":"address","internalType":"address"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"executeAndLock","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"executeAndLockERC20","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]}],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"executeAndLockERC20WithPermit2","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"calls","type":"tuple[]","internalType":"struct Router.Call[]","components":[{"name":"target","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"callData","type":"bytes","internalType":"bytes"}]},{"name":"permit","type":"tuple","internalType":"struct ISignatureTransfer.PermitTransferFrom","components":[{"name":"permitted","type":"tuple","internalType":"struct ISignatureTransfer.TokenPermissions","components":[{"name":"token","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}]},{"name":"nonce","type":"uint256","internalType":"uint256"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"owner","type":"address","internalType":"address"},{"name":"signature","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"payable"},{"type":"error","name":"CallFailed","inputs":[{"name":"index","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"ClaimInvalidAddress","inputs":[]},{"type":"error","name":"InsufficientBalance","inputs":[]},{"type":"error","name":"ReentrancyGuardReentrantCall","inputs":[]},{"type":"error","name":"SafeERC20FailedOperation","inputs":[{"name":"token","type":"address","internalType":"address"}]},{"type":"error","name":"SwapCallNotAllowed","inputs":[]}]',
  'Router',
);

class Router extends _i1.GeneratedContract {
  Router({
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
  Future<_i2.EthereumAddress> ERC20_SWAP_CONTRACT(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '2067b7ca'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> PERMIT2({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '6afdd850'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> SWAP_CONTRACT({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'cf3afa51'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i3.Uint8List> TYPEHASH_CLAIM({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'ebb7af92'));
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
  Future<_i3.Uint8List> TYPEHASH_CLAIM_CALL({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '73e09a78'));
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
  Future<_i3.Uint8List> TYPEHASH_CLAIM_SEND({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '6531efdf'));
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
  Future<_i3.Uint8List> TYPEHASH_EXECUTE_LOCK_ERC20(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'ea8cd088'));
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
  Future<_i3.Uint8List> TYPEHASH_SEND_DATA({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '4a0870ff'));
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
  Future<String> TYPESTRING_EXECUTE_LOCK_ERC20({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, 'b47ec1a0'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> VERSION({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'ffa1ad74'));
    final params = [];
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
  Future<String> claimCall(
    ({
      dynamic claim,
      _i2.EthereumAddress callee,
      _i3.Uint8List callData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '3503c73d'));
    final params = [
      args.claim,
      args.callee,
      args.callData,
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
  Future<String> claimCall$2(
    ({
      dynamic claim,
      _i2.EthereumAddress callee,
      _i3.Uint8List callData,
      BigInt v,
      _i3.Uint8List r,
      _i3.Uint8List s
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '5b2acb70'));
    final params = [
      args.claim,
      args.callee,
      args.callData,
      args.v,
      args.r,
      args.s,
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
  Future<String> claimERC20Call(
    ({
      dynamic claim,
      _i2.EthereumAddress callee,
      _i3.Uint8List callData,
      BigInt v,
      _i3.Uint8List r,
      _i3.Uint8List s
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, 'da2271c3'));
    final params = [
      args.claim,
      args.callee,
      args.callData,
      args.v,
      args.r,
      args.s,
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
  Future<String> claimERC20Call$2(
    ({
      dynamic claim,
      _i2.EthereumAddress callee,
      _i3.Uint8List callData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'fe54c240'));
    final params = [
      args.claim,
      args.callee,
      args.callData,
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
  Future<String> claimERC20Execute(
    ({
      dynamic claim,
      List<dynamic> calls,
      _i2.EthereumAddress token,
      BigInt minAmountOut,
      _i2.EthereumAddress destination,
      BigInt v,
      _i3.Uint8List r,
      _i3.Uint8List s
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '211f3440'));
    final params = [
      args.claim,
      args.calls,
      args.token,
      args.minAmountOut,
      args.destination,
      args.v,
      args.r,
      args.s,
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
  Future<String> claimERC20Execute$2(
    ({
      dynamic claim,
      List<dynamic> calls,
      _i2.EthereumAddress token,
      BigInt minAmountOut
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '9667434f'));
    final params = [
      args.claim,
      args.calls,
      args.token,
      args.minAmountOut,
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
  Future<String> claimERC20ExecuteOft(
    ({
      dynamic claim,
      List<dynamic> calls,
      _i2.EthereumAddress token,
      _i2.EthereumAddress oft,
      dynamic sendData,
      dynamic auth
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '15ee82d3'));
    final params = [
      args.claim,
      args.calls,
      args.token,
      args.oft,
      args.sendData,
      args.auth,
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
  Future<String> claimExecute(
    ({
      dynamic claim,
      List<dynamic> calls,
      _i2.EthereumAddress token,
      BigInt minAmountOut
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, '891d6080'));
    final params = [
      args.claim,
      args.calls,
      args.token,
      args.minAmountOut,
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
  Future<String> claimExecute$2(
    ({
      dynamic claim,
      List<dynamic> calls,
      _i2.EthereumAddress token,
      BigInt minAmountOut,
      _i2.EthereumAddress destination,
      BigInt v,
      _i3.Uint8List r,
      _i3.Uint8List s
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, 'a7b77acb'));
    final params = [
      args.claim,
      args.calls,
      args.token,
      args.minAmountOut,
      args.destination,
      args.v,
      args.r,
      args.s,
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
  Future<String> executeAndLock(
    ({
      _i3.Uint8List preimageHash,
      _i2.EthereumAddress claimAddress,
      _i2.EthereumAddress refundAddress,
      BigInt timelock,
      List<dynamic> calls
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '1bcd0c09'));
    final params = [
      args.preimageHash,
      args.claimAddress,
      args.refundAddress,
      args.timelock,
      args.calls,
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
  Future<String> executeAndLockERC20(
    ({
      _i3.Uint8List preimageHash,
      _i2.EthereumAddress tokenAddress,
      _i2.EthereumAddress claimAddress,
      _i2.EthereumAddress refundAddress,
      BigInt timelock,
      List<dynamic> calls
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, 'ea81272e'));
    final params = [
      args.preimageHash,
      args.tokenAddress,
      args.claimAddress,
      args.refundAddress,
      args.timelock,
      args.calls,
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
  Future<String> executeAndLockERC20WithPermit2(
    ({
      _i3.Uint8List preimageHash,
      _i2.EthereumAddress tokenAddress,
      _i2.EthereumAddress claimAddress,
      _i2.EthereumAddress refundAddress,
      BigInt timelock,
      List<dynamic> calls,
      dynamic permit,
      _i2.EthereumAddress owner,
      _i3.Uint8List signature
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, 'a66bd06e'));
    final params = [
      args.preimageHash,
      args.tokenAddress,
      args.claimAddress,
      args.refundAddress,
      args.timelock,
      args.calls,
      args.permit,
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
}
