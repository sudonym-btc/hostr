import 'package:models/main.dart';

/// Proof that reveals the signed participant authorization plaintext used in a
/// order `participant_proof`. Review verification matches this plaintext
/// against the order proof's hash before trusting the authorization.
class ParticipationProof {
  final String role;
  final String participantPubkey;
  final String authorizationPayload;

  ParticipationProof({
    this.role = 'buyer',
    required this.participantPubkey,
    required this.authorizationPayload,
  });

  String get authorizationPayloadHash =>
      OrderParticipantProofTag.hashPayload(authorizationPayload);

  OrderParticipantAuthorizationPayload? get authorization =>
      OrderParticipantAuthorizationPayload.tryDecode(
        authorizationPayload,
      );

  Map<String, dynamic> toJson() {
    return {
      "role": role,
      "participantPubkey": participantPubkey,
      "authorizationPayload": authorizationPayload,
    };
  }

  static ParticipationProof fromJson(Map<String, dynamic> json) {
    return ParticipationProof(
      role: json["role"] as String? ?? 'buyer',
      participantPubkey: json["participantPubkey"] as String,
      authorizationPayload: json["authorizationPayload"] as String,
    );
  }
}
