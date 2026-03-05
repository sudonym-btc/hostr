import 'dart:io';

import 'package:models/main.dart';

void main(List<String> args) {
  final hex =
      args.isNotEmpty ? args.first : Platform.environment['PRIVATE_KEY'];
  if (hex == null || hex.isEmpty) {
    stderr.writeln('Usage: dart run bin/pubkey.dart <nsec_hex>');
    exit(1);
  }
  print(Bip340.fromPrivateKey(hex).publicKey);
}
