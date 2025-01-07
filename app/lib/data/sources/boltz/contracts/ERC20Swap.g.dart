// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"constructor","inputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"DOMAIN_SEPARATOR","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"TYPEHASH_REFUND","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"claim","inputs":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claim","inputs":[{"name":"preimage","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"claimBatch","inputs":[{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"preimages","type":"bytes32[]","internalType":"bytes32[]"},{"name":"amounts","type":"uint256[]","internalType":"uint256[]"},{"name":"refundAddresses","type":"address[]","internalType":"address[]"},{"name":"timelocks","type":"uint256[]","internalType":"uint256[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"hashValues","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"lock","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"lockPrepayMinerfee","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address payable"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"refund","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"refundAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"refund","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"refundCooperative","inputs":[{"name":"preimageHash","type":"bytes32","internalType":"bytes32"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"tokenAddress","type":"address","internalType":"address"},{"name":"claimAddress","type":"address","internalType":"address"},{"name":"timelock","type":"uint256","internalType":"uint256"},{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"swaps","inputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"version","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"event","name":"Claim","inputs":[{"name":"preimageHash","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"preimage","type":"bytes32","indexed":false,"internalType":"bytes32"}],"anonymous":false},{"type":"event","name":"Lockup","inputs":[{"name":"preimageHash","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"amount","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"tokenAddress","type":"address","indexed":false,"internalType":"address"},{"name":"claimAddress","type":"address","indexed":false,"internalType":"address"},{"name":"refundAddress","type":"address","indexed":true,"internalType":"address"},{"name":"timelock","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"Refund","inputs":[{"name":"preimageHash","type":"bytes32","indexed":true,"internalType":"bytes32"}],"anonymous":false}]',
  'ERC20Swap',
);

class ERC20Swap extends _i1.GeneratedContract {
  ERC20Swap({
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
  Future<_i2.Uint8List> DOMAIN_SEPARATOR({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '3644e515'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.Uint8List);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.Uint8List> TYPEHASH_REFUND({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'a9ab4d5b'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.Uint8List);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> claim(
    ({
      _i2.Uint8List preimage,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress claimAddress,
      _i1.EthereumAddress refundAddress,
      BigInt timelock
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'bc586b28'));
    final params = [
      args.preimage,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.refundAddress,
      args.timelock,
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
  Future<String> claim$2(
    ({
      _i2.Uint8List preimage,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress refundAddress,
      BigInt timelock
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'cd413efa'));
    final params = [
      args.preimage,
      args.amount,
      args.tokenAddress,
      args.refundAddress,
      args.timelock,
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
  Future<String> claimBatch(
    ({
      _i1.EthereumAddress tokenAddress,
      List<_i2.Uint8List> preimages,
      List<BigInt> amounts,
      List<_i1.EthereumAddress> refundAddresses,
      List<BigInt> timelocks
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '8579dc5f'));
    final params = [
      args.tokenAddress,
      args.preimages,
      args.amounts,
      args.refundAddresses,
      args.timelocks,
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
  Future<_i2.Uint8List> hashValues(
    ({
      _i2.Uint8List preimageHash,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress claimAddress,
      _i1.EthereumAddress refundAddress,
      BigInt timelock
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '7beb9d6d'));
    final params = [
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
    return (response[0] as _i2.Uint8List);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> lock(
    ({
      _i2.Uint8List preimageHash,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress claimAddress,
      BigInt timelock
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '91644b2b'));
    final params = [
      args.preimageHash,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.timelock,
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
  Future<String> lockPrepayMinerfee(
    ({
      _i2.Uint8List preimageHash,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress claimAddress,
      BigInt timelock
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'b8080ab8'));
    final params = [
      args.preimageHash,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.timelock,
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
  Future<String> refund(
    ({
      _i2.Uint8List preimageHash,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress claimAddress,
      _i1.EthereumAddress refundAddress,
      BigInt timelock
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '0e5bbd59'));
    final params = [
      args.preimageHash,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.refundAddress,
      args.timelock,
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
  Future<String> refund$2(
    ({
      _i2.Uint8List preimageHash,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress claimAddress,
      BigInt timelock
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '36504721'));
    final params = [
      args.preimageHash,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.timelock,
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
  Future<String> refundCooperative(
    ({
      _i2.Uint8List preimageHash,
      BigInt amount,
      _i1.EthereumAddress tokenAddress,
      _i1.EthereumAddress claimAddress,
      BigInt timelock,
      BigInt v,
      _i2.Uint8List r,
      _i2.Uint8List s
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'fb35dd96'));
    final params = [
      args.preimageHash,
      args.amount,
      args.tokenAddress,
      args.claimAddress,
      args.timelock,
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

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> swaps(
    ({_i2.Uint8List $param51}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, 'eb84e7f2'));
    final params = [args.$param51];
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
  Future<BigInt> version({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '54fd4d50'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// Returns a live stream of all Claim events emitted by this contract.
  Stream<Claim> claimEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Claim');
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
      return Claim(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Lockup events emitted by this contract.
  Stream<Lockup> lockupEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Lockup');
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
      return Lockup(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Refund events emitted by this contract.
  Stream<Refund> refundEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Refund');
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
      return Refund(
        decoded,
        result,
      );
    });
  }
}

class Claim {
  Claim(
    List<dynamic> response,
    this.event,
  )   : preimageHash = (response[0] as _i2.Uint8List),
        preimage = (response[1] as _i2.Uint8List);

  final _i2.Uint8List preimageHash;

  final _i2.Uint8List preimage;

  final _i1.FilterEvent event;
}

class Lockup {
  Lockup(
    List<dynamic> response,
    this.event,
  )   : preimageHash = (response[0] as _i2.Uint8List),
        amount = (response[1] as BigInt),
        tokenAddress = (response[2] as _i1.EthereumAddress),
        claimAddress = (response[3] as _i1.EthereumAddress),
        refundAddress = (response[4] as _i1.EthereumAddress),
        timelock = (response[5] as BigInt);

  final _i2.Uint8List preimageHash;

  final BigInt amount;

  final _i1.EthereumAddress tokenAddress;

  final _i1.EthereumAddress claimAddress;

  final _i1.EthereumAddress refundAddress;

  final BigInt timelock;

  final _i1.FilterEvent event;
}

class Refund {
  Refund(
    List<dynamic> response,
    this.event,
  ) : preimageHash = (response[0] as _i2.Uint8List);

  final _i2.Uint8List preimageHash;

  final _i1.FilterEvent event;
}
