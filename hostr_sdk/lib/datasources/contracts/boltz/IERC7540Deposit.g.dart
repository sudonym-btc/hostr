// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'package:wallet/wallet.dart' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"claimableDepositRequest","inputs":[{"name":"requestId","type":"uint256","internalType":"uint256"},{"name":"controller","type":"address","internalType":"address"}],"outputs":[{"name":"claimableAssets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"deposit","inputs":[{"name":"assets","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"},{"name":"controller","type":"address","internalType":"address"}],"outputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"isOperator","inputs":[{"name":"controller","type":"address","internalType":"address"},{"name":"operator","type":"address","internalType":"address"}],"outputs":[{"name":"status","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"mint","inputs":[{"name":"shares","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"},{"name":"controller","type":"address","internalType":"address"}],"outputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"pendingDepositRequest","inputs":[{"name":"requestId","type":"uint256","internalType":"uint256"},{"name":"controller","type":"address","internalType":"address"}],"outputs":[{"name":"pendingAssets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"requestDeposit","inputs":[{"name":"assets","type":"uint256","internalType":"uint256"},{"name":"controller","type":"address","internalType":"address"},{"name":"owner","type":"address","internalType":"address"}],"outputs":[{"name":"requestId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"setOperator","inputs":[{"name":"operator","type":"address","internalType":"address"},{"name":"approved","type":"bool","internalType":"bool"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"event","name":"DepositRequest","inputs":[{"name":"controller","type":"address","indexed":true,"internalType":"address"},{"name":"owner","type":"address","indexed":true,"internalType":"address"},{"name":"requestId","type":"uint256","indexed":true,"internalType":"uint256"},{"name":"sender","type":"address","indexed":false,"internalType":"address"},{"name":"assets","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"OperatorSet","inputs":[{"name":"controller","type":"address","indexed":true,"internalType":"address"},{"name":"operator","type":"address","indexed":true,"internalType":"address"},{"name":"approved","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false}]',
  'IERC7540Deposit',
);

class IERC7540Deposit extends _i1.GeneratedContract {
  IERC7540Deposit({
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
  Future<BigInt> claimableDepositRequest(
    ({BigInt requestId, _i2.EthereumAddress controller}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '995ea21a'));
    final params = [
      args.requestId,
      args.controller,
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
  Future<String> deposit(
    ({
      BigInt assets,
      _i2.EthereumAddress receiver,
      _i2.EthereumAddress controller
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '2e2d2984'));
    final params = [
      args.assets,
      args.receiver,
      args.controller,
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
  Future<bool> isOperator(
    ({_i2.EthereumAddress controller, _i2.EthereumAddress operator}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'b6363cf2'));
    final params = [
      args.controller,
      args.operator,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> mint(
    ({
      BigInt shares,
      _i2.EthereumAddress receiver,
      _i2.EthereumAddress controller
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'da39b3e7'));
    final params = [
      args.shares,
      args.receiver,
      args.controller,
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
  Future<BigInt> pendingDepositRequest(
    ({BigInt requestId, _i2.EthereumAddress controller}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '26c6f96c'));
    final params = [
      args.requestId,
      args.controller,
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
  Future<String> requestDeposit(
    ({
      BigInt assets,
      _i2.EthereumAddress controller,
      _i2.EthereumAddress owner
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '85b77f45'));
    final params = [
      args.assets,
      args.controller,
      args.owner,
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
  Future<String> setOperator(
    ({_i2.EthereumAddress operator, bool approved}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '558a7297'));
    final params = [
      args.operator,
      args.approved,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all DepositRequest events emitted by this contract.
  Stream<DepositRequest> depositRequestEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('DepositRequest');
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
      return DepositRequest(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all OperatorSet events emitted by this contract.
  Stream<OperatorSet> operatorSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('OperatorSet');
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
      return OperatorSet(
        decoded,
        result,
      );
    });
  }
}

class DepositRequest {
  DepositRequest(
    List<dynamic> response,
    this.event,
  )   : controller = (response[0] as _i2.EthereumAddress),
        owner = (response[1] as _i2.EthereumAddress),
        requestId = (response[2] as BigInt),
        sender = (response[3] as _i2.EthereumAddress),
        assets = (response[4] as BigInt);

  final _i2.EthereumAddress controller;

  final _i2.EthereumAddress owner;

  final BigInt requestId;

  final _i2.EthereumAddress sender;

  final BigInt assets;

  final _i1.FilterEvent event;
}

class OperatorSet {
  OperatorSet(
    List<dynamic> response,
    this.event,
  )   : controller = (response[0] as _i2.EthereumAddress),
        operator = (response[1] as _i2.EthereumAddress),
        approved = (response[2] as bool);

  final _i2.EthereumAddress controller;

  final _i2.EthereumAddress operator;

  final bool approved;

  final _i1.FilterEvent event;
}
