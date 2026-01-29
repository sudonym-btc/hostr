import 'package:models/main.dart';
import 'package:models/nostr/escrow_method.dart';
import 'package:ndk/ndk.dart';

var MOCK_ESCROW_METHODS = () async {
  return [
    EscrowMethods.fromNostrEvent(await (Nip51List(
            pubKey: MockKeys.hoster.publicKey,
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
            kind: NOSTR_KIND_ESCROW_TRUST,
            elements: [])
          ..addElement(EscrowType.EVM.toString(),
              ChainIds.Rootstock.value.toString(), false))
        .toEvent(Bip340EventSigner(
            privateKey: MockKeys.hoster.privateKey,
            publicKey: MockKeys.hoster.publicKey))),
    EscrowMethods.fromNostrEvent(await (Nip51List(
            pubKey: MockKeys.guest.publicKey,
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
            kind: NOSTR_KIND_ESCROW_TRUST,
            elements: [])
          ..addElement(EscrowType.EVM.toString(),
              ChainIds.Rootstock.value.toString(), false))
        .toEvent(Bip340EventSigner(
            privateKey: MockKeys.guest.privateKey,
            publicKey: MockKeys.guest.publicKey)))
  ];
};
