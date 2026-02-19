import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:web3dart/web3dart.dart';

class ReservationTags extends EventTags
    with ReferencesListing<ReservationTags>, CommitmentTag<ReservationTags> {
  ReservationTags(super.tags);
}

class Reservation
    extends JsonContentNostrEvent<ReservationContent, ReservationTags> {
  static const Object _unset = Object();

  static const List<int> kinds = [kNostrKindReservation];
  static final EventTagsParser<ReservationTags> _tagParser =
      ReservationTags.new;
  static final EventContentParser<ReservationContent> _contentParser =
      ReservationContent.fromJson;
  static const requiredTags = [
    [kListingRefTag],
  ];

  Reservation(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindReservation,
            tagParser: _tagParser,
            contentParser: _contentParser);

  Reservation.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );

  Reservation copy({
    int? createdAt,
    Object? id = _unset,
    int? kind,
    String? pubKey,
    ReservationContent? content,
    ReservationTags? tags,
  }) {
    return Reservation(
      id: identical(id, _unset) ? this.id : id as String?,
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.parsedTags,
      content: content ?? this.parsedContent,
      sig: sig ?? this.sig,
    );
  }

  // Returns the most senior valid reservation for a listing, or null if no valid reservations exist. Seniority is determined by the following rules (in order of precedence):
  // 1. Reservations published by the listing owner are more senior than those published by others
  // 2. Cancelled reservations are more senior than non-cancelled reservations
  // 3. For reservations with the same publisher and cancellation status, the most recent reservation
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

  // Pass in reservations for same commitment hash and returns a status for the thread
  static ReservationStatus getReservationStatus(
      {required List<Reservation> reservations, required Listing listing}) {
    final validReservations = reservations
        .where(
            (reservation) => Reservation.validate(reservation, listing).isValid)
        .toList();
    final hostReservations = validReservations
        .where((reservation) => reservation.pubKey == listing.pubKey)
        .toList();
    final cancelledReservations = validReservations
        .where((reservation) => reservation.parsedContent.cancelled)
        .toList();

    if (validReservations.isEmpty) {
      return ReservationStatus.invalid;
    }

    if (cancelledReservations.isNotEmpty) {
      return ReservationStatus.cancelled;
    }

    final hasReservationEnded =
        validReservations.first.parsedContent.end.isBefore(DateTime.now());
    if (hasReservationEnded) {
      return ReservationStatus.completed;
    }
    if (hostReservations.isNotEmpty) {
      return ReservationStatus.confirmed;
    }

    return ReservationStatus.valid;
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

  bool isBlockedDate(KeyPair hostKey) {
    final salt = Reservation.getSaltForBlockedReservation(
        start: parsedContent.start, end: parsedContent.end, hostKey: hostKey);

    return parsedTags.commitmentHash ==
        ParticipationProof.computeCommitmentHash(hostKey.publicKey, salt);
  }

  static getSaltForBlockedReservation(
      {required DateTime start,
      required DateTime end,
      required KeyPair hostKey}) {
    return sha256
        .convert(utf8.encode(start.toIso8601String() +
            end.toIso8601String() +
            hostKey.privateKey!))
        .toString();
  }
}

class ReservationContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final bool cancelled;
  final PaymentProof? proof;

  ReservationContent({
    required this.start,
    required this.end,
    this.cancelled = false,
    this.proof,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "proof": proof?.toJson(),
      "cancelled": cancelled,
    };
  }

  ReservationContent copyWith({
    DateTime? start,
    DateTime? end,
    bool? cancelled,
    PaymentProof? proof,
  }) {
    return ReservationContent(
      start: start ?? this.start,
      end: end ?? this.end,
      cancelled: cancelled ?? this.cancelled,
      proof: proof ?? this.proof,
    );
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
        proof:
            json["proof"] != null ? PaymentProof.fromJson(json["proof"]) : null,
        cancelled: cancelled);
  }
}

class PaymentProof {
  Nip01Event hoster;
  Listing listing;
  ZapProof? zapProof;
  EscrowProof? escrowProof;
  // Include the signed seller reservation request if buyer offering sub-marketprice for this reservation so can be seen that hoster accepted the offer by signing the reservation request
  ReservationRequest? sellerReservationRequest;

  PaymentProof(
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

  static PaymentProof fromJson(Map<String, dynamic> json) {
    return PaymentProof(
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

enum ReservationStatus {
  valid,
  confirmed,
  invalid,
  cancelled,
  completed,
}
