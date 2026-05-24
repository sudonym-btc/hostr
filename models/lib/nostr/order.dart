import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

const _publishedAtTag = 'published_at';
const kOrderParticipantProofTag = 'participant_proof';
const kOrderParticipantProofSchemeNip44 = 'nip44';

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

/// The stage of a order in its lifecycle.
///
/// - [negotiate]: Mutable proposal / counter-offer. Only exchanged via DMs;
///   clients MUST ignore published negotiate events for availability.
/// - [commit]: Immutable booking. Only `stage=commit` affects availability.
/// - [cancel]: Cancels a prior commit for the same `trade_id`.
enum OrderStage {
  negotiate,
  commit,
  cancel,
}

/// A participant tag for a order event.
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

class OrderTags extends EventTags with ReferencesListing<OrderTags> {
  OrderTags(super.tags);

  List<OrderParticipantProofTag> get participantProofs => tags
      .map(OrderParticipantProofTag.tryFromTag)
      .whereType<OrderParticipantProofTag>()
      .toList(growable: false);
}

/// Encrypted participant identity capsule for one role-marked `p` tag.
///
/// Shape:
/// `["participant_proof", role, participantPubkey, recipientPubkey, scheme, payloadHash, payload]`
///
/// [payloadHash] is the sha256 hex digest of the plaintext signed participant
/// authorization. [payload] is that authorization encrypted for
/// [recipientPubkey] when [scheme] is [kOrderParticipantProofSchemeNip44].
class OrderParticipantProofTag {
  final String role;
  final String participantPubkey;
  final String recipientPubkey;
  final String scheme;
  final String payloadHash;
  final String payload;

  const OrderParticipantProofTag({
    required this.role,
    required this.participantPubkey,
    required this.recipientPubkey,
    required this.scheme,
    required this.payloadHash,
    required this.payload,
  });

  static String hashPayload(String payload) =>
      sha256.convert(utf8.encode(payload)).toString();

  bool matchesPayload(String plaintext) =>
      payloadHash == hashPayload(plaintext);

  List<String> toTag() => [
        kOrderParticipantProofTag,
        role,
        participantPubkey,
        recipientPubkey,
        scheme,
        payloadHash,
        payload,
      ];

  static OrderParticipantProofTag? tryFromTag(List<String> tag) {
    if (tag.length < 7 || tag.first != kOrderParticipantProofTag) {
      return null;
    }
    return OrderParticipantProofTag(
      role: tag[1],
      participantPubkey: tag[2],
      recipientPubkey: tag[3],
      scheme: tag[4],
      payloadHash: tag[5],
      payload: tag[6],
    );
  }
}

/// Compact plaintext encrypted into a [OrderParticipantProofTag].
///
/// Plaintext is the JSON-encoded signed [TradeKeyAuthorization] event.
class OrderParticipantAuthorizationPayload {
  final String pubkey;
  final TradeKeyAuthorization authorizationEvent;

  const OrderParticipantAuthorizationPayload({
    required this.pubkey,
    required this.authorizationEvent,
  });

