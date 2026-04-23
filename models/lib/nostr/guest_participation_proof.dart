import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

/// Proof that reveals the private key needed to decrypt the reservation's
/// attached identity authorization capsule for public review verification.
class ParticipationProof {
  final String revealPrivateKey;
  final String role;

  ParticipationProof({
    required this.revealPrivateKey,
    this.role = 'buyer',
  });

  KeyPair get revealKeyPair => Bip340.fromPrivateKey(revealPrivateKey);
  String get revealPubkey => revealKeyPair.publicKey;

  Map<String, dynamic> toJson() {
    return {
      "revealPrivateKey": revealPrivateKey,
      "role": role,
    };
  }

  static ParticipationProof fromJson(Map<String, dynamic> json) {
    return ParticipationProof(
      revealPrivateKey: json["revealPrivateKey"] as String,
      role: json["role"] as String? ?? 'buyer',
    );
  }
}
