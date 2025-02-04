import 'dart:convert';

import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

var MOCK_RESERVATIONS = [
  Reservation.fromNostrEvent(Nip01Event.fromJson({
    "pubkey": MockKeys.hoster.publicKey,
    "content": json.encode(ReservationContent(
            start: DateTime(2025, 1, 1), end: DateTime(2025, 5, 1))
        .toJson()),
    "createdAt": DateTime(2025),
    "kind": NOSTR_KIND_RESERVATION,
    "tags": [
      ['e', MOCK_LISTINGS[0].nip01Event.id]
    ]
  })),
  Reservation.fromNostrEvent(Nip01Event.fromJson({
    "pubkey": MockKeys.hoster.publicKey,
    "content": json.encode(ReservationContent(
            start: DateTime(2025, 1, 1), end: DateTime(2025, 5, 1))
        .toJson()),
    "createdAt": DateTime(2025),
    "kind": NOSTR_KIND_RESERVATION,
    "tags": [
      ['e', MOCK_LISTINGS[1].nip01Event.id]
    ]
  })),
].toList();
