import 'dart:typed_data';

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
