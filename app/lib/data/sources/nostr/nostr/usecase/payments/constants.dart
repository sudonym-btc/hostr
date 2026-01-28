import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:web3dart/web3dart.dart';

BigInt satoshiWeiFactor = BigInt.from(10).pow(10);
num btcSatoshiFactor = pow(10, 8);
num btcMilliSatoshiFactor = pow(10, 11);

Uint8List getBytes32(String eventId) {
  return Uint8List.fromList(hex.decode(eventId));
}

String getTopicHex(Uint8List idBytes32) {
  return bytesToHex(idBytes32, padToEvenLength: true, include0x: true);
}
