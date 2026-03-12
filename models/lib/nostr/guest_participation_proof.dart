import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:models/main.dart';

/// Proof that a guest was a participant in a reservation.
///
/// When a guest wants to prove they were in a reservation, they reveal this proof
/// in a review. Anyone can verify the guest participated by checking:
///   SHA256(guest_pubkey || salt) == reservation.guestCommitmentHash
///
/// This design ensures:
/// - Only the guest knows the salt for their reservation
/// - Revealing a proof for one reservation doesn't reveal other reservations
///   (each has a unique random salt)
/// - No host proof needed; host publishes the reservation directly
class ParticipationProof {
  /// Tweak material unique to this reservation.
  /// When revealed in a review, its `salt` is combined with the guest pubkey
  /// to verify participation and its `parity` is used for deterministic
  /// untweaking.
  final ReservationTweakMaterial tweakMaterial;

  ParticipationProof({
    required this.tweakMaterial,
  });

  /// Compute the guest commitment hash for verification
  ///
  /// This is computed as: SHA256(guest_pubkey || salt)
  /// Should match the reservation's guestCommitmentHash
  static String computeCommitmentHash(String guestPubKey, String salt) {
    final combined = guestPubKey + salt;
    return crypto.sha256.convert(utf8.encode(combined)).toString();
  }

  /// Verify this proof matches the given commitment hash
  bool verify(String guestPubKey, String commitmentHash) {
    return computeCommitmentHash(guestPubKey, tweakMaterial.salt) ==
        commitmentHash;
  }

  bool verifyTweakedPubKey({
    required String pubKey,
    required String tweakedPubKey,
    required ReservationTweakMaterial tweakMaterial,
  }) {
    return verifyTweakedPublicKey(
      publicKey: pubKey,
      salt: tweakMaterial.salt,
      tweakedPublicKey: tweakedPubKey,
      tweakedPublicKeyParity: tweakMaterial.parity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tweakMaterial": tweakMaterial.toJson(),
    };
  }

  static ParticipationProof fromJson(Map<String, dynamic> json) {
    return ParticipationProof(
      tweakMaterial: ReservationTweakMaterial.fromJson(
        json["tweakMaterial"] as Map<String, dynamic>,
      ),
    );
  }
}
