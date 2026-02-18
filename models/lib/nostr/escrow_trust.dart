import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../bip340.dart';
import '../nostr_kinds.dart';

class EscrowTrust extends Event {
  static const List<int> kinds = [kNostrKindEscrowTrust];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;

  EscrowTrust.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  Future<Nip51List> toNip51List() async {
    final tempKey = Bip340.generatePrivateKey();
    return Nip51List.fromEvent(
        this,
        Bip340EventSigner(
            privateKey: tempKey.privateKey, publicKey: tempKey.publicKey));
  }
}
