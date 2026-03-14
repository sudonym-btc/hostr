import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class ContractCallIntent {
  final EthereumAddress to;
  final Uint8List data;
  final EtherAmount value;
  final EtherAmount? gasPrice;
  final int? maxGas;
  final EthereumAddress? from;
  final String methodName;

  const ContractCallIntent({
    required this.to,
    required this.data,
    required this.value,
    this.gasPrice,
    this.maxGas,
    this.from,
    required this.methodName,
  });

  bool get isZeroValue => value.getInWei == BigInt.zero;

  ContractCallIntent copyWith({
    EthereumAddress? to,
    Uint8List? data,
    EtherAmount? value,
    EtherAmount? gasPrice,
    int? maxGas,
    EthereumAddress? from,
    String? methodName,
  }) => ContractCallIntent(
    to: to ?? this.to,
    data: data ?? this.data,
    value: value ?? this.value,
    gasPrice: gasPrice ?? this.gasPrice,
    maxGas: maxGas ?? this.maxGas,
    from: from ?? this.from,
    methodName: methodName ?? this.methodName,
  );

  Map<String, dynamic> toJson() => {
    'to': to.eip55With0x,
    'data': bytesToHex(data, include0x: true),
    'valueWei': value.getInWei.toString(),
    if (gasPrice != null) 'gasPriceWei': gasPrice!.getInWei.toString(),
    if (maxGas != null) 'maxGas': maxGas,
    if (from != null) 'from': from!.eip55With0x,
    'methodName': methodName,
  };

  factory ContractCallIntent.fromJson(Map<String, dynamic> json) {
    final rawData = (json['data'] as String).replaceFirst('0x', '');
    return ContractCallIntent(
      to: EthereumAddress.fromHex(json['to'] as String),
      data: Uint8List.fromList(hex.decode(rawData)),
      value: EtherAmount.inWei(BigInt.parse(json['valueWei'] as String)),
      gasPrice: json['gasPriceWei'] != null
          ? EtherAmount.inWei(BigInt.parse(json['gasPriceWei'] as String))
          : null,
      maxGas: json['maxGas'] as int?,
      from: json['from'] != null
          ? EthereumAddress.fromHex(json['from'] as String)
          : null,
      methodName: json['methodName'] as String,
    );
  }

  Transaction toTransaction({int? nonce}) => Transaction(
    to: to,
    data: data,
    value: value,
    gasPrice: gasPrice,
    maxGas: maxGas,
    nonce: nonce,
  );

  @override
  String toString() =>
      'ContractCallIntent(method=$methodName, to=${to.eip55With0x}, '
      'from=${from?.eip55With0x}, value=${value.getInWei}, '
      'gasPrice=${gasPrice?.getInWei}, maxGas=$maxGas, '
      'data=${bytesToHex(data, include0x: true)})';
}
