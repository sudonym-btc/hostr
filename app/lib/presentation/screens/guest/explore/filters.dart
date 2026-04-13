import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/forms/main.dart';
import 'package:hostr/presentation/forms/search/location_controller.dart';
import 'package:models/main.dart';

@RoutePage()
class FiltersScreen extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const FiltersScreen();

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late final SearchFormController _controller;

  @override
  void initState() {
    super.initState();
    final initialLocation = context.read<FilterCubit>().state.location;
    final initialDateRange = context.read<DateRangeCubit>().state.dateRange;

    _controller = SearchFormController(
      locationController: LocationController(initialText: initialLocation),
      dateRangeController: DateRangeController(
        initialDateRange: initialDateRange,
      ),
    );
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      // title: AppLocalizations.of(context)!.search,
      content: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [SearchForm(controller: _controller)],
        ),
      ),
      buttons: Row(
        children: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clear,
              child: Text(AppLocalizations.of(context)!.clear),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _controller.canSubmit ? _submit : null,
            child: Text(AppLocalizations.of(context)!.search),
          ),
        ],
      ),
    );
  }

  void _submit() {
    // Location field has its own validator — only run it when text is present.
    final hasLocationText = _controller.locationController.text
        .trim()
        .isNotEmpty;
    if (hasLocationText && !_controller.validate()) return;

    final state = _controller.buildSubmitState();
    BlocProvider.of<DateRangeCubit>(
      context,
    ).updateDateRange(state.availabilityRange);

    // Build relay-side filter using promoted single-letter tags.
    final builder = Listing.buildFilter();

    // Geohash (location).
    if (state.h3Tags.isNotEmpty) {
      builder.rawTags({'g': state.h3Tags.map((tag) => tag.index).toList()});
    }

    // Listing type.
    if (state.listingType != null) {
      builder.listingTypes([state.listingType!]);
    }

    // Guest capacity.
    if (state.guests != null) {
      builder.minGuests(state.guests!);
    }

    // Beachfront.
    if (state.beachfront) {
      builder.features(['beachfront']);
    }

    context.read<FilterCubit>().updateFilter(
      builder.build(),
      location: state.location,
    );
    Navigator.pop(context);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _hasActiveFilters =>
      _controller.locationController.text.trim().isNotEmpty ||
      _controller.dateRangeController.hasValue ||
      _controller.guests != null ||
      _controller.listingType != null ||
      _controller.beachfront;

  void _clear() {
    _controller.clearAll();
    context.read<DateRangeCubit>().updateDateRange(null);
    context.read<FilterCubit>().clear();
  }
}
