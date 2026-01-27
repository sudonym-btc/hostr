import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_ESCROW_TRUSTS = [
  EscrowTrust.fromNostrEvent(Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          content: '',
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          kind: NOSTR_KIND_ESCROW_TRUST,
          tags: [
            ['p', MockKeys.escrow.publicKey],
          ]))),
  EscrowTrust.fromNostrEvent(Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.guest.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.guest.publicKey,
          content: '',
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          kind: NOSTR_KIND_ESCROW_TRUST,
          tags: [
            ['p', MockKeys.escrow.publicKey],
          ]))),
].toList();
