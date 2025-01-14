import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../models/nostr_kind/escrow.dart';
import 'keypairs.dart';

var MOCK_ESCROWS = [
  Escrow.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.escrow,
      content: json.encode(EscrowContent(
              chainId: 30,
              pubkey: MockKeys.escrow.public,
              maxDuration: Duration(days: 365),
              type: EscrowType.ROOTSTOCK)
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_ESCROW,
      tags: []))
].toList();
