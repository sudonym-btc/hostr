// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;import 'package:wallet/wallet.dart' as _i2;import 'dart:typed_data' as _i3;final _contractAbi = _i1.ContractAbi.fromJson('[{"type":"constructor","inputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"basic","inputs":[],"outputs":[{"name":"a","type":"uint256","internalType":"uint256"},{"name":"b","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"const","inputs":[],"outputs":[{"name":"t","type":"bytes32","internalType":"bytes32"}],"stateMutability":"pure"},{"type":"function","name":"deep_map","inputs":[{"name":"","type":"address","internalType":"address"},{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"deep_map_struct","inputs":[{"name":"","type":"address","internalType":"address"},{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"a","type":"uint256","internalType":"uint256"},{"name":"b","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"edgeCaseArray","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"exists","inputs":[],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"extra_sload","inputs":[],"outputs":[{"name":"t","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"getRandomPacked","inputs":[{"name":"size","type":"uint256","internalType":"uint256"},{"name":"offset","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getRandomPacked","inputs":[{"name":"shifts","type":"uint8","internalType":"uint8"},{"name":"shiftSizes","type":"uint8[]","internalType":"uint8[]"},{"name":"elem","type":"uint8","internalType":"uint8"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"hidden","inputs":[],"outputs":[{"name":"t","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"map_addr","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"map_bool","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"map_packed","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"map_struct","inputs":[{"name":"","type":"address","internalType":"address"}],"outputs":[{"name":"a","type":"uint256","internalType":"uint256"},{"name":"b","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"map_uint","inputs":[{"name":"","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"read_struct_lower","inputs":[{"name":"who","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"read_struct_upper","inputs":[{"name":"who","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"setRandomPacking","inputs":[{"name":"val","type":"uint256","internalType":"uint256"},{"name":"size","type":"uint256","internalType":"uint256"},{"name":"offset","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setRandomPacking","inputs":[{"name":"val","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"tA","inputs":[],"outputs":[{"name":"","type":"uint248","internalType":"uint248"}],"stateMutability":"view"},{"type":"function","name":"tB","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"tC","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"tD","inputs":[],"outputs":[{"name":"","type":"uint248","internalType":"uint248"}],"stateMutability":"view"},{"type":"function","name":"tE","inputs":[],"outputs":[{"name":"","type":"bytes32","internalType":"bytes32"}],"stateMutability":"view"},{"type":"function","name":"tF","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"tG","inputs":[],"outputs":[{"name":"","type":"int256","internalType":"int256"}],"stateMutability":"view"},{"type":"function","name":"tH","inputs":[],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"}]', 'StorageTest', );class StorageTest extends _i1.GeneratedContract {StorageTest({required _i2.EthereumAddress address, required _i1.Web3Client client, int? chainId, }) : super(_i1.DeployedContract(_contractAbi, address, ), client, chainId, );

