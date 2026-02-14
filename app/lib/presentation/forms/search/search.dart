import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'date_range_buttons.dart';
import 'location_field.dart';

class SearchForm extends StatefulWidget {
  final Function(SearchFormState) onSubmit;

  const SearchForm({super.key, required this.onSubmit});

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _formKey = GlobalKey<FormState>();
  late SearchFormState _formState;
  int _geohashRequestId = 0;
  Timer? _geohashDebounce;

  @override
  void initState() {
    super.initState();
    _formState = SearchFormState();
  }

  @override
  void dispose() {
    _geohashDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormLabel(label: 'Where are you going?'),
                SizedBox(height: kDefaultPadding.toDouble() / 2),
                LocationField(
                  value: _formState.location,
                  onChanged: _onLocationChanged,
                ),
                SizedBox(height: kDefaultPadding.toDouble()),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formState.geohash.isEmpty
                        ? 'geohash'
                        : 'geohash: ${_formState.geohash}',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
                SizedBox(height: kDefaultPadding.toDouble()),
                FormLabel(label: 'When?'),
                SizedBox(height: kDefaultPadding.toDouble()),

                SizedBox(
                  width: double.infinity,
                  child: DateRangeButtons(
                    onTap: showDatePicker,
                    selectedDateRange: _formState.availabilityRange,
                  ),
                ),
              ],
            ),
          ),
          CustomPadding(
            top: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: _formState.geohash.isEmpty
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            widget.onSubmit(_formState);
                            BlocProvider.of<DateRangeCubit>(
                              context,
                            ).updateDateRange(_formState.availabilityRange);
                            context.read<FilterCubit>().updateFilter(
                              Filter(
                                kinds: [Listing.kinds[0]],
                                tags: {
                                  'g': [_formState.geohash],
                                },
                              ),
                              location: _formState.location,
                            );
                          }
                        },
                  child: Text(AppLocalizations.of(context)!.search),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),

      /// Testing blocked days
      selectableDayPredicate:
          (day, DateTime? selectedStartDay, DateTime? selectedEndDay) =>
              day.isAfter(DateTime.now()),
      initialDateRange: _formState.availabilityRange,
    );
    setState(() {
      _formState = _formState.copyWith(
        availabilityRange: ensureStartDateIsBeforeEndDate(picked),
      );
    });
  }

  Future<void> _onLocationChanged(String value) async {
    setState(() {
      _formState = _formState.copyWith(location: value);
    });

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _formState = _formState.copyWith(geohash: '');
      });
      return;
    }

    _geohashDebounce?.cancel();
    _geohashDebounce = Timer(const Duration(milliseconds: 800), () async {
      final requestId = ++_geohashRequestId;

      try {
        final result = await getIt<Hostr>().location.geohash(trimmed);
        if (!mounted || requestId != _geohashRequestId) return;

        setState(() {
          _formState = _formState.copyWith(geohash: result.geohash);
        });
      } catch (_) {
        if (!mounted || requestId != _geohashRequestId) return;
        setState(() {
          _formState = _formState.copyWith(geohash: '');
        });
      }
    });
  }
}

DateTimeRange? ensureStartDateIsBeforeEndDate(DateTimeRange? picked) {
  if (picked != null && picked.start.isAfter(picked.end)) {
    return DateTimeRange(start: picked.end, end: picked.start);
  }
  return picked;
}

class SearchFormState {
  final String location;
  final DateTimeRange? availabilityRange;
  final String geohash;

  const SearchFormState({
    this.location = '',
    this.availabilityRange,
    this.geohash = '',
  });

  SearchFormState copyWith({
    String? location,
    DateTimeRange? availabilityRange,
    String? geohash,
  }) {
    return SearchFormState(
      location: location ?? this.location,
      availabilityRange: availabilityRange ?? this.availabilityRange,
      geohash: geohash ?? this.geohash,
    );
  }
}
