import 'package:models/main.dart';

/// Generates a fresh Nostr private key (hex) and prints it to stdout.
///
/// Usage:
///   dart run bin/generate_nsec.dart
///
/// Pipe directly into gcloud:
///   dart run bin/generate_nsec.dart | gcloud secrets versions add ESCROW_PRIVATE_KEY --data-file=-
void main() {
  final kp = Bip340.generatePrivateKey();
  print(kp.privateKey);
}
