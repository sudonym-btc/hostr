// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"inputs":[{"internalType":"address","name":"_penalizer","type":"address"},{"internalType":"uint256","name":"_maxWorkerCount","type":"uint256"},{"internalType":"uint256","name":"_minimumEntryDepositValue","type":"uint256"},{"internalType":"uint256","name":"_minimumUnstakeDelay","type":"uint256"},{"internalType":"uint256","name":"_minimumStake","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayWorker","type":"address"},{"indexed":false,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"Penalized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":false,"internalType":"string","name":"relayUrl","type":"string"}],"name":"RelayServerRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":false,"internalType":"address[]","name":"newRelayWorkers","type":"address[]"},{"indexed":false,"internalType":"uint256","name":"workersCount","type":"uint256"}],"name":"RelayWorkersAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":false,"internalType":"address[]","name":"relayWorkers","type":"address[]"},{"indexed":false,"internalType":"uint256","name":"workersCount","type":"uint256"}],"name":"RelayWorkersDisabled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"stake","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"unstakeDelay","type":"uint256"}],"name":"StakeAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":true,"internalType":"address","name":"beneficiary","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"StakePenalized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"withdrawBlock","type":"uint256"}],"name":"StakeUnlocked","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"StakeWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":false,"internalType":"address","name":"relayWorker","type":"address"},{"indexed":false,"internalType":"bytes32","name":"relayRequestSigHash","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"relayedCallReturnValue","type":"bytes"}],"name":"TransactionRelayed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayManager","type":"address"},{"indexed":false,"internalType":"address","name":"relayWorker","type":"address"},{"indexed":false,"internalType":"bytes32","name":"relayRequestSigHash","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"reason","type":"bytes"}],"name":"TransactionRelayedButRevertedByRecipient","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes","name":"returnValue","type":"bytes"}],"name":"TransactionResult","type":"event"},{"inputs":[{"internalType":"address[]","name":"newRelayWorkers","type":"address[]"}],"name":"addRelayWorkers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"components":[{"internalType":"address","name":"relayHub","type":"address"},{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"address","name":"tokenContract","type":"address"},{"internalType":"address","name":"recoverer","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"tokenAmount","type":"uint256"},{"internalType":"uint256","name":"tokenGas","type":"uint256"},{"internalType":"uint256","name":"validUntilTime","type":"uint256"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"internalType":"struct IForwarder.DeployRequest","name":"request","type":"tuple"},{"components":[{"internalType":"uint256","name":"gasPrice","type":"uint256"},{"internalType":"address","name":"feesReceiver","type":"address"},{"internalType":"address","name":"callForwarder","type":"address"},{"internalType":"address","name":"callVerifier","type":"address"}],"internalType":"struct EnvelopingTypes.RelayData","name":"relayData","type":"tuple"}],"internalType":"struct EnvelopingTypes.DeployRequest","name":"deployRequest","type":"tuple"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"deployCall","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"relayWorkers","type":"address[]"}],"name":"disableRelayWorkers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"relayManager","type":"address"}],"name":"getRelayInfo","outputs":[{"components":[{"internalType":"address","name":"manager","type":"address"},{"internalType":"bool","name":"currentlyStaked","type":"bool"},{"internalType":"bool","name":"registered","type":"bool"},{"internalType":"string","name":"url","type":"string"}],"internalType":"struct IRelayHub.RelayManagerData","name":"relayManagerData","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"relayManager","type":"address"}],"name":"getStakeInfo","outputs":[{"components":[{"internalType":"uint256","name":"stake","type":"uint256"},{"internalType":"uint256","name":"unstakeDelay","type":"uint256"},{"internalType":"uint256","name":"withdrawBlock","type":"uint256"},{"internalType":"address payable","name":"owner","type":"address"}],"internalType":"struct IRelayHub.StakeInfo","name":"stakeInfo","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"relayManager","type":"address"}],"name":"isRelayManagerStaked","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxWorkerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minimumEntryDepositValue","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minimumStake","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minimumUnstakeDelay","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"relayWorker","type":"address"},{"internalType":"address payable","name":"beneficiary","type":"address"}],"name":"penalize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"penalizer","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"url","type":"string"}],"name":"registerRelayServer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"components":[{"internalType":"address","name":"relayHub","type":"address"},{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"address","name":"tokenContract","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"gas","type":"uint256"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"tokenAmount","type":"uint256"},{"internalType":"uint256","name":"tokenGas","type":"uint256"},{"internalType":"uint256","name":"validUntilTime","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"internalType":"struct IForwarder.ForwardRequest","name":"request","type":"tuple"},{"components":[{"internalType":"uint256","name":"gasPrice","type":"uint256"},{"internalType":"address","name":"feesReceiver","type":"address"},{"internalType":"address","name":"callForwarder","type":"address"},{"internalType":"address","name":"callVerifier","type":"address"}],"internalType":"struct EnvelopingTypes.RelayData","name":"relayData","type":"tuple"}],"internalType":"struct EnvelopingTypes.RelayRequest","name":"relayRequest","type":"tuple"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"relayCall","outputs":[{"internalType":"bool","name":"destinationCallSuccess","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"relayData","outputs":[{"internalType":"address","name":"manager","type":"address"},{"internalType":"bool","name":"currentlyStaked","type":"bool"},{"internalType":"bool","name":"registered","type":"bool"},{"internalType":"string","name":"url","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"relayManager","type":"address"},{"internalType":"uint256","name":"unstakeDelay","type":"uint256"}],"name":"stakeForAddress","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"stakes","outputs":[{"internalType":"uint256","name":"stake","type":"uint256"},{"internalType":"uint256","name":"unstakeDelay","type":"uint256"},{"internalType":"uint256","name":"withdrawBlock","type":"uint256"},{"internalType":"address payable","name":"owner","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"relayManager","type":"address"}],"name":"unlockStake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"versionHub","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"relayManager","type":"address"}],"name":"withdrawStake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"workerCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"workerToManager","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"}]',
  'RelayHub',
);

