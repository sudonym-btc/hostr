import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_ESCROW_TRUSTS = () async {
  return [
    EscrowTrust.fromNostrEvent(Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.hoster.privateKey!,
        event: await (Nip51List(
                pubKey: MockKeys.hoster.publicKey,
                createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
                kind: kNostrKindEscrowTrust,
                elements: [])
              ..addElement('p', MockKeys.escrow.publicKey, false))
            .toEvent(Bip340EventSigner(
                privateKey: MockKeys.hoster.privateKey,
                publicKey: MockKeys.hoster.publicKey)))),
    EscrowTrust.fromNostrEvent(Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.guest.privateKey!,
        event: await (Nip51List(
                pubKey: MockKeys.guest.publicKey,
                createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
                kind: kNostrKindEscrowTrust,
                elements: [])
              ..addElement('p', MockKeys.escrow.publicKey, false))
            .toEvent(Bip340EventSigner(
                privateKey: MockKeys.guest.privateKey,
                publicKey: MockKeys.guest.publicKey))))
  ];
};
