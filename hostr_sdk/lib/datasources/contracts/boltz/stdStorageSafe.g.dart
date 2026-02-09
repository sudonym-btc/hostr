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
  '[{"type":"event","name":"SlotFound","inputs":[{"name":"who","type":"address","indexed":false,"internalType":"address"},{"name":"fsig","type":"bytes4","indexed":false,"internalType":"bytes4"},{"name":"keysHash","type":"bytes32","indexed":false,"internalType":"bytes32"},{"name":"slot","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false},{"type":"event","name":"WARNING_UninitedSlot","inputs":[{"name":"who","type":"address","indexed":false,"internalType":"address"},{"name":"slot","type":"uint256","indexed":false,"internalType":"uint256"}],"anonymous":false}]',
  'StdStorageSafe',
);

class StdStorageSafe extends _i1.GeneratedContract {
  StdStorageSafe({
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

  /// Returns a live stream of all SlotFound events emitted by this contract.
  Stream<SlotFound> slotFoundEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('SlotFound');
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
      return SlotFound(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all WARNING_UninitedSlot events emitted by this contract.
  Stream<WARNING_UninitedSlot> wARNING_UninitedSlotEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('WARNING_UninitedSlot');
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
      return WARNING_UninitedSlot(
        decoded,
        result,
      );
    });
  }
}

class SlotFound {
  SlotFound(
    List<dynamic> response,
    this.event,
  )   : who = (response[0] as _i2.EthereumAddress),
        fsig = (response[1] as _i3.Uint8List),
        keysHash = (response[2] as _i3.Uint8List),
        slot = (response[3] as BigInt);

  final _i2.EthereumAddress who;

  final _i3.Uint8List fsig;

  final _i3.Uint8List keysHash;

  final BigInt slot;

  final _i1.FilterEvent event;
}

class WARNING_UninitedSlot {
  WARNING_UninitedSlot(
    List<dynamic> response,
    this.event,
  )   : who = (response[0] as _i2.EthereumAddress),
        slot = (response[1] as BigInt);

  final _i2.EthereumAddress who;

  final BigInt slot;

  final _i1.FilterEvent event;
}
