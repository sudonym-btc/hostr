import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../bip340.dart';
import '../nostr_kinds.dart';

class EscrowTrust extends Event {
  static const List<int> kinds = [kNostrKindEscrowTrust];

  EscrowTrust.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);

  Future<Nip51List> toNip51List() async {
    final tempKey = Bip340.generatePrivateKey();
    return Nip51List.fromEvent(
        this,
        Bip340EventSigner(
            privateKey: tempKey.privateKey, publicKey: tempKey.publicKey));
  }
}