  factory OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
    TradeKeyAuthorization authorizationEvent,
  ) {
    return OrderParticipantAuthorizationPayload(
      pubkey: authorizationEvent.pubKey,
      authorizationEvent: authorizationEvent,
    );
  }

  String encode() => authorizationEvent.model.toJsonString();

  static OrderParticipantAuthorizationPayload? tryDecode(
    String plaintext,
  ) {
    try {
      final event = Nip01EventModel.fromJson(jsonDecode(plaintext));
      if (event.kind != kNostrKindTradeKeyAuthorization) {
        return null;
      }
      final authorization = TradeKeyAuthorization.fromNostrEvent(event);
      return OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
        authorization,
      );
    } catch (_) {
      return null;
    }
  }

  bool verifiesForOrder({
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

class OrderExpectedAmount {
  final DenominatedAmount listingPrice;
  final DenominatedAmount? negotiatedAmount;
  final DenominatedAmount expectedAmount;
  final bool hasOffListAmount;
  final bool isBelowListing;
  final bool sellerCommitOk;
  final bool negotiationAllowed;
  final bool usesNegotiatedAmount;

  const OrderExpectedAmount({
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

class Order extends JsonContentNostrEvent<OrderContent, OrderTags> {
  static const Object _unset = Object();

  static const List<int> kinds = [kNostrKindOrder];
  static final EventTagsParser<OrderTags> _tagParser = OrderTags.new;
  static final EventContentParser<OrderContent> _contentParser =
      OrderContent.fromJson;
  static const requiredTags = [
    [kListingRefTag],
  ];

  // ── Convenience getters ─────────────────────────────────────────────
  DateTime? get start => parsedContent.start;
  DateTime? get end => parsedContent.end;
  bool get cancelled => stage == OrderStage.cancel;
  PaymentProof? get proof => parsedContent.proof;
  OrderStage get stage => parsedContent.stage;
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
    return commitAuthorization!.authorizesOrder(
      authorPubkey: authorPubkey,
      listingAnchor: parsedTags.listingAnchor,
      tradeId: tradeId,
      commitHash: commitHash(),
      committedFields: parsedContent.committedFields,
    );
  }

  OrderExpectedAmount resolveExpectedAmount({required Listing listing}) {
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

    return OrderExpectedAmount(
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

  Order(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindOrder,
            tagParser: _tagParser,
            contentParser: _contentParser);

  Order.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
          requiredTags: requiredTags,
        );

  // ── Factory constructor ─────────────────────────────────────────────
  factory Order.create({
    required String pubKey,
    required String dTag,
    required String listingAnchor,
    DateTime? start,
    DateTime? end,
    // Content fields
    OrderStage stage = OrderStage.negotiate,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    PaymentProof? proof,
    CommitAuthorization? commitAuthorization,
    // Tag fields
    List<PTag> pTags = const [],
    List<List<String>> extraTags = const [],
    // Event-level
    String? id,
    int? createdAt,
  }) {
    final eventCreatedAt =
        createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return Order(
      id: id,
      pubKey: pubKey,
      createdAt: eventCreatedAt,
      tags: OrderTags(
        _withPublishedAt(
          [
            [kListingRefTag, listingAnchor],
            ['d', dTag],
            for (final p in pTags) p.toTag(),
            ...extraTags,
          ],
          eventCreatedAt,
        ),
      ),
      content: OrderContent(
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

  Order copy({
    int? createdAt,
    Object? id = _unset,
    int? kind,
    String? pubKey,
    OrderContent? content,
    OrderTags? tags,
    Object? sig = _unset,
  }) {
    final firstPublishedAt = parsedTags.getTagInt(_publishedAtTag);
    final copiedTags = tags ?? this.parsedTags;

    return Order(
      id: identical(id, _unset) ? this.id : id as String?,
      pubKey: pubKey ?? this.pubKey,
      createdAt: createdAt ?? this.createdAt,
      tags: OrderTags(
        firstPublishedAt == null
            ? copiedTags.tags
            : _withPublishedAt(copiedTags.tags, firstPublishedAt),
      ),
      content: content ?? this.parsedContent,
      sig: identical(sig, _unset) ? this.sig : sig as String?,
    );
  }

  // Returns the most senior valid order for a listing, or null if no valid orders exist. Seniority is determined by the following rules (in order of precedence):
  // 1. Orders published by the listing owner are more senior than those published by others
  // 2. Cancelled orders are more senior than non-cancelled orders
  // 3. For orders with the same publisher and cancellation status, the most recent order
  static Order? getSeniorOrder({
    required List<Order> orders,
  }) {
    final listingAuthor = orders.first.parsedTags.listingAnchor;
    final validOrders =
        orders.where((order) => Order.validate(order).isValid).toList();

    if (validOrders.isEmpty) {
      return null;
    }

    // Sort to prefer (in order): host then guest, cancelled then non-cancelled orders
    validOrders.sort((a, b) {
      int score(Order r) {
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

    return validOrders.first;
  }

  // Pass in orders for same commitment hash and returns a status for the thread
  static OrderStatus getOrderStatus({
    required List<Order> orders,
  }) {
    final validOrders =
        orders.where((order) => Order.validate(order).isValid).toList();
    final hostOrders = validOrders
        .where((order) =>
            order.pubKey == getPubKeyFromAnchor(order.parsedTags.listingAnchor))
        .toList();
    final cancelledOrders =
        validOrders.where((order) => order.cancelled).toList();

    if (validOrders.isEmpty) {
      return OrderStatus.invalid;
    }

    if (cancelledOrders.isNotEmpty) {
      return OrderStatus.cancelled;
    }

    final orderEnd = validOrders.first.end;
    final hasOrderEnded =
        orderEnd != null && orderEnd.isBefore(DateTime.now().toUtc());
    if (hasOrderEnded) {
      return OrderStatus.completed;
    }
    if (hostOrders.isNotEmpty) {
      return OrderStatus.confirmed;
    }

    return OrderStatus.valid;
  }

  static ValidationResult validate(Order order) {
    final fieldResults = <String, FieldValidation>{};

    void setField(String key, bool ok, [String? message]) {
      fieldResults[key] = FieldValidation(ok: ok, message: message);
    }

    final listingAuthor = getPubKeyFromAnchor(order.parsedTags.listingAnchor);
    // Any order published by the listing owner is valid
    if (order.pubKey == listingAuthor) {
      setField('publisher', true);
      return ValidationResult(
        isValid: true,
        fields: fieldResults,
      );
    }

    if (order.proof == null) {
      setField(
        'proof',
        false,
        'Must include a payment proof if self-publishing order event',
      );
      return ValidationResult(
        isValid: false,
        fields: fieldResults,
      );
    }

    final proof = order.proof!;

    final paymentProof = proof.paymentProof;
    if (paymentProof == null) {
      setField(
        'paymentProof',
        false,
        'Unsupported or missing payment proof type',
      );
    } else if (paymentProof.method == PaymentMethod.zap &&
        paymentProof.params is ZapPaymentProofParams) {
      final params = paymentProof.params as ZapPaymentProofParams;
      final receipt = ZapReceipt.fromEvent(params.receipt);

      final expectedAmount = order.resolveExpectedAmount(
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

      final recipientProfileOk =
          params.recipientProfile.pubKey == listingAuthor;
      setField(
        'recipientProfile',
        recipientProfileOk,
        recipientProfileOk
            ? null
            : 'Attached recipient profile does not match listing pubkey',
      );

      final lnurlOk =
          receipt.lnurl == Metadata.fromEvent(params.recipientProfile).lud16;
      setField(
        'zapLnurl',
        lnurlOk,
        lnurlOk ? null : 'Zap receipt LNURL does not match hoster lud16',
      );
    } else if (paymentProof.method == PaymentMethod.evm &&
        paymentProof.params is EvmPaymentProofParams) {
      final escrow = proof.escrow;
      if (escrow == null) {
        setField(
          'escrow',
          false,
          'Missing escrow context for EVM payment proof',
        );
      } else {
        setField('escrow', true);
      }
      // TODO: Implement EVM escrow proof validation and update field results
    } else {
      setField(
        'paymentProof',
        false,
        'Unsupported or missing payment proof type',
      );
    }

    final isValid = fieldResults.values.every((field) => field.ok);
    return ValidationResult(isValid: isValid, fields: fieldResults);
  }

  bool isBlockedDate(KeyPair hostKey) {
    if (start == null || end == null) return false;
    final nonce = Order.getNonceForBlockedOrder(
        start: start!, end: end!, hostKey: hostKey);

    return getDtag() == nonce;
  }

  static getNonceForBlockedOrder(
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

class OrderContent extends EventContent with CommitTerms {
  final DateTime? start;
  final DateTime? end;
  final PaymentProof? proof;

  /// The lifecycle stage of this order snapshot.
  final OrderStage stage;

  /// Number of rooms / units requested.
  final int quantity;

  /// The agreed (or proposed) price for this order.
  final DenominatedAmount? amount;

  /// Public key of the intended recipient (e.g. the guest).
  final String? recipient;

  /// Structured seller authorization event over [commitHash].
  final CommitAuthorization? commitAuthorization;

  /// The fields whose values are locked into the commitment hash.
  @override
  Set<String> get committedFields =>
      {'start', 'end', 'quantity', 'amount', 'recipient'};

  /// Whether this order is cancelled – derived from [stage].
  bool get cancelled => stage == OrderStage.cancel;

  OrderContent({
    this.start,
    this.end,
    this.proof,
    this.stage = OrderStage.negotiate,
    this.quantity = 1,
    this.amount,
    this.recipient,
    this.commitAuthorization,
  });

  factory OrderContent.negotiate({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return OrderContent(
      start: start,
      end: end,
      proof: proof,
      stage: OrderStage.negotiate,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      commitAuthorization: commitAuthorization,
    );
  }

  factory OrderContent.commit({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return OrderContent(
      start: start,
      end: end,
      proof: proof,
      stage: OrderStage.commit,
      quantity: quantity,
      amount: amount,
      recipient: recipient,
      commitAuthorization: commitAuthorization,
    );
  }

  factory OrderContent.cancel({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    int quantity = 1,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return OrderContent(
      start: start,
      end: end,
      proof: proof,
      stage: OrderStage.cancel,
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

  OrderContent copyWith({
    DateTime? start,
    DateTime? end,
    PaymentProof? proof,
    OrderStage? stage,
    int? quantity,
    DenominatedAmount? amount,
    String? recipient,
    CommitAuthorization? commitAuthorization,
  }) {
    return OrderContent(
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

  static OrderContent fromJson(Map<String, dynamic> json) {
    final stage = OrderStage.values.firstWhere(
      (e) => e.name == json["stage"],
    );
    final commitAuthorizationJson =
        json["commitAuthorization"] as Map<String, dynamic>?;
    return OrderContent(
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

  /// Whether this order is in the negotiation stage.
  bool get isNegotiation => stage == OrderStage.negotiate;

  /// Whether this order is a committed booking.
  bool get isCommit => stage == OrderStage.commit;

  /// Whether this order is a cancellation.
  bool get isCancel => stage == OrderStage.cancel;
}

class PaymentProof {
  final Listing listing;
  final PaymentProofEvidence? paymentProof;
  final EscrowPaymentContext? escrow;

  PaymentProof({
    required this.listing,
    required this.paymentProof,
    this.escrow,
  });

  factory PaymentProof.evm({
    required Listing listing,
    required String txHash,
    required EscrowService escrowService,
    required EscrowMethod sellerEscrowMethod,
  }) {
    return PaymentProof(
      listing: listing,
      paymentProof: PaymentProofEvidence(
        method: PaymentMethod.evm,
        params: EvmPaymentProofParams(txHash: txHash),
      ),
      escrow: EscrowPaymentContext(
        escrowService: escrowService,
        sellerEscrowMethod: sellerEscrowMethod,
      ),
    );
  }

  factory PaymentProof.zap({
    required Listing listing,
    required Nip01EventModel receipt,
    required Nip01Event recipientProfile,
  }) {
    return PaymentProof(
      listing: listing,
      paymentProof: PaymentProofEvidence(
        method: PaymentMethod.zap,
        params: ZapPaymentProofParams(
          receipt: receipt,
          recipientProfile: recipientProfile,
        ),
      ),
    );
  }

  EvmPaymentProofParams? get evmParams {
    final proof = paymentProof;
    final params = proof?.params;
    if (proof?.method == PaymentMethod.evm && params is EvmPaymentProofParams) {
      return params;
    }
    return null;
  }

  ZapPaymentProofParams? get zapParams {
    final proof = paymentProof;
    final params = proof?.params;
    if (proof?.method == PaymentMethod.zap && params is ZapPaymentProofParams) {
      return params;
    }
    return null;
  }

  bool get hasEscrowPaymentProof => evmParams != null && escrow != null;

  Map<String, dynamic> toJson() {
    return {
      "listing": Nip01EventModel.fromEntity(listing).toJson(),
      "paymentProof": paymentProof?.toJson(),
      if (escrow != null) "escrow": escrow!.toJson(),
    };
  }

  static PaymentProof fromJson(Map<String, dynamic> json) {
    final listing = Listing.fromNostrEvent(
      Nip01EventModel.fromJson(json["listing"]),
    );

    final paymentProofJson = json["paymentProof"];
    if (paymentProofJson is Map) {
      return PaymentProof(
        listing: listing,
        paymentProof: PaymentProofEvidence.fromJson(
          Map<String, dynamic>.from(paymentProofJson),
        ),
        escrow: json["escrow"] != null
            ? EscrowPaymentContext.fromJson(
                Map<String, dynamic>.from(json["escrow"] as Map),
              )
            : null,
      );
    }

    return PaymentProof(
      listing: listing,
      paymentProof: null,
    );
  }
}

class EscrowPaymentContext {
  final EscrowService escrowService;
  final EscrowMethod sellerEscrowMethod;

  EscrowPaymentContext({
    required this.sellerEscrowMethod,
    required this.escrowService,
  });

  Map<String, dynamic> toJson() {
    return {
      "escrowService": escrowService.toString(),
      "sellerEscrowMethod": sellerEscrowMethod.toString(),
    };
  }

  static EscrowPaymentContext fromJson(Map<String, dynamic> json) {
    final escrowService = EscrowService.fromNostrEvent(
      Nip01EventModel.fromJson(jsonDecode(json["escrowService"])),
    );
    return EscrowPaymentContext(
      escrowService: escrowService,
      sellerEscrowMethod: EscrowMethod.fromNostrEvent(
        Nip01EventModel.fromJson(jsonDecode(json["sellerEscrowMethod"])),
      ),
    );
  }
}

class PaymentProofEvidence {
  final PaymentMethod method;
  final PaymentProofParams params;

  const PaymentProofEvidence({
    required this.method,
    required this.params,
  });

  Map<String, dynamic> toJson() => {
        'method': method.wireName,
        'params': params.toJson(),
      };

  factory PaymentProofEvidence.fromJson(Map<String, dynamic> json) {
    final method = PaymentMethod.fromJson(json['method']);
    return PaymentProofEvidence(
      method: method,
      params: PaymentProofParams.fromJson(
        method,
        Map<String, dynamic>.from(json['params'] as Map),
      ),
    );
  }
}

abstract class PaymentProofParams {
  const PaymentProofParams();

  Map<String, dynamic> toJson();

  static PaymentProofParams fromJson(
    PaymentMethod method,
    Map<String, dynamic> json,
  ) {
    return switch (method) {
      PaymentMethod.evm => EvmPaymentProofParams.fromJson(json),
      PaymentMethod.zap => ZapPaymentProofParams.fromJson(json),
    };
  }
}

final class EvmPaymentProofParams extends PaymentProofParams {
  final String txHash;

  const EvmPaymentProofParams({required this.txHash});

  @override
  Map<String, dynamic> toJson() => {
        'txHash': txHash,
      };

  factory EvmPaymentProofParams.fromJson(Map<String, dynamic> json) =>
      EvmPaymentProofParams(txHash: json['txHash'] as String);
}

final class ZapPaymentProofParams extends PaymentProofParams {
  final Nip01EventModel receipt;
  final Nip01Event recipientProfile;

  const ZapPaymentProofParams({
    required this.receipt,
    required this.recipientProfile,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "receipt": receipt.toJsonString(),
      "recipientProfile": Nip01EventModel.fromEntity(recipientProfile).toJson(),
    };
  }

  factory ZapPaymentProofParams.fromJson(Map<String, dynamic> json) =>
      ZapPaymentProofParams(
        receipt: Nip01EventModel.fromJson(jsonDecode(json["receipt"])),
        recipientProfile: Nip01EventModel.fromJson(json["recipientProfile"]),
      );
}

enum OrderStatus {
  valid,
  confirmed,
  invalid,
  cancelled,
  completed,
}
