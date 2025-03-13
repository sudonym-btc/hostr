import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

var MOCK_ESCROWS = [
  Escrow.fromNostrEvent(Nip01Event(
      pubKey: MockKeys.escrow.publicKey,
      content: json.encode(EscrowContent(
              chainId: 30,
              pubkey: MockKeys.escrow.publicKey,
              contractAddress: "0x1460fd6f56f2e62104a794C69Cc06BE7DC975Bed",
              maxDuration: Duration(days: 365),
              type: EscrowType.ROOTSTOCK)
          .toJson()),
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      kind: NOSTR_KIND_ESCROW,
      tags: [])
    ..sign(MockKeys.escrow.privateKey!)),
].toList();
