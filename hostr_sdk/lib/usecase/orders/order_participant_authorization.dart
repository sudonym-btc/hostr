import 'package:models/main.dart';

extension OrderParticipantRolePubkeys on Order {
  String participantPubkeyForRole(String role) {
    switch (role) {
      case 'buyer':
        return parsedTags.getTagValueByMarker('p', 'buyer') ??
            recipient ??
            pubKey;
      case 'seller':
        return parsedTags.getTagValueByMarker('p', 'seller') ??
            getPubKeyFromAnchor(parsedTags.listingAnchor);
      case 'escrow':
        final escrowPubkey =
            parsedTags.getTagValueByMarker('p', 'escrow') ??
            proof?.escrowProof?.escrowService.escrowPubkey;
        if (escrowPubkey != null && escrowPubkey.isNotEmpty) {
          return escrowPubkey;
        }
        throw UnsupportedError('No escrow participant pubkey on order');
      default:
        throw UnsupportedError('No participant pubkey mapping for role: $role');
    }
  }
}
