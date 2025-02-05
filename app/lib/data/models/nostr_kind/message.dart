import 'dart:core';

import 'package:hostr/config/constants.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'event.dart';

class Message extends Event {
  static const List<int> kinds = [NOSTR_KIND_DM];

  Message.fromNostrEvent(super.nip01Event, KeyPair? key);
}
