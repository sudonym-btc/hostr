import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show bytesToHex;

/// Lean descriptor for a single EVM contract call.
///
/// Maps 1:1 to `permissionless.Call` plus a human-readable [methodName].
/// Gas parameters are intentionally absent — the bundler/paymaster handles
/// gas pricing under ERC-4337.
class CallIntent {
  final EthereumAddress to;
  final Uint8List data;
  final EtherAmount value;
  final String methodName;

  const CallIntent({
    required this.to,
    required this.data,
    required this.value,
    required this.methodName,
  });

  bool get isZeroValue => value.getInWei == BigInt.zero;

  CallIntent copyWith({
    EthereumAddress? to,
    Uint8List? data,
    EtherAmount? value,
    String? methodName,
  }) => CallIntent(
    to: to ?? this.to,
    data: data ?? this.data,
    value: value ?? this.value,
    methodName: methodName ?? this.methodName,
  );

  Map<String, dynamic> toJson() => {
    'to': to.eip55With0x,
    'data': bytesToHex(data, include0x: true),
    'valueWei': value.getInWei.toString(),
    'methodName': methodName,
  };

  factory CallIntent.fromJson(Map<String, dynamic> json) {
    final rawData = (json['data'] as String).replaceFirst('0x', '');
    return CallIntent(
      to: EthereumAddress.fromHex(json['to'] as String),
      data: Uint8List.fromList(hex.decode(rawData)),
      value: EtherAmount.inWei(BigInt.parse(json['valueWei'] as String)),
      methodName: json['methodName'] as String,
    );
  }

  @override
  String toString() =>
      'CallIntent(method=$methodName, to=${to.eip55With0x}, '
      'value=${value.getInWei}, '
      'data=${bytesToHex(data, include0x: true)})';
}