class RelayHub extends _i1.GeneratedContract {
  RelayHub({
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

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addRelayWorkers(
    ({List<_i1.EthereumAddress> newRelayWorkers}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'c2da0786'));
    final params = [args.newRelayWorkers];
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
  Future<String> deployCall(
    ({dynamic deployRequest, _i2.Uint8List signature}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'ecb39940'));
    final params = [
      args.deployRequest,
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
  Future<String> disableRelayWorkers(
    ({List<_i1.EthereumAddress> relayWorkers}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'c4464b29'));
    final params = [args.relayWorkers];
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
  Future<dynamic> getRelayInfo(
    ({_i1.EthereumAddress relayManager}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '4b84219e'));
    final params = [args.relayManager];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getStakeInfo(
    ({_i1.EthereumAddress relayManager}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'c3453153'));
    final params = [args.relayManager];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isRelayManagerStaked(
    ({_i1.EthereumAddress relayManager}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '2ad311b5'));
    final params = [args.relayManager];
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
  Future<BigInt> maxWorkerCount({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'e5fad978'));
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
  Future<BigInt> minimumEntryDepositValue({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '1c9faa89'));
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
  Future<BigInt> minimumStake({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, 'ec5ffac2'));
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
  Future<BigInt> minimumUnstakeDelay({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '71116320'));
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
  Future<String> penalize(
    ({_i1.EthereumAddress relayWorker, _i1.EthereumAddress beneficiary}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, 'ebcd31ac'));
    final params = [
      args.relayWorker,
      args.beneficiary,
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
  Future<_i1.EthereumAddress> penalizer({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, 'c4775a68'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i1.EthereumAddress);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> registerRelayServer(
    ({String url}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, 'c425c6a5'));
    final params = [args.url];
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
  Future<String> relayCall(
    ({dynamic relayRequest, _i2.Uint8List signature}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '528ab2ad'));
    final params = [
      args.relayRequest,
      args.signature,
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
  Future<RelayData> relayData(
    ({_i1.EthereumAddress $param12}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'c5a716cc'));
    final params = [args.$param12];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return RelayData(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> stakeForAddress(
    ({_i1.EthereumAddress relayManager, BigInt unstakeDelay}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '5d2fb768'));
    final params = [
      args.relayManager,
      args.unstakeDelay,
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
  Future<Stakes> stakes(
    ({_i1.EthereumAddress $param15}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '16934fc4'));
    final params = [args.$param15];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Stakes(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> unlockStake(
    ({_i1.EthereumAddress relayManager}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '4a1ce599'));
    final params = [args.relayManager];
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
  Future<String> versionHub({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'd904c732'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as String);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> withdrawStake(
    ({_i1.EthereumAddress relayManager}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, 'c23a5cea'));
    final params = [args.relayManager];
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
  Future<BigInt> workerCount(
    ({_i1.EthereumAddress $param18}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '194ac307'));
    final params = [args.$param18];
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
  Future<_i2.Uint8List> workerToManager(
    ({_i1.EthereumAddress $param19}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, 'ca998f56'));
    final params = [args.$param19];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.Uint8List);
  }

  /// Returns a live stream of all Penalized events emitted by this contract.
  Stream<Penalized> penalizedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Penalized');
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
      return Penalized(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RelayServerRegistered events emitted by this contract.
  Stream<RelayServerRegistered> relayServerRegisteredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RelayServerRegistered');
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
      return RelayServerRegistered(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RelayWorkersAdded events emitted by this contract.
  Stream<RelayWorkersAdded> relayWorkersAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RelayWorkersAdded');
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
      return RelayWorkersAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all RelayWorkersDisabled events emitted by this contract.
  Stream<RelayWorkersDisabled> relayWorkersDisabledEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('RelayWorkersDisabled');
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
      return RelayWorkersDisabled(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all StakeAdded events emitted by this contract.
  Stream<StakeAdded> stakeAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('StakeAdded');
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
      return StakeAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all StakePenalized events emitted by this contract.
  Stream<StakePenalized> stakePenalizedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('StakePenalized');
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
      return StakePenalized(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all StakeUnlocked events emitted by this contract.
  Stream<StakeUnlocked> stakeUnlockedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('StakeUnlocked');
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
      return StakeUnlocked(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all StakeWithdrawn events emitted by this contract.
  Stream<StakeWithdrawn> stakeWithdrawnEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('StakeWithdrawn');
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
      return StakeWithdrawn(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TransactionRelayed events emitted by this contract.
  Stream<TransactionRelayed> transactionRelayedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TransactionRelayed');
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
      return TransactionRelayed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TransactionRelayedButRevertedByRecipient events emitted by this contract.
  Stream<TransactionRelayedButRevertedByRecipient>
      transactionRelayedButRevertedByRecipientEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TransactionRelayedButRevertedByRecipient');
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
      return TransactionRelayedButRevertedByRecipient(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all TransactionResult events emitted by this contract.
  Stream<TransactionResult> transactionResultEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('TransactionResult');
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
      return TransactionResult(
        decoded,
        result,
      );
    });
  }
}

class RelayData {
  RelayData(List<dynamic> response)
      : manager = (response[0] as _i1.EthereumAddress),
        currentlyStaked = (response[1] as bool),
        registered = (response[2] as bool),
        url = (response[3] as String);

  final _i1.EthereumAddress manager;

  final bool currentlyStaked;

  final bool registered;

  final String url;
}

class Stakes {
  Stakes(List<dynamic> response)
      : stake = (response[0] as BigInt),
        unstakeDelay = (response[1] as BigInt),
        withdrawBlock = (response[2] as BigInt),
        owner = (response[3] as _i1.EthereumAddress);

  final BigInt stake;

  final BigInt unstakeDelay;

  final BigInt withdrawBlock;

  final _i1.EthereumAddress owner;
}

class Penalized {
  Penalized(
    List<dynamic> response,
    this.event,
  )   : relayWorker = (response[0] as _i1.EthereumAddress),
        sender = (response[1] as _i1.EthereumAddress),
        reward = (response[2] as BigInt);

  final _i1.EthereumAddress relayWorker;

  final _i1.EthereumAddress sender;

  final BigInt reward;

  final _i1.FilterEvent event;
}

class RelayServerRegistered {
  RelayServerRegistered(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        relayUrl = (response[1] as String);

  final _i1.EthereumAddress relayManager;

  final String relayUrl;

  final _i1.FilterEvent event;
}

class RelayWorkersAdded {
  RelayWorkersAdded(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        newRelayWorkers =
            (response[1] as List<dynamic>).cast<_i1.EthereumAddress>(),
        workersCount = (response[2] as BigInt);

  final _i1.EthereumAddress relayManager;

  final List<_i1.EthereumAddress> newRelayWorkers;

  final BigInt workersCount;

  final _i1.FilterEvent event;
}

class RelayWorkersDisabled {
  RelayWorkersDisabled(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        relayWorkers =
            (response[1] as List<dynamic>).cast<_i1.EthereumAddress>(),
        workersCount = (response[2] as BigInt);

  final _i1.EthereumAddress relayManager;

  final List<_i1.EthereumAddress> relayWorkers;

  final BigInt workersCount;

  final _i1.FilterEvent event;
}

class StakeAdded {
  StakeAdded(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        owner = (response[1] as _i1.EthereumAddress),
        stake = (response[2] as BigInt),
        unstakeDelay = (response[3] as BigInt);

  final _i1.EthereumAddress relayManager;

  final _i1.EthereumAddress owner;

  final BigInt stake;

  final BigInt unstakeDelay;

  final _i1.FilterEvent event;
}

class StakePenalized {
  StakePenalized(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        beneficiary = (response[1] as _i1.EthereumAddress),
        reward = (response[2] as BigInt);

  final _i1.EthereumAddress relayManager;

  final _i1.EthereumAddress beneficiary;

  final BigInt reward;

  final _i1.FilterEvent event;
}

class StakeUnlocked {
  StakeUnlocked(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        owner = (response[1] as _i1.EthereumAddress),
        withdrawBlock = (response[2] as BigInt);

  final _i1.EthereumAddress relayManager;

  final _i1.EthereumAddress owner;

  final BigInt withdrawBlock;

  final _i1.FilterEvent event;
}

class StakeWithdrawn {
  StakeWithdrawn(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        owner = (response[1] as _i1.EthereumAddress),
        amount = (response[2] as BigInt);

  final _i1.EthereumAddress relayManager;

  final _i1.EthereumAddress owner;

  final BigInt amount;

  final _i1.FilterEvent event;
}

class TransactionRelayed {
  TransactionRelayed(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        relayWorker = (response[1] as _i1.EthereumAddress),
        relayRequestSigHash = (response[2] as _i2.Uint8List),
        relayedCallReturnValue = (response[3] as _i2.Uint8List);

  final _i1.EthereumAddress relayManager;

  final _i1.EthereumAddress relayWorker;

  final _i2.Uint8List relayRequestSigHash;

  final _i2.Uint8List relayedCallReturnValue;

  final _i1.FilterEvent event;
}

class TransactionRelayedButRevertedByRecipient {
  TransactionRelayedButRevertedByRecipient(
    List<dynamic> response,
    this.event,
  )   : relayManager = (response[0] as _i1.EthereumAddress),
        relayWorker = (response[1] as _i1.EthereumAddress),
        relayRequestSigHash = (response[2] as _i2.Uint8List),
        reason = (response[3] as _i2.Uint8List);

  final _i1.EthereumAddress relayManager;

  final _i1.EthereumAddress relayWorker;

  final _i2.Uint8List relayRequestSigHash;

  final _i2.Uint8List reason;

  final _i1.FilterEvent event;
}

class TransactionResult {
  TransactionResult(
    List<dynamic> response,
    this.event,
  ) : returnValue = (response[0] as _i2.Uint8List);

  final _i2.Uint8List returnValue;

  final _i1.FilterEvent event;
}
