import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_RESERVATIONS = [
  Reservation.fromNostrEvent(Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          content: json.encode(ReservationContent(
                  start: DateTime(2025, 1, 1), end: DateTime(2025, 5, 1))
              .toJson()),
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          kind: NOSTR_KIND_RESERVATION,
          tags: [
            ['e', MOCK_LISTINGS[0].id]
          ]))),
  Reservation.fromNostrEvent(Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          content: json.encode(ReservationContent(
                  start: DateTime(2025, 1, 1), end: DateTime(2025, 5, 1))
              .toJson()),
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          kind: NOSTR_KIND_RESERVATION,
          tags: [
            ['e', MOCK_LISTINGS[1].id]
          ]))),
].toList();
