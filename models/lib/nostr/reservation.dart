import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

const _publishedAtTag = 'published_at';
const kReservationPubkeyProofTag = 'pubkey_proof';
const kReservationPubkeyProofSchemeNip44V1 = 'nip44-v1';

List<List<String>> _withPublishedAt(
  List<List<String>> tags,
  int publishedAt,
) {
  if (tags.any((t) => t.length >= 2 && t[0] == _publishedAtTag)) {
    return tags;
  }
  return [
    ...tags,
    [_publishedAtTag, publishedAt.toString()],
  ];
}

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

/// A participant tag for a reservation event.
///
/// Emitted as `["p", pubkey]` when [role] is `null`, or
/// `["p", pubkey, "", role]` with the standard NIP-01 relay-hint slot
/// left empty when a role is specified.
class PTag {
  final String pubkey;

  /// Optional relay URL hint (NIP-01 3rd position) to help clients
  /// discover this participant's events without a separate NIP-65 lookup.
  final String relayHint;
  final String? role;

  const PTag(this.pubkey, {this.relayHint = '', this.role});

  /// Creates a tag for the seller (host) participant.
  const PTag.seller(this.pubkey, {this.relayHint = ''}) : role = 'seller';

  /// Creates a tag for the buyer (guest) participant.
  const PTag.buyer(this.pubkey, {this.relayHint = ''}) : role = 'buyer';

  /// Creates a tag for the escrow service participant.
  const PTag.escrow(this.pubkey, {this.relayHint = ''}) : role = 'escrow';

  /// Converts to a raw Nostr tag array.
  /// Format: `["p", <pubkey>, <relay-hint>, <role>]`
  List<String> toTag() =>
      role != null ? ['p', pubkey, relayHint, role!] : ['p', pubkey, relayHint];
}

class ReservationTags extends EventTags
    with ReferencesListing<ReservationTags> {
  ReservationTags(super.tags);

  List<ReservationPubkeyProofTag> get pubkeyProofs => tags
      .map(ReservationPubkeyProofTag.tryFromTag)
      .whereType<ReservationPubkeyProofTag>()
      .toList(growable: false);

  List<ReservationPubkeyProofTag> pubkeyProofsFor({
    required String role,
    required String recipientPubkey,
  }) {
    return pubkeyProofs
        .where(
          (proof) =>
              proof.role == role && proof.recipientPubkey == recipientPubkey,
        )
        .toList(growable: false);
  }
}

/// Encrypted reservation tag that can prove a hidden participant pubkey.
///
/// Shape:
/// `["pubkey_proof", role, recipientPubkey, scheme, ciphertext]`
///
/// The current scheme is [kReservationPubkeyProofSchemeNip44V1], where
/// [ciphertext] decrypts to a [ReservationPubkeyProofPayload].
class ReservationPubkeyProofTag {
  final String role;
  final String recipientPubkey;
  final String scheme;
  final String ciphertext;

  const ReservationPubkeyProofTag({
    required this.role,
    required this.recipientPubkey,
    required this.scheme,
    required this.ciphertext,
  });

  List<String> toTag() => [
        kReservationPubkeyProofTag,
        role,
        recipientPubkey,
        scheme,
        ciphertext,
      ];

  static ReservationPubkeyProofTag? tryFromTag(List<String> tag) {
    if (tag.length < 5 || tag.first != kReservationPubkeyProofTag) {
      return null;
    }
    return ReservationPubkeyProofTag(
      role: tag[1],
      recipientPubkey: tag[2],
      scheme: tag[3],
      ciphertext: tag[4],
    );
  }
}

/// Compact plaintext encrypted into a [ReservationPubkeyProofTag].
///
/// Plaintext is the JSON-encoded signed [TradeKeyAuthorization] event.
class ReservationPubkeyProofPayload {
  final String pubkey;
  final TradeKeyAuthorization authorizationEvent;

  const ReservationPubkeyProofPayload({
    required this.pubkey,
    required this.authorizationEvent,
  });

