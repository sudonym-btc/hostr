import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/forms/main.dart';
import 'package:hostr/presentation/forms/search/location_controller.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

@RoutePage()
class FiltersScreen extends StatefulWidget {
  final bool asBottomSheet;

  // ignore: use_key_in_widget_constructors
  const FiltersScreen({this.asBottomSheet = false});

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
    final content = SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchForm(controller: _controller),
            CustomPadding(
              top: 0,
              child: Row(
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
            ),
          ],
        ),
      ),
    );

    if (widget.asBottomSheet) {
      return content;
    }

    return Scaffold(body: content);
  }

  void _submit() {
    if (!_controller.validate()) return;

    final state = _controller.buildSubmitState();
    BlocProvider.of<DateRangeCubit>(
      context,
    ).updateDateRange(state.availabilityRange);
    context.read<FilterCubit>().updateFilter(
      Filter(
        kinds: [Listing.kinds[0]],
        tags: {'g': state.h3Tags.map((tag) => tag.index).toList()},
      ),
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
      _controller.dateRangeController.hasValue;

  void _clear() {
    _controller.clearAll();
    context.read<DateRangeCubit>().updateDateRange(null);
    context.read<FilterCubit>().clear();
  }
}
