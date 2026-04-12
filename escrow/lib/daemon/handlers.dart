import 'dart:async';
import 'dart:convert';

import 'package:escrow/shared/protocol.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Metadata, Nip01Event;

/// Registers all JSON-RPC method handlers on a per-client [json_rpc.Server].
class DaemonHandler {
  final EscrowDaemon daemon;

  /// In-memory cache: pubkey → display name (null = looked up but no name).
  final Map<String, String?> _nameCache = {};

  DaemonHandler({required this.daemon});

  Hostr get hostr => daemon.hostr;
  SupportedEscrowContract get contract => daemon.context.contract;
  EscrowService get escrowService => daemon.context.escrowService;

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
    server.registerMethod(kRpcListReservationGroups, _listReservationGroups);
    server.registerMethod(kRpcListBadgeDefinitions, _listBadgeDefinitions);
    server.registerMethod(kRpcUpsertBadgeDefinition, _upsertBadgeDefinition);
    server.registerMethod(kRpcDeleteBadgeDefinition, _deleteBadgeDefinition);
    server.registerMethod(kRpcListBadgeAwards, _listBadgeAwards);
    server.registerMethod(kRpcAwardBadge, _awardBadge);
    server.registerMethod(kRpcRevokeBadge, _revokeBadge);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _getStatus(json_rpc.Parameters params) {
    return {
      'status': 'ok',
      'trackedTrades': daemon.trades.length,
      'pendingTrades': daemon.pendingTrades.length,
      'syncedThreads': hostr.messaging.threads.threads.length,
    };
  }

