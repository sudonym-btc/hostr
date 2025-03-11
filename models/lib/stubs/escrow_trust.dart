import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

var MOCK_ESCROW_TRUSTS = [
  EscrowTrust.fromNostrEvent(Nip01Event(
      pubKey: MockKeys.hoster.publicKey,
      content: '',
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      kind: NOSTR_KIND_ESCROW_TRUST,
      tags: [
        ['p', MockKeys.escrow.publicKey],
      ])
    ..sign(MockKeys.hoster.privateKey!)),
  EscrowTrust.fromNostrEvent(Nip01Event(
      pubKey: MockKeys.guest.publicKey,
      content: '',
      createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
      kind: NOSTR_KIND_ESCROW_TRUST,
      tags: [
        ['p', MockKeys.escrow.publicKey],
      ])
    ..sign(MockKeys.guest.privateKey!)),
].toList();
