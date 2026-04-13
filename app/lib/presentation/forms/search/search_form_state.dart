import 'package:flutter/material.dart';
import 'package:models/main.dart';

class SearchFormState {
  final String location;
  final DateTimeRange? availabilityRange;
  final List<H3Tag> h3Tags;
  final int? guests;
  final ListingType? listingType;
  final bool beachfront;

  /// Sentinel used internally by [copyWith] to distinguish "set to null"
  /// from "not provided".
  static const _unset = Object();

  const SearchFormState({
    this.location = '',
    this.availabilityRange,
    this.h3Tags = const [],
    this.guests,
    this.listingType,
    this.beachfront = false,
  });

  SearchFormState copyWith({
    String? location,
    Object? availabilityRange = _unset,
    List<H3Tag>? h3Tags,
    Object? guests = _unset,
    Object? listingType = _unset,
    bool? beachfront,
  }) {
    return SearchFormState(
      location: location ?? this.location,
      availabilityRange: identical(availabilityRange, _unset)
          ? this.availabilityRange
          : availabilityRange as DateTimeRange?,
      h3Tags: h3Tags ?? this.h3Tags,
      guests: identical(guests, _unset) ? this.guests : guests as int?,
      listingType: identical(listingType, _unset)
          ? this.listingType
          : listingType as ListingType?,
      beachfront: beachfront ?? this.beachfront,
    );
  }
}
