import 'package:flutter/material.dart';
import 'package:hostr/logic/location/h3_tag.dart';

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

  const SearchFormState({
    this.location = '',
    this.availabilityRange,
    this.h3Tags = const [],
  });

  SearchFormState copyWith({
    String? location,
    DateTimeRange? availabilityRange,
    List<H3Tag>? h3Tags,
  }) {
    return SearchFormState(
      location: location ?? this.location,
      availabilityRange: availabilityRange ?? this.availabilityRange,
      h3Tags: h3Tags ?? this.h3Tags,
    );
  }
}
