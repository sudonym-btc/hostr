import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';

class EscrowTrust extends Event {
  static const List<int> kinds = [NOSTR_KIND_ESCROW_TRUST];

  EscrowTrust.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);
}
