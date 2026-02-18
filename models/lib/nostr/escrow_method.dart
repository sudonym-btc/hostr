import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import '../stubs/keypairs.dart';

class EscrowMethod extends Event {
  static const List<int> kinds = [kNostrKindEscrowMethod];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;

  EscrowMethod.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  Future<Nip51List> toNip51List() async {
    return Nip51List.fromEvent(
        this,
        Bip340EventSigner(
            privateKey: MockKeys.escrow.privateKey,
            publicKey: MockKeys.escrow.publicKey));
  }
}
