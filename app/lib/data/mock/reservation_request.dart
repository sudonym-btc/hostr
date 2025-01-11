import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/mock/reservation.dart';
import 'package:hostr/data/models/amount.dart';

NostrKeyPairs keyPairs = NostrKeyPairs.generate();

var MOCK_RESERVATION_REQUESTS = [
  ReservationRequest.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: json.encode(ReservationRequestContent(
              start: MOCK_RESERVATIONS[0].parsedContent.start,
              end: MOCK_RESERVATIONS[0].parsedContent.end,
              quantity: 1,
              amount: Amount(value: 0.001, currency: Currency.BTC))
          .toJson()),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_RESERVATION_REQUEST,
      tags: [])),
].toList();
