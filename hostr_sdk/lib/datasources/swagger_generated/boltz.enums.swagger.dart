// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

enum RescuableSwapType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('submarine')
  submarine('submarine'),
  @JsonValue('chain')
  chain('chain');

  final String? value;

  const RescuableSwapType(this.value);
}

enum RestorableSwapType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('submarine')
  submarine('submarine'),
  @JsonValue('reverse')
  reverse('reverse'),
  @JsonValue('chain')
  chain('chain');

  final String? value;

  const RestorableSwapType(this.value);
}

enum SwapSwapTypeStatsFromToGetSwapType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('submarine')
  submarine('submarine'),
  @JsonValue('reverse')
  reverse('reverse'),
  @JsonValue('chain')
  chain('chain');

  final String? value;

  const SwapSwapTypeStatsFromToGetSwapType(this.value);
}

enum SwapSwapTypeStatsFromToGetReferral {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('pro')
  pro('pro');

  final String? value;

  const SwapSwapTypeStatsFromToGetReferral(this.value);
}
