import 'dart:convert';
import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'listing.dart';
import 'type_json_content.dart';

class Reservation extends JsonContentNostrEvent<ReservationContent> {
  static const List<int> kinds = [NOSTR_KIND_RESERVATION];

  getCommitmentHash() {
    return tags.firstWhere((tag) => tag[0] == 'commitmentHash')[1];
  }

  Reservation.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e) {
    parsedContent = ReservationContent.fromJson(json.decode(content));
  }

  static validate(Reservation reservation, Listing listing) {
    // Any reservation published by the listing owner is valid
    if (reservation.pubKey == listing.pubKey) {
      return true;
    } else {
      if (reservation.parsedContent.proof == null) {
        return 'Must include a payment proof if self-publishing reservation event';
      }
      if (reservation
          .parsedContent.proof!.listing.parsedContent.requiresEscrow) {
        return 'Listing requires escrow for guest reservations';
      }
      if (reservation.parsedContent.proof!.zapProof != null) {
        // Validate zap proof
        ZapProof proof = reservation.parsedContent.proof!.zapProof!;

        // Check that zap amount is correct
        if (proof.receipt.amountSats! <
            reservation.parsedContent.proof!.listing
                .cost(reservation.parsedContent.start,
                    reservation.parsedContent.end)
                .value) {
          return 'Amount insufficient';
        }
        // Check that the receipt commits to the correct reservation request
        if (proof.receipt.recipient != listing.pubKey) {
          return 'Receipt recipient does not match listing pubKey';
        }

        // Check that the listing pubkey matches the proof's attached profile
        if (reservation.parsedContent.proof!.hoster.pubKey != listing.pubKey) {
          return 'Attached profile does not match listing pubkey';
        }

        // Check that the zap receipt is from the users lud16 provider

        if (proof.receipt.lnurl !=
            Metadata.fromEvent(reservation.parsedContent.proof!.hoster).lud16) {
          return 'Zap receipt LNURL does not match hoster lud16';
        }
      } else if (reservation.parsedContent.proof!.escrowProof != null) {
        // Validate escrow proof
        EscrowProof proof = reservation.parsedContent.proof!.escrowProof!;
      }
    }
    return false;
  }
}

class ReservationContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final SelfSignedProof? proof;

  ReservationContent({required this.start, required this.end, this.proof});

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "proof": proof?.toJson(),
    };
  }

  static ReservationContent fromJson(Map<String, dynamic> json) {
    return ReservationContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
      proof: json["proof"] != null
          ? SelfSignedProof.fromJson(json["proof"])
          : null,
    );
  }
}

class SelfSignedProof {
  Nip01Event hoster;
  Listing listing;
  ZapProof? zapProof;
  EscrowProof? escrowProof;

  SelfSignedProof(
      {required this.hoster,
      required this.listing,
      required this.zapProof,
      required this.escrowProof});

  Map<String, dynamic> toJson() {
    return {
      "listing": listing.toString(),
      "zapProof": zapProof,
      "escrowProof": escrowProof,
    };
  }

  static SelfSignedProof fromJson(Map<String, dynamic> json) {
    return SelfSignedProof(
      listing:
          Listing.fromNostrEvent(Nip01EventModel.fromJson(json["listing"])),
      zapProof: ZapProof.fromJson(json["zapProof"]),
      escrowProof: EscrowProof.fromJson(json["escrowProof"]),
      hoster: Nip01EventModel.fromJson(json["hoster"]),
    );
  }
}

class EscrowProof {
  dynamic escrowStateUponFunding;
  // Signed list of trusted escrows by hostr
  Nip01Event hostsTrustedEscrows;

  EscrowProof(
      {required this.escrowStateUponFunding,
      required this.hostsTrustedEscrows});
  toJson() {
    return {
      "escrowStateUponFunding": escrowStateUponFunding,
      "hostsTrustedEscrows": hostsTrustedEscrows.toString(),
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return EscrowProof(
      escrowStateUponFunding: json["escrowStateUponFunding"],
      hostsTrustedEscrows:
          Nip01EventModel.fromJson(json["hostsTrustedEscrows"]),
    );
  }
}

class ZapProof {
  ZapReceipt receipt;

  ZapProof({required this.receipt});

  toJson() {
    return {
      "receipt": receipt.toString(),
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return ZapProof(
      receipt: ZapReceipt.fromEvent(Nip01EventModel.fromJson(json["receipt"])),
    );
  }
}
