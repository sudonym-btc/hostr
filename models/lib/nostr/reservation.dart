import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

/// The stage of a reservation in its lifecycle.
///
/// - [negotiate]: Mutable proposal / counter-offer. Only exchanged via DMs;
///   clients MUST ignore published negotiate events for availability.
/// - [commit]: Immutable booking. Only `stage=commit` affects availability.
/// - [cancel]: Cancels a prior commit for the same `trade_id`.
enum ReservationStage {
  negotiate,
  commit,
  cancel,
}

class ReservationTags extends EventTags
    with ReferencesListing<ReservationTags> {
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
    final nonce = Reservation.getNonceForBlockedReservation(
        start: parsedContent.start, end: parsedContent.end, hostKey: hostKey);

    return getDtag() == nonce;
  }

  static getNonceForBlockedReservation(
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

class ReservationContent extends EventContent with CommitTerms {
  final DateTime start;
  final DateTime end;
  final bool cancelled;
  final PaymentProof? proof;

  /// Private recipient witness used to derive recipient commitments.
  /// Keep this for negotiate/private flows; omit from public commit events.
  final String? salt;

  /// The lifecycle stage of this reservation snapshot.
  final ReservationStage stage;

  /// Number of rooms / units requested.
  final int quantity;

  /// The agreed (or proposed) price for this reservation.
  final Amount? amount;

  /// Public key of the intended recipient (e.g. the guest).
  final String? recipient;

  /// Schnorr signatures over [commitHash], keyed by public key.
  @override
  final Map<String, String> signatures;

  /// The fields whose values are locked into the commitment hash.
  @override
  Set<String> get committedFields =>
      {'start', 'end', 'quantity', 'amount', 'recipient'};

  ReservationContent({
    required this.start,
    required this.end,
    this.cancelled = false,
    this.proof,
    this.salt,
    this.stage = ReservationStage.negotiate,
    this.quantity = 1,
    this.amount,
    this.recipient,
    this.signatures = const {},
  });

  factory ReservationContent.negotiate({
    required DateTime start,
    required DateTime end,
    PaymentProof? proof,
    String? salt,
    int quantity = 1,
    Amount? amount,
    String? recipient,
    Map<String, String> signatures = const {},
  }) {
    return ReservationContent(
      start: start,
      end: end,
      cancelled: false,
      proof: proof,
      salt: salt,
      stage: ReservationStage.negotiate,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      signatures: signatures,
    );
  }

  factory ReservationContent.commit({
    required DateTime start,
    required DateTime end,
    PaymentProof? proof,
    String? salt,
    int quantity = 1,
    Amount? amount,
    String? recipient,
    Map<String, String> signatures = const {},
  }) {
    return ReservationContent(
      start: start,
      end: end,
      cancelled: false,
      proof: proof,
      salt: salt,
      stage: ReservationStage.commit,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      signatures: signatures,
    );
  }

  factory ReservationContent.cancel({
    required DateTime start,
    required DateTime end,
    PaymentProof? proof,
    String? salt,
    int quantity = 1,
    Amount? amount,
    String? recipient,
    Map<String, String> signatures = const {},
  }) {
    return ReservationContent(
      start: start,
      end: end,
      cancelled: true,
      proof: proof,
      salt: salt,
      stage: ReservationStage.cancel,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      signatures: signatures,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toUtc().toIso8601String(),
      "end": end.toUtc().toIso8601String(),
      "proof": proof?.toJson(),
      if (salt != null) "salt": salt,
      "cancelled": cancelled,
      "stage": stage.name,
      "quantity": quantity,
      if (amount != null) "amount": amount!.toJson(),
      if (recipient != null) "recipient": recipient,
      if (signatures.isNotEmpty)
        "signatures": Map<String, String>.from(signatures),
    };
  }

  ReservationContent copyWith({
    DateTime? start,
    DateTime? end,
    bool? cancelled,
    PaymentProof? proof,
    String? salt,
    ReservationStage? stage,
    int? quantity,
    Amount? amount,
    String? recipient,
    Map<String, String>? signatures,
  }) {
    return ReservationContent(
      start: start ?? this.start,
      end: end ?? this.end,
      cancelled: cancelled ?? this.cancelled,
      proof: proof ?? this.proof,
      salt: salt ?? this.salt,
      stage: stage ?? this.stage,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      signatures: signatures ?? this.signatures,
    );
  }

  static ReservationContent fromJson(Map<String, dynamic> json) {
    final cancelledValue = json["cancelled"];
    final cancelled = cancelledValue is bool
        ? cancelledValue
        : (cancelledValue is String
            ? cancelledValue.toLowerCase() == 'true'
            : false);
    final stageStr = json["stage"] as String?;
    final stage = stageStr != null
        ? ReservationStage.values.firstWhere(
            (e) => e.name == stageStr,
            orElse: () => ReservationStage.negotiate,
          )
        : ReservationStage.negotiate;
    final sigs = json["signatures"] as Map<String, dynamic>?;
    return ReservationContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
      proof:
          json["proof"] != null ? PaymentProof.fromJson(json["proof"]) : null,
      salt: json["salt"] as String?,
      cancelled: cancelled,
      stage: stage,
      quantity: json["quantity"] as int? ?? 1,
      amount: json["amount"] != null ? Amount.fromJson(json["amount"]) : null,
      recipient: json["recipient"] as String?,
      signatures: sigs?.map((k, v) => MapEntry(k, v as String)) ?? const {},
    );
  }

  /// Whether this reservation is in the negotiation stage.
  bool get isNegotiation => stage == ReservationStage.negotiate;

  /// Whether this reservation is a committed booking.
  bool get isCommit => stage == ReservationStage.commit;

  /// Whether this reservation is a cancellation.
  bool get isCancel => stage == ReservationStage.cancel;
}

class PaymentProof {
  Nip01Event hoster;
  Listing listing;
  ZapProof? zapProof;
  EscrowProof? escrowProof;

  /// Include the signed seller negotiate reservation if buyer offering
  /// sub-market price, so it can be seen that hoster accepted the offer.
  Reservation? sellerNegotiateReservation;

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
