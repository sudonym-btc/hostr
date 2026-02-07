import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_ESCROW_METHODS = () async {
  return [
    EscrowMethod.fromNostrEvent(Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: await (Nip51List(
              pubKey: MockKeys.hoster.publicKey,
              createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
              kind: kNostrKindEscrowMethod,
              elements: [])
            ..addElement('t', EscrowType.EVM.name, false)
            ..addElement('c', "DeployedBytecodeHash", false))
          .toEvent(Bip340EventSigner(
              privateKey: MockKeys.hoster.privateKey,
              publicKey: MockKeys.hoster.publicKey)),
    )),
    EscrowMethod.fromNostrEvent(Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.guest.privateKey!,
        event: await (Nip51List(
                pubKey: MockKeys.guest.publicKey,
                createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
                kind: kNostrKindEscrowMethod,
                elements: [])
              ..addElement('t', EscrowType.EVM.name, false)
              ..addElement('c', "DeployedBytecodeHash", false))
            .toEvent(Bip340EventSigner(
                privateKey: MockKeys.guest.privateKey,
                publicKey: MockKeys.guest.publicKey))))
  ];
};