  factory ReservationPubkeyProofPayload.fromAuthorizationEvent(
    TradeKeyAuthorization authorizationEvent,
  ) {
    return ReservationPubkeyProofPayload(
      pubkey: authorizationEvent.pubKey,
      authorizationEvent: authorizationEvent,
    );
  }

  String encode() => authorizationEvent.model.toJsonString();

  static ReservationPubkeyProofPayload? tryDecode(String plaintext) {
    try {
      final event = Nip01EventModel.fromJson(jsonDecode(plaintext));
      if (event.kind != kNostrKindTradeKeyAuthorization) {
        return null;
      }
      final authorization = TradeKeyAuthorization.fromNostrEvent(event);
      return ReservationPubkeyProofPayload.fromAuthorizationEvent(
        authorization,
      );
    } catch (_) {
      return null;
    }
  }

  bool verifiesForReservation({
    required String tradeId,
    required String listingAnchor,
    required String participantPubkey,
    required String role,
  }) {
    return authorizationEvent.authorizesParticipant(
      identityPubkey: pubkey,
      listingAnchor: listingAnchor,
      tradeId: tradeId,
      participantPubkey: participantPubkey,
      role: role,
    );
  }
}

// Public reservations can reveal a durable participant pubkey to authorized
// recipients with encrypted `pubkey_proof` tags while keeping role-marked `p`
// tags disposable. The decrypted signed authorization event remains the
// authority.
class ReservationExpectedAmount {
  final DenominatedAmount listingPrice;
  final DenominatedAmount? negotiatedAmount;
  final DenominatedAmount expectedAmount;
  final bool hasOffListAmount;
  final bool isBelowListing;
  final bool sellerCommitOk;
  final bool negotiationAllowed;
  final bool usesNegotiatedAmount;

  const ReservationExpectedAmount({
    required this.listingPrice,
    required this.negotiatedAmount,
    required this.expectedAmount,
    required this.hasOffListAmount,
    required this.isBelowListing,
    required this.sellerCommitOk,
    required this.negotiationAllowed,
    required this.usesNegotiatedAmount,
  });

  String? get overrideFailureReason {
    if (!hasOffListAmount) return null;
    if (!sellerCommitOk) {
      return 'Missing valid host commitment for negotiated amount';
    }
    if (isBelowListing && !negotiationAllowed) {
      return 'Listing does not allow negotiation below listing price';
    }
    return null;
  }
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

  // ── Convenience getters ─────────────────────────────────────────────
  DateTime? get start => parsedContent.start;
  DateTime? get end => parsedContent.end;
  bool get cancelled => stage == ReservationStage.cancel;
  PaymentProof? get proof => parsedContent.proof;
  ReservationStage get stage => parsedContent.stage;
  int get quantity => parsedContent.quantity;
  DenominatedAmount? get amount => parsedContent.amount;
  String? get recipient => parsedContent.recipient;
  CommitAuthorization? get commitAuthorization =>
      parsedContent.commitAuthorization;
  bool get isNegotiation => parsedContent.isNegotiation;
  bool get isCommit => parsedContent.isCommit;
  bool get isCancel => parsedContent.isCancel;
  bool get isSeller => pubKey == getPubKeyFromAnchor(parsedTags.listingAnchor);
  bool get isBuyer => !isSeller;

  String commitHash() => parsedContent.commitHash();
  bool verifyCommit(String authorPubkey) {
    final tradeId = getDtag();
    if (tradeId == null || commitAuthorization == null) return false;
    return commitAuthorization!.authorizesReservation(
      authorPubkey: authorPubkey,
      listingAnchor: parsedTags.listingAnchor,
      tradeId: tradeId,
      commitHash: commitHash(),
    );
  }

