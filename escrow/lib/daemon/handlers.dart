import 'package:escrow/daemon/bootstrap.dart';
import 'package:escrow/daemon/escrow_monitor.dart';
import 'package:escrow/shared/protocol.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Metadata, Nip01Event;

/// Registers all JSON-RPC method handlers on a per-client [json_rpc.Server].
class DaemonHandler {
  final DaemonContext ctx;
  final EscrowMonitor monitor;

  /// In-memory cache: pubkey → display name (null = looked up but no name).
  final Map<String, String?> _nameCache = {};

  DaemonHandler({required this.ctx, required this.monitor});

  Hostr get hostr => ctx.hostr;
  SupportedEscrowContract get contract => ctx.contract;
  EscrowService get escrowService => ctx.escrowService;

  /// Wire every RPC method onto [server].
  void register(json_rpc.Server server) {
    server.registerMethod(kRpcGetStatus, _getStatus);
    server.registerMethod(kRpcListTrades, _listTrades);
    server.registerMethod(kRpcGetTrade, _getTrade);
    server.registerMethod(kRpcAudit, _audit);
    server.registerMethod(kRpcArbitrate, _arbitrate);
    server.registerMethod(kRpcListThreads, _listThreads);
    server.registerMethod(kRpcGetThread, _getThread);
    server.registerMethod(kRpcSendReply, _sendReply);
    server.registerMethod(kRpcListServices, _listServices);
    server.registerMethod(kRpcGetService, _getService);
    server.registerMethod(kRpcUpdateService, _updateService);
    server.registerMethod(kRpcGetProfile, _getProfile);
    server.registerMethod(kRpcUpdateProfile, _updateProfile);
    server.registerMethod(kRpcGetEvmMnemonic, _getEvmMnemonic);
    server.registerMethod(kRpcResolveNames, _resolveNames);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _getStatus(json_rpc.Parameters params) {
    return {
      'status': 'ok',
      'trackedTrades': monitor.trades.length,
      'pendingTrades': monitor.pendingTrades.length,
      'syncedThreads': hostr.messaging.threads.threads.length,
    };
  }

  Map<String, dynamic> _listTrades(json_rpc.Parameters params) {
    final trades = monitor.trades.values.toList()
      ..sort((a, b) {
        // Pending (funded) first, then by updatedAt descending.
        final aP = a.status == TradeStatus.funded ? 0 : 1;
        final bP = b.status == TradeStatus.funded ? 0 : 1;
        if (aP != bP) return aP.compareTo(bP);
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return {
      'trades': trades.map((t) => t.toSummary().toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> _getTrade(json_rpc.Parameters params) async {
    final tradeId = params['tradeId'].asString;

    // Try in-memory first, then fall back to on-chain lookup.
    final snapshot = monitor.getTrade(tradeId);
    print('[getTrade] tradeId=$tradeId, snapshot=${snapshot?.status}');
    final onChain = await contract.getTrade(tradeId);
    print('[getTrade] onChain=$onChain');

    return {
      'tradeId': tradeId,
      'cached': snapshot?.toSummary().toJson(),
      'onChain': onChain != null
          ? {
              'isActive': onChain.isActive,
              'buyer': onChain.buyer.eip55With0x,
              'seller': onChain.seller.eip55With0x,
              'arbiter': onChain.arbiter.eip55With0x,
              'amount': onChain.amount.toString(),
              'unlockAt': onChain.unlockAt.toString(),
              'escrowFee': onChain.escrowFee.toString(),
            }
          : null,
    };
  }

  Future<Map<String, dynamic>> _audit(json_rpc.Parameters params) async {
    final tradeId = params['tradeId'].asString;
    final result = await hostr.tradeAudit.audit(tradeId);
    return {
      'tradeId': result.tradeId,
      'explanation': result.explanation,
      'formatted': result.format(),
      'hasBuyer': result.buyer != null,
      'hasSeller': result.seller != null,
      'buyerStage': result.buyer?.currentStage?.name,
      'sellerStage': result.seller?.currentStage?.name,
    };
  }

  Future<Map<String, dynamic>> _arbitrate(json_rpc.Parameters params) async {
    final tradeId = params['tradeId'].asString;
    final forward = params['forward'].asNum.toDouble();

    if (forward < 0 || forward > 1) {
      throw json_rpc.RpcException(
        -32602,
        'forward must be between 0 and 1 (inclusive)',
      );
    }

    // Look up the on-chain trade to find the arbiter address, then derive
    // the matching HD key. This ensures we sign with the correct account
    // even if the trade was created with a non-default account index.
    print('[arbitrate] Looking up trade on chain: $tradeId');
    final onChain = await contract.getTrade(tradeId);
    print('[arbitrate] getTrade result: $onChain');
    if (onChain == null) {
      throw json_rpc.RpcException(-32001, 'Trade not found on chain: $tradeId');
    }
    if (!onChain.isActive) {
      throw json_rpc.RpcException(
          -32001, 'Trade is no longer active: $tradeId');
    }

    final arbiterAddress = onChain.arbiter;
    final int accountIndex;
    try {
      accountIndex = hostr.auth.findEvmAccountIndex(arbiterAddress);
    } catch (_) {
      throw json_rpc.RpcException(
        -32001,
        'We are not the arbiter for this trade. '
        'On-chain arbiter: ${arbiterAddress.eip55With0x}, '
        'our address: ${hostr.auth.getActiveEvmKey().address.eip55With0x}',
      );
    }

    final txHash = await contract.arbitrate(
      ContractArbitrateParams(
        tradeId: tradeId,
        forward: forward,
        ethKey: hostr.auth.getActiveEvmKey(accountIndex: accountIndex),
      ),
    );
    return {'txHash': '$txHash'};
  }

  Map<String, dynamic> _listThreads(json_rpc.Parameters params) {
    final threads = hostr.messaging.threads.threads;
    return {
      'threads': threads.entries.map((e) {
        final state = e.value.state.value;
        final lastMsg = state.sortedMessages.lastOrNull;
        return ThreadSummary(
          anchor: e.key,
          messageCount: state.messages.length,
          participants: state.participantPubkeys,
          lastMessage: lastMsg?.content,
          lastMessageAt: lastMsg != null
              ? DateTime.fromMillisecondsSinceEpoch(lastMsg.createdAt * 1000)
              : null,
        ).toJson();
      }).toList(),
    };
  }

  Map<String, dynamic> _getThread(json_rpc.Parameters params) {
    final threadId = params['threadId'].asString;
    final thread = hostr.messaging.threads.threads[threadId];

    if (thread == null) {
      throw json_rpc.RpcException(-32001, 'Thread not found: $threadId');
    }

    final state = thread.state.value;
    return {
      'threadId': threadId,
      'participants': state.participantPubkeys,
      'messages': state.sortedMessages
          .map((m) => ThreadMessage(
                id: m.id,
                pubKey: m.pubKey,
                content: m.content,
                createdAt: m.createdAt,
              ).toJson())
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _sendReply(json_rpc.Parameters params) async {
    final threadId = params['threadId'].asString;
    final content = params['content'].asString;

    final thread = hostr.messaging.threads.threads[threadId];
    if (thread == null) {
      throw json_rpc.RpcException(-32001, 'Thread not found: $threadId');
    }
    print([
      ...thread.addedParticipants,
      ...thread.state.value.participantPubkeys
    ]);
    await thread.replyText(content);
    return {'ok': true};
  }

  // ── Services ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _listServices(json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final services = await hostr.escrows.list(
      Filter(authors: [pubkey]),
    );
    return {
      'services': services
          .map((s) => ServiceSummary(
                id: s.id,
                contractAddress: s.contractAddress,
                chainId: s.chainId,
                feeBase: s.feeBase,
                feePercent: s.feePercent,
                minAmount: s.minAmount,
                maxAmount: s.maxAmount,
              ).toJson())
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _getService(json_rpc.Parameters params) async {
    final serviceId = params['serviceId'].asString;
    final service = await hostr.escrows.getById(serviceId);
    return {
      'id': service.id,
      'pubkey': service.escrowPubkey,
      'evmAddress': service.evmAddress,
      'contractAddress': service.contractAddress,
      'chainId': service.chainId,
      'feeBase': service.feeBase,
      'feePercent': service.feePercent,
      'minAmount': service.minAmount,
      'maxAmount': service.maxAmount,
      'maxDuration': service.maxDuration.inSeconds,
    };
  }

  Future<Map<String, dynamic>> _updateService(
      json_rpc.Parameters params) async {
    final serviceId = params['serviceId'].asString;

    final existing = await hostr.escrows.getById(serviceId);
    final old = existing.parsedContent;

    final updated = EscrowService(
      pubKey: existing.pubKey,
      tags: EventTags(existing.tags.map((t) => List<String>.from(t)).toList()),
      content: EscrowServiceContent(
        pubkey: old.pubkey,
        evmAddress: old.evmAddress,
        contractAddress: old.contractAddress,
        contractBytecodeHash: old.contractBytecodeHash,
        chainId: old.chainId,
        maxDuration: old.maxDuration,
        type: old.type,
        feeBase: params['feeBase'].asNumOr(old.feeBase).toInt(),
        feePercent: params['feePercent'].asNumOr(old.feePercent).toDouble(),
        minAmount: params['minAmount'].asNumOr(old.minAmount).toInt(),
        maxAmount: params['maxAmount'].valueOr(null) != null
            ? params['maxAmount'].asNum.toInt()
            : old.maxAmount,
      ),
    );

    await hostr.escrows.upsert(updated);
    return {'ok': true};
  }

  // ── Profile ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _getProfile(json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final profile = await hostr.metadata.loadMetadata(pubkey);

    if (profile == null) {
      return {'pubkey': pubkey};
    }

    final m = profile.metadata;
    String? evmAddr;
    try {
      evmAddr = profile.evmAddress;
    } catch (_) {
      // No EVM address tag set yet.
    }
    return {
      'pubkey': pubkey,
      'name': m.name,
      'displayName': m.displayName,
      'about': m.about,
      'picture': m.picture,
      'banner': m.banner,
      'nip05': m.nip05,
      'lud16': m.lud16,
      'website': m.website,
      'evmAddress': evmAddr,
    };
  }

  Future<Map<String, dynamic>> _updateProfile(
      json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final existing = await hostr.metadata.loadMetadata(pubkey);

    final old = existing?.metadata;

    final metadata = Metadata(
      pubKey: pubkey,
      name: params['name'].asStringOr(old?.name ?? ''),
      displayName: params['displayName'].asStringOr(old?.displayName ?? ''),
      about: params['about'].asStringOr(old?.about ?? ''),
      picture: params['picture'].asStringOr(old?.picture ?? ''),
      banner: params['banner'].asStringOr(old?.banner ?? ''),
      nip05: params['nip05'].asStringOr(old?.nip05 ?? ''),
      lud16: params['lud16'].asStringOr(old?.lud16 ?? ''),
      website: params['website'].asStringOr(old?.website ?? ''),
    );

    final event = metadata.toEvent();

    // Preserve existing tags (like EVM address) from old event
    final tags = List<List<String>>.from(event.tags);
    if (existing != null) {
      for (final tag in existing.tags) {
        if (tag.isNotEmpty && tag[0] == 'i') {
          tags.add(List<String>.from(tag));
        }
      }
    }

    final fullEvent = Nip01Event(
      pubKey: event.pubKey,
      kind: event.kind,
      tags: tags,
      content: event.content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final profile = ProfileMetadata.fromNostrEvent(fullEvent);
    await hostr.metadata.upsert(profile);
    return {'ok': true};
  }

  // ── EVM Key Info ──────────────────────────────────────────────────────────

  Map<String, dynamic> _getEvmMnemonic(json_rpc.Parameters params) {
    final nsecHex = hostr.auth.activeKeyPair!.privateKey!;
    final mnemonic = deriveEvmMnemonic(nsecHex);
    final evmAddress = hostr.auth.getActiveEvmKey().address.eip55With0x;
    return {
      'mnemonic': mnemonic,
      'evmAddress': evmAddress,
      'derivationPath': "m/44'/60'/0'/0/0",
    };
  }

  // ── Metadata Resolution ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> _resolveNames(json_rpc.Parameters params) async {
    final pubkeys =
        (params['pubkeys'].value as List).map((e) => e as String).toList();

    // Only fetch pubkeys we haven't cached yet.
    final uncached =
        pubkeys.where((pk) => !_nameCache.containsKey(pk)).toList();

    // Resolve uncached pubkeys in parallel.
    if (uncached.isNotEmpty) {
      await Future.wait(uncached.map((pk) async {
        try {
          final profile = await hostr.metadata.loadMetadata(pk);
          final m = profile?.metadata;
          _nameCache[pk] = m?.displayName?.isNotEmpty == true
              ? m!.displayName
              : m?.name?.isNotEmpty == true
                  ? m!.name
                  : null;
        } catch (_) {
          _nameCache[pk] = null;
        }
      }));
    }

    return {
      'names': {for (final pk in pubkeys) pk: _nameCache[pk]},
    };
  }
}
