import 'dart:convert';
import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:web3dart/web3dart.dart';

class Reservation extends JsonContentNostrEvent<ReservationContent>
    with ReferencesListing<Reservation>, ReferencesThread<Reservation> {
  static const List<int> kinds = [kNostrKindReservation];
  static const requiredTags = [
    [kThreadRefTag],
    [kListingRefTag]
  ];

  Reservation(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : assert(hasRequiredTags(tags, Reservation.requiredTags)),
        super(kind: kNostrKindReservation);

  String? get commitmentHash {
    return getFirstTag('guestCommitmentHash');
  }

  set commitmentHash(String? value) {
    if (value == null) return;
    tags.add(['guestCommitmentHash', value]);
  }

  Reservation.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e) {
    parsedContent = ReservationContent.fromJson(json.decode(content));
  }

  static Reservation? getSeniorReservation(
      {required List<Reservation> reservations, required Listing listing}) {
    final validReservations = reservations
        .where((reservation) => Reservation.validate(reservation, listing))
        .toList();

    if (validReservations.isEmpty) {
      return null;
    }

    return validReservations.firstWhere(
      (reservation) => reservation.pubKey == listing.pubKey,
      orElse: () => validReservations.first,
    );
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
                .value
                .toInt()) {
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
        // TODO: Implement escrow proof validation
      }
    }
    return false;
  }
}

class ReservationContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final SelfSignedProof? proof;

  /// Blinded guest identifier: SHA256(guest_pubkey + random_salt)
  /// Only the guest knows the salt, allowing them to prove participation by revealing it.
  /// Each reservation has a unique random salt, preventing linking across reservations.
  final String guestCommitmentHash;

  ReservationContent({
    required this.start,
    required this.end,
    required this.guestCommitmentHash,
    this.proof,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "guestCommitmentHash": guestCommitmentHash,
      "proof": proof?.toJson(),
    };
  }

  static ReservationContent fromJson(Map<String, dynamic> json) {
    return ReservationContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
      guestCommitmentHash: json["guestCommitmentHash"] ?? '',
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
      "hoster": Nip01EventModel.fromEntity(hoster).toJson(),
      "listing": Nip01EventModel.fromEntity(listing).toJson(),
      "zapProof": zapProof?.toJson(),
      "escrowProof": escrowProof?.toJson(),
    };
  }

  static SelfSignedProof fromJson(Map<String, dynamic> json) {
    return SelfSignedProof(
      listing:
          Listing.fromNostrEvent(Nip01EventModel.fromJson(json["listing"])),
      zapProof:
          json["zapProof"] != null ? ZapProof.fromJson(json["zapProof"]) : null,
      escrowProof: json["escrowProof"] != null
          ? EscrowProof.fromJson(json["escrowProof"])
          : null,
      hoster: Nip01EventModel.fromJson(json["hoster"]),
    );
  }
}

class EscrowProof {
  String method;
  String chainId;
  String txHash;

  // Signed list of trusted escrows by hoster
  EscrowTrust hostsTrustedEscrows;
  EscrowMethod hostsEscrowMethods;

  EscrowProof(
      {required this.method,
      required this.chainId,
      required this.txHash,
      required this.hostsTrustedEscrows,
      required this.hostsEscrowMethods});

  toJson() {
    return {
      "method": method,
      "chainId": chainId,
      "txHash": txHash,
      "hostsEscrowMethods": hostsEscrowMethods.toString(),
      "hostsTrustedEscrows": hostsTrustedEscrows.toString(),
    };
  }

  // @TODO: Must validate all components
  static Future<bool> validate({
    required EscrowProof proof,
    required Web3Client client,
    required BigInt minAmount,
  }) async {
    final txHash = proof.txHash;
    if (txHash == null) {
      return false;
    }

    final information = await client.getTransactionByHash(txHash);
    if (information == null) {
      return false;
    }

    final receipt = await client.getTransactionReceipt(txHash);
    if (receipt == null) {
      return false;
    }

    final to = information.to;
    final value = information.value;
    if (to == null || value == null) {
      return false;
    }

    assert(
      (await proof.hostsTrustedEscrows.toNip51List())
          .elements
          .any((el) => el.value == to),
      'Transaction does not target escrow address',
    );
    assert(
      receipt.status == true,
      'Escrow funding transaction failed',
    );

    return false;
  }

  static fromJson(Map<String, dynamic> json) {
    return EscrowProof(
      method: json["method"],
      chainId: json["chainId"],
      txHash: json['txHash'],
      hostsEscrowMethods: EscrowMethod.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json["hostsEscrowMethods"]))),
      hostsTrustedEscrows: EscrowTrust.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json["hostsTrustedEscrows"]))),
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