  ReservationExpectedAmount resolveExpectedAmount({required Listing listing}) {
    final listingAuthor = getPubKeyFromAnchor(parsedTags.listingAnchor);
    final listingPrice =
        listing.cost(start: start, end: end, quantity: quantity);
    final negotiatedAmount = amount;
    final sameDenomination =
        negotiatedAmount?.denomination == listingPrice.denomination;
    final hasOffListAmount = negotiatedAmount != null &&
        (!sameDenomination || negotiatedAmount.value != listingPrice.value);
    final isBelowListing = negotiatedAmount != null &&
        sameDenomination &&
        negotiatedAmount.value < listingPrice.value;
    final sellerCommitOk =
        !hasOffListAmount ? true : verifyCommit(listingAuthor);
    final sellerAcceptedTerms = hasOffListAmount && sellerCommitOk;
    final negotiationAllowed =
        !isBelowListing || listing.negotiable || sellerAcceptedTerms;
    final usesNegotiatedAmount = sellerAcceptedTerms && negotiationAllowed;

    return ReservationExpectedAmount(
      listingPrice: listingPrice,
      negotiatedAmount: negotiatedAmount,
      expectedAmount: usesNegotiatedAmount ? negotiatedAmount : listingPrice,
      hasOffListAmount: hasOffListAmount,
      isBelowListing: isBelowListing,
      sellerCommitOk: sellerCommitOk,
      negotiationAllowed: negotiationAllowed,
      usesNegotiatedAmount: usesNegotiatedAmount,
    );
  }

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

  // ── Factory constructor ─────────────────────────────────────────────
  factory Reservation.create({
    required String pubKey,
    required String dTag,
    required String listingAnchor,
    DateTime? start,
    DateTime? end,
    // Content fields
    ReservationStage stage = ReservationStage.negotiate,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    PaymentProof? proof,
    CommitAuthorization? commitAuthorization,
    // Tag fields
    String? threadAnchor,
    List<PTag> pTags = const [],
    List<ReservationPubkeyProofTag> pubkeyProofs = const [],
    List<List<String>> extraTags = const [],
    // Event-level
    String? id,
    int? createdAt,
  }) {
    final eventCreatedAt =
        createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Reservation(
      id: id,
      pubKey: pubKey,
      createdAt: eventCreatedAt,
      tags: ReservationTags(
        _withPublishedAt(
          [
            [kListingRefTag, listingAnchor],
            ['d', dTag],
            if (threadAnchor != null) [kThreadRefTag, threadAnchor],
            for (final p in pTags) p.toTag(),
            for (final proof in pubkeyProofs) proof.toTag(),
            ...extraTags,
          ],
          eventCreatedAt,
        ),
      ),
      content: ReservationContent(
        start: start,
        end: end,
        stage: stage,
        quantity: quantity,
        amount: amount,
        recipient: recipient,
        proof: proof,
        commitAuthorization: commitAuthorization,
      ),
    );
  }

  Reservation copy({
    int? createdAt,
    Object? id = _unset,
    int? kind,
    String? pubKey,
    ReservationContent? content,
    ReservationTags? tags,
    Object? sig = _unset,
  }) {
    final firstPublishedAt = parsedTags.getTagInt(_publishedAtTag);
    final copiedTags = tags ?? this.parsedTags;

    return Reservation(
      id: identical(id, _unset) ? this.id : id as String?,
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      tags: ReservationTags(
        firstPublishedAt == null
            ? copiedTags.tags
            : _withPublishedAt(copiedTags.tags, firstPublishedAt),
      ),
      content: content ?? this.parsedContent,
      sig: identical(sig, _unset) ? this.sig : sig as String?,
    );
  }

  // Returns the most senior valid reservation for a listing, or null if no valid reservations exist. Seniority is determined by the following rules (in order of precedence):
  // 1. Reservations published by the listing owner are more senior than those published by others
  // 2. Cancelled reservations are more senior than non-cancelled reservations
  // 3. For reservations with the same publisher and cancellation status, the most recent reservation
  static Reservation? getSeniorReservation({
    required List<Reservation> reservations,
  }) {
    final listingAuthor = reservations.first.parsedTags.listingAnchor;
    final validReservations = reservations
        .where((reservation) => Reservation.validate(reservation).isValid)
        .toList();

    if (validReservations.isEmpty) {
      return null;
    }

    // Sort to prefer (in order): host then guest, cancelled then non-cancelled reservations
    validReservations.sort((a, b) {
      int score(Reservation r) {
        final isHost = r.pubKey == listingAuthor;
        final isCancelled = r.cancelled;
        return [isCancelled, isHost].where((a) => a).length;
      }

      final sa = score(a);
      final sb = score(b);
      if (sa != sb) return sa - sb;

      // If same score, prefer the most recent event
      final at =
          DateTime.fromMillisecondsSinceEpoch(a.createdAt * 1000, isUtc: true);
      final bt =
          DateTime.fromMillisecondsSinceEpoch(b.createdAt * 1000, isUtc: true);
      return bt.compareTo(at);
    });

    return validReservations.first;
  }

