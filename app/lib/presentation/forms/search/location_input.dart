import 'package:flutter/material.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'location_controller.dart';
import 'location_field.dart';

/// A preconfigured [LocationField] for resolving a single address
/// to an H3 hierarchy (e.g. listing edit form).
///
/// Wraps [LocationField] with `h3Mode: LocationFieldH3Mode.addressHierarchy`.
class LocationInput extends StatelessWidget {
  final LocationController controller;
  final String hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<LocationSuggestion>? onSelected;
  final int minQueryLength;
  final Duration debounceDuration;
  final int addressFinestResolution;
  final int addressMaxTags;

  const LocationInput({
    super.key,
    required this.controller,
    this.hintText = 'Enter an address',
    this.validator,
    this.onSelected,
    this.minQueryLength = 3,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.addressFinestResolution = 15,
    this.addressMaxTags = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LocationField(
      controller: controller,
      hintText: hintText,
      validator: validator,
      onSelected: onSelected,
      featureTypes: null,
      h3Mode: LocationFieldH3Mode.addressHierarchy,
      minQueryLength: minQueryLength,
      debounceDuration: debounceDuration,
      addressFinestResolution: addressFinestResolution,
      addressMaxTags: addressMaxTags,
    );
  }
}

/// A preconfigured [LocationField] for resolving a named area
/// to a list of H3 polygon-cover tags (e.g. search form).
///
/// Wraps [LocationField] with `h3Mode: LocationFieldH3Mode.polygonCover`.
class AreaLocationInput extends StatelessWidget {
  final LocationController controller;
  final String hintText;
  final FormFieldValidator<String>? validator;
  final Set<String>? featureTypes;
  final Set<String>? polygonFeatureTypes;
  final int minQueryLength;
  final Duration debounceDuration;
  final int polygonMaxTags;
  final bool showH3Output;

  const AreaLocationInput({
    super.key,
    required this.controller,
    this.hintText = 'Enter a location',
    this.validator,
    this.featureTypes = const {'country', 'state', 'region', 'city', 'town'},
    this.polygonFeatureTypes,
    this.minQueryLength = 3,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.polygonMaxTags = 500,
    this.showH3Output = false,
  });

  @override
  Widget build(BuildContext context) {
    return LocationField(
      controller: controller,
      hintText: hintText,
      validator: validator,
      featureTypes: featureTypes,
      polygonFeatureTypes: polygonFeatureTypes,
      h3Mode: LocationFieldH3Mode.polygonCover,
      minQueryLength: minQueryLength,
      debounceDuration: debounceDuration,
      polygonMaxTags: polygonMaxTags,
      showH3Output: showH3Output,
    );
  }
}
