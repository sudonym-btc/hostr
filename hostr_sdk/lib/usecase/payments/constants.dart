import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:web3dart/web3dart.dart';

BigInt satoshiWeiFactor = BigInt.from(10).pow(10);
BigInt btcSatoshiFactor = BigInt.from(10).pow(8);
BigInt btcMilliSatoshiFactor = BigInt.from(10).pow(11);

String normalizeBytes32Hex(String eventId) {
  final normalized = eventId.trim().toLowerCase();
  final stripped = normalized.startsWith('0x')
      ? normalized.substring(2)
      : normalized;

  if (stripped.length != 64) {
    throw ArgumentError(
      'Expected 32-byte hex (64 chars) trade id, got length ${stripped.length}: $eventId',
    );
  }

  final hexPattern = RegExp(r'^[0-9a-f]{64}$');
  if (!hexPattern.hasMatch(stripped)) {
    throw ArgumentError('Trade id is not valid hex: $eventId');
  }

  return stripped;
}

Uint8List getBytes32(String eventId) {
  return Uint8List.fromList(hex.decode(normalizeBytes32Hex(eventId)));
}

String getTopicHex(Uint8List idBytes32) {
  return bytesToHex(idBytes32, padToEvenLength: true, include0x: true);
}
