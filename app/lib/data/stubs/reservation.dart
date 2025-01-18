import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';

var MOCK_RESERVATIONS = [
  Reservation.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ReservationContent(
              start: DateTime(2025, 1, 1), end: DateTime(2025, 5, 1))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_RESERVATION,
      tags: [
        ['e', MOCK_LISTINGS[0].id!]
      ])),
  Reservation.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ReservationContent(
              start: DateTime(2025, 1, 1), end: DateTime(2025, 5, 1))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_RESERVATION,
      tags: [
        ['e', MOCK_LISTINGS[1].id!]
      ])),
].toList();
