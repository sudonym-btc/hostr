import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:models/stubs/keypairs.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';

class EscrowTrust extends Event {
  static const List<int> kinds = [NOSTR_KIND_ESCROW_TRUST];

  EscrowTrust.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);

  Future<Nip51List> toNip51List() async {
    return Nip51List.fromEvent(
        this,
        Bip340EventSigner(
            privateKey: MockKeys.escrow.privateKey,
            publicKey: MockKeys.escrow.publicKey));
  }
}
