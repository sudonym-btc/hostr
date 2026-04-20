import 'package:flutter/material.dart';
import 'package:hostr/logic/forms/bool_field_controller.dart';
import 'package:hostr/logic/forms/enum_field_controller.dart';
import 'package:hostr/logic/forms/nullable_int_field_controller.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'date_range_controller.dart';
import 'location_controller.dart';

/// Form controller for the search / explore filters sheet.
///
/// Follows the same [UpsertFormController] + [FormFieldController] pattern
/// used by [EditListingController]. Each filter dimension is a registered
/// field so [isDirty] / [canSubmit] / [submitListenable] are automatic.
class SearchFormController extends UpsertFormController {
  // ── Sub-controllers ─────────────────────────────────────────────
  final LocationController locationField;
  final DateRangeController dateRangeField;
  final EnumFieldController<ListingType> listingTypeField;
  final NullableIntFieldController guestsField;
  final BoolFieldController beachfrontField;
  final BoolFieldController kitchenField;
  final BoolFieldController allowsPetsField;
  final BoolFieldController negotiableField;
  final NullableIntFieldController bedroomsField;
  final NullableIntFieldController bedsField;
  final NullableIntFieldController bathroomsField;

  SearchFormController({
    LocationController? locationField,
    DateRangeController? dateRangeField,
  }) : locationField = locationField ?? LocationController(required: false),
       dateRangeField = dateRangeField ?? DateRangeController(),
       listingTypeField = EnumFieldController<ListingType>(),
       guestsField = NullableIntFieldController(),
       beachfrontField = BoolFieldController(),
       kitchenField = BoolFieldController(),
       allowsPetsField = BoolFieldController(),
       negotiableField = BoolFieldController(),
       bedroomsField = NullableIntFieldController(),
       bedsField = NullableIntFieldController(),
       bathroomsField = NullableIntFieldController() {
    registerField(this.locationField);
    registerField(this.dateRangeField);
    registerField(listingTypeField);
    registerField(guestsField);
    registerField(beachfrontField);
    registerField(kitchenField);
    registerField(allowsPetsField);
    registerField(negotiableField);
    registerField(bedroomsField);
    registerField(bedsField);
    registerField(bathroomsField);
  }

  // ── canSubmit override ──────────────────────────────────────────
  // For a search form, "can submit" means the user has changed at
  // least one field from its initial state AND all fields are valid.
  @override
  bool get canSubmit => !isSaving && isReady && isDirty && _allFieldsReady;

  bool get _allFieldsReady {
    // Location only requires valid+canSubmit when text was entered.
    if (!locationField.isValid || !locationField.canSubmit) return false;
    // Other fields are always valid (no validation constraints), but
    // check the base contract anyway.
    return dateRangeField.isValid &&
        dateRangeField.canSubmit &&
        listingTypeField.isValid &&
        guestsField.isValid &&
        beachfrontField.isValid &&
        kitchenField.isValid &&
        allowsPetsField.isValid &&
        negotiableField.isValid &&
        bedroomsField.isValid &&
        bedsField.isValid &&
        bathroomsField.isValid;
  }

  // ── State initialisation ────────────────────────────────────────
  /// Populate all fields from an existing [FilterState] + date range.
  /// After this call every field's [isDirty] is `false`.
  void setStateFromFilter({
    String location = '',
    DateTimeRange? dateRange,
    Filter? filter,
  }) {
    locationField.setState(location);
    dateRangeField.setState(dateRange);

    // Reverse-parse the promoted tag values out of the existing filter.
    final tags = filter?.tags ?? {};

    // Listing type (target letter 'T').
    final typeValues = tags['T'];
    ListingType? parsedType;
    if (typeValues != null && typeValues.isNotEmpty) {
      final name = typeValues.first;
      parsedType = ListingType.values.cast<ListingType?>().firstWhere(
        (t) => t!.name == name,
        orElse: () => null,
      );
    }
    listingTypeField.setState(parsedType);

    // Guest capacity (target letter 'c').
    guestsField.setState(_parseMinInt(tags['c']));

    // Beachfront (target letter 's', value 'beachfront').
    final featureValues = tags['s'];
    beachfrontField.setState(
      featureValues != null && featureValues.contains('beachfront'),
    );
    kitchenField.setState(
      featureValues != null && featureValues.contains('kitchen'),
    );
    allowsPetsField.setState(
      featureValues != null && featureValues.contains('allows_pets'),
    );
    negotiableField.setState(tags['N']?.contains('true') ?? false);

    // Bedrooms (target letter 'B').
    bedroomsField.setState(_parseMinInt(tags['B']));

    // Beds (target letter 'b').
    bedsField.setState(_parseMinInt(tags['b']));

    // Bathrooms (target letter 'R').
    bathroomsField.setState(_parseMinInt(tags['R']));

    notifyListeners();
  }

  /// Reset all fields to their defaults (empty / null / false).
  void clearAll() {
    setStateFromFilter();
  }

  // ── Build the relay filter ──────────────────────────────────────
  /// Constructs an NDK [Filter] from the current field values using
  /// the [Listing] tag promotion rules.
  Filter buildFilter() {
    final builder = Listing.buildFilter();

    // Geohash (location).
    if (locationField.h3Tags.isNotEmpty) {
      builder.rawTags({
        'g': locationField.h3Tags.map((tag) => tag.index).toList(),
      });
    }

    // Listing type.
    if (listingTypeField.value != null) {
      builder.listingTypes([listingTypeField.value!]);
    }

    // Guest capacity.
    if (guestsField.value != null) {
      builder.minGuests(guestsField.value!);
    }

    // Boolean features.
    final features = <String>[
      if (beachfrontField.value) 'beachfront',
      if (kitchenField.value) 'kitchen',
      if (allowsPetsField.value) 'allows_pets',
    ];
    if (features.isNotEmpty) builder.features(features);
    if (negotiableField.value) builder.negotiable();

    // Room counts.
    if (bedroomsField.value != null) builder.minBedrooms(bedroomsField.value!);
    if (bedsField.value != null) builder.minBeds(bedsField.value!);
    if (bathroomsField.value != null) {
      builder.minBathrooms(bathroomsField.value!);
    }

    return builder.build();
  }

  // ── UpsertFormController plumbing ───────────────────────────────
  // Search forms don't persist — upsert is a no-op.
  @override
  Future<void> upsert() async {}

  @override
  void dispose() {
    locationField.dispose();
    dateRangeField.dispose();
    listingTypeField.dispose();
    guestsField.dispose();
    beachfrontField.dispose();
    kitchenField.dispose();
    allowsPetsField.dispose();
    negotiableField.dispose();
    bedroomsField.dispose();
    bedsField.dispose();
    bathroomsField.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────
  /// Parse the minimum int from a list of stringified ints (promoted
  /// valued tags store a range like ['1','2','3',…,'20']).
  static int? _parseMinInt(List<String>? values) {
    if (values == null || values.isEmpty) return null;
    final ints = values.map(int.tryParse).whereType<int>();
    return ints.isEmpty ? null : ints.reduce((a, b) => a < b ? a : b);
  }
}
