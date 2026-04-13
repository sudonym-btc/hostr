// ──────────────────────────────────────────────────────────────────────────────
// JSON-RPC method names shared between daemon and CLI.
// ──────────────────────────────────────────────────────────────────────────────

/// Daemon health check. Returns `{ "status": "ok" }`.
const kRpcGetStatus = 'getStatus';

/// List all trades our escrow is involved in.
/// Returns `{ "trades": [ TradeSummaryJson, … ] }`.
const kRpcListTrades = 'listTrades';

/// Get a single trade's on-chain state.
/// Params: `{ "tradeId": String }`.
/// Returns `OnChainTradeJson`.
const kRpcGetTrade = 'getTrade';

/// Run a full audit on a trade.
/// Params: `{ "tradeId": String }`.
/// Returns `{ "formatted": String, … }`.
const kRpcAudit = 'audit';

/// Arbitrate a trade.
/// Params: `{ "tradeId": String, "forward": double }`.
/// Returns `{ "txHash": String }`.
const kRpcArbitrate = 'arbitrate';

/// List all synced threads.
/// Returns `{ "threads": [ ThreadSummaryJson, … ] }`.
const kRpcListThreads = 'listThreads';

/// Get messages for a single thread.
/// Params: `{ "threadId": String }`.
/// Returns `{ "messages": [ MessageJson, … ], "participants": [String] }`.
const kRpcGetThread = 'getThread';

/// Send a text reply in a thread.
/// Params: `{ "threadId": String, "content": String }`.
/// Returns `{ "ok": true }`.
const kRpcSendReply = 'sendReply';

// ── Services ────────────────────────────────────────────────────────────────

/// List escrow services published by our pubkey.
/// Returns `{ "services": [ ServiceSummaryJson, … ] }`.
const kRpcListServices = 'listServices';

/// Get full details for a single escrow service.
/// Params: `{ "serviceId": String }`.
/// Returns `ServiceDetailJson`.
const kRpcGetService = 'getService';

/// Update an escrow service's editable fields and re-broadcast.
/// Params: `{ "serviceId": String, "feeBase": int?, "feePercent": double?,
///            "minAmount": int?, "maxAmount": int? }`.
/// Returns `{ "ok": true }`.
const kRpcUpdateService = 'updateService';

// ── Profile ─────────────────────────────────────────────────────────────────

/// Get the current user's profile metadata.
/// Returns `ProfileJson`.
const kRpcGetProfile = 'getProfile';

/// Update profile metadata fields and broadcast.
/// Params: `{ "name": String?, "displayName": String?, "about": String?,
///            "picture": String?, "banner": String?, "nip05": String?,
///            "lud16": String?, "website": String? }`.
/// Returns `{ "ok": true }`.
const kRpcUpdateProfile = 'updateProfile';

// ── EVM Key Info ────────────────────────────────────────────────────────────

/// Get the BIP-39 mnemonic derived from the daemon's nsec.
/// Returns `{ "mnemonic": String, "evmAddress": String,
///            "derivationPath": String }`.
const kRpcGetEvmMnemonic = 'getEvmMnemonic';

// ── Metadata Resolution ─────────────────────────────────────────────────────

/// Resolve display names for a batch of pubkeys.
/// Params: `{ "pubkeys": [String, …] }`.
/// Returns `{ "names": { pubkey: displayName | null, … } }`.
const kRpcResolveNames = 'resolveNames';

// ── Reservation Groups ──────────────────────────────────────────────────────

/// List all reservation groups the escrow is tracking.
/// Returns `{ "groups": [ ReservationGroupSummaryJson, … ] }`.
const kRpcListReservationGroups = 'listReservationGroups';

// ── Badges ──────────────────────────────────────────────────────────────────

/// List all badge definitions published by the escrow keypair.
/// Returns `{ "definitions": [ BadgeDefinitionSummaryJson, … ] }`.
const kRpcListBadgeDefinitions = 'listBadgeDefinitions';

/// Create or update a badge definition (kind 30009, identified by `d` tag).
/// Params: `{ "identifier": String, "name": String, "description": String?,
///            "image": String? }`.
/// Returns `{ "anchor": String }`.
const kRpcUpsertBadgeDefinition = 'upsertBadgeDefinition';

/// Delete a badge definition by anchor.
/// Params: `{ "anchor": String }`.
/// Returns `{ "ok": true }`.
const kRpcDeleteBadgeDefinition = 'deleteBadgeDefinition';

/// List badge awards issued by the escrow keypair,
/// optionally filtered by badge definition anchor.
/// Params: `{ "definitionAnchor": String? }`.
/// Returns `{ "awards": [ BadgeAwardSummaryJson, … ] }`.
const kRpcListBadgeAwards = 'listBadgeAwards';

/// Award a badge to a pubkey, optionally tied to a listing anchor.
/// Params: `{ "definitionAnchor": String, "recipientPubkey": String,
///            "listingAnchor": String? }`.
/// Returns `{ "awardId": String }`.
const kRpcAwardBadge = 'awardBadge';

/// Revoke a badge award by event id (publishes a NIP-09 deletion).
/// Params: `{ "awardId": String }`.
/// Returns `{ "ok": true }`.
const kRpcRevokeBadge = 'revokeBadge';

// ──────────────────────────────────────────────────────────────────────────────
// Serialisation helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Lightweight snapshot of a trade for list views.
class TradeSummary {
  final String tradeId;
  final String status;

