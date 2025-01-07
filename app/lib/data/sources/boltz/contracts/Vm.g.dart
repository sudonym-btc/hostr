// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"type":"function","name":"accesses","inputs":[{"name":"target","type":"address","internalType":"address"}],"outputs":[{"name":"readSlots","type":"bytes32[]","internalType":"bytes32[]"},{"name":"writeSlots","type":"bytes32[]","internalType":"bytes32[]"}],"stateMutability":"nonpayable"},{"type":"function","name":"activeFork","inputs":[],"outputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"addr","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"keyAddr","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"allowCheatcodes","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"assertApproxEqAbs","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqAbs","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqAbs","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqAbs","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqAbsDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqAbsDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqAbsDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqAbsDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRel","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRel","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRel","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRel","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRelDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRelDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRelDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertApproxEqRelDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"maxPercentDelta","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes32[]","internalType":"bytes32[]"},{"name":"right","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"int256[]","internalType":"int256[]"},{"name":"right","type":"int256[]","internalType":"int256[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"address","internalType":"address"},{"name":"right","type":"address","internalType":"address"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"string","internalType":"string"},{"name":"right","type":"string","internalType":"string"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"address[]","internalType":"address[]"},{"name":"right","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"address[]","internalType":"address[]"},{"name":"right","type":"address[]","internalType":"address[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bool","internalType":"bool"},{"name":"right","type":"bool","internalType":"bool"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"address","internalType":"address"},{"name":"right","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"uint256[]","internalType":"uint256[]"},{"name":"right","type":"uint256[]","internalType":"uint256[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bool[]","internalType":"bool[]"},{"name":"right","type":"bool[]","internalType":"bool[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"int256[]","internalType":"int256[]"},{"name":"right","type":"int256[]","internalType":"int256[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes32","internalType":"bytes32"},{"name":"right","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"uint256[]","internalType":"uint256[]"},{"name":"right","type":"uint256[]","internalType":"uint256[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes","internalType":"bytes"},{"name":"right","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes32","internalType":"bytes32"},{"name":"right","type":"bytes32","internalType":"bytes32"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"string[]","internalType":"string[]"},{"name":"right","type":"string[]","internalType":"string[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes32[]","internalType":"bytes32[]"},{"name":"right","type":"bytes32[]","internalType":"bytes32[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes","internalType":"bytes"},{"name":"right","type":"bytes","internalType":"bytes"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bool[]","internalType":"bool[]"},{"name":"right","type":"bool[]","internalType":"bool[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes[]","internalType":"bytes[]"},{"name":"right","type":"bytes[]","internalType":"bytes[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"string[]","internalType":"string[]"},{"name":"right","type":"string[]","internalType":"string[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"string","internalType":"string"},{"name":"right","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bytes[]","internalType":"bytes[]"},{"name":"right","type":"bytes[]","internalType":"bytes[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"bool","internalType":"bool"},{"name":"right","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEq","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEqDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEqDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEqDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertEqDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertFalse","inputs":[{"name":"condition","type":"bool","internalType":"bool"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertFalse","inputs":[{"name":"condition","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGe","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGe","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGe","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGe","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGeDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGeDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGeDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGeDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGt","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGt","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGt","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGt","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGtDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGtDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGtDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertGtDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLe","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLe","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLe","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLe","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLeDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLeDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLeDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLeDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLt","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLt","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLt","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLt","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLtDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLtDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLtDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertLtDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes32[]","internalType":"bytes32[]"},{"name":"right","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"int256[]","internalType":"int256[]"},{"name":"right","type":"int256[]","internalType":"int256[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bool","internalType":"bool"},{"name":"right","type":"bool","internalType":"bool"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes[]","internalType":"bytes[]"},{"name":"right","type":"bytes[]","internalType":"bytes[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bool","internalType":"bool"},{"name":"right","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bool[]","internalType":"bool[]"},{"name":"right","type":"bool[]","internalType":"bool[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes","internalType":"bytes"},{"name":"right","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"address[]","internalType":"address[]"},{"name":"right","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"uint256[]","internalType":"uint256[]"},{"name":"right","type":"uint256[]","internalType":"uint256[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bool[]","internalType":"bool[]"},{"name":"right","type":"bool[]","internalType":"bool[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"string","internalType":"string"},{"name":"right","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"address[]","internalType":"address[]"},{"name":"right","type":"address[]","internalType":"address[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"string","internalType":"string"},{"name":"right","type":"string","internalType":"string"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"address","internalType":"address"},{"name":"right","type":"address","internalType":"address"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes32","internalType":"bytes32"},{"name":"right","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes","internalType":"bytes"},{"name":"right","type":"bytes","internalType":"bytes"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"uint256[]","internalType":"uint256[]"},{"name":"right","type":"uint256[]","internalType":"uint256[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"address","internalType":"address"},{"name":"right","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes32","internalType":"bytes32"},{"name":"right","type":"bytes32","internalType":"bytes32"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"string[]","internalType":"string[]"},{"name":"right","type":"string[]","internalType":"string[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes32[]","internalType":"bytes32[]"},{"name":"right","type":"bytes32[]","internalType":"bytes32[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"string[]","internalType":"string[]"},{"name":"right","type":"string[]","internalType":"string[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"int256[]","internalType":"int256[]"},{"name":"right","type":"int256[]","internalType":"int256[]"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"bytes[]","internalType":"bytes[]"},{"name":"right","type":"bytes[]","internalType":"bytes[]"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEq","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEqDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEqDecimal","inputs":[{"name":"left","type":"int256","internalType":"int256"},{"name":"right","type":"int256","internalType":"int256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEqDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertNotEqDecimal","inputs":[{"name":"left","type":"uint256","internalType":"uint256"},{"name":"right","type":"uint256","internalType":"uint256"},{"name":"decimals","type":"uint256","internalType":"uint256"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertTrue","inputs":[{"name":"condition","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assertTrue","inputs":[{"name":"condition","type":"bool","internalType":"bool"},{"name":"error","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assume","inputs":[{"name":"condition","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"assumeNoRevert","inputs":[],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"blobBaseFee","inputs":[{"name":"newBlobBaseFee","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"blobhashes","inputs":[{"name":"hashes","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"breakpoint","inputs":[{"name":"char","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"breakpoint","inputs":[{"name":"char","type":"string","internalType":"string"},{"name":"value","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"pure"},{"type":"function","name":"broadcast","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"broadcast","inputs":[{"name":"signer","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"broadcast","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"broadcastRawTransaction","inputs":[{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"chainId","inputs":[{"name":"newChainId","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"clearMockedCalls","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"cloneAccount","inputs":[{"name":"source","type":"address","internalType":"address"},{"name":"target","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"closeFile","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"coinbase","inputs":[{"name":"newCoinbase","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"computeCreate2Address","inputs":[{"name":"salt","type":"bytes32","internalType":"bytes32"},{"name":"initCodeHash","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"computeCreate2Address","inputs":[{"name":"salt","type":"bytes32","internalType":"bytes32"},{"name":"initCodeHash","type":"bytes32","internalType":"bytes32"},{"name":"deployer","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"computeCreateAddress","inputs":[{"name":"deployer","type":"address","internalType":"address"},{"name":"nonce","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"copyFile","inputs":[{"name":"from","type":"string","internalType":"string"},{"name":"to","type":"string","internalType":"string"}],"outputs":[{"name":"copied","type":"uint64","internalType":"uint64"}],"stateMutability":"nonpayable"},{"type":"function","name":"copyStorage","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"createDir","inputs":[{"name":"path","type":"string","internalType":"string"},{"name":"recursive","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"createFork","inputs":[{"name":"urlOrAlias","type":"string","internalType":"string"}],"outputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"createFork","inputs":[{"name":"urlOrAlias","type":"string","internalType":"string"},{"name":"blockNumber","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"createFork","inputs":[{"name":"urlOrAlias","type":"string","internalType":"string"},{"name":"txHash","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"createSelectFork","inputs":[{"name":"urlOrAlias","type":"string","internalType":"string"},{"name":"blockNumber","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"createSelectFork","inputs":[{"name":"urlOrAlias","type":"string","internalType":"string"},{"name":"txHash","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"createSelectFork","inputs":[{"name":"urlOrAlias","type":"string","internalType":"string"}],"outputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"createWallet","inputs":[{"name":"walletLabel","type":"string","internalType":"string"}],"outputs":[{"name":"wallet","type":"tuple","internalType":"struct VmSafe.Wallet","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"publicKeyX","type":"uint256","internalType":"uint256"},{"name":"publicKeyY","type":"uint256","internalType":"uint256"},{"name":"privateKey","type":"uint256","internalType":"uint256"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"createWallet","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"wallet","type":"tuple","internalType":"struct VmSafe.Wallet","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"publicKeyX","type":"uint256","internalType":"uint256"},{"name":"publicKeyY","type":"uint256","internalType":"uint256"},{"name":"privateKey","type":"uint256","internalType":"uint256"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"createWallet","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"walletLabel","type":"string","internalType":"string"}],"outputs":[{"name":"wallet","type":"tuple","internalType":"struct VmSafe.Wallet","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"publicKeyX","type":"uint256","internalType":"uint256"},{"name":"publicKeyY","type":"uint256","internalType":"uint256"},{"name":"privateKey","type":"uint256","internalType":"uint256"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"deal","inputs":[{"name":"account","type":"address","internalType":"address"},{"name":"newBalance","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"deleteSnapshot","inputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"success","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"deleteSnapshots","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"deleteStateSnapshot","inputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"success","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"deleteStateSnapshots","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"deployCode","inputs":[{"name":"artifactPath","type":"string","internalType":"string"},{"name":"constructorArgs","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"deployedAddress","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"deployCode","inputs":[{"name":"artifactPath","type":"string","internalType":"string"}],"outputs":[{"name":"deployedAddress","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"deriveKey","inputs":[{"name":"mnemonic","type":"string","internalType":"string"},{"name":"derivationPath","type":"string","internalType":"string"},{"name":"index","type":"uint32","internalType":"uint32"},{"name":"language","type":"string","internalType":"string"}],"outputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"deriveKey","inputs":[{"name":"mnemonic","type":"string","internalType":"string"},{"name":"index","type":"uint32","internalType":"uint32"},{"name":"language","type":"string","internalType":"string"}],"outputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"deriveKey","inputs":[{"name":"mnemonic","type":"string","internalType":"string"},{"name":"index","type":"uint32","internalType":"uint32"}],"outputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"deriveKey","inputs":[{"name":"mnemonic","type":"string","internalType":"string"},{"name":"derivationPath","type":"string","internalType":"string"},{"name":"index","type":"uint32","internalType":"uint32"}],"outputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"difficulty","inputs":[{"name":"newDifficulty","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"dumpState","inputs":[{"name":"pathToStateJson","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"ensNamehash","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"envAddress","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"envAddress","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"envBool","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"envBool","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"bool[]","internalType":"bool[]"}],"stateMutability":"view"},{"type":"function","name":"envBytes","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"envBytes","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"bytes[]","internalType":"bytes[]"}],"stateMutability":"view"},{"type":"function","name":"envBytes32","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"bytes32[]","internalType":"bytes32[]"}],"stateMutability":"view"},{"type":"function","name":"envBytes32","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"envExists","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"result","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"envInt","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"int256[]","internalType":"int256[]"}],"stateMutability":"view"},{"type":"function","name":"envInt","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"int256","internalType":"int256"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"},{"name":"defaultValue","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[{"name":"value","type":"bytes32[]","internalType":"bytes32[]"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"},{"name":"defaultValue","type":"int256[]","internalType":"int256[]"}],"outputs":[{"name":"value","type":"int256[]","internalType":"int256[]"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"defaultValue","type":"bool","internalType":"bool"}],"outputs":[{"name":"value","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"defaultValue","type":"address","internalType":"address"}],"outputs":[{"name":"value","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"defaultValue","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"value","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"},{"name":"defaultValue","type":"bytes[]","internalType":"bytes[]"}],"outputs":[{"name":"value","type":"bytes[]","internalType":"bytes[]"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"},{"name":"defaultValue","type":"uint256[]","internalType":"uint256[]"}],"outputs":[{"name":"value","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"},{"name":"defaultValue","type":"string[]","internalType":"string[]"}],"outputs":[{"name":"value","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"defaultValue","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"value","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"defaultValue","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"value","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"defaultValue","type":"int256","internalType":"int256"}],"outputs":[{"name":"value","type":"int256","internalType":"int256"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"},{"name":"defaultValue","type":"address[]","internalType":"address[]"}],"outputs":[{"name":"value","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"defaultValue","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"envOr","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"},{"name":"defaultValue","type":"bool[]","internalType":"bool[]"}],"outputs":[{"name":"value","type":"bool[]","internalType":"bool[]"}],"stateMutability":"view"},{"type":"function","name":"envString","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"string[]","internalType":"string[]"}],"stateMutability":"view"},{"type":"function","name":"envString","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"envUint","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"envUint","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"delim","type":"string","internalType":"string"}],"outputs":[{"name":"value","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"view"},{"type":"function","name":"etch","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"newRuntimeBytecode","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"eth_getLogs","inputs":[{"name":"fromBlock","type":"uint256","internalType":"uint256"},{"name":"toBlock","type":"uint256","internalType":"uint256"},{"name":"target","type":"address","internalType":"address"},{"name":"topics","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[{"name":"logs","type":"tuple[]","internalType":"struct VmSafe.EthGetLogs[]","components":[{"name":"emitter","type":"address","internalType":"address"},{"name":"topics","type":"bytes32[]","internalType":"bytes32[]"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"blockHash","type":"bytes32","internalType":"bytes32"},{"name":"blockNumber","type":"uint64","internalType":"uint64"},{"name":"transactionHash","type":"bytes32","internalType":"bytes32"},{"name":"transactionIndex","type":"uint64","internalType":"uint64"},{"name":"logIndex","type":"uint256","internalType":"uint256"},{"name":"removed","type":"bool","internalType":"bool"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"exists","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"result","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"expectCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"gas","type":"uint64","internalType":"uint64"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"gas","type":"uint64","internalType":"uint64"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"count","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"count","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"count","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectCallMinGas","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"minGas","type":"uint64","internalType":"uint64"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectCallMinGas","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"minGas","type":"uint64","internalType":"uint64"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"count","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmit","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmit","inputs":[{"name":"checkTopic1","type":"bool","internalType":"bool"},{"name":"checkTopic2","type":"bool","internalType":"bool"},{"name":"checkTopic3","type":"bool","internalType":"bool"},{"name":"checkData","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmit","inputs":[{"name":"checkTopic1","type":"bool","internalType":"bool"},{"name":"checkTopic2","type":"bool","internalType":"bool"},{"name":"checkTopic3","type":"bool","internalType":"bool"},{"name":"checkData","type":"bool","internalType":"bool"},{"name":"emitter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmit","inputs":[{"name":"emitter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmitAnonymous","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmitAnonymous","inputs":[{"name":"emitter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmitAnonymous","inputs":[{"name":"checkTopic0","type":"bool","internalType":"bool"},{"name":"checkTopic1","type":"bool","internalType":"bool"},{"name":"checkTopic2","type":"bool","internalType":"bool"},{"name":"checkTopic3","type":"bool","internalType":"bool"},{"name":"checkData","type":"bool","internalType":"bool"},{"name":"emitter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectEmitAnonymous","inputs":[{"name":"checkTopic0","type":"bool","internalType":"bool"},{"name":"checkTopic1","type":"bool","internalType":"bool"},{"name":"checkTopic2","type":"bool","internalType":"bool"},{"name":"checkTopic3","type":"bool","internalType":"bool"},{"name":"checkData","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectPartialRevert","inputs":[{"name":"revertData","type":"bytes4","internalType":"bytes4"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectPartialRevert","inputs":[{"name":"revertData","type":"bytes4","internalType":"bytes4"},{"name":"reverter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectRevert","inputs":[{"name":"revertData","type":"bytes4","internalType":"bytes4"},{"name":"reverter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectRevert","inputs":[{"name":"revertData","type":"bytes","internalType":"bytes"},{"name":"reverter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectRevert","inputs":[{"name":"revertData","type":"bytes4","internalType":"bytes4"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectRevert","inputs":[{"name":"reverter","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectRevert","inputs":[{"name":"revertData","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectRevert","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectSafeMemory","inputs":[{"name":"min","type":"uint64","internalType":"uint64"},{"name":"max","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"expectSafeMemoryCall","inputs":[{"name":"min","type":"uint64","internalType":"uint64"},{"name":"max","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"fee","inputs":[{"name":"newBasefee","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"ffi","inputs":[{"name":"commandInput","type":"string[]","internalType":"string[]"}],"outputs":[{"name":"result","type":"bytes","internalType":"bytes"}],"stateMutability":"nonpayable"},{"type":"function","name":"fsMetadata","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"metadata","type":"tuple","internalType":"struct VmSafe.FsMetadata","components":[{"name":"isDir","type":"bool","internalType":"bool"},{"name":"isSymlink","type":"bool","internalType":"bool"},{"name":"length","type":"uint256","internalType":"uint256"},{"name":"readOnly","type":"bool","internalType":"bool"},{"name":"modified","type":"uint256","internalType":"uint256"},{"name":"accessed","type":"uint256","internalType":"uint256"},{"name":"created","type":"uint256","internalType":"uint256"}]}],"stateMutability":"view"},{"type":"function","name":"getArtifactPathByCode","inputs":[{"name":"code","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"path","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"getArtifactPathByDeployedCode","inputs":[{"name":"deployedCode","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"path","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"getBlobBaseFee","inputs":[],"outputs":[{"name":"blobBaseFee","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getBlobhashes","inputs":[],"outputs":[{"name":"hashes","type":"bytes32[]","internalType":"bytes32[]"}],"stateMutability":"view"},{"type":"function","name":"getBlockNumber","inputs":[],"outputs":[{"name":"height","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getBlockTimestamp","inputs":[],"outputs":[{"name":"timestamp","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getCode","inputs":[{"name":"artifactPath","type":"string","internalType":"string"}],"outputs":[{"name":"creationBytecode","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"getDeployedCode","inputs":[{"name":"artifactPath","type":"string","internalType":"string"}],"outputs":[{"name":"runtimeBytecode","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"getFoundryVersion","inputs":[],"outputs":[{"name":"version","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"getLabel","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"currentLabel","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"getMappingKeyAndParentOf","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"elementSlot","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"found","type":"bool","internalType":"bool"},{"name":"key","type":"bytes32","internalType":"bytes32"},{"name":"parent","type":"bytes32","internalType":"bytes32"}],"stateMutability":"nonpayable"},{"type":"function","name":"getMappingLength","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"mappingSlot","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"length","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"getMappingSlotAt","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"mappingSlot","type":"bytes32","internalType":"bytes32"},{"name":"idx","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"value","type":"bytes32","internalType":"bytes32"}],"stateMutability":"nonpayable"},{"type":"function","name":"getNonce","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"nonce","type":"uint64","internalType":"uint64"}],"stateMutability":"view"},{"type":"function","name":"getNonce","inputs":[{"name":"wallet","type":"tuple","internalType":"struct VmSafe.Wallet","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"publicKeyX","type":"uint256","internalType":"uint256"},{"name":"publicKeyY","type":"uint256","internalType":"uint256"},{"name":"privateKey","type":"uint256","internalType":"uint256"}]}],"outputs":[{"name":"nonce","type":"uint64","internalType":"uint64"}],"stateMutability":"nonpayable"},{"type":"function","name":"getRecordedLogs","inputs":[],"outputs":[{"name":"logs","type":"tuple[]","internalType":"struct VmSafe.Log[]","components":[{"name":"topics","type":"bytes32[]","internalType":"bytes32[]"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"emitter","type":"address","internalType":"address"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"getScriptWallets","inputs":[],"outputs":[{"name":"wallets","type":"address[]","internalType":"address[]"}],"stateMutability":"nonpayable"},{"type":"function","name":"getWallets","inputs":[],"outputs":[{"name":"wallets","type":"address[]","internalType":"address[]"}],"stateMutability":"nonpayable"},{"type":"function","name":"indexOf","inputs":[{"name":"input","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"isContext","inputs":[{"name":"context","type":"uint8","internalType":"enum VmSafe.ForgeContext"}],"outputs":[{"name":"result","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"isDir","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"result","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"isFile","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"result","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"isPersistent","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"persistent","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"keyExists","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"keyExistsJson","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"keyExistsToml","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"label","inputs":[{"name":"account","type":"address","internalType":"address"},{"name":"newLabel","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"lastCallGas","inputs":[],"outputs":[{"name":"gas","type":"tuple","internalType":"struct VmSafe.Gas","components":[{"name":"gasLimit","type":"uint64","internalType":"uint64"},{"name":"gasTotalUsed","type":"uint64","internalType":"uint64"},{"name":"gasMemoryUsed","type":"uint64","internalType":"uint64"},{"name":"gasRefunded","type":"int64","internalType":"int64"},{"name":"gasRemaining","type":"uint64","internalType":"uint64"}]}],"stateMutability":"view"},{"type":"function","name":"load","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"slot","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"data","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"loadAllocs","inputs":[{"name":"pathToAllocsJson","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"makePersistent","inputs":[{"name":"accounts","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"makePersistent","inputs":[{"name":"account0","type":"address","internalType":"address"},{"name":"account1","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"makePersistent","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"makePersistent","inputs":[{"name":"account0","type":"address","internalType":"address"},{"name":"account1","type":"address","internalType":"address"},{"name":"account2","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"mockCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"returnData","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"mockCall","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"returnData","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"mockCallRevert","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"revertData","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"mockCallRevert","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"revertData","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"mockCalls","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"msgValue","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"returnData","type":"bytes[]","internalType":"bytes[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"mockCalls","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"returnData","type":"bytes[]","internalType":"bytes[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"mockFunction","inputs":[{"name":"callee","type":"address","internalType":"address"},{"name":"target","type":"address","internalType":"address"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"parseAddress","inputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"outputs":[{"name":"parsedValue","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"parseBool","inputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"outputs":[{"name":"parsedValue","type":"bool","internalType":"bool"}],"stateMutability":"pure"},{"type":"function","name":"parseBytes","inputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"outputs":[{"name":"parsedValue","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseBytes32","inputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"outputs":[{"name":"parsedValue","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"parseInt","inputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"outputs":[{"name":"parsedValue","type":"int256","internalType":"int256"}],"stateMutability":"pure"},{"type":"function","name":"parseJson","inputs":[{"name":"json","type":"string","internalType":"string"}],"outputs":[{"name":"abiEncodedData","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseJson","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"abiEncodedData","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonAddress","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonAddressArray","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonBool","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonBoolArray","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool[]","internalType":"bool[]"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonBytes","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonBytes32","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonBytes32Array","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes32[]","internalType":"bytes32[]"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonBytesArray","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes[]","internalType":"bytes[]"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonInt","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"int256","internalType":"int256"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonIntArray","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"int256[]","internalType":"int256[]"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonKeys","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"keys","type":"string[]","internalType":"string[]"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonString","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonStringArray","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"string[]","internalType":"string[]"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonType","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"typeDescription","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonType","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"},{"name":"typeDescription","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonTypeArray","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"},{"name":"typeDescription","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonUint","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"parseJsonUintArray","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"pure"},{"type":"function","name":"parseToml","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"abiEncodedData","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseToml","inputs":[{"name":"toml","type":"string","internalType":"string"}],"outputs":[{"name":"abiEncodedData","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlAddress","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlAddressArray","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlBool","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlBoolArray","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bool[]","internalType":"bool[]"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlBytes","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlBytes32","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlBytes32Array","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes32[]","internalType":"bytes32[]"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlBytesArray","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes[]","internalType":"bytes[]"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlInt","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"int256","internalType":"int256"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlIntArray","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"int256[]","internalType":"int256[]"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlKeys","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"keys","type":"string[]","internalType":"string[]"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlString","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlStringArray","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"string[]","internalType":"string[]"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlType","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"typeDescription","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlType","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"},{"name":"typeDescription","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlTypeArray","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"},{"name":"typeDescription","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlUint","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"parseTomlUintArray","inputs":[{"name":"toml","type":"string","internalType":"string"},{"name":"key","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256[]","internalType":"uint256[]"}],"stateMutability":"pure"},{"type":"function","name":"parseUint","inputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"outputs":[{"name":"parsedValue","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"pauseGasMetering","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"pauseTracing","inputs":[],"outputs":[],"stateMutability":"view"},{"type":"function","name":"prank","inputs":[{"name":"msgSender","type":"address","internalType":"address"},{"name":"txOrigin","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"prank","inputs":[{"name":"msgSender","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"prevrandao","inputs":[{"name":"newPrevrandao","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"prevrandao","inputs":[{"name":"newPrevrandao","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"projectRoot","inputs":[],"outputs":[{"name":"path","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"prompt","inputs":[{"name":"promptText","type":"string","internalType":"string"}],"outputs":[{"name":"input","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"promptAddress","inputs":[{"name":"promptText","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"promptSecret","inputs":[{"name":"promptText","type":"string","internalType":"string"}],"outputs":[{"name":"input","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"promptSecretUint","inputs":[{"name":"promptText","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"promptUint","inputs":[{"name":"promptText","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"publicKeyP256","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"publicKeyX","type":"uint256","internalType":"uint256"},{"name":"publicKeyY","type":"uint256","internalType":"uint256"}],"stateMutability":"pure"},{"type":"function","name":"randomAddress","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"randomBool","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"randomBytes","inputs":[{"name":"len","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"randomBytes4","inputs":[],"outputs":[{"name":"","type":"bytes4","internalType":"bytes4"}],"stateMutability":"view"},{"type":"function","name":"randomBytes8","inputs":[],"outputs":[{"name":"","type":"bytes8","internalType":"bytes8"}],"stateMutability":"view"},{"type":"function","name":"randomInt","inputs":[],"outputs":[{"name":"","type":"int256","internalType":"int256"}],"stateMutability":"view"},{"type":"function","name":"randomInt","inputs":[{"name":"bits","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"int256","internalType":"int256"}],"stateMutability":"view"},{"type":"function","name":"randomUint","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"randomUint","inputs":[{"name":"bits","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"randomUint","inputs":[{"name":"min","type":"uint256","internalType":"uint256"},{"name":"max","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"readCallers","inputs":[],"outputs":[{"name":"callerMode","type":"uint8","internalType":"enum VmSafe.CallerMode"},{"name":"msgSender","type":"address","internalType":"address"},{"name":"txOrigin","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"readDir","inputs":[{"name":"path","type":"string","internalType":"string"},{"name":"maxDepth","type":"uint64","internalType":"uint64"}],"outputs":[{"name":"entries","type":"tuple[]","internalType":"struct VmSafe.DirEntry[]","components":[{"name":"errorMessage","type":"string","internalType":"string"},{"name":"path","type":"string","internalType":"string"},{"name":"depth","type":"uint64","internalType":"uint64"},{"name":"isDir","type":"bool","internalType":"bool"},{"name":"isSymlink","type":"bool","internalType":"bool"}]}],"stateMutability":"view"},{"type":"function","name":"readDir","inputs":[{"name":"path","type":"string","internalType":"string"},{"name":"maxDepth","type":"uint64","internalType":"uint64"},{"name":"followLinks","type":"bool","internalType":"bool"}],"outputs":[{"name":"entries","type":"tuple[]","internalType":"struct VmSafe.DirEntry[]","components":[{"name":"errorMessage","type":"string","internalType":"string"},{"name":"path","type":"string","internalType":"string"},{"name":"depth","type":"uint64","internalType":"uint64"},{"name":"isDir","type":"bool","internalType":"bool"},{"name":"isSymlink","type":"bool","internalType":"bool"}]}],"stateMutability":"view"},{"type":"function","name":"readDir","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"entries","type":"tuple[]","internalType":"struct VmSafe.DirEntry[]","components":[{"name":"errorMessage","type":"string","internalType":"string"},{"name":"path","type":"string","internalType":"string"},{"name":"depth","type":"uint64","internalType":"uint64"},{"name":"isDir","type":"bool","internalType":"bool"},{"name":"isSymlink","type":"bool","internalType":"bool"}]}],"stateMutability":"view"},{"type":"function","name":"readFile","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"data","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"readFileBinary","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"data","type":"bytes","internalType":"bytes"}],"stateMutability":"view"},{"type":"function","name":"readLine","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[{"name":"line","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"readLink","inputs":[{"name":"linkPath","type":"string","internalType":"string"}],"outputs":[{"name":"targetPath","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"record","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"recordLogs","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"rememberKey","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"keyAddr","type":"address","internalType":"address"}],"stateMutability":"nonpayable"},{"type":"function","name":"rememberKeys","inputs":[{"name":"mnemonic","type":"string","internalType":"string"},{"name":"derivationPath","type":"string","internalType":"string"},{"name":"count","type":"uint32","internalType":"uint32"}],"outputs":[{"name":"keyAddrs","type":"address[]","internalType":"address[]"}],"stateMutability":"nonpayable"},{"type":"function","name":"rememberKeys","inputs":[{"name":"mnemonic","type":"string","internalType":"string"},{"name":"derivationPath","type":"string","internalType":"string"},{"name":"language","type":"string","internalType":"string"},{"name":"count","type":"uint32","internalType":"uint32"}],"outputs":[{"name":"keyAddrs","type":"address[]","internalType":"address[]"}],"stateMutability":"nonpayable"},{"type":"function","name":"removeDir","inputs":[{"name":"path","type":"string","internalType":"string"},{"name":"recursive","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"removeFile","inputs":[{"name":"path","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"replace","inputs":[{"name":"input","type":"string","internalType":"string"},{"name":"from","type":"string","internalType":"string"},{"name":"to","type":"string","internalType":"string"}],"outputs":[{"name":"output","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"resetGasMetering","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"resetNonce","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"resumeGasMetering","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"resumeTracing","inputs":[],"outputs":[],"stateMutability":"view"},{"type":"function","name":"revertTo","inputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"success","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"revertToAndDelete","inputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"success","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"revertToState","inputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"success","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"revertToStateAndDelete","inputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"success","type":"bool","internalType":"bool"}],"stateMutability":"nonpayable"},{"type":"function","name":"revokePersistent","inputs":[{"name":"accounts","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"revokePersistent","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"roll","inputs":[{"name":"newHeight","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"rollFork","inputs":[{"name":"txHash","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"rollFork","inputs":[{"name":"forkId","type":"uint256","internalType":"uint256"},{"name":"blockNumber","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"rollFork","inputs":[{"name":"blockNumber","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"rollFork","inputs":[{"name":"forkId","type":"uint256","internalType":"uint256"},{"name":"txHash","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"rpc","inputs":[{"name":"urlOrAlias","type":"string","internalType":"string"},{"name":"method","type":"string","internalType":"string"},{"name":"params","type":"string","internalType":"string"}],"outputs":[{"name":"data","type":"bytes","internalType":"bytes"}],"stateMutability":"nonpayable"},{"type":"function","name":"rpc","inputs":[{"name":"method","type":"string","internalType":"string"},{"name":"params","type":"string","internalType":"string"}],"outputs":[{"name":"data","type":"bytes","internalType":"bytes"}],"stateMutability":"nonpayable"},{"type":"function","name":"rpcUrl","inputs":[{"name":"rpcAlias","type":"string","internalType":"string"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"view"},{"type":"function","name":"rpcUrlStructs","inputs":[],"outputs":[{"name":"urls","type":"tuple[]","internalType":"struct VmSafe.Rpc[]","components":[{"name":"key","type":"string","internalType":"string"},{"name":"url","type":"string","internalType":"string"}]}],"stateMutability":"view"},{"type":"function","name":"rpcUrls","inputs":[],"outputs":[{"name":"urls","type":"string[2][]","internalType":"string[2][]"}],"stateMutability":"view"},{"type":"function","name":"selectFork","inputs":[{"name":"forkId","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"serializeAddress","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"values","type":"address[]","internalType":"address[]"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeAddress","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"address","internalType":"address"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeBool","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"values","type":"bool[]","internalType":"bool[]"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeBool","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"bool","internalType":"bool"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeBytes","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"values","type":"bytes[]","internalType":"bytes[]"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeBytes","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeBytes32","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"values","type":"bytes32[]","internalType":"bytes32[]"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeBytes32","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeInt","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"int256","internalType":"int256"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeInt","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"values","type":"int256[]","internalType":"int256[]"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeJson","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"value","type":"string","internalType":"string"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeJsonType","inputs":[{"name":"typeDescription","type":"string","internalType":"string"},{"name":"value","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"serializeJsonType","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"typeDescription","type":"string","internalType":"string"},{"name":"value","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeString","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"values","type":"string[]","internalType":"string[]"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeString","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"string","internalType":"string"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeUint","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeUint","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"values","type":"uint256[]","internalType":"uint256[]"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"serializeUintToHex","inputs":[{"name":"objectKey","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"},{"name":"value","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"json","type":"string","internalType":"string"}],"stateMutability":"nonpayable"},{"type":"function","name":"setArbitraryStorage","inputs":[{"name":"target","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setBlockhash","inputs":[{"name":"blockNumber","type":"uint256","internalType":"uint256"},{"name":"blockHash","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setEnv","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"value","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setNonce","inputs":[{"name":"account","type":"address","internalType":"address"},{"name":"newNonce","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setNonceUnsafe","inputs":[{"name":"account","type":"address","internalType":"address"},{"name":"newNonce","type":"uint64","internalType":"uint64"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"sign","inputs":[{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"sign","inputs":[{"name":"signer","type":"address","internalType":"address"},{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"sign","inputs":[{"name":"wallet","type":"tuple","internalType":"struct VmSafe.Wallet","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"publicKeyX","type":"uint256","internalType":"uint256"},{"name":"publicKeyY","type":"uint256","internalType":"uint256"},{"name":"privateKey","type":"uint256","internalType":"uint256"}]},{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"stateMutability":"nonpayable"},{"type":"function","name":"sign","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"signCompact","inputs":[{"name":"wallet","type":"tuple","internalType":"struct VmSafe.Wallet","components":[{"name":"addr","type":"address","internalType":"address"},{"name":"publicKeyX","type":"uint256","internalType":"uint256"},{"name":"publicKeyY","type":"uint256","internalType":"uint256"},{"name":"privateKey","type":"uint256","internalType":"uint256"}]},{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"vs","type":"bytes32","internalType":"bytes32"}],"stateMutability":"nonpayable"},{"type":"function","name":"signCompact","inputs":[{"name":"signer","type":"address","internalType":"address"},{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"vs","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"signCompact","inputs":[{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"vs","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"signCompact","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"vs","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"signP256","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"},{"name":"digest","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"skip","inputs":[{"name":"skipTest","type":"bool","internalType":"bool"},{"name":"reason","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"skip","inputs":[{"name":"skipTest","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"sleep","inputs":[{"name":"duration","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"snapshot","inputs":[],"outputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"snapshotGasLastCall","inputs":[{"name":"group","type":"string","internalType":"string"},{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"gasUsed","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"snapshotGasLastCall","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"gasUsed","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"snapshotState","inputs":[],"outputs":[{"name":"snapshotId","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"snapshotValue","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"value","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"snapshotValue","inputs":[{"name":"group","type":"string","internalType":"string"},{"name":"name","type":"string","internalType":"string"},{"name":"value","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"split","inputs":[{"name":"input","type":"string","internalType":"string"},{"name":"delimiter","type":"string","internalType":"string"}],"outputs":[{"name":"outputs","type":"string[]","internalType":"string[]"}],"stateMutability":"pure"},{"type":"function","name":"startBroadcast","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startBroadcast","inputs":[{"name":"signer","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startBroadcast","inputs":[{"name":"privateKey","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startDebugTraceRecording","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startMappingRecording","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startPrank","inputs":[{"name":"msgSender","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startPrank","inputs":[{"name":"msgSender","type":"address","internalType":"address"},{"name":"txOrigin","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startSnapshotGas","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startSnapshotGas","inputs":[{"name":"group","type":"string","internalType":"string"},{"name":"name","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"startStateDiffRecording","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"stopAndReturnDebugTraceRecording","inputs":[],"outputs":[{"name":"step","type":"tuple[]","internalType":"struct VmSafe.DebugStep[]","components":[{"name":"stack","type":"uint256[]","internalType":"uint256[]"},{"name":"memoryInput","type":"bytes","internalType":"bytes"},{"name":"opcode","type":"uint8","internalType":"uint8"},{"name":"depth","type":"uint64","internalType":"uint64"},{"name":"isOutOfGas","type":"bool","internalType":"bool"},{"name":"contractAddr","type":"address","internalType":"address"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"stopAndReturnStateDiff","inputs":[],"outputs":[{"name":"accountAccesses","type":"tuple[]","internalType":"struct VmSafe.AccountAccess[]","components":[{"name":"chainInfo","type":"tuple","internalType":"struct VmSafe.ChainInfo","components":[{"name":"forkId","type":"uint256","internalType":"uint256"},{"name":"chainId","type":"uint256","internalType":"uint256"}]},{"name":"kind","type":"uint8","internalType":"enum VmSafe.AccountAccessKind"},{"name":"account","type":"address","internalType":"address"},{"name":"accessor","type":"address","internalType":"address"},{"name":"initialized","type":"bool","internalType":"bool"},{"name":"oldBalance","type":"uint256","internalType":"uint256"},{"name":"newBalance","type":"uint256","internalType":"uint256"},{"name":"deployedCode","type":"bytes","internalType":"bytes"},{"name":"value","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"},{"name":"reverted","type":"bool","internalType":"bool"},{"name":"storageAccesses","type":"tuple[]","internalType":"struct VmSafe.StorageAccess[]","components":[{"name":"account","type":"address","internalType":"address"},{"name":"slot","type":"bytes32","internalType":"bytes32"},{"name":"isWrite","type":"bool","internalType":"bool"},{"name":"previousValue","type":"bytes32","internalType":"bytes32"},{"name":"newValue","type":"bytes32","internalType":"bytes32"},{"name":"reverted","type":"bool","internalType":"bool"}]},{"name":"depth","type":"uint64","internalType":"uint64"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"stopBroadcast","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"stopExpectSafeMemory","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"stopMappingRecording","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"stopPrank","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"stopSnapshotGas","inputs":[{"name":"group","type":"string","internalType":"string"},{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"gasUsed","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"stopSnapshotGas","inputs":[{"name":"name","type":"string","internalType":"string"}],"outputs":[{"name":"gasUsed","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"stopSnapshotGas","inputs":[],"outputs":[{"name":"gasUsed","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"store","inputs":[{"name":"target","type":"address","internalType":"address"},{"name":"slot","type":"bytes32","internalType":"bytes32"},{"name":"value","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"toBase64","inputs":[{"name":"data","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toBase64","inputs":[{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toBase64URL","inputs":[{"name":"data","type":"string","internalType":"string"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toBase64URL","inputs":[{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toLowercase","inputs":[{"name":"input","type":"string","internalType":"string"}],"outputs":[{"name":"output","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toString","inputs":[{"name":"value","type":"address","internalType":"address"}],"outputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toString","inputs":[{"name":"value","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toString","inputs":[{"name":"value","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toString","inputs":[{"name":"value","type":"bool","internalType":"bool"}],"outputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toString","inputs":[{"name":"value","type":"int256","internalType":"int256"}],"outputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toString","inputs":[{"name":"value","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"stringifiedValue","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"toUppercase","inputs":[{"name":"input","type":"string","internalType":"string"}],"outputs":[{"name":"output","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"transact","inputs":[{"name":"forkId","type":"uint256","internalType":"uint256"},{"name":"txHash","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"transact","inputs":[{"name":"txHash","type":"bytes32","internalType":"bytes32"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"trim","inputs":[{"name":"input","type":"string","internalType":"string"}],"outputs":[{"name":"output","type":"string","internalType":"string"}],"stateMutability":"pure"},{"type":"function","name":"tryFfi","inputs":[{"name":"commandInput","type":"string[]","internalType":"string[]"}],"outputs":[{"name":"result","type":"tuple","internalType":"struct VmSafe.FfiResult","components":[{"name":"exitCode","type":"int32","internalType":"int32"},{"name":"stdout","type":"bytes","internalType":"bytes"},{"name":"stderr","type":"bytes","internalType":"bytes"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"txGasPrice","inputs":[{"name":"newGasPrice","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"unixTime","inputs":[],"outputs":[{"name":"milliseconds","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"warp","inputs":[{"name":"newTimestamp","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeFile","inputs":[{"name":"path","type":"string","internalType":"string"},{"name":"data","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeFileBinary","inputs":[{"name":"path","type":"string","internalType":"string"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeJson","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"path","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeJson","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"path","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeLine","inputs":[{"name":"path","type":"string","internalType":"string"},{"name":"data","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeToml","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"path","type":"string","internalType":"string"},{"name":"valueKey","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"writeToml","inputs":[{"name":"json","type":"string","internalType":"string"},{"name":"path","type":"string","internalType":"string"}],"outputs":[],"stateMutability":"nonpayable"}]',
  'Vm',
);

