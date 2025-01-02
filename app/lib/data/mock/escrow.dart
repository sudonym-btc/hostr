import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../models/escrow.dart';
import 'keypairs.dart';

var MOCK_ESCROWS = [
  NostrEvent.fromPartialData(
      keyPairs: MockKeys.sccrow,
      content: JsonEncoder().convert({
        'type': 'ROOTSTOCK',
        'kinds': [NOSTR_KIND_BOOKING],
        'maxTime': 365,
        'cost': {
          'flat': 100,
          'percentage': 10,
          'flatTime': 100,
          'percentageTime': 0
        },
      }),
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_ESCROW,
      tags: [])
].map(Escrow.fromNostrEvent).toList();
