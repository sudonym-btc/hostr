import 'package:flutter/material.dart';
import 'package:models/main.dart';

DateTimeRange? ensureStartDateIsBeforeEndDate(DateTimeRange? picked) {
  if (picked != null && picked.start.isAfter(picked.end)) {
    return DateTimeRange(start: picked.end, end: picked.start);
  }
  return picked;
}

class SearchFormState {
  final String location;
  final DateTimeRange? availabilityRange;
  final List<H3Tag> h3Tags;

  /// Sentinel used internally by [copyWith] to distinguish "set to null"
  /// from "not provided".
  static const _unset = Object();

  const SearchFormState({
    this.location = '',
    this.availabilityRange,
    this.h3Tags = const [],
  });

  SearchFormState copyWith({
    String? location,
    Object? availabilityRange = _unset,
    List<H3Tag>? h3Tags,
  }) {
    return SearchFormState(
      location: location ?? this.location,
      availabilityRange: identical(availabilityRange, _unset)
          ? this.availabilityRange
          : availabilityRange as DateTimeRange?,
      h3Tags: h3Tags ?? this.h3Tags,
    );
  }
}
