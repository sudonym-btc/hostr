import 'dart:convert';
import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:web3dart/web3dart.dart';

class Reservation extends JsonContentNostrEvent<ReservationContent>
    with ReferencesListing<Reservation>, ReferencesThread<Reservation> {
  static const Object _unset = Object();

  static const List<int> kinds = [kNostrKindReservation];
  static const requiredTags = [
    [kThreadRefTag],
    [kListingRefTag],
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
    return getFirstTag(kCommitmentHashTag);
  }

  Reservation.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e) {
    parsedContent = ReservationContent.fromJson(json.decode(content));
  }

  Reservation copyWith({
    String? content,
    int? createdAt,
    Object? id = _unset,
    int? kind,
    String? pubKey,
    String? sig,
    List<String>? sources,
    List<List<String>>? tags,
    bool? validSig,
  }) {
    return Reservation.fromNostrEvent(
      Nip01Event(
        id: identical(id, _unset) ? this.id : id as String?,
        pubKey: pubKey ?? this.pubKey,
        createdAt: createdAt ?? this.createdAt,
        kind: kind ?? this.kind,
        tags: tags ?? this.tags,
        content: content ?? this.content,
        sig: sig ?? this.sig,
        validSig: validSig ?? this.validSig,
        sources: sources ?? this.sources,
      ),
    );
  }

  Reservation copyWithContent({
    DateTime? start,
    DateTime? end,
    SelfSignedProof? proof,
    String? commitmentHash,
    bool? cancelled,
  }) {
    return Reservation(
      pubKey: pubKey,
      tags: tags.map((tag) => [...tag]).toList(),
      createdAt: createdAt,
      sig: sig,
      content: ReservationContent(
        start: start ?? parsedContent.start,
        end: end ?? parsedContent.end,
        proof: proof ?? parsedContent.proof,
        commitmentHash: commitmentHash ?? parsedContent.commitmentHash,
        cancelled: cancelled ?? parsedContent.cancelled,
      ),
    );
  }

  static Reservation? getSeniorReservation(
      {required List<Reservation> reservations, required Listing listing}) {
    final validReservations = reservations
        .where(
            (reservation) => Reservation.validate(reservation, listing).isValid)
        .toList();

    if (validReservations.isEmpty) {
      return null;
    }

    // Sort to prefer (in order): host then guest, cancelled then non-cancelled reservations
    validReservations.sort((a, b) {
      int score(Reservation r) {
        final isHost = r.pubKey == listing.pubKey;
        final isCancelled = r.parsedContent.cancelled;
        return [isCancelled, isHost].where((a) => a).length;
      }

      final sa = score(a);
      final sb = score(b);
      if (sa != sb) return sa - sb;

      // If same score, prefer the most recent event
      final at = DateTime.fromMillisecondsSinceEpoch(a.createdAt * 1000);
      final bt = DateTime.fromMillisecondsSinceEpoch(b.createdAt * 1000);
      return bt.compareTo(at);
    });

    return validReservations.first;
  }

  static ValidationResult validate(Reservation reservation, Listing listing) {
    final fieldResults = <String, FieldValidation>{};

    void setField(String key, bool ok, [String? message]) {
      fieldResults[key] = FieldValidation(ok: ok, message: message);
    }

    // Any reservation published by the listing owner is valid
    if (reservation.pubKey == listing.pubKey) {
      setField('publisher', true);
      return ValidationResult(
        isValid: true,
        fields: fieldResults,
      );
    }

    if (reservation.parsedContent.proof == null) {
      setField(
        'proof',
        false,
        'Must include a payment proof if self-publishing reservation event',
      );
      return ValidationResult(
        isValid: false,
        fields: fieldResults,
      );
    }

    final proof = reservation.parsedContent.proof!;

    if (proof.zapProof != null) {
      final zapProof = proof.zapProof!;
      final receipt = ZapReceipt.fromEvent(zapProof.receipt);

      final expected = proof.listing
          .cost(reservation.parsedContent.start, reservation.parsedContent.end)
          .value
          .toInt();
      final amountOk =
          receipt.amountSats != null && receipt.amountSats! >= expected;
      setField(
        'zapAmount',
        amountOk,
        amountOk ? null : 'Amount insufficient',
      );

      final recipientOk = receipt.recipient == listing.pubKey;
      setField(
        'zapRecipient',
        recipientOk,
        recipientOk ? null : 'Receipt recipient does not match listing pubKey',
      );

      final hosterOk = proof.hoster.pubKey == listing.pubKey;
      setField(
        'hosterProfile',
        hosterOk,
        hosterOk ? null : 'Attached profile does not match listing pubkey',
      );

      final lnurlOk = receipt.lnurl == Metadata.fromEvent(proof.hoster).lud16;
      setField(
        'zapLnurl',
        lnurlOk,
        lnurlOk ? null : 'Zap receipt LNURL does not match hoster lud16',
      );
    } else if (proof.escrowProof != null) {
      setField('escrowProof', true);
      // TODO: Implement escrow proof validation and update field results
    } else {
      setField(
        'proofType',
        false,
        'Unsupported or missing payment proof type',
      );
    }

    final isValid = fieldResults.values.every((field) => field.ok);
    return ValidationResult(isValid: isValid, fields: fieldResults);
  }
}

class ReservationContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final SelfSignedProof? proof;

  /// Blinded guest identifier: SHA256(guest_pubkey + random_salt)
  /// Only the guest/host knows the salt, allowing them to prove participation by revealing it.
  /// Each reservation has a unique random salt, preventing linking across reservations.
  final String commitmentHash;
  final bool cancelled;

  ReservationContent({
    required this.start,
    required this.end,
    required this.commitmentHash,
    this.cancelled = false,
    this.proof,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "guestCommitmentHash": commitmentHash,
      "proof": proof?.toJson(),
      "cancelled": cancelled,
    };
  }

  static ReservationContent fromJson(Map<String, dynamic> json) {
    final cancelledValue = json["cancelled"];
    final cancelled = cancelledValue is bool
        ? cancelledValue
        : (cancelledValue is String
            ? cancelledValue.toLowerCase() == 'true'
            : false);
    return ReservationContent(
        start: DateTime.parse(json["start"]),
        end: DateTime.parse(json["end"]),
        commitmentHash: json["guestCommitmentHash"] ?? '',
        proof: json["proof"] != null
            ? SelfSignedProof.fromJson(json["proof"])
            : null,
        cancelled: cancelled);
  }
}

class SelfSignedProof {
  Nip01Event hoster;
  Listing listing;
  ZapProof? zapProof;
  EscrowProof? escrowProof;
  // Include the signed seller reservation request if buyer offering sub-marketprice for this reservation so can be seen that hoster accepted the offer by signing the reservation request
  ReservationRequest? sellerReservationRequest;

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
  final String txHash;

  final EscrowService escrowService;
  // Signed list of trusted escrows by hoster
  final EscrowTrust hostsTrustedEscrows;
  final EscrowMethod hostsEscrowMethods;

  EscrowProof(
      {required this.txHash,
      required this.hostsTrustedEscrows,
      required this.hostsEscrowMethods,
      required this.escrowService});

  toJson() {
    return {
      "txHash": txHash,
      "escrowService": escrowService.toString(),
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
      escrowService: EscrowService.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json["escrowService"]))),
      txHash: json['txHash'],
      hostsEscrowMethods: EscrowMethod.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json["hostsEscrowMethods"]))),
      hostsTrustedEscrows: EscrowTrust.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json["hostsTrustedEscrows"]))),
    );
  }
}

class ZapProof {
  final Nip01EventModel receipt;
  ZapProof({required this.receipt});

  toJson() {
    return {
      "receipt": receipt.toJsonString(),
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return ZapProof(
        receipt: Nip01EventModel.fromJson(jsonDecode(json["receipt"])));
  }
}