/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<Basic> basic({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
1
];
assert(checkSignature(function, '15e8b345'));
final params = [];
final response =  await read(function, params, atBlock, );
return  Basic(response); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<_i3.Uint8List> const({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
2
];
assert(checkSignature(function, '3b80a793'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as _i3.Uint8List); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> deep_map(({_i2.EthereumAddress $param0, _i2.EthereumAddress $param1}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
3
];
assert(checkSignature(function, '8cd8156d'));
final params = [args.$param0, args.$param1, ];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<Deep_map_struct> deep_map_struct(({_i2.EthereumAddress $param2, _i2.EthereumAddress $param3}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
4
];
assert(checkSignature(function, '0310c060'));
final params = [args.$param2, args.$param3, ];
final response =  await read(function, params, atBlock, );
return  Deep_map_struct(response); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> edgeCaseArray(({BigInt $param4}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
5
];
assert(checkSignature(function, 'e92e9dc4'));
final params = [args.$param4];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> exists({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
6
];
assert(checkSignature(function, '267c4ae4'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<_i3.Uint8List> extra_sload({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
7
];
assert(checkSignature(function, '9e7936e6'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as _i3.Uint8List); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> getRandomPacked(({BigInt size, BigInt offset}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
8
];
assert(checkSignature(function, '1aa844b4'));
final params = [args.size, args.offset, ];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> getRandomPacked$2(({BigInt shifts, List<BigInt> shiftSizes, BigInt elem}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
9
];
assert(checkSignature(function, '61a97569'));
final params = [args.shifts, args.shiftSizes, args.elem, ];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<_i3.Uint8List> hidden({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
10
];
assert(checkSignature(function, 'aef6d4b1'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as _i3.Uint8List); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> map_addr(({_i2.EthereumAddress $param10}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
11
];
assert(checkSignature(function, 'a73e40cc'));
final params = [args.$param10];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<bool> map_bool(({_i2.EthereumAddress $param11}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
12
];
assert(checkSignature(function, '8c6b4551'));
final params = [args.$param11];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as bool); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> map_packed(({_i2.EthereumAddress $param12}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
13
];
assert(checkSignature(function, '5c23fe9e'));
final params = [args.$param12];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<Map_struct> map_struct(({_i2.EthereumAddress $param13}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
14
];
assert(checkSignature(function, '504429bf'));
final params = [args.$param13];
final response =  await read(function, params, atBlock, );
return  Map_struct(response); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> map_uint(({BigInt $param14}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
15
];
assert(checkSignature(function, '6a56c3d4'));
final params = [args.$param14];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> read_struct_lower(({_i2.EthereumAddress who}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
16
];
assert(checkSignature(function, '41b6edb2'));
final params = [args.who];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> read_struct_upper(({_i2.EthereumAddress who}) args, {_i1.BlockNum? atBlock, }) async  { final function = self.abi.functions  [
17
];
assert(checkSignature(function, '3eae2218'));
final params = [args.who];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [transaction] parameter can be used to override parameters
/// like the gas price, nonce and max gas. The `data` and `to` fields will be
/// set by the contract.
Future<String> setRandomPacking(({BigInt val, BigInt size, BigInt offset}) args, {required _i1.Credentials credentials, _i1.Transaction? transaction, }) async  { final function = self.abi.functions  [
18
];
assert(checkSignature(function, '1971f00b'));
final params = [args.val, args.size, args.offset, ];
return  write(credentials, transaction, function, params, ); } 
/// The optional [transaction] parameter can be used to override parameters
/// like the gas price, nonce and max gas. The `data` and `to` fields will be
/// set by the contract.
Future<String> setRandomPacking$2(({BigInt val}) args, {required _i1.Credentials credentials, _i1.Transaction? transaction, }) async  { final function = self.abi.functions  [
19
];
assert(checkSignature(function, 'aa463826'));
final params = [args.val];
return  write(credentials, transaction, function, params, ); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> tA({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
20
];
assert(checkSignature(function, '79da7e4d'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<bool> tB({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
21
];
assert(checkSignature(function, '57351c45'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as bool); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<bool> tC({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
22
];
assert(checkSignature(function, 'eb53f990'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as bool); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> tD({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
23
];
assert(checkSignature(function, 'e4c62a11'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<_i3.Uint8List> tE({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
24
];
assert(checkSignature(function, 'b7e19e29'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as _i3.Uint8List); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<_i2.EthereumAddress> tF({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
25
];
assert(checkSignature(function, '08f23aad'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as _i2.EthereumAddress); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<BigInt> tG({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
26
];
assert(checkSignature(function, 'e5ed1efe'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as BigInt); } 
/// The optional [atBlock] parameter can be used to view historical data. When
/// set, the function will be evaluated in the specified block. By default, the
/// latest on-chain block will be used.
Future<bool> tH({_i1.BlockNum? atBlock}) async  { final function = self.abi.functions  [
27
];
assert(checkSignature(function, '4f87aeb7'));
final params = [];
final response =  await read(function, params, atBlock, );
return  (response  [
0
] as bool); } 
 }
class Basic {Basic(List<dynamic> response) : a = (response[0] as BigInt), b = (response[1] as BigInt);

final BigInt a;

final BigInt b;

 }
class Deep_map_struct {Deep_map_struct(List<dynamic> response) : a = (response[0] as BigInt), b = (response[1] as BigInt);

final BigInt a;

final BigInt b;

 }
class Map_struct {Map_struct(List<dynamic> response) : a = (response[0] as BigInt), b = (response[1] as BigInt);

final BigInt a;

final BigInt b;

 }
