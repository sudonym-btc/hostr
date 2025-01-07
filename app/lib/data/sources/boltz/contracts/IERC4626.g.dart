// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"allowance","inputs":[{"name":"owner","type":"address","internalType":"address"},{"name":"spender","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"approve","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"asset","inputs":[],"outputs":[{"name":"assetTokenAddress","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"balanceOf","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"convertToAssets","inputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"convertToShares","inputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"decimals","inputs":[],"outputs":[{"name":"","type":"uint8","internalType":"uint8"}],"stateMutability":"view"},{"type":"function","name":"deposit","inputs":[{"name":"assets","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"}],"outputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"maxDeposit","inputs":[{"name":"receiver","type":"address","internalType":"address"}],"outputs":[{"name":"maxAssets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"maxMint","inputs":[{"name":"receiver","type":"address","internalType":"address"}],"outputs":[{"name":"maxShares","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"maxRedeem","inputs":[{"name":"owner","type":"address","internalType":"address"}],"outputs":[{"name":"maxShares","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"maxWithdraw","inputs":[{"name":"owner","type":"address","internalType":"address"}],"outputs":[{"name":"maxAssets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"mint","inputs":[{"name":"shares","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"}],"outputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"name","inputs":[],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"previewDeposit","inputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"previewMint","inputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"previewRedeem","inputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"previewWithdraw","inputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"redeem","inputs":[{"name":"shares","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"},{"name":"owner","type":"address","internalType":"address"}],"outputs":[{"name":"assets","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"symbol","inputs":[],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"totalAssets","inputs":[],"outputs":[{"name":"totalManagedAssets","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"totalSupply","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"transfer","inputs":[{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"transferFrom","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"withdraw","inputs":[{"name":"assets","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"},{"name":"owner","type":"address","internalType":"address"}],"outputs":[{"name":"shares","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"event","name":"Approval","inputs":[{"name":"owner","type":"address","indexed":true,"internalType":"address"},{"name":"spender","type":"address","indexed":true,"internalType":"address"},{"name":"value","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"Deposit","inputs":[{"name":"sender","type":"address","indexed":true,"internalType":"address"},{"name":"owner","type":"address","indexed":true,"internalType":"address"},{"name":"assets","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"shares","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"Transfer","inputs":[{"name":"from","type":"address","indexed":true,"internalType":"address"},{"name":"to","type":"address","indexed":true,"internalType":"address"},{"name":"value","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"Withdraw","inputs":[{"name":"sender","type":"address","indexed":true,"internalType":"address"},{"name":"receiver","type":"address","indexed":true,"internalType":"address"},{"name":"owner","type":"address","indexed":true,"internalType":"address"},{"name":"assets","type":"uint256","indexed":false,"internalType":"uint256"},{"name":"shares","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false}]',
  'IERC4626',
);