  // Pass in reservations for same commitment hash and returns a status for the thread
  static ReservationStatus getReservationStatus({
    required List<Reservation> reservations,
  }) {
    final validReservations = reservations
        .where((reservation) => Reservation.validate(reservation).isValid)
        .toList();
    final hostReservations = validReservations
        .where((reservation) =>
            reservation.pubKey ==
            getPubKeyFromAnchor(reservation.parsedTags.listingAnchor))
        .toList();
    final cancelledReservations = validReservations
        .where((reservation) => reservation.cancelled)
        .toList();

    if (validReservations.isEmpty) {
      return ReservationStatus.invalid;
    }

    if (cancelledReservations.isNotEmpty) {
      return ReservationStatus.cancelled;
    }

    final reservationEnd = validReservations.first.end;
    final hasReservationEnded = reservationEnd != null &&
        reservationEnd.isBefore(DateTime.now().toUtc());
    if (hasReservationEnded) {
      return ReservationStatus.completed;
    }
    if (hostReservations.isNotEmpty) {
      return ReservationStatus.confirmed;
    }

    return ReservationStatus.valid;
  }

  static ValidationResult validate(Reservation reservation) {
    final fieldResults = <String, FieldValidation>{};

    void setField(String key, bool ok, [String? message]) {
      fieldResults[key] = FieldValidation(ok: ok, message: message);
    }

    final listingAuthor =
        getPubKeyFromAnchor(reservation.parsedTags.listingAnchor);
    // Any reservation published by the listing owner is valid
    if (reservation.pubKey == listingAuthor) {
      setField('publisher', true);
      return ValidationResult(
        isValid: true,
        fields: fieldResults,
      );
    }

    if (reservation.proof == null) {
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

    final proof = reservation.proof!;

    if (proof.zapProof != null) {
      final zapProof = proof.zapProof!;
      final receipt = ZapReceipt.fromEvent(zapProof.receipt);

      final expectedAmount = reservation.resolveExpectedAmount(
        listing: proof.listing,
      );

      if (expectedAmount.hasOffListAmount) {
        if (expectedAmount.isBelowListing) {
          setField(
            'negotiationAllowed',
            expectedAmount.negotiationAllowed,
            expectedAmount.negotiationAllowed
                ? null
                : 'Listing does not allow negotiation below listing price',
          );
        }
        setField(
          'sellerCommit',
          expectedAmount.sellerCommitOk,
          expectedAmount.sellerCommitOk
              ? null
              : 'Missing valid host commitment for negotiated amount',
        );
      }

      final amountOk = receipt.amountSats != null &&
          receipt.amountSats! >= expectedAmount.expectedAmount.value.toInt();
      setField(
        'zapAmount',
        amountOk,
        amountOk ? null : 'Amount insufficient',
      );

      final recipientOk = receipt.recipient == listingAuthor;
      setField(
        'zapRecipient',
        recipientOk,
        recipientOk ? null : 'Receipt recipient does not match listing pubKey',
      );

      final hosterOk = proof.hoster.pubKey == listingAuthor;
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
    if (start == null || end == null) return false;
    final nonce = Reservation.getNonceForBlockedReservation(
        start: start!, end: end!, hostKey: hostKey);

    return getDtag() == nonce;
  }

  static getNonceForBlockedReservation(
      {required DateTime start,
      required DateTime end,
      required KeyPair hostKey}) {
    final normalized = normalizeOrderedDateBounds(start, end);

    return sha256
        .convert(utf8.encode(normalized.start.toIso8601String() +
            normalized.end.toIso8601String() +
            hostKey.privateKey!))
        .toString();
  }
}

class ReservationContent extends EventContent with CommitTerms {
  final DateTime? start;
  final DateTime? end;
  final PaymentProof? proof;

  /// The lifecycle stage of this reservation snapshot.
  final ReservationStage stage;

  /// Number of rooms / units requested.
  final int quantity;

  /// The agreed (or proposed) price for this reservation.
  final DenominatedAmount? amount;

  /// Public key of the intended recipient (e.g. the guest).
  final String? recipient;

  /// Structured seller authorization event over [commitHash].
  final CommitAuthorization? commitAuthorization;

  /// The fields whose values are locked into the commitment hash.
  @override
  Set<String> get committedFields =>
      {'start', 'end', 'quantity', 'amount', 'recipient'};

  /// Whether this reservation is cancelled – derived from [stage].
  bool get cancelled => stage == ReservationStage.cancel;

  ReservationContent({
    this.start,
    this.end,
    this.proof,
    this.stage = ReservationStage.negotiate,
    this.quantity = 1,
    this.amount,
    this.recipient,
    this.commitAuthorization,
  });

  factory ReservationContent.negotiate({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return ReservationContent(
      start: start,
      end: end,
      proof: proof,
      stage: ReservationStage.negotiate,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      commitAuthorization: commitAuthorization,
    );
  }

  factory ReservationContent.commit({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return ReservationContent(
      start: start,
      end: end,
      proof: proof,
      stage: ReservationStage.commit,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      commitAuthorization: commitAuthorization,
    );
  }

  factory ReservationContent.cancel({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return ReservationContent(
      start: start,
      end: end,
      proof: proof,
      stage: ReservationStage.cancel,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      commitAuthorization: commitAuthorization,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (start != null) "start": start!.toUtc().toIso8601String(),
      if (end != null) "end": end!.toUtc().toIso8601String(),
      "proof": proof?.toJson(),
      "stage": stage.name,
      "quantity": quantity,
      if (amount != null) "amount": amount!.toJson(),
      if (recipient != null) "recipient": recipient,
      if (commitAuthorization != null)
        "commitAuthorization":
            Nip01EventModel.fromEntity(commitAuthorization!).toJson(),
    };
  }

  ReservationContent copyWith({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    ReservationStage? stage,
    int? quantity,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return ReservationContent(
      start: start ?? this.start,
      end: end ?? this.end,
      proof: proof ?? this.proof,
      stage: stage ?? this.stage,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      commitAuthorization: commitAuthorization ?? this.commitAuthorization,
    );
  }

  static ReservationContent fromJson(Map<String, dynamic> json) {
    final stage = ReservationStage.values.firstWhere(
      (e) => e.name == json["stage"],
    );
    final commitAuthorizationJson =
        json["commitAuthorization"] as Map<String, dynamic>?;
    return ReservationContent(
      start: json["start"] != null ? DateTime.parse(json["start"]) : null,
      end: json["end"] != null ? DateTime.parse(json["end"]) : null,
      proof:
          json["proof"] != null ? PaymentProof.fromJson(json["proof"]) : null,
      stage: stage,
      quantity: json["quantity"] as int? ?? 1,
      amount: json["amount"] != null
          ? DenominatedAmount.fromJson(json["amount"])
          : null,
      recipient: json["recipient"] as String?,
      commitAuthorization: commitAuthorizationJson != null
          ? CommitAuthorization.fromNostrEvent(
              Nip01EventModel.fromJson(commitAuthorizationJson),
            )
          : null,
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
  final EscrowMethod hostsEscrowMethods;

  EscrowProof(
      {required this.txHash,
      required this.hostsEscrowMethods,
      required this.escrowService});

  toJson() {
    return {
      "txHash": txHash,
      "escrowService": escrowService.toString(),
      "hostsEscrowMethods": hostsEscrowMethods.toString(),
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return EscrowProof(
      escrowService: EscrowService.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json["escrowService"]))),
      txHash: json['txHash'],
      hostsEscrowMethods: EscrowMethod.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json["hostsEscrowMethods"]))),
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