class Vm extends _i1.GeneratedContract {
  Vm({
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
  Future<String> accesses(
    ({_i1.EthereumAddress target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '65bc9481'));
    final params = [args.target];
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
  Future<BigInt> activeFork({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '2f103f22'));
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
  Future<_i1.EthereumAddress> addr(
    ({BigInt privateKey}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, 'ffa18649'));
    final params = [args.privateKey];
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
  Future<String> allowCheatcodes(
    ({_i1.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, 'ea060291'));
    final params = [args.account];
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
  Future<void> assertApproxEqAbs(
    ({BigInt left, BigInt right, BigInt maxDelta}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '16d207c6'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqAbs$2(
    ({BigInt left, BigInt right, BigInt maxDelta}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '240f839d'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqAbs$3(
    ({BigInt left, BigInt right, BigInt maxDelta, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '8289e621'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqAbs$4(
    ({BigInt left, BigInt right, BigInt maxDelta, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'f710b062'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqAbsDecimal(
    ({BigInt left, BigInt right, BigInt maxDelta, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '045c55ce'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqAbsDecimal$2(
    ({BigInt left, BigInt right, BigInt maxDelta, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '3d5bc8bc'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqAbsDecimal$3(
    ({
      BigInt left,
      BigInt right,
      BigInt maxDelta,
      BigInt decimals,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '60429eb2'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqAbsDecimal$4(
    ({
      BigInt left,
      BigInt right,
      BigInt maxDelta,
      BigInt decimals,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '6a5066d4'));
    final params = [
      args.left,
      args.right,
      args.maxDelta,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRel(
    ({BigInt left, BigInt right, BigInt maxPercentDelta, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '1ecb7d33'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRel$2(
    ({BigInt left, BigInt right, BigInt maxPercentDelta}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '8cf25ef4'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRel$3(
    ({BigInt left, BigInt right, BigInt maxPercentDelta, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, 'ef277d72'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRel$4(
    ({BigInt left, BigInt right, BigInt maxPercentDelta}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'fea2d14f'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRelDecimal(
    ({
      BigInt left,
      BigInt right,
      BigInt maxPercentDelta,
      BigInt decimals
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '21ed2977'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRelDecimal$2(
    ({
      BigInt left,
      BigInt right,
      BigInt maxPercentDelta,
      BigInt decimals,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '82d6c8fd'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRelDecimal$3(
    ({
      BigInt left,
      BigInt right,
      BigInt maxPercentDelta,
      BigInt decimals
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, 'abbf21cc'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertApproxEqRelDecimal$4(
    ({
      BigInt left,
      BigInt right,
      BigInt maxPercentDelta,
      BigInt decimals,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'fccc11c4'));
    final params = [
      args.left,
      args.right,
      args.maxPercentDelta,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq(
    ({List<_i2.Uint8List> left, List<_i2.Uint8List> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '0cc9ee84'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$2(
    ({List<BigInt> left, List<BigInt> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '191f1b30'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$3(
    ({
      _i1.EthereumAddress left,
      _i1.EthereumAddress right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '2f2769d1'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$4(
    ({String left, String right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '36f656d8'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$5(
    ({List<_i1.EthereumAddress> left, List<_i1.EthereumAddress> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[24];
    assert(checkSignature(function, '3868ac34'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$6(
    ({
      List<_i1.EthereumAddress> left,
      List<_i1.EthereumAddress> right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[25];
    assert(checkSignature(function, '3e9173c5'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$7(
    ({bool left, bool right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[26];
    assert(checkSignature(function, '4db19e7e'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$8(
    ({_i1.EthereumAddress left, _i1.EthereumAddress right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[27];
    assert(checkSignature(function, '515361f6'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$9(
    ({List<BigInt> left, List<BigInt> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[28];
    assert(checkSignature(function, '5d18c73a'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$10(
    ({List<bool> left, List<bool> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[29];
    assert(checkSignature(function, '707df785'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$11(
    ({List<BigInt> left, List<BigInt> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[30];
    assert(checkSignature(function, '711043ac'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$12(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[31];
    assert(checkSignature(function, '714a2f13'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$13(
    ({_i2.Uint8List left, _i2.Uint8List right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[32];
    assert(checkSignature(function, '7c84c69b'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$14(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[33];
    assert(checkSignature(function, '88b44c85'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$15(
    ({List<BigInt> left, List<BigInt> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[34];
    assert(checkSignature(function, '975d5a12'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$16(
    ({_i2.Uint8List left, _i2.Uint8List right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[35];
    assert(checkSignature(function, '97624631'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$17(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[36];
    assert(checkSignature(function, '98296c54'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$18(
    ({_i2.Uint8List left, _i2.Uint8List right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[37];
    assert(checkSignature(function, 'c1fa1ed0'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$19(
    ({List<String> left, List<String> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[38];
    assert(checkSignature(function, 'cf1c049c'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$20(
    ({
      List<_i2.Uint8List> left,
      List<_i2.Uint8List> right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[39];
    assert(checkSignature(function, 'e03e9177'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$21(
    ({_i2.Uint8List left, _i2.Uint8List right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[40];
    assert(checkSignature(function, 'e24fed00'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$22(
    ({List<bool> left, List<bool> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[41];
    assert(checkSignature(function, 'e48a8f8d'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$23(
    ({List<_i2.Uint8List> left, List<_i2.Uint8List> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[42];
    assert(checkSignature(function, 'e5fb9b4a'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$24(
    ({List<String> left, List<String> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[43];
    assert(checkSignature(function, 'eff6b27d'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$25(
    ({String left, String right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[44];
    assert(checkSignature(function, 'f320d963'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$26(
    ({
      List<_i2.Uint8List> left,
      List<_i2.Uint8List> right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[45];
    assert(checkSignature(function, 'f413f0b6'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$27(
    ({bool left, bool right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[46];
    assert(checkSignature(function, 'f7fe3477'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEq$28(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[47];
    assert(checkSignature(function, 'fe74f05b'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEqDecimal(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[48];
    assert(checkSignature(function, '27af7d9c'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEqDecimal$2(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[49];
    assert(checkSignature(function, '48016c04'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEqDecimal$3(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[50];
    assert(checkSignature(function, '7e77b0c5'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertEqDecimal$4(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[51];
    assert(checkSignature(function, 'd0cbbdef'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertFalse(
    ({bool condition, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[52];
    assert(checkSignature(function, '7ba04809'));
    final params = [
      args.condition,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertFalse$2(
    ({bool condition}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[53];
    assert(checkSignature(function, 'a5982885'));
    final params = [args.condition];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGe(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[54];
    assert(checkSignature(function, '0a30b771'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGe$2(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[55];
    assert(checkSignature(function, 'a84328dd'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGe$3(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[56];
    assert(checkSignature(function, 'a8d4d1d9'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGe$4(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[57];
    assert(checkSignature(function, 'e25242c0'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGeDecimal(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[58];
    assert(checkSignature(function, '3d1fe08a'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGeDecimal$2(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[59];
    assert(checkSignature(function, '5df93c9b'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGeDecimal$3(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[60];
    assert(checkSignature(function, '8bff9133'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGeDecimal$4(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[61];
    assert(checkSignature(function, 'dc28c0f1'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGt(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[62];
    assert(checkSignature(function, '5a362d45'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGt$2(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[63];
    assert(checkSignature(function, 'd9a3c4d2'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGt$3(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[64];
    assert(checkSignature(function, 'db07fcd2'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGt$4(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[65];
    assert(checkSignature(function, 'f8d33b9b'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGtDecimal(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[66];
    assert(checkSignature(function, '04a5c7ab'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGtDecimal$2(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[67];
    assert(checkSignature(function, '64949a8d'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGtDecimal$3(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[68];
    assert(checkSignature(function, '78611f0e'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertGtDecimal$4(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[69];
    assert(checkSignature(function, 'eccd2437'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLe(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[70];
    assert(checkSignature(function, '4dfe692c'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLe$2(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[71];
    assert(checkSignature(function, '8466f415'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLe$3(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[72];
    assert(checkSignature(function, '95fd154e'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLe$4(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[73];
    assert(checkSignature(function, 'd17d4b0d'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLeDecimal(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[74];
    assert(checkSignature(function, '11d1364a'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLeDecimal$2(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[75];
    assert(checkSignature(function, '7fefbbe0'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLeDecimal$3(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[76];
    assert(checkSignature(function, 'aa5cf788'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLeDecimal$4(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[77];
    assert(checkSignature(function, 'c304aab7'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLt(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[78];
    assert(checkSignature(function, '3e914080'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLt$2(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[79];
    assert(checkSignature(function, '65d5c135'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLt$3(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[80];
    assert(checkSignature(function, '9ff531e3'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLt$4(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[81];
    assert(checkSignature(function, 'b12fc005'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLtDecimal(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[82];
    assert(checkSignature(function, '2077337e'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLtDecimal$2(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[83];
    assert(checkSignature(function, '40f0b4e0'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLtDecimal$3(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[84];
    assert(checkSignature(function, 'a972d037'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertLtDecimal$4(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[85];
    assert(checkSignature(function, 'dbe8d88b'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq(
    ({List<_i2.Uint8List> left, List<_i2.Uint8List> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[86];
    assert(checkSignature(function, '0603ea68'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$2(
    ({List<BigInt> left, List<BigInt> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[87];
    assert(checkSignature(function, '0b72f4ef'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$3(
    ({bool left, bool right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[88];
    assert(checkSignature(function, '1091a261'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$4(
    ({
      List<_i2.Uint8List> left,
      List<_i2.Uint8List> right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[89];
    assert(checkSignature(function, '1dcd1f68'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$5(
    ({bool left, bool right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[90];
    assert(checkSignature(function, '236e4d66'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$6(
    ({List<bool> left, List<bool> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[91];
    assert(checkSignature(function, '286fafea'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$7(
    ({_i2.Uint8List left, _i2.Uint8List right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[92];
    assert(checkSignature(function, '3cf78e28'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$8(
    ({List<_i1.EthereumAddress> left, List<_i1.EthereumAddress> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[93];
    assert(checkSignature(function, '46d0b252'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$9(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[94];
    assert(checkSignature(function, '4724c5b9'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$10(
    ({List<BigInt> left, List<BigInt> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[95];
    assert(checkSignature(function, '56f29cba'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$11(
    ({List<bool> left, List<bool> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[96];
    assert(checkSignature(function, '62c6f9fb'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$12(
    ({String left, String right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[97];
    assert(checkSignature(function, '6a8237b3'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$13(
    ({
      List<_i1.EthereumAddress> left,
      List<_i1.EthereumAddress> right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[98];
    assert(checkSignature(function, '72c7e0b5'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$14(
    ({String left, String right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[99];
    assert(checkSignature(function, '78bdcea7'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$15(
    ({
      _i1.EthereumAddress left,
      _i1.EthereumAddress right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[100];
    assert(checkSignature(function, '8775a591'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$16(
    ({_i2.Uint8List left, _i2.Uint8List right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[101];
    assert(checkSignature(function, '898e83fc'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$17(
    ({_i2.Uint8List left, _i2.Uint8List right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[102];
    assert(checkSignature(function, '9507540e'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$18(
    ({BigInt left, BigInt right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[103];
    assert(checkSignature(function, '98f9bdbd'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$19(
    ({List<BigInt> left, List<BigInt> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[104];
    assert(checkSignature(function, '9a7fbd8f'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$20(
    ({_i1.EthereumAddress left, _i1.EthereumAddress right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[105];
    assert(checkSignature(function, 'b12e1694'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$21(
    ({_i2.Uint8List left, _i2.Uint8List right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[106];
    assert(checkSignature(function, 'b2332f51'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$22(
    ({List<String> left, List<String> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[107];
    assert(checkSignature(function, 'b67187f3'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$23(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[108];
    assert(checkSignature(function, 'b7909320'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$24(
    ({
      List<_i2.Uint8List> left,
      List<_i2.Uint8List> right,
      String error
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[109];
    assert(checkSignature(function, 'b873634c'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$25(
    ({List<String> left, List<String> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[110];
    assert(checkSignature(function, 'bdfacbe8'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$26(
    ({List<BigInt> left, List<BigInt> right, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[111];
    assert(checkSignature(function, 'd3977322'));
    final params = [
      args.left,
      args.right,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$27(
    ({List<_i2.Uint8List> left, List<_i2.Uint8List> right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[112];
    assert(checkSignature(function, 'edecd035'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEq$28(
    ({BigInt left, BigInt right}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[113];
    assert(checkSignature(function, 'f4c004e3'));
    final params = [
      args.left,
      args.right,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEqDecimal(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[114];
    assert(checkSignature(function, '14e75680'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEqDecimal$2(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[115];
    assert(checkSignature(function, '33949f0b'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEqDecimal$3(
    ({BigInt left, BigInt right, BigInt decimals}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[116];
    assert(checkSignature(function, '669efca7'));
    final params = [
      args.left,
      args.right,
      args.decimals,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertNotEqDecimal$4(
    ({BigInt left, BigInt right, BigInt decimals, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[117];
    assert(checkSignature(function, 'f5a55558'));
    final params = [
      args.left,
      args.right,
      args.decimals,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertTrue(
    ({bool condition}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[118];
    assert(checkSignature(function, '0c9fd581'));
    final params = [args.condition];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assertTrue$2(
    ({bool condition, String error}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[119];
    assert(checkSignature(function, 'a34edc03'));
    final params = [
      args.condition,
      args.error,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assume(
    ({bool condition}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[120];
    assert(checkSignature(function, '4c63e562'));
    final params = [args.condition];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> assumeNoRevert({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[121];
    assert(checkSignature(function, '285b366a'));
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
  Future<String> blobBaseFee(
    ({BigInt newBlobBaseFee}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[122];
    assert(checkSignature(function, '6d315d7e'));
    final params = [args.newBlobBaseFee];
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
  Future<String> blobhashes(
    ({List<_i2.Uint8List> hashes}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[123];
    assert(checkSignature(function, '129de7eb'));
    final params = [args.hashes];
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
  Future<void> breakpoint(
    ({String char}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[124];
    assert(checkSignature(function, 'f0259e92'));
    final params = [args.char];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<void> breakpoint$2(
    ({String char, bool value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[125];
    assert(checkSignature(function, 'f7d39a8d'));
    final params = [
      args.char,
      args.value,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> broadcast({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[126];
    assert(checkSignature(function, 'afc98040'));
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
  Future<String> broadcast$2(
    ({_i1.EthereumAddress signer}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[127];
    assert(checkSignature(function, 'e6962cdb'));
    final params = [args.signer];
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
  Future<String> broadcast$3(
    ({BigInt privateKey}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[128];
    assert(checkSignature(function, 'f67a965b'));
    final params = [args.privateKey];
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
  Future<String> broadcastRawTransaction(
    ({_i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[129];
    assert(checkSignature(function, '8c0c72e0'));
    final params = [args.data];
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
  Future<String> chainId(
    ({BigInt newChainId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[130];
    assert(checkSignature(function, '4049ddd2'));
    final params = [args.newChainId];
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
  Future<String> clearMockedCalls({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[131];
    assert(checkSignature(function, '3fdf4e15'));
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
  Future<String> cloneAccount(
    ({_i1.EthereumAddress source, _i1.EthereumAddress target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[132];
    assert(checkSignature(function, '533d61c9'));
    final params = [
      args.source,
      args.target,
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
  Future<String> closeFile(
    ({String path}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[133];
    assert(checkSignature(function, '48c3241f'));
    final params = [args.path];
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
  Future<String> coinbase(
    ({_i1.EthereumAddress newCoinbase}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[134];
    assert(checkSignature(function, 'ff483c54'));
    final params = [args.newCoinbase];
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
  Future<_i1.EthereumAddress> computeCreate2Address(
    ({_i2.Uint8List salt, _i2.Uint8List initCodeHash}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[135];
    assert(checkSignature(function, '890c283b'));
    final params = [
      args.salt,
      args.initCodeHash,
    ];
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
  Future<_i1.EthereumAddress> computeCreate2Address$2(
    ({
      _i2.Uint8List salt,
      _i2.Uint8List initCodeHash,
      _i1.EthereumAddress deployer
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[136];
    assert(checkSignature(function, 'd323826a'));
    final params = [
      args.salt,
      args.initCodeHash,
      args.deployer,
    ];
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
  Future<_i1.EthereumAddress> computeCreateAddress(
    ({_i1.EthereumAddress deployer, BigInt nonce}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[137];
    assert(checkSignature(function, '74637a7a'));
    final params = [
      args.deployer,
      args.nonce,
    ];
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
  Future<String> copyFile(
    ({String from, String to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[138];
    assert(checkSignature(function, 'a54a87d8'));
    final params = [
      args.from,
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
  Future<String> copyStorage(
    ({_i1.EthereumAddress from, _i1.EthereumAddress to}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[139];
    assert(checkSignature(function, '203dac0d'));
    final params = [
      args.from,
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
  Future<String> createDir(
    ({String path, bool recursive}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[140];
    assert(checkSignature(function, '168b64d3'));
    final params = [
      args.path,
      args.recursive,
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
  Future<String> createFork(
    ({String urlOrAlias}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[141];
    assert(checkSignature(function, '31ba3498'));
    final params = [args.urlOrAlias];
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
  Future<String> createFork$2(
    ({String urlOrAlias, BigInt blockNumber}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[142];
    assert(checkSignature(function, '6ba3ba2b'));
    final params = [
      args.urlOrAlias,
      args.blockNumber,
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
  Future<String> createFork$3(
    ({String urlOrAlias, _i2.Uint8List txHash}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[143];
    assert(checkSignature(function, '7ca29682'));
    final params = [
      args.urlOrAlias,
      args.txHash,
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
  Future<String> createSelectFork(
    ({String urlOrAlias, BigInt blockNumber}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[144];
    assert(checkSignature(function, '71ee464d'));
    final params = [
      args.urlOrAlias,
      args.blockNumber,
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
  Future<String> createSelectFork$2(
    ({String urlOrAlias, _i2.Uint8List txHash}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[145];
    assert(checkSignature(function, '84d52b7a'));
    final params = [
      args.urlOrAlias,
      args.txHash,
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
  Future<String> createSelectFork$3(
    ({String urlOrAlias}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[146];
    assert(checkSignature(function, '98680034'));
    final params = [args.urlOrAlias];
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
  Future<String> createWallet(
    ({String walletLabel}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[147];
    assert(checkSignature(function, '7404f1d2'));
    final params = [args.walletLabel];
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
  Future<String> createWallet$2(
    ({BigInt privateKey}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[148];
    assert(checkSignature(function, '7a675bb6'));
    final params = [args.privateKey];
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
  Future<String> createWallet$3(
    ({BigInt privateKey, String walletLabel}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[149];
    assert(checkSignature(function, 'ed7c5462'));
    final params = [
      args.privateKey,
      args.walletLabel,
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
  Future<String> deal(
    ({_i1.EthereumAddress account, BigInt newBalance}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[150];
    assert(checkSignature(function, 'c88a5e6d'));
    final params = [
      args.account,
      args.newBalance,
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
  Future<String> deleteSnapshot(
    ({BigInt snapshotId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[151];
    assert(checkSignature(function, 'a6368557'));
    final params = [args.snapshotId];
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
  Future<String> deleteSnapshots({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[152];
    assert(checkSignature(function, '421ae469'));
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
  Future<String> deleteStateSnapshot(
    ({BigInt snapshotId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[153];
    assert(checkSignature(function, '08d6b37a'));
    final params = [args.snapshotId];
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
  Future<String> deleteStateSnapshots({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[154];
    assert(checkSignature(function, 'e0933c74'));
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
  Future<String> deployCode(
    ({String artifactPath, _i2.Uint8List constructorArgs}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[155];
    assert(checkSignature(function, '29ce9dde'));
    final params = [
      args.artifactPath,
      args.constructorArgs,
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
  Future<String> deployCode$2(
    ({String artifactPath}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[156];
    assert(checkSignature(function, '9a8325a0'));
    final params = [args.artifactPath];
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
  Future<BigInt> deriveKey(
    ({
      String mnemonic,
      String derivationPath,
      BigInt index,
      String language
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[157];
    assert(checkSignature(function, '29233b1f'));
    final params = [
      args.mnemonic,
      args.derivationPath,
      args.index,
      args.language,
    ];
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
  Future<BigInt> deriveKey$2(
    ({String mnemonic, BigInt index, String language}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[158];
    assert(checkSignature(function, '32c8176d'));
    final params = [
      args.mnemonic,
      args.index,
      args.language,
    ];
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
  Future<BigInt> deriveKey$3(
    ({String mnemonic, BigInt index}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[159];
    assert(checkSignature(function, '6229498b'));
    final params = [
      args.mnemonic,
      args.index,
    ];
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
  Future<BigInt> deriveKey$4(
    ({String mnemonic, String derivationPath, BigInt index}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[160];
    assert(checkSignature(function, '6bcb2c1b'));
    final params = [
      args.mnemonic,
      args.derivationPath,
      args.index,
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
  Future<String> difficulty(
    ({BigInt newDifficulty}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[161];
    assert(checkSignature(function, '46cc92d9'));
    final params = [args.newDifficulty];
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
  Future<String> dumpState(
    ({String pathToStateJson}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[162];
    assert(checkSignature(function, '709ecd3f'));
    final params = [args.pathToStateJson];
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
  Future<_i2.Uint8List> ensNamehash(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[163];
    assert(checkSignature(function, '8c374c65'));
    final params = [args.name];
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
  Future<_i1.EthereumAddress> envAddress(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[164];
    assert(checkSignature(function, '350d56bf'));
    final params = [args.name];
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
  Future<List<_i1.EthereumAddress>> envAddress$2(
    ({String name, String delim}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[165];
    assert(checkSignature(function, 'ad31b9fa'));
    final params = [
      args.name,
      args.delim,
    ];
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
  Future<bool> envBool(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[166];
    assert(checkSignature(function, '7ed1ec7d'));
    final params = [args.name];
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
  Future<List<bool>> envBool$2(
    ({String name, String delim}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[167];
    assert(checkSignature(function, 'aaaddeaf'));
    final params = [
      args.name,
      args.delim,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<bool>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.Uint8List> envBytes(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[168];
    assert(checkSignature(function, '4d7baf06'));
    final params = [args.name];
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
  Future<List<_i2.Uint8List>> envBytes$2(
    ({String name, String delim}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[169];
    assert(checkSignature(function, 'ddc2651b'));
    final params = [
      args.name,
      args.delim,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.Uint8List>> envBytes32(
    ({String name, String delim}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[170];
    assert(checkSignature(function, '5af231c1'));
    final params = [
      args.name,
      args.delim,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.Uint8List> envBytes32$2(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[171];
    assert(checkSignature(function, '97949042'));
    final params = [args.name];
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
  Future<bool> envExists(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[172];
    assert(checkSignature(function, 'ce8365f9'));
    final params = [args.name];
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
  Future<List<BigInt>> envInt(
    ({String name, String delim}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[173];
    assert(checkSignature(function, '42181150'));
    final params = [
      args.name,
      args.delim,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> envInt$2(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[174];
    assert(checkSignature(function, '892a0c61'));
    final params = [args.name];
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
  Future<List<_i2.Uint8List>> envOr(
    ({String name, String delim, List<_i2.Uint8List> defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[175];
    assert(checkSignature(function, '2281f367'));
    final params = [
      args.name,
      args.delim,
      args.defaultValue,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<BigInt>> envOr$2(
    ({String name, String delim, List<BigInt> defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[176];
    assert(checkSignature(function, '4700d74b'));
    final params = [
      args.name,
      args.delim,
      args.defaultValue,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> envOr$3(
    ({String name, bool defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[177];
    assert(checkSignature(function, '4777f3cf'));
    final params = [
      args.name,
      args.defaultValue,
    ];
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
  Future<_i1.EthereumAddress> envOr$4(
    ({String name, _i1.EthereumAddress defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[178];
    assert(checkSignature(function, '561fe540'));
    final params = [
      args.name,
      args.defaultValue,
    ];
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
  Future<BigInt> envOr$5(
    ({String name, BigInt defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[179];
    assert(checkSignature(function, '5e97348f'));
    final params = [
      args.name,
      args.defaultValue,
    ];
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
  Future<List<_i2.Uint8List>> envOr$6(
    ({String name, String delim, List<_i2.Uint8List> defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[180];
    assert(checkSignature(function, '64bc3e64'));
    final params = [
      args.name,
      args.delim,
      args.defaultValue,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<BigInt>> envOr$7(
    ({String name, String delim, List<BigInt> defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[181];
    assert(checkSignature(function, '74318528'));
    final params = [
      args.name,
      args.delim,
      args.defaultValue,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> envOr$8(
    ({String name, String delim, List<String> defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[182];
    assert(checkSignature(function, '859216bc'));
    final params = [
      args.name,
      args.delim,
      args.defaultValue,
    ];
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
  Future<_i2.Uint8List> envOr$9(
    ({String name, _i2.Uint8List defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[183];
    assert(checkSignature(function, 'b3e47705'));
    final params = [
      args.name,
      args.defaultValue,
    ];
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
  Future<_i2.Uint8List> envOr$10(
    ({String name, _i2.Uint8List defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[184];
    assert(checkSignature(function, 'b4a85892'));
    final params = [
      args.name,
      args.defaultValue,
    ];
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
  Future<BigInt> envOr$11(
    ({String name, BigInt defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[185];
    assert(checkSignature(function, 'bbcb713e'));
    final params = [
      args.name,
      args.defaultValue,
    ];
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
  Future<List<_i1.EthereumAddress>> envOr$12(
    ({
      String name,
      String delim,
      List<_i1.EthereumAddress> defaultValue
    }) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[186];
    assert(checkSignature(function, 'c74e9deb'));
    final params = [
      args.name,
      args.delim,
      args.defaultValue,
    ];
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
  Future<String> envOr$13(
    ({String name, String defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[187];
    assert(checkSignature(function, 'd145736c'));
    final params = [
      args.name,
      args.defaultValue,
    ];
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
  Future<List<bool>> envOr$14(
    ({String name, String delim, List<bool> defaultValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[188];
    assert(checkSignature(function, 'eb85e83b'));
    final params = [
      args.name,
      args.delim,
      args.defaultValue,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<bool>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> envString(
    ({String name, String delim}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[189];
    assert(checkSignature(function, '14b02bc9'));
    final params = [
      args.name,
      args.delim,
    ];
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
  Future<String> envString$2(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[190];
    assert(checkSignature(function, 'f877cb19'));
    final params = [args.name];
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
  Future<BigInt> envUint(
    ({String name}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[191];
    assert(checkSignature(function, 'c1978d1f'));
    final params = [args.name];
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
  Future<List<BigInt>> envUint$2(
    ({String name, String delim}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[192];
    assert(checkSignature(function, 'f3dec099'));
    final params = [
      args.name,
      args.delim,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> etch(
    ({_i1.EthereumAddress target, _i2.Uint8List newRuntimeBytecode}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[193];
    assert(checkSignature(function, 'b4d6c782'));
    final params = [
      args.target,
      args.newRuntimeBytecode,
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
  Future<String> eth_getLogs(
    ({
      BigInt fromBlock,
      BigInt toBlock,
      _i1.EthereumAddress target,
      List<_i2.Uint8List> topics
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[194];
    assert(checkSignature(function, '35e1349b'));
    final params = [
      args.fromBlock,
      args.toBlock,
      args.target,
      args.topics,
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
  Future<String> exists(
    ({String path}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[195];
    assert(checkSignature(function, '261a323e'));
    final params = [args.path];
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
  Future<String> expectCall(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      BigInt gas,
      _i2.Uint8List data
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[196];
    assert(checkSignature(function, '23361207'));
    final params = [
      args.callee,
      args.msgValue,
      args.gas,
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
  Future<String> expectCall$2(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      BigInt gas,
      _i2.Uint8List data,
      BigInt count
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[197];
    assert(checkSignature(function, '65b7b7cc'));
    final params = [
      args.callee,
      args.msgValue,
      args.gas,
      args.data,
      args.count,
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
  Future<String> expectCall$3(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      _i2.Uint8List data,
      BigInt count
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[198];
    assert(checkSignature(function, 'a2b1a1ae'));
    final params = [
      args.callee,
      args.msgValue,
      args.data,
      args.count,
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
  Future<String> expectCall$4(
    ({_i1.EthereumAddress callee, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[199];
    assert(checkSignature(function, 'bd6af434'));
    final params = [
      args.callee,
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
  Future<String> expectCall$5(
    ({_i1.EthereumAddress callee, _i2.Uint8List data, BigInt count}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[200];
    assert(checkSignature(function, 'c1adbbff'));
    final params = [
      args.callee,
      args.data,
      args.count,
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
  Future<String> expectCall$6(
    ({_i1.EthereumAddress callee, BigInt msgValue, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[201];
    assert(checkSignature(function, 'f30c7ba3'));
    final params = [
      args.callee,
      args.msgValue,
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
  Future<String> expectCallMinGas(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      BigInt minGas,
      _i2.Uint8List data
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[202];
    assert(checkSignature(function, '08e4e116'));
    final params = [
      args.callee,
      args.msgValue,
      args.minGas,
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
  Future<String> expectCallMinGas$2(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      BigInt minGas,
      _i2.Uint8List data,
      BigInt count
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[203];
    assert(checkSignature(function, 'e13a1834'));
    final params = [
      args.callee,
      args.msgValue,
      args.minGas,
      args.data,
      args.count,
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
  Future<String> expectEmit({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[204];
    assert(checkSignature(function, '440ed10d'));
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
  Future<String> expectEmit$2(
    ({
      bool checkTopic1,
      bool checkTopic2,
      bool checkTopic3,
      bool checkData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[205];
    assert(checkSignature(function, '491cc7c2'));
    final params = [
      args.checkTopic1,
      args.checkTopic2,
      args.checkTopic3,
      args.checkData,
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
  Future<String> expectEmit$3(
    ({
      bool checkTopic1,
      bool checkTopic2,
      bool checkTopic3,
      bool checkData,
      _i1.EthereumAddress emitter
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[206];
    assert(checkSignature(function, '81bad6f3'));
    final params = [
      args.checkTopic1,
      args.checkTopic2,
      args.checkTopic3,
      args.checkData,
      args.emitter,
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
  Future<String> expectEmit$4(
    ({_i1.EthereumAddress emitter}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[207];
    assert(checkSignature(function, '86b9620d'));
    final params = [args.emitter];
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
  Future<String> expectEmitAnonymous({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[208];
    assert(checkSignature(function, '2e5f270c'));
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
  Future<String> expectEmitAnonymous$2(
    ({_i1.EthereumAddress emitter}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[209];
    assert(checkSignature(function, '6fc68705'));
    final params = [args.emitter];
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
  Future<String> expectEmitAnonymous$3(
    ({
      bool checkTopic0,
      bool checkTopic1,
      bool checkTopic2,
      bool checkTopic3,
      bool checkData,
      _i1.EthereumAddress emitter
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[210];
    assert(checkSignature(function, '71c95899'));
    final params = [
      args.checkTopic0,
      args.checkTopic1,
      args.checkTopic2,
      args.checkTopic3,
      args.checkData,
      args.emitter,
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
  Future<String> expectEmitAnonymous$4(
    ({
      bool checkTopic0,
      bool checkTopic1,
      bool checkTopic2,
      bool checkTopic3,
      bool checkData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[211];
    assert(checkSignature(function, 'c948db5e'));
    final params = [
      args.checkTopic0,
      args.checkTopic1,
      args.checkTopic2,
      args.checkTopic3,
      args.checkData,
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
  Future<String> expectPartialRevert(
    ({_i2.Uint8List revertData}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[212];
    assert(checkSignature(function, '11fb5b9c'));
    final params = [args.revertData];
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
  Future<String> expectPartialRevert$2(
    ({_i2.Uint8List revertData, _i1.EthereumAddress reverter}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[213];
    assert(checkSignature(function, '51aa008a'));
    final params = [
      args.revertData,
      args.reverter,
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
  Future<String> expectRevert(
    ({_i2.Uint8List revertData, _i1.EthereumAddress reverter}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[214];
    assert(checkSignature(function, '260bc5de'));
    final params = [
      args.revertData,
      args.reverter,
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
  Future<String> expectRevert$2(
    ({_i2.Uint8List revertData, _i1.EthereumAddress reverter}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[215];
    assert(checkSignature(function, '61ebcf12'));
    final params = [
      args.revertData,
      args.reverter,
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
  Future<String> expectRevert$3(
    ({_i2.Uint8List revertData}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[216];
    assert(checkSignature(function, 'c31eb0e0'));
    final params = [args.revertData];
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
  Future<String> expectRevert$4(
    ({_i1.EthereumAddress reverter}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[217];
    assert(checkSignature(function, 'd814f38a'));
    final params = [args.reverter];
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
  Future<String> expectRevert$5(
    ({_i2.Uint8List revertData}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[218];
    assert(checkSignature(function, 'f28dceb3'));
    final params = [args.revertData];
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
  Future<String> expectRevert$6({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[219];
    assert(checkSignature(function, 'f4844814'));
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
  Future<String> expectSafeMemory(
    ({BigInt min, BigInt max}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[220];
    assert(checkSignature(function, '6d016688'));
    final params = [
      args.min,
      args.max,
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
  Future<String> expectSafeMemoryCall(
    ({BigInt min, BigInt max}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[221];
    assert(checkSignature(function, '05838bf4'));
    final params = [
      args.min,
      args.max,
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
  Future<String> fee(
    ({BigInt newBasefee}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[222];
    assert(checkSignature(function, '39b37ab0'));
    final params = [args.newBasefee];
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
  Future<String> ffi(
    ({List<String> commandInput}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[223];
    assert(checkSignature(function, '89160467'));
    final params = [args.commandInput];
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
  Future<dynamic> fsMetadata(
    ({String path}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[224];
    assert(checkSignature(function, 'af368a08'));
    final params = [args.path];
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
  Future<String> getArtifactPathByCode(
    ({_i2.Uint8List code}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[225];
    assert(checkSignature(function, 'eb74848c'));
    final params = [args.code];
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
  Future<String> getArtifactPathByDeployedCode(
    ({_i2.Uint8List deployedCode}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[226];
    assert(checkSignature(function, '6d853ba5'));
    final params = [args.deployedCode];
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
  Future<BigInt> getBlobBaseFee({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[227];
    assert(checkSignature(function, '1f6d6ef7'));
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
  Future<List<_i2.Uint8List>> getBlobhashes({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[228];
    assert(checkSignature(function, 'f56ff18b'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> getBlockNumber({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[229];
    assert(checkSignature(function, '42cbb15c'));
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
  Future<BigInt> getBlockTimestamp({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[230];
    assert(checkSignature(function, '796b89b9'));
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
  Future<_i2.Uint8List> getCode(
    ({String artifactPath}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[231];
    assert(checkSignature(function, '8d1cc925'));
    final params = [args.artifactPath];
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
  Future<_i2.Uint8List> getDeployedCode(
    ({String artifactPath}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[232];
    assert(checkSignature(function, '3ebf73b4'));
    final params = [args.artifactPath];
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
  Future<String> getFoundryVersion({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[233];
    assert(checkSignature(function, 'ea991bb5'));
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
  Future<String> getLabel(
    ({_i1.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[234];
    assert(checkSignature(function, '28a249b0'));
    final params = [args.account];
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
  Future<String> getMappingKeyAndParentOf(
    ({_i1.EthereumAddress target, _i2.Uint8List elementSlot}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[235];
    assert(checkSignature(function, '876e24e6'));
    final params = [
      args.target,
      args.elementSlot,
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
  Future<String> getMappingLength(
    ({_i1.EthereumAddress target, _i2.Uint8List mappingSlot}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[236];
    assert(checkSignature(function, '2f2fd63f'));
    final params = [
      args.target,
      args.mappingSlot,
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
  Future<String> getMappingSlotAt(
    ({
      _i1.EthereumAddress target,
      _i2.Uint8List mappingSlot,
      BigInt idx
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[237];
    assert(checkSignature(function, 'ebc73ab4'));
    final params = [
      args.target,
      args.mappingSlot,
      args.idx,
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
  Future<BigInt> getNonce(
    ({_i1.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[238];
    assert(checkSignature(function, '2d0335ab'));
    final params = [args.account];
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
  Future<String> getNonce$2(
    ({dynamic wallet}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[239];
    assert(checkSignature(function, 'a5748aad'));
    final params = [args.wallet];
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
  Future<String> getRecordedLogs({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[240];
    assert(checkSignature(function, '191553a4'));
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
  Future<String> getScriptWallets({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[241];
    assert(checkSignature(function, '7c49aa1f'));
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
  Future<String> getWallets({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[242];
    assert(checkSignature(function, 'db7a4605'));
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
  Future<BigInt> indexOf(
    ({String input, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[243];
    assert(checkSignature(function, '8a0807b7'));
    final params = [
      args.input,
      args.key,
    ];
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
  Future<bool> isContext(
    ({BigInt context}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[244];
    assert(checkSignature(function, '64af255d'));
    final params = [args.context];
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
  Future<String> isDir(
    ({String path}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[245];
    assert(checkSignature(function, '7d15d019'));
    final params = [args.path];
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
  Future<String> isFile(
    ({String path}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[246];
    assert(checkSignature(function, 'e0eb04d4'));
    final params = [args.path];
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
  Future<bool> isPersistent(
    ({_i1.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[247];
    assert(checkSignature(function, 'd92d8efd'));
    final params = [args.account];
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
  Future<bool> keyExists(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[248];
    assert(checkSignature(function, '528a683c'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<bool> keyExistsJson(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[249];
    assert(checkSignature(function, 'db4235f6'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<bool> keyExistsToml(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[250];
    assert(checkSignature(function, '600903ad'));
    final params = [
      args.toml,
      args.key,
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
  Future<String> label(
    ({_i1.EthereumAddress account, String newLabel}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[251];
    assert(checkSignature(function, 'c657c718'));
    final params = [
      args.account,
      args.newLabel,
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
  Future<dynamic> lastCallGas({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[252];
    assert(checkSignature(function, '2b589b28'));
    final params = [];
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
  Future<_i2.Uint8List> load(
    ({_i1.EthereumAddress target, _i2.Uint8List slot}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[253];
    assert(checkSignature(function, '667f9d70'));
    final params = [
      args.target,
      args.slot,
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
  Future<String> loadAllocs(
    ({String pathToAllocsJson}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[254];
    assert(checkSignature(function, 'b3a056d7'));
    final params = [args.pathToAllocsJson];
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
  Future<String> makePersistent(
    ({List<_i1.EthereumAddress> accounts}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[255];
    assert(checkSignature(function, '1d9e269e'));
    final params = [args.accounts];
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
  Future<String> makePersistent$2(
    ({_i1.EthereumAddress account0, _i1.EthereumAddress account1}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[256];
    assert(checkSignature(function, '4074e0a8'));
    final params = [
      args.account0,
      args.account1,
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
  Future<String> makePersistent$3(
    ({_i1.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[257];
    assert(checkSignature(function, '57e22dde'));
    final params = [args.account];
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
  Future<String> makePersistent$4(
    ({
      _i1.EthereumAddress account0,
      _i1.EthereumAddress account1,
      _i1.EthereumAddress account2
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[258];
    assert(checkSignature(function, 'efb77a75'));
    final params = [
      args.account0,
      args.account1,
      args.account2,
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
  Future<String> mockCall(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      _i2.Uint8List data,
      _i2.Uint8List returnData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[259];
    assert(checkSignature(function, '81409b91'));
    final params = [
      args.callee,
      args.msgValue,
      args.data,
      args.returnData,
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
  Future<String> mockCall$2(
    ({
      _i1.EthereumAddress callee,
      _i2.Uint8List data,
      _i2.Uint8List returnData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[260];
    assert(checkSignature(function, 'b96213e4'));
    final params = [
      args.callee,
      args.data,
      args.returnData,
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
  Future<String> mockCallRevert(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      _i2.Uint8List data,
      _i2.Uint8List revertData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[261];
    assert(checkSignature(function, 'd23cd037'));
    final params = [
      args.callee,
      args.msgValue,
      args.data,
      args.revertData,
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
  Future<String> mockCallRevert$2(
    ({
      _i1.EthereumAddress callee,
      _i2.Uint8List data,
      _i2.Uint8List revertData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[262];
    assert(checkSignature(function, 'dbaad147'));
    final params = [
      args.callee,
      args.data,
      args.revertData,
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
  Future<String> mockCalls(
    ({
      _i1.EthereumAddress callee,
      BigInt msgValue,
      _i2.Uint8List data,
      List<_i2.Uint8List> returnData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[263];
    assert(checkSignature(function, '08bcbae1'));
    final params = [
      args.callee,
      args.msgValue,
      args.data,
      args.returnData,
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
  Future<String> mockCalls$2(
    ({
      _i1.EthereumAddress callee,
      _i2.Uint8List data,
      List<_i2.Uint8List> returnData
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[264];
    assert(checkSignature(function, '5c5c3de9'));
    final params = [
      args.callee,
      args.data,
      args.returnData,
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
  Future<String> mockFunction(
    ({
      _i1.EthereumAddress callee,
      _i1.EthereumAddress target,
      _i2.Uint8List data
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[265];
    assert(checkSignature(function, 'adf84d21'));
    final params = [
      args.callee,
      args.target,
      args.data,
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
  Future<_i1.EthereumAddress> parseAddress(
    ({String stringifiedValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[266];
    assert(checkSignature(function, 'c6ce059d'));
    final params = [args.stringifiedValue];
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
  Future<bool> parseBool(
    ({String stringifiedValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[267];
    assert(checkSignature(function, '974ef924'));
    final params = [args.stringifiedValue];
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
  Future<_i2.Uint8List> parseBytes(
    ({String stringifiedValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[268];
    assert(checkSignature(function, '8f5d232d'));
    final params = [args.stringifiedValue];
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
  Future<_i2.Uint8List> parseBytes32(
    ({String stringifiedValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[269];
    assert(checkSignature(function, '087e6e81'));
    final params = [args.stringifiedValue];
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
  Future<BigInt> parseInt(
    ({String stringifiedValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[270];
    assert(checkSignature(function, '42346c5e'));
    final params = [args.stringifiedValue];
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
  Future<_i2.Uint8List> parseJson(
    ({String json}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[271];
    assert(checkSignature(function, '6a82600a'));
    final params = [args.json];
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
  Future<_i2.Uint8List> parseJson$2(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[272];
    assert(checkSignature(function, '85940ef1'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<_i1.EthereumAddress> parseJsonAddress(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[273];
    assert(checkSignature(function, '1e19e657'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<List<_i1.EthereumAddress>> parseJsonAddressArray(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[274];
    assert(checkSignature(function, '2fce7883'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<bool> parseJsonBool(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[275];
    assert(checkSignature(function, '9f86dc91'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<List<bool>> parseJsonBoolArray(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[276];
    assert(checkSignature(function, '91f3b94f'));
    final params = [
      args.json,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<bool>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.Uint8List> parseJsonBytes(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[277];
    assert(checkSignature(function, 'fd921be8'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<_i2.Uint8List> parseJsonBytes32(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[278];
    assert(checkSignature(function, '1777e59d'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<List<_i2.Uint8List>> parseJsonBytes32Array(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[279];
    assert(checkSignature(function, '91c75bc3'));
    final params = [
      args.json,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.Uint8List>> parseJsonBytesArray(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[280];
    assert(checkSignature(function, '6631aa99'));
    final params = [
      args.json,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> parseJsonInt(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[281];
    assert(checkSignature(function, '7b048ccd'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<List<BigInt>> parseJsonIntArray(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[282];
    assert(checkSignature(function, '9983c28a'));
    final params = [
      args.json,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> parseJsonKeys(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[283];
    assert(checkSignature(function, '213e4198'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<String> parseJsonString(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[284];
    assert(checkSignature(function, '49c4fac8'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<List<String>> parseJsonStringArray(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[285];
    assert(checkSignature(function, '498fdcf4'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<_i2.Uint8List> parseJsonType(
    ({String json, String typeDescription}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[286];
    assert(checkSignature(function, 'a9da313b'));
    final params = [
      args.json,
      args.typeDescription,
    ];
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
  Future<_i2.Uint8List> parseJsonType$2(
    ({String json, String key, String typeDescription}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[287];
    assert(checkSignature(function, 'e3f5ae33'));
    final params = [
      args.json,
      args.key,
      args.typeDescription,
    ];
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
  Future<_i2.Uint8List> parseJsonTypeArray(
    ({String json, String key, String typeDescription}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[288];
    assert(checkSignature(function, '0175d535'));
    final params = [
      args.json,
      args.key,
      args.typeDescription,
    ];
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
  Future<BigInt> parseJsonUint(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[289];
    assert(checkSignature(function, 'addde2b6'));
    final params = [
      args.json,
      args.key,
    ];
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
  Future<List<BigInt>> parseJsonUintArray(
    ({String json, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[290];
    assert(checkSignature(function, '522074ab'));
    final params = [
      args.json,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.Uint8List> parseToml(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[291];
    assert(checkSignature(function, '37736e08'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<_i2.Uint8List> parseToml$2(
    ({String toml}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[292];
    assert(checkSignature(function, '592151f0'));
    final params = [args.toml];
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
  Future<_i1.EthereumAddress> parseTomlAddress(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[293];
    assert(checkSignature(function, '65e7c844'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<List<_i1.EthereumAddress>> parseTomlAddressArray(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[294];
    assert(checkSignature(function, '65c428e7'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<bool> parseTomlBool(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[295];
    assert(checkSignature(function, 'd30dced6'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<List<bool>> parseTomlBoolArray(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[296];
    assert(checkSignature(function, '127cfe9a'));
    final params = [
      args.toml,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<bool>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.Uint8List> parseTomlBytes(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[297];
    assert(checkSignature(function, 'd77bfdb9'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<_i2.Uint8List> parseTomlBytes32(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[298];
    assert(checkSignature(function, '8e214810'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<List<_i2.Uint8List>> parseTomlBytes32Array(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[299];
    assert(checkSignature(function, '3e716f81'));
    final params = [
      args.toml,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<_i2.Uint8List>> parseTomlBytesArray(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[300];
    assert(checkSignature(function, 'b197c247'));
    final params = [
      args.toml,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.Uint8List>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> parseTomlInt(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[301];
    assert(checkSignature(function, 'c1350739'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<List<BigInt>> parseTomlIntArray(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[302];
    assert(checkSignature(function, 'd3522ae6'));
    final params = [
      args.toml,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<String>> parseTomlKeys(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[303];
    assert(checkSignature(function, '812a44b2'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<String> parseTomlString(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[304];
    assert(checkSignature(function, '8bb8dd43'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<List<String>> parseTomlStringArray(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[305];
    assert(checkSignature(function, '9f629281'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<_i2.Uint8List> parseTomlType(
    ({String toml, String typeDescription}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[306];
    assert(checkSignature(function, '47fa5e11'));
    final params = [
      args.toml,
      args.typeDescription,
    ];
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
  Future<_i2.Uint8List> parseTomlType$2(
    ({String toml, String key, String typeDescription}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[307];
    assert(checkSignature(function, 'f9fa5cdb'));
    final params = [
      args.toml,
      args.key,
      args.typeDescription,
    ];
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
  Future<_i2.Uint8List> parseTomlTypeArray(
    ({String toml, String key, String typeDescription}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[308];
    assert(checkSignature(function, '49be3743'));
    final params = [
      args.toml,
      args.key,
      args.typeDescription,
    ];
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
  Future<BigInt> parseTomlUint(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[309];
    assert(checkSignature(function, 'cc7b0487'));
    final params = [
      args.toml,
      args.key,
    ];
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
  Future<List<BigInt>> parseTomlUintArray(
    ({String toml, String key}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[310];
    assert(checkSignature(function, 'b5df27c8'));
    final params = [
      args.toml,
      args.key,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<BigInt>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> parseUint(
    ({String stringifiedValue}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[311];
    assert(checkSignature(function, 'fa91454d'));
    final params = [args.stringifiedValue];
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
  Future<String> pauseGasMetering({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[312];
    assert(checkSignature(function, 'd1a5b36f'));
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
  Future<void> pauseTracing({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[313];
    assert(checkSignature(function, 'c94d1f90'));
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
  Future<String> prank(
    ({_i1.EthereumAddress msgSender, _i1.EthereumAddress txOrigin}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[314];
    assert(checkSignature(function, '47e50cce'));
    final params = [
      args.msgSender,
      args.txOrigin,
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
  Future<String> prank$2(
    ({_i1.EthereumAddress msgSender}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[315];
    assert(checkSignature(function, 'ca669fa7'));
    final params = [args.msgSender];
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
  Future<String> prevrandao(
    ({_i2.Uint8List newPrevrandao}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[316];
    assert(checkSignature(function, '3b925549'));
    final params = [args.newPrevrandao];
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
  Future<String> prevrandao$2(
    ({BigInt newPrevrandao}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[317];
    assert(checkSignature(function, '9cb1c0d4'));
    final params = [args.newPrevrandao];
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
  Future<String> projectRoot({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[318];
    assert(checkSignature(function, 'd930a0e6'));
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
  Future<String> prompt(
    ({String promptText}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[319];
    assert(checkSignature(function, '47eaf474'));
    final params = [args.promptText];
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
  Future<String> promptAddress(
    ({String promptText}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[320];
    assert(checkSignature(function, '62ee05f4'));
    final params = [args.promptText];
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
  Future<String> promptSecret(
    ({String promptText}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[321];
    assert(checkSignature(function, '1e279d41'));
    final params = [args.promptText];
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
  Future<String> promptSecretUint(
    ({String promptText}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[322];
    assert(checkSignature(function, '69ca02b7'));
    final params = [args.promptText];
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
  Future<String> promptUint(
    ({String promptText}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[323];
    assert(checkSignature(function, '652fd489'));
    final params = [args.promptText];
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
  Future<PublicKeyP256> publicKeyP256(
    ({BigInt privateKey}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[324];
    assert(checkSignature(function, 'c453949e'));
    final params = [args.privateKey];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return PublicKeyP256(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> randomAddress({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[325];
    assert(checkSignature(function, 'd5bee9f5'));
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
  Future<bool> randomBool({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[326];
    assert(checkSignature(function, 'cdc126bd'));
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
  Future<_i2.Uint8List> randomBytes(
    ({BigInt len}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[327];
    assert(checkSignature(function, '6c5d32a9'));
    final params = [args.len];
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
  Future<_i2.Uint8List> randomBytes4({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[328];
    assert(checkSignature(function, '9b7cd579'));
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
  Future<_i2.Uint8List> randomBytes8({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[329];
    assert(checkSignature(function, '0497b0a5'));
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
  Future<BigInt> randomInt({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[330];
    assert(checkSignature(function, '111f1202'));
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
  Future<BigInt> randomInt$2(
    ({BigInt bits}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[331];
    assert(checkSignature(function, '12845966'));
    final params = [args.bits];
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
  Future<String> randomUint({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[332];
    assert(checkSignature(function, '25124730'));
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
  Future<BigInt> randomUint$2(
    ({BigInt bits}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[333];
    assert(checkSignature(function, 'cf81e69c'));
    final params = [args.bits];
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
  Future<String> randomUint$3(
    ({BigInt min, BigInt max}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[334];
    assert(checkSignature(function, 'd61b051b'));
    final params = [
      args.min,
      args.max,
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
  Future<String> readCallers({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[335];
    assert(checkSignature(function, '4ad0bac9'));
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
  Future<List<dynamic>> readDir(
    ({String path, BigInt maxDepth}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[336];
    assert(checkSignature(function, '1497876c'));
    final params = [
      args.path,
      args.maxDepth,
    ];
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
  Future<List<dynamic>> readDir$2(
    ({String path, BigInt maxDepth, bool followLinks}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[337];
    assert(checkSignature(function, '8102d70d'));
    final params = [
      args.path,
      args.maxDepth,
      args.followLinks,
    ];
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
  Future<List<dynamic>> readDir$3(
    ({String path}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[338];
    assert(checkSignature(function, 'c4bc59e0'));
    final params = [args.path];
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
  Future<String> readFile(
    ({String path}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[339];
    assert(checkSignature(function, '60f9bb11'));
    final params = [args.path];
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
  Future<_i2.Uint8List> readFileBinary(
    ({String path}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[340];
    assert(checkSignature(function, '16ed7bc4'));
    final params = [args.path];
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
  Future<String> readLine(
    ({String path}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[341];
    assert(checkSignature(function, '70f55728'));
    final params = [args.path];
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
  Future<String> readLink(
    ({String linkPath}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[342];
    assert(checkSignature(function, '9f5684a2'));
    final params = [args.linkPath];
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
  Future<String> record({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[343];
    assert(checkSignature(function, '266cf109'));
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
  Future<String> recordLogs({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[344];
    assert(checkSignature(function, '41af2f52'));
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
  Future<String> rememberKey(
    ({BigInt privateKey}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[345];
    assert(checkSignature(function, '22100064'));
    final params = [args.privateKey];
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
  Future<String> rememberKeys(
    ({String mnemonic, String derivationPath, BigInt count}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[346];
    assert(checkSignature(function, '97cb9189'));
    final params = [
      args.mnemonic,
      args.derivationPath,
      args.count,
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
  Future<String> rememberKeys$2(
    ({
      String mnemonic,
      String derivationPath,
      String language,
      BigInt count
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[347];
    assert(checkSignature(function, 'f8d58eaf'));
    final params = [
      args.mnemonic,
      args.derivationPath,
      args.language,
      args.count,
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
  Future<String> removeDir(
    ({String path, bool recursive}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[348];
    assert(checkSignature(function, '45c62011'));
    final params = [
      args.path,
      args.recursive,
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
  Future<String> removeFile(
    ({String path}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[349];
    assert(checkSignature(function, 'f1afe04d'));
    final params = [args.path];
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
  Future<String> replace(
    ({String input, String from, String to}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[350];
    assert(checkSignature(function, 'e00ad03e'));
    final params = [
      args.input,
      args.from,
      args.to,
    ];
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
  Future<String> resetGasMetering({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[351];
    assert(checkSignature(function, 'be367dd3'));
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
  Future<String> resetNonce(
    ({_i1.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[352];
    assert(checkSignature(function, '1c72346d'));
    final params = [args.account];
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
  Future<String> resumeGasMetering({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[353];
    assert(checkSignature(function, '2bcd50e0'));
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
  Future<void> resumeTracing({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[354];
    assert(checkSignature(function, '72a09ccb'));
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
  Future<String> revertTo(
    ({BigInt snapshotId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[355];
    assert(checkSignature(function, '44d7f0a4'));
    final params = [args.snapshotId];
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
  Future<String> revertToAndDelete(
    ({BigInt snapshotId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[356];
    assert(checkSignature(function, '03e0aca9'));
    final params = [args.snapshotId];
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
  Future<String> revertToState(
    ({BigInt snapshotId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[357];
    assert(checkSignature(function, 'c2527405'));
    final params = [args.snapshotId];
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
  Future<String> revertToStateAndDelete(
    ({BigInt snapshotId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[358];
    assert(checkSignature(function, '3a1985dc'));
    final params = [args.snapshotId];
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
  Future<String> revokePersistent(
    ({List<_i1.EthereumAddress> accounts}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[359];
    assert(checkSignature(function, '3ce969e6'));
    final params = [args.accounts];
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
  Future<String> revokePersistent$2(
    ({_i1.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[360];
    assert(checkSignature(function, '997a0222'));
    final params = [args.account];
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
  Future<String> roll(
    ({BigInt newHeight}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[361];
    assert(checkSignature(function, '1f7b4f30'));
    final params = [args.newHeight];
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
  Future<String> rollFork(
    ({_i2.Uint8List txHash}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[362];
    assert(checkSignature(function, '0f29772b'));
    final params = [args.txHash];
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
  Future<String> rollFork$2(
    ({BigInt forkId, BigInt blockNumber}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[363];
    assert(checkSignature(function, 'd74c83a4'));
    final params = [
      args.forkId,
      args.blockNumber,
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
  Future<String> rollFork$3(
    ({BigInt blockNumber}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[364];
    assert(checkSignature(function, 'd9bbf3a1'));
    final params = [args.blockNumber];
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
  Future<String> rollFork$4(
    ({BigInt forkId, _i2.Uint8List txHash}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[365];
    assert(checkSignature(function, 'f2830f7b'));
    final params = [
      args.forkId,
      args.txHash,
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
  Future<String> rpc(
    ({String urlOrAlias, String method, String params}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[366];
    assert(checkSignature(function, '0199a220'));
    final params = [
      args.urlOrAlias,
      args.method,
      args.params,
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
  Future<String> rpc$2(
    ({String method, String params}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[367];
    assert(checkSignature(function, '1206c8a8'));
    final params = [
      args.method,
      args.params,
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
  Future<String> rpcUrl(
    ({String rpcAlias}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[368];
    assert(checkSignature(function, '975a6ce9'));
    final params = [args.rpcAlias];
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
  Future<List<dynamic>> rpcUrlStructs({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[369];
    assert(checkSignature(function, '9d2ad72a'));
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
  Future<List<List<String>>> rpcUrls({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[370];
    assert(checkSignature(function, 'a85a8418'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>)
        .cast<List<dynamic>>()
        .map<List<String>>((e) {
      return e.cast<String>();
    }).toList();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> selectFork(
    ({BigInt forkId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[371];
    assert(checkSignature(function, '9ebf6827'));
    final params = [args.forkId];
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
  Future<String> serializeAddress(
    ({
      String objectKey,
      String valueKey,
      List<_i1.EthereumAddress> values
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[372];
    assert(checkSignature(function, '1e356e1a'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.values,
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
  Future<String> serializeAddress$2(
    ({String objectKey, String valueKey, _i1.EthereumAddress value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[373];
    assert(checkSignature(function, '972c6062'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> serializeBool(
    ({String objectKey, String valueKey, List<bool> values}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[374];
    assert(checkSignature(function, '92925aa1'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.values,
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
  Future<String> serializeBool$2(
    ({String objectKey, String valueKey, bool value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[375];
    assert(checkSignature(function, 'ac22e971'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> serializeBytes(
    ({String objectKey, String valueKey, List<_i2.Uint8List> values}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[376];
    assert(checkSignature(function, '9884b232'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.values,
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
  Future<String> serializeBytes$2(
    ({String objectKey, String valueKey, _i2.Uint8List value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[377];
    assert(checkSignature(function, 'f21d52c7'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> serializeBytes32(
    ({String objectKey, String valueKey, List<_i2.Uint8List> values}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[378];
    assert(checkSignature(function, '201e43e2'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.values,
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
  Future<String> serializeBytes32$2(
    ({String objectKey, String valueKey, _i2.Uint8List value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[379];
    assert(checkSignature(function, '2d812b44'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> serializeInt(
    ({String objectKey, String valueKey, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[380];
    assert(checkSignature(function, '3f33db60'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> serializeInt$2(
    ({String objectKey, String valueKey, List<BigInt> values}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[381];
    assert(checkSignature(function, '7676e127'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.values,
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
  Future<String> serializeJson(
    ({String objectKey, String value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[382];
    assert(checkSignature(function, '9b3358b0'));
    final params = [
      args.objectKey,
      args.value,
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
  Future<String> serializeJsonType(
    ({String typeDescription, _i2.Uint8List value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[383];
    assert(checkSignature(function, '6d4f96a6'));
    final params = [
      args.typeDescription,
      args.value,
    ];
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
  Future<String> serializeJsonType$2(
    ({
      String objectKey,
      String valueKey,
      String typeDescription,
      _i2.Uint8List value
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[384];
    assert(checkSignature(function, '6f93bccb'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.typeDescription,
      args.value,
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
  Future<String> serializeString(
    ({String objectKey, String valueKey, List<String> values}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[385];
    assert(checkSignature(function, '561cd6f3'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.values,
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
  Future<String> serializeString$2(
    ({String objectKey, String valueKey, String value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[386];
    assert(checkSignature(function, '88da6d35'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> serializeUint(
    ({String objectKey, String valueKey, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[387];
    assert(checkSignature(function, '129e9002'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> serializeUint$2(
    ({String objectKey, String valueKey, List<BigInt> values}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[388];
    assert(checkSignature(function, 'fee9a469'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.values,
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
  Future<String> serializeUintToHex(
    ({String objectKey, String valueKey, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[389];
    assert(checkSignature(function, 'ae5a2ae8'));
    final params = [
      args.objectKey,
      args.valueKey,
      args.value,
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
  Future<String> setArbitraryStorage(
    ({_i1.EthereumAddress target}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[390];
    assert(checkSignature(function, 'e1631837'));
    final params = [args.target];
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
  Future<String> setBlockhash(
    ({BigInt blockNumber, _i2.Uint8List blockHash}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[391];
    assert(checkSignature(function, '5314b54a'));
    final params = [
      args.blockNumber,
      args.blockHash,
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
  Future<String> setEnv(
    ({String name, String value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[392];
    assert(checkSignature(function, '3d5923ee'));
    final params = [
      args.name,
      args.value,
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
  Future<String> setNonce(
    ({_i1.EthereumAddress account, BigInt newNonce}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[393];
    assert(checkSignature(function, 'f8e18b57'));
    final params = [
      args.account,
      args.newNonce,
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
  Future<String> setNonceUnsafe(
    ({_i1.EthereumAddress account, BigInt newNonce}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[394];
    assert(checkSignature(function, '9b67b21c'));
    final params = [
      args.account,
      args.newNonce,
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
  Future<Sign> sign(
    ({_i2.Uint8List digest}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[395];
    assert(checkSignature(function, '799cd333'));
    final params = [args.digest];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Sign(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<Sign$2> sign$2(
    ({_i1.EthereumAddress signer, _i2.Uint8List digest}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[396];
    assert(checkSignature(function, '8c1aa205'));
    final params = [
      args.signer,
      args.digest,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Sign$2(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> sign$3(
    ({dynamic wallet, _i2.Uint8List digest}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[397];
    assert(checkSignature(function, 'b25c5a25'));
    final params = [
      args.wallet,
      args.digest,
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
  Future<Sign$3> sign$4(
    ({BigInt privateKey, _i2.Uint8List digest}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[398];
    assert(checkSignature(function, 'e341eaa4'));
    final params = [
      args.privateKey,
      args.digest,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Sign$3(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> signCompact(
    ({dynamic wallet, _i2.Uint8List digest}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[399];
    assert(checkSignature(function, '3d0e292f'));
    final params = [
      args.wallet,
      args.digest,
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
  Future<SignCompact> signCompact$2(
    ({_i1.EthereumAddress signer, _i2.Uint8List digest}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[400];
    assert(checkSignature(function, '8e2f97bf'));
    final params = [
      args.signer,
      args.digest,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return SignCompact(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<SignCompact$2> signCompact$3(
    ({_i2.Uint8List digest}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[401];
    assert(checkSignature(function, 'a282dc4b'));
    final params = [args.digest];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return SignCompact$2(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<SignCompact$3> signCompact$4(
    ({BigInt privateKey, _i2.Uint8List digest}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[402];
    assert(checkSignature(function, 'cc2a781f'));
    final params = [
      args.privateKey,
      args.digest,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return SignCompact$3(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<SignP256> signP256(
    ({BigInt privateKey, _i2.Uint8List digest}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[403];
    assert(checkSignature(function, '83211b40'));
    final params = [
      args.privateKey,
      args.digest,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return SignP256(response);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> skip(
    ({bool skipTest, String reason}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[404];
    assert(checkSignature(function, 'c42a80a7'));
    final params = [
      args.skipTest,
      args.reason,
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
  Future<String> skip$2(
    ({bool skipTest}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[405];
    assert(checkSignature(function, 'dd82d13e'));
    final params = [args.skipTest];
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
  Future<String> sleep(
    ({BigInt duration}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[406];
    assert(checkSignature(function, 'fa9d8713'));
    final params = [args.duration];
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
  Future<String> snapshot({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[407];
    assert(checkSignature(function, '9711715a'));
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
  Future<String> snapshotGasLastCall(
    ({String group, String name}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[408];
    assert(checkSignature(function, '200c6772'));
    final params = [
      args.group,
      args.name,
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
  Future<String> snapshotGasLastCall$2(
    ({String name}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[409];
    assert(checkSignature(function, 'dd9fca12'));
    final params = [args.name];
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
  Future<String> snapshotState({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[410];
    assert(checkSignature(function, '9cd23835'));
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
  Future<String> snapshotValue(
    ({String name, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[411];
    assert(checkSignature(function, '51db805a'));
    final params = [
      args.name,
      args.value,
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
  Future<String> snapshotValue$2(
    ({String group, String name, BigInt value}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[412];
    assert(checkSignature(function, '6d2b27d8'));
    final params = [
      args.group,
      args.name,
      args.value,
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
  Future<List<String>> split(
    ({String input, String delimiter}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[413];
    assert(checkSignature(function, '8bb75533'));
    final params = [
      args.input,
      args.delimiter,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<String>();
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> startBroadcast({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[414];
    assert(checkSignature(function, '7fb5297f'));
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
  Future<String> startBroadcast$2(
    ({_i1.EthereumAddress signer}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[415];
    assert(checkSignature(function, '7fec2a8d'));
    final params = [args.signer];
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
  Future<String> startBroadcast$3(
    ({BigInt privateKey}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[416];
    assert(checkSignature(function, 'ce817d47'));
    final params = [args.privateKey];
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
  Future<String> startDebugTraceRecording({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[417];
    assert(checkSignature(function, '419c8832'));
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
  Future<String> startMappingRecording({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[418];
    assert(checkSignature(function, '3e9705c0'));
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
  Future<String> startPrank(
    ({_i1.EthereumAddress msgSender}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[419];
    assert(checkSignature(function, '06447d56'));
    final params = [args.msgSender];
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
  Future<String> startPrank$2(
    ({_i1.EthereumAddress msgSender, _i1.EthereumAddress txOrigin}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[420];
    assert(checkSignature(function, '45b56078'));
    final params = [
      args.msgSender,
      args.txOrigin,
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
  Future<String> startSnapshotGas(
    ({String name}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[421];
    assert(checkSignature(function, '3cad9d7b'));
    final params = [args.name];
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
  Future<String> startSnapshotGas$2(
    ({String group, String name}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[422];
    assert(checkSignature(function, '6cd0cc53'));
    final params = [
      args.group,
      args.name,
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
  Future<String> startStateDiffRecording({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[423];
    assert(checkSignature(function, 'cf22e3c9'));
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
  Future<String> stopAndReturnDebugTraceRecording({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[424];
    assert(checkSignature(function, 'ced398a2'));
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
  Future<String> stopAndReturnStateDiff({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[425];
    assert(checkSignature(function, 'aa5cf90e'));
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
  Future<String> stopBroadcast({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[426];
    assert(checkSignature(function, '76eadd36'));
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
  Future<String> stopExpectSafeMemory({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[427];
    assert(checkSignature(function, '0956441b'));
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
  Future<String> stopMappingRecording({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[428];
    assert(checkSignature(function, '0d4aae9b'));
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
  Future<String> stopPrank({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[429];
    assert(checkSignature(function, '90c5013b'));
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
  Future<String> stopSnapshotGas(
    ({String group, String name}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[430];
    assert(checkSignature(function, '0c9db707'));
    final params = [
      args.group,
      args.name,
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
  Future<String> stopSnapshotGas$2(
    ({String name}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[431];
    assert(checkSignature(function, '773b2805'));
    final params = [args.name];
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
  Future<String> stopSnapshotGas$3({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[432];
    assert(checkSignature(function, 'f6402eda'));
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
  Future<String> store(
    ({
      _i1.EthereumAddress target,
      _i2.Uint8List slot,
      _i2.Uint8List value
    }) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[433];
    assert(checkSignature(function, '70ca10bb'));
    final params = [
      args.target,
      args.slot,
      args.value,
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
  Future<String> toBase64(
    ({String data}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[434];
    assert(checkSignature(function, '3f8be2c8'));
    final params = [args.data];
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
  Future<String> toBase64$2(
    ({_i2.Uint8List data}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[435];
    assert(checkSignature(function, 'a5cbfe65'));
    final params = [args.data];
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
  Future<String> toBase64URL(
    ({String data}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[436];
    assert(checkSignature(function, 'ae3165b3'));
    final params = [args.data];
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
  Future<String> toBase64URL$2(
    ({_i2.Uint8List data}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[437];
    assert(checkSignature(function, 'c8bd0e4a'));
    final params = [args.data];
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
  Future<String> toLowercase(
    ({String input}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[438];
    assert(checkSignature(function, '50bb0884'));
    final params = [args.input];
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
  Future<String> toString(
    ({_i1.EthereumAddress value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[439];
    assert(checkSignature(function, '56ca623e'));
    final params = [args.value];
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
  Future<String> toString$2(
    ({BigInt value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[440];
    assert(checkSignature(function, '6900a3ae'));
    final params = [args.value];
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
  Future<String> toString$3(
    ({_i2.Uint8List value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[441];
    assert(checkSignature(function, '71aad10d'));
    final params = [args.value];
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
  Future<String> toString$4(
    ({bool value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[442];
    assert(checkSignature(function, '71dce7da'));
    final params = [args.value];
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
  Future<String> toString$5(
    ({BigInt value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[443];
    assert(checkSignature(function, 'a322c40e'));
    final params = [args.value];
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
  Future<String> toString$6(
    ({_i2.Uint8List value}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[444];
    assert(checkSignature(function, 'b11a19e8'));
    final params = [args.value];
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
  Future<String> toUppercase(
    ({String input}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[445];
    assert(checkSignature(function, '074ae3d7'));
    final params = [args.input];
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
  Future<String> transact(
    ({BigInt forkId, _i2.Uint8List txHash}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[446];
    assert(checkSignature(function, '4d8abc4b'));
    final params = [
      args.forkId,
      args.txHash,
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
  Future<String> transact$2(
    ({_i2.Uint8List txHash}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[447];
    assert(checkSignature(function, 'be646da1'));
    final params = [args.txHash];
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
  Future<String> trim(
    ({String input}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[448];
    assert(checkSignature(function, 'b2dad155'));
    final params = [args.input];
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
  Future<String> tryFfi(
    ({List<String> commandInput}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[449];
    assert(checkSignature(function, 'f45c1ce7'));
    final params = [args.commandInput];
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
  Future<String> txGasPrice(
    ({BigInt newGasPrice}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[450];
    assert(checkSignature(function, '48f50c0f'));
    final params = [args.newGasPrice];
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
  Future<String> unixTime({
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[451];
    assert(checkSignature(function, '625387dc'));
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
  Future<String> warp(
    ({BigInt newTimestamp}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[452];
    assert(checkSignature(function, 'e5d6bf02'));
    final params = [args.newTimestamp];
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
  Future<String> writeFile(
    ({String path, String data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[453];
    assert(checkSignature(function, '897e0a97'));
    final params = [
      args.path,
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
  Future<String> writeFileBinary(
    ({String path, _i2.Uint8List data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[454];
    assert(checkSignature(function, '1f21fc80'));
    final params = [
      args.path,
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
  Future<String> writeJson(
    ({String json, String path, String valueKey}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[455];
    assert(checkSignature(function, '35d6ad46'));
    final params = [
      args.json,
      args.path,
      args.valueKey,
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
  Future<String> writeJson$2(
    ({String json, String path}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[456];
    assert(checkSignature(function, 'e23cd19f'));
    final params = [
      args.json,
      args.path,
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
  Future<String> writeLine(
    ({String path, String data}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[457];
    assert(checkSignature(function, '619d897f'));
    final params = [
      args.path,
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
  Future<String> writeToml(
    ({String json, String path, String valueKey}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[458];
    assert(checkSignature(function, '51ac6a33'));
    final params = [
      args.json,
      args.path,
      args.valueKey,
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
  Future<String> writeToml$2(
    ({String json, String path}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[459];
    assert(checkSignature(function, 'c0865ba7'));
    final params = [
      args.json,
      args.path,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }
}

class PublicKeyP256 {
  PublicKeyP256(List<dynamic> response)
      : publicKeyX = (response[0] as BigInt),
        publicKeyY = (response[1] as BigInt);

  final BigInt publicKeyX;

  final BigInt publicKeyY;
}

class Sign {
  Sign(List<dynamic> response)
      : v = (response[0] as BigInt),
        r = (response[1] as _i2.Uint8List),
        s = (response[2] as _i2.Uint8List);

  final BigInt v;

  final _i2.Uint8List r;

  final _i2.Uint8List s;
}

class Sign$2 {
  Sign$2(List<dynamic> response)
      : v = (response[0] as BigInt),
        r = (response[1] as _i2.Uint8List),
        s = (response[2] as _i2.Uint8List);

  final BigInt v;

  final _i2.Uint8List r;

  final _i2.Uint8List s;
}

class Sign$3 {
  Sign$3(List<dynamic> response)
      : v = (response[0] as BigInt),
        r = (response[1] as _i2.Uint8List),
        s = (response[2] as _i2.Uint8List);

  final BigInt v;

  final _i2.Uint8List r;

  final _i2.Uint8List s;
}

class SignCompact {
  SignCompact(List<dynamic> response)
      : r = (response[0] as _i2.Uint8List),
        vs = (response[1] as _i2.Uint8List);

  final _i2.Uint8List r;

  final _i2.Uint8List vs;
}

class SignCompact$2 {
  SignCompact$2(List<dynamic> response)
      : r = (response[0] as _i2.Uint8List),
        vs = (response[1] as _i2.Uint8List);

  final _i2.Uint8List r;

  final _i2.Uint8List vs;
}

class SignCompact$3 {
  SignCompact$3(List<dynamic> response)
      : r = (response[0] as _i2.Uint8List),
        vs = (response[1] as _i2.Uint8List);

  final _i2.Uint8List r;

  final _i2.Uint8List vs;
}

class SignP256 {
  SignP256(List<dynamic> response)
      : r = (response[0] as _i2.Uint8List),
        s = (response[1] as _i2.Uint8List);

  final _i2.Uint8List r;

  final _i2.Uint8List s;
}