  Map<String, dynamic> _listTrades(json_rpc.Parameters params) {
    final threads = hostr.messaging.threads;
    final trades = daemon.trades.values.toList()
      ..sort((a, b) {
        // Pending (funded) first, then by updatedAt descending.
        final aP = a.status == TradeStatus.funded ? 0 : 1;
        final bP = b.status == TradeStatus.funded ? 0 : 1;
        if (aP != bP) return aP.compareTo(bP);
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return {
      'trades': trades.map((t) {
        final json = t.toJson();
        json['disputed'] = threads.findByConversationTag(t.tradeId).isNotEmpty;
        return json;
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _getTrade(json_rpc.Parameters params) async {
    final tradeId = params['tradeId'].asString;

    // Try in-memory first, then fall back to on-chain lookup.
    final snapshot = daemon.getTrade(tradeId);
    final onChain = await contract.getTrade(tradeId);

    // Resolve trade ID → thread anchor so the CLI can navigate directly.
    final threadAnchor =
        hostr.messaging.threads.findPreferredConversationIdByTradeId(tradeId);

    return {
      'tradeId': tradeId,
      'threadAnchor': threadAnchor,
      'cached': snapshot?.toJson(),
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
      'hasEscrow': result.escrow != null,
      'buyerStage': result.buyer?.currentStage?.name,
      'sellerStage': result.seller?.currentStage?.name,
      'escrowStage': result.escrow?.currentStage?.name,
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
    final onChain = await contract.getTrade(tradeId);
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
      accountIndex = await hostr.auth.hd.findEvmAccountIndex(arbiterAddress);
    } catch (_) {
      throw json_rpc.RpcException(
        -32001,
        'We are not the arbiter for this trade. '
        'On-chain arbiter: ${arbiterAddress.eip55With0x}, '
        'our address: ${(await hostr.auth.hd.getActiveEvmKey()).address.eip55With0x}',
      );
    }

    final signer =
        await hostr.auth.hd.getActiveEvmKey(accountIndex: accountIndex);
    final intent = await contract.arbitrate(
      tradeId: tradeId,
      forward: forward,
      ethKey: signer,
    );
    final txHash = await daemon.context.configuredChain
        .sendCalls(signer, {'arbitrate': intent});

    // Eagerly update the in-memory cache so the CLI sees the new status
    // immediately, without waiting for the event stream.
    final existing = daemon.getTrade(tradeId);
    if (existing != null) {
      daemon.updateTrade(existing.copyWith(
        status: TradeStatus.arbitrated,
        lastTxHash: '$txHash',
        updatedAt: DateTime.now().toUtc(),
      ));
    }

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
      'conversationTag': thread.conversationTag,
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
    try {
      await thread
          .replyTextAndWait(content)
          .timeout(const Duration(seconds: 15));
      return {'ok': true};
    } on TimeoutException {
      throw json_rpc.RpcException(
        -32002,
        'Reply was broadcast, but the synced thread did not receive it in time.',
      );
    }
  }

  // ── Services ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _listServices(json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final services = await hostr.escrows.list(
      Filter(authors: [pubkey]),
    );

    // Deduplicate by contract address, keeping the newest event per contract.
    // This handles legacy events that were published without a 'd' tag.
    final byContract = <String, EscrowService>{};
    for (final s in services) {
      final existing = byContract[s.contractAddress];
      if (existing == null || s.createdAt > existing.createdAt) {
        byContract[s.contractAddress] = s;
      }
    }

    return {
      'services': byContract.values
          .map((s) => ServiceSummary(
                id: s.id,
                contractAddress: s.contractAddress,
                chainId: s.chainId,
                feePercent: s.feePercent,
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
      'feePercent': service.feePercent,
      'maxDuration': service.maxDuration.inSeconds,
    };
  }

  Future<Map<String, dynamic>> _updateService(
      json_rpc.Parameters params) async {
    final serviceId = params['serviceId'].asString;

    final existing = await hostr.escrows.getById(serviceId);
    final old = existing.parsedContent;

    // Ensure the 'd' tag is present so relays replace the previous event.
    final existingTags =
        existing.tags.map((t) => List<String>.from(t)).toList();
    if (!existingTags.any((t) => t.isNotEmpty && t[0] == 'd')) {
      existingTags.add(['d', old.contractAddress]);
    }

    final updated = EscrowService(
      pubKey: existing.pubKey,
      tags: EventTags(existingTags),
      content: EscrowServiceContent(
        pubkey: old.pubkey,
        evmAddress: old.evmAddress,
        contractAddress: old.contractAddress,
        contractBytecodeHash: old.contractBytecodeHash,
        chainId: old.chainId,
        maxDuration: old.maxDuration,
        type: old.type,
        feePercent: params['feePercent'].asNumOr(old.feePercent).toDouble(),
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

  Future<Map<String, dynamic>> _getEvmMnemonic(
      json_rpc.Parameters params) async {
    final mnemonic = (await hostr.auth.hd.getEvmMnemonic()).join(' ');
    final evmAddress =
        (await hostr.auth.hd.getActiveEvmKey()).address.eip55With0x;
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

  // ── Badges ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _listBadgeDefinitions(
      json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final definitions = await hostr.badgeDefinitions.list(
      Filter(authors: [pubkey], kinds: [30009]),
    );
    return {
      'definitions': definitions.map((d) {
        return BadgeDefinitionSummary(
          anchor: d.anchor,
          identifier: d.identifier ?? '',
          name: d.name,
          description: d.description,
          image: d.image,
        ).toJson();
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _upsertBadgeDefinition(
      json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final identifier = params['identifier'].asString;
    final name = params['name'].asString;
    final description = params['description'].asStringOr('');
    final image = params['image'].asStringOr('');

    // Build content JSON as per NIP-58 spec.
    final contentMap = <String, dynamic>{'name': name};
    if (description.isNotEmpty) contentMap['description'] = description;
    if (image.isNotEmpty) contentMap['image'] = image;

    final event = Nip01Event(
      pubKey: pubkey,
      kind: 30009,
      tags: [
        ['d', identifier],
      ],
      content: jsonEncode(contentMap),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final definition = BadgeDefinition.fromNostrEvent(event);
    await hostr.badgeDefinitions.upsert(definition);
    return {'anchor': definition.anchor};
  }

  Future<Map<String, dynamic>> _deleteBadgeDefinition(
      json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final anchor = params['anchor'].asString;
    final existing = await hostr.badgeDefinitions.getOneByAnchor(anchor);
    if (existing == null) {
      throw json_rpc.RpcException(
          -32001, 'Badge definition not found: $anchor');
    }
    // NIP-09 deletion event.
    final deletion = Nip01Event(
      pubKey: pubkey,
      kind: 5,
      tags: [
        ['e', existing.id],
        ['a', anchor],
      ],
      content: 'Badge definition deleted by escrow operator',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await hostr.badgeDefinitions
        .upsert(BadgeDefinition.fromNostrEvent(deletion));
    return {'ok': true};
  }

  Future<Map<String, dynamic>> _listBadgeAwards(
      json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final definitionAnchor = params['definitionAnchor'].asStringOr('');

    final filter = definitionAnchor.isNotEmpty
        ? Filter(
            authors: [pubkey],
            kinds: [8],
            tags: {
              'a': [definitionAnchor],
            },
          )
        : Filter(authors: [pubkey], kinds: [8]);

    final awards = await hostr.badgeAwards.list(filter);
    return {
      'awards': awards.map((a) {
        final issuedAt = DateTime.fromMillisecondsSinceEpoch(
          a.createdAt * 1000,
          isUtc: true,
        );
        return BadgeAwardSummary(
          id: a.id,
          definitionAnchor: a.badgeDefinitionAnchor ?? '',
          recipientPubkey: a.recipients.firstOrNull ?? '',
          listingAnchor: a.targetAnchor,
          issuedAt: issuedAt,
        ).toJson();
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _awardBadge(json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final definitionAnchor = params['definitionAnchor'].asString;
    final recipientPubkey = params['recipientPubkey'].asString;
    final listingAnchor = params['listingAnchor'].asStringOr('');

    final tags = <List<String>>[
      ['a', definitionAnchor],
      ['p', recipientPubkey],
    ];
    if (listingAnchor.isNotEmpty) {
      // Second 'a' tag marks the specific listing being awarded.
      tags.add(['a', listingAnchor]);
    }

    final event = Nip01Event(
      pubKey: pubkey,
      kind: 8,
      tags: tags,
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final award = BadgeAward.fromNostrEvent(event);
    await hostr.badgeAwards.upsert(award);
    return {'awardId': award.id};
  }

  Future<Map<String, dynamic>> _revokeBadge(json_rpc.Parameters params) async {
    final pubkey = hostr.auth.activeKeyPair!.publicKey;
    final awardId = params['awardId'].asString;
    final existing = await hostr.badgeAwards.getById(awardId);

    // NIP-09 deletion event referencing the award.
    final deletion = Nip01Event(
      pubKey: pubkey,
      kind: 5,
      tags: [
        ['e', existing.id],
      ],
      content: 'Badge award revoked by escrow operator',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    // Broadcast the deletion through the generic badgeAwards channel
    // so the relay processes it as a NIP-09 deletion.
    await hostr.badgeAwards.upsert(BadgeAward.fromNostrEvent(deletion));
    return {'ok': true};
  }

  // ── Reservation Groups ────────────────────────────────────────────────────

  Map<String, dynamic> _listReservationGroups(json_rpc.Parameters params) {
    final groups = daemon.reservationGroups;
    return {
      'groups': groups.entries.map((e) {
        final g = e.value;
        return {
          'groupId': e.key,
          'tradeId': g.tradeId,
          'listingAnchor': g.listingAnchor,
          'stage': g.stage.name,
          'cancelled': g.cancelled,
          'hasBuyer': g.buyerReservation != null,
          'hasSeller': g.sellerReservation != null,
          'hasEscrow': g.escrowReservation != null,
          'escrowStage': g.escrowReservation?.stage.name,
          'participants': g.participantSet.toList(),
        };
      }).toList(),
    };
  }
}
