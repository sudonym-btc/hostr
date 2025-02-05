import 'dart:convert';

import 'package:hostr/config/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../models/nostr_kind/escrow.dart';
import 'keypairs.dart';

var MOCK_ESCROWS = [
  Escrow.fromNostrEvent(Nip01Event(
      pubKey: MockKeys.escrow.publicKey,
      content: json.encode(EscrowContent(
              chainId: 30,
              pubkey: MockKeys.escrow.publicKey,
              contractAddress: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
              maxDuration: Duration(days: 365),
              type: EscrowType.ROOTSTOCK)
          .toJson()),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      kind: NOSTR_KIND_ESCROW,
      tags: [])
    ..sign(MockKeys.escrow.privateKey!)),
].toList();
