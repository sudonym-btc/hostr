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

// ──────────────────────────────────────────────────────────────────────────────
// Serialisation helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Lightweight snapshot of a trade for list views.
class TradeSummary {
  final String tradeId;
  final String status;
  final int amountSats;
  final String? txHash;
  final DateTime updatedAt;

  TradeSummary({
    required this.tradeId,
    required this.status,
    required this.amountSats,
    this.txHash,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'tradeId': tradeId,
        'status': status,
        'amountSats': amountSats,
        'txHash': txHash,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TradeSummary.fromJson(Map<String, dynamic> json) => TradeSummary(
        tradeId: json['tradeId'] as String,
        status: json['status'] as String,
        amountSats: json['amountSats'] as int,
        txHash: json['txHash'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
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
  final int feeBase;
  final double feePercent;
  final int minAmount;
  final int? maxAmount;

  ServiceSummary({
    required this.id,
    required this.contractAddress,
    required this.chainId,
    required this.feeBase,
    required this.feePercent,
    required this.minAmount,
    this.maxAmount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contractAddress': contractAddress,
        'chainId': chainId,
        'feeBase': feeBase,
        'feePercent': feePercent,
        'minAmount': minAmount,
        if (maxAmount != null) 'maxAmount': maxAmount,
      };

  factory ServiceSummary.fromJson(Map<String, dynamic> json) => ServiceSummary(
        id: json['id'] as String,
        contractAddress: json['contractAddress'] as String,
        chainId: json['chainId'] as int,
        feeBase: (json['feeBase'] as num).toInt(),
        feePercent: (json['feePercent'] as num).toDouble(),
        minAmount: (json['minAmount'] as num).toInt(),
        maxAmount: (json['maxAmount'] as num?)?.toInt(),
      );
}
