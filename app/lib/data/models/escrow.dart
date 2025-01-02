import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/nostr/model/event/event.dart';

import 'event.dart';

class Cost {
  final int flat;
  final int percentage;
  final int flatTime;
  final int percentageTime;

  Cost(
      {required this.flat,
      required this.percentage,
      required this.flatTime,
      required this.percentageTime});
}

enum EscrowType { ROOTSTOCK }

class Escrow extends Event {
  final Duration maxTime;
  final Cost cost;
  final EscrowType type;

  Escrow(super.event,
      {required this.type, required this.maxTime, required this.cost});

  static fromNostrEvent(NostrEvent event) {
    Map json = jsonDecode(event.content!);

    return Escrow(event,
        type: EscrowType.ROOTSTOCK,
        maxTime: Duration(days: int.parse(json["maxTime"].toString())),
        cost: Cost(
          flat: 100,
          percentage: 10,
          flatTime: 100,
          percentageTime: 0,
        ));
  }
}