  /// Raw token amount in the token's smallest unit, as a decimal string
  /// (BigInt serialised to avoid JSON integer overflow).
  final String amountWei;

  /// EVM token address. `0x0000000000000000000000000000000000000000` = native.
  final String tokenAddress;

  /// Number of decimals for the token (e.g. 6 for USDT, 8 for tBTC, 18 for ETH).
  final int tokenDecimals;

  /// Human-readable symbol resolved by the daemon (e.g. "USDT", "tBTC", "ETH").
  final String tokenSymbol;
  final String? txHash;
  final DateTime updatedAt;
  final bool disputed;

  TradeSummary({
    required this.tradeId,
    required this.status,
    required this.amountWei,
    required this.tokenAddress,
    required this.tokenDecimals,
    required this.tokenSymbol,
    this.txHash,
    required this.updatedAt,
    this.disputed = false,
  });

  Map<String, dynamic> toJson() => {
        'tradeId': tradeId,
        'status': status,
        'amountWei': amountWei,
        'tokenAddress': tokenAddress,
        'tokenDecimals': tokenDecimals,
        'tokenSymbol': tokenSymbol,
        'txHash': txHash,
        'updatedAt': updatedAt.toIso8601String(),
        'disputed': disputed,
      };

  factory TradeSummary.fromJson(Map<String, dynamic> json) => TradeSummary(
        tradeId: json['tradeId'] as String,
        status: json['status'] as String,
        amountWei: json['amountWei'] as String? ?? '${json['amountSats'] ?? 0}',
        tokenAddress: json['tokenAddress'] as String? ??
            '0x0000000000000000000000000000000000000000',
        tokenDecimals: json['tokenDecimals'] as int? ?? 8,
        tokenSymbol: json['tokenSymbol'] as String? ?? 'sat',
        txHash: json['txHash'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        disputed: json['disputed'] as bool? ?? false,
      );
}

/// Summary of a thread for list views.
class ThreadSummary {
  final String anchor;
  final int messageCount;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ThreadSummary({
    required this.anchor,
    required this.messageCount,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
  });

  Map<String, dynamic> toJson() => {
        'anchor': anchor,
        'messageCount': messageCount,
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
      };

  factory ThreadSummary.fromJson(Map<String, dynamic> json) => ThreadSummary(
        anchor: json['anchor'] as String,
        messageCount: json['messageCount'] as int,
        participants:
            (json['participants'] as List).map((e) => e as String).toList(),
        lastMessage: json['lastMessage'] as String?,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'] as String)
            : null,
      );
}

/// A single thread message, serialisable over the wire.
class ThreadMessage {
  final String id;
  final String pubKey;
  final String content;
  final int createdAt;

  ThreadMessage({
    required this.id,
    required this.pubKey,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubKey': pubKey,
        'content': content,
        'createdAt': createdAt,
      };

  factory ThreadMessage.fromJson(Map<String, dynamic> json) => ThreadMessage(
        id: json['id'] as String,
        pubKey: json['pubKey'] as String,
        content: json['content'] as String,
        createdAt: json['createdAt'] as int,
      );
}

/// Summary of an escrow service for list views.
class ServiceSummary {
  final String id;
  final String contractAddress;
  final int chainId;
  final double feePercent;

  ServiceSummary({
    required this.id,
    required this.contractAddress,
    required this.chainId,
    required this.feePercent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contractAddress': contractAddress,
        'chainId': chainId,
        'feePercent': feePercent,
      };

  factory ServiceSummary.fromJson(Map<String, dynamic> json) => ServiceSummary(
        id: json['id'] as String,
        contractAddress: json['contractAddress'] as String,
        chainId: json['chainId'] as int,
        feePercent: (json['feePercent'] as num).toDouble(),
      );
}

// ── Badge DTOs ───────────────────────────────────────────────────────────────

/// Summary of a badge definition for list views.
class BadgeDefinitionSummary {
  final String anchor;
  final String identifier;
  final String name;
  final String? description;
  final String? image;

  BadgeDefinitionSummary({
    required this.anchor,
    required this.identifier,
    required this.name,
    this.description,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'anchor': anchor,
        'identifier': identifier,
        'name': name,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
      };

  factory BadgeDefinitionSummary.fromJson(Map<String, dynamic> json) =>
      BadgeDefinitionSummary(
        anchor: json['anchor'] as String,
        identifier: json['identifier'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        image: json['image'] as String?,
      );
}

/// Summary of a badge award for list views.
class BadgeAwardSummary {
  final String id;
  final String definitionAnchor;
  final String recipientPubkey;
  final String? listingAnchor;
  final DateTime issuedAt;

  BadgeAwardSummary({
    required this.id,
    required this.definitionAnchor,
    required this.recipientPubkey,
    this.listingAnchor,
    required this.issuedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'definitionAnchor': definitionAnchor,
        'recipientPubkey': recipientPubkey,
        if (listingAnchor != null) 'listingAnchor': listingAnchor,
        'issuedAt': issuedAt.toIso8601String(),
      };

  factory BadgeAwardSummary.fromJson(Map<String, dynamic> json) =>
      BadgeAwardSummary(
        id: json['id'] as String,
        definitionAnchor: json['definitionAnchor'] as String,
        recipientPubkey: json['recipientPubkey'] as String,
        listingAnchor: json['listingAnchor'] as String?,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
      );
}