class IERC4626 extends _i1.GeneratedContract {
  IERC4626({
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
  Future<BigInt> allowance(
    ({_i1.EthereumAddress owner, _i1.EthereumAddress spender}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'dd62ed3e'));
    final params = [
      args.owner,
      args.spender,
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
  Future<String> approve(
    ({_i1.EthereumAddress spender, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '095ea7b3'));
    final params = [
      args.spender,
      args.amount,
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
  Future<_i1.EthereumAddress> asset({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '38d52e0f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i1.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> balanceOf(
    ({_i1.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '70a08231'));
    final params = [args.account];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> convertToAssets(
    ({BigInt shares}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '07a2d13a'));
    final params = [args.shares];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> convertToShares(
    ({BigInt assets}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'c6e6f592'));
    final params = [args.assets];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> decimals({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '313ce567'));
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
  Future<String> deposit(
    ({BigInt assets, _i1.EthereumAddress receiver}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, '6e553f65'));
    final params = [
      args.assets,
      args.receiver,
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
  Future<BigInt> maxDeposit(
    ({_i1.EthereumAddress receiver}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '402d267d'));
    final params = [args.receiver];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxMint(
    ({_i1.EthereumAddress receiver}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, 'c63d75b6'));
    final params = [args.receiver];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxRedeem(
    ({_i1.EthereumAddress owner}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, 'd905777e'));
    final params = [args.owner];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxWithdraw(
    ({_i1.EthereumAddress owner}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'ce96cb77'));
    final params = [args.owner];
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
  Future<String> mint(
    ({BigInt shares, _i1.EthereumAddress receiver}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '94bf804d'));
    final params = [
      args.shares,
      args.receiver,
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
  Future<String> name({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '06fdde03'));
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
  Future<BigInt> previewDeposit(
    ({BigInt assets}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, 'ef8b30f7'));
    final params = [args.assets];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> previewMint(
    ({BigInt shares}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'b3d7f6b9'));
    final params = [args.shares];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> previewRedeem(
    ({BigInt shares}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '4cdad506'));
    final params = [args.shares];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> previewWithdraw(
    ({BigInt assets}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '0a28a477'));
    final params = [args.assets];
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
  Future<String> redeem(
    ({
      BigInt shares,
      _i1.EthereumAddress receiver,
      _i1.EthereumAddress owner
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'ba087652'));
    final params = [
      args.shares,
      args.receiver,
      args.owner,
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
  Future<String> symbol({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, '95d89b41'));
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
  Future<BigInt> totalAssets({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '01e1d114'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> totalSupply({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '18160ddd'));
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
  Future<String> transfer(
    ({_i1.EthereumAddress to, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, 'a9059cbb'));
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
  Future<String> transferFrom(
    ({_i1.EthereumAddress from, _i1.EthereumAddress to, BigInt amount}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '23b872dd'));
    final params = [
      args.from,
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
  Future<String> withdraw(
    ({
      BigInt assets,
      _i1.EthereumAddress receiver,
      _i1.EthereumAddress owner
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, 'b460af94'));
    final params = [
      args.assets,
      args.receiver,
      args.owner,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all Approval events emitted by this contract.
  Stream<Approval> approvalEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Approval');
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
      return Approval(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Deposit events emitted by this contract.
  Stream<Deposit> depositEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Deposit');
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
      return Deposit(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Transfer events emitted by this contract.
  Stream<Transfer> transferEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Transfer');
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
      return Transfer(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Withdraw events emitted by this contract.
  Stream<Withdraw> withdrawEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Withdraw');
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
      return Withdraw(
        decoded,
        result,
      );
    });
  }
}

class Approval {
  Approval(
    List<dynamic> response,
    this.event,
  )   : owner = (response[0] as _i1.EthereumAddress),
        spender = (response[1] as _i1.EthereumAddress),
        value = (response[2] as BigInt);

  final _i1.EthereumAddress owner;

  final _i1.EthereumAddress spender;

  final BigInt value;

  final _i1.FilterEvent event;
}

class Deposit {
  Deposit(
    List<dynamic> response,
    this.event,
  )   : sender = (response[0] as _i1.EthereumAddress),
        owner = (response[1] as _i1.EthereumAddress),
        assets = (response[2] as BigInt),
        shares = (response[3] as BigInt);

  final _i1.EthereumAddress sender;

  final _i1.EthereumAddress owner;

  final BigInt assets;

  final BigInt shares;

  final _i1.FilterEvent event;
}

class Transfer {
  Transfer(
    List<dynamic> response,
    this.event,
  )   : from = (response[0] as _i1.EthereumAddress),
        to = (response[1] as _i1.EthereumAddress),
        value = (response[2] as BigInt);

  final _i1.EthereumAddress from;

  final _i1.EthereumAddress to;

  final BigInt value;

  final _i1.FilterEvent event;
}

class Withdraw {
  Withdraw(
    List<dynamic> response,
    this.event,
  )   : sender = (response[0] as _i1.EthereumAddress),
        receiver = (response[1] as _i1.EthereumAddress),
        owner = (response[2] as _i1.EthereumAddress),
        assets = (response[3] as BigInt),
        shares = (response[4] as BigInt);

  final _i1.EthereumAddress sender;

  final _i1.EthereumAddress receiver;

  final _i1.EthereumAddress owner;

  final BigInt assets;

  final BigInt shares;

  final _i1.FilterEvent event;
}
