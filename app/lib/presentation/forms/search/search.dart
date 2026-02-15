import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/location/h3_polygon_cover.dart';
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
  final CustomLogger _logger = CustomLogger();
  late SearchFormState _formState;
  int _h3RequestId = 0;
  Timer? _h3Debounce;
  bool _isResolvingH3 = false;
  String? _h3StatusError;

  @override
  void initState() {
    super.initState();
    _formState = SearchFormState();
  }

  @override
  void dispose() {
    _h3Debounce?.cancel();
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
                  onSelected: _onLocationSelected,
                  featureTypes: const {
                    'country',
                    'state',
                    'region',
                    'city',
                    'town',
                  },
                  debounceDuration: const Duration(milliseconds: 400),
                ),
                SizedBox(height: kDefaultPadding.toDouble()),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_isResolvingH3)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Resolving H3…',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w300),
                            ),
                          ],
                        )
                      else
                        Text(
                          _formState.h3Tags.isEmpty
                              ? 'h3'
                              : 'h3 tags: ${_formState.h3Tags.length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w200,
                              ),
                        ),
                      if (_h3StatusError != null)
                        Text(
                          _h3StatusError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                    ],
                  ),
                ),
                if (_formState.h3Tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _formState.h3Tags
                              .take(6)
                              .map(
                                (tag) => Chip(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  label: Text(
                                    tag,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy H3 tags'),
                            onPressed: _copyH3TagsToClipboard,
                          ),
                        ),
                      ],
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
                  onPressed: _formState.h3Tags.isEmpty
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
                                tags: {'g': _formState.h3Tags},
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

  Future<void> _onLocationSelected(LocationSuggestion suggestion) async {
    setState(() {
      _formState = _formState.copyWith(
        location: suggestion.displayName,
        h3Tags: const [],
      );
      _h3StatusError = null;
      _isResolvingH3 = true;
    });

    final trimmed = suggestion.displayName.trim();
    if (trimmed.isEmpty) return;

    _h3Debounce?.cancel();
    _h3Debounce = Timer(const Duration(milliseconds: 250), () async {
      final requestId = ++_h3RequestId;

      try {
        final polygonResult = await getIt<Hostr>().location.polygon(
          trimmed,
          featureTypes: const {'country', 'state', 'region', 'city', 'town'},
        );
        _logger.i(
          'H3 polygon fetched for "$trimmed": '
          'placeId=${polygonResult.placeId}, '
          'type=${polygonResult.geoJson['type']}, '
          'display=${polygonResult.displayName}',
        );
        final h3Tags = H3PolygonCover.fromGeoJson(
          geoJson: polygonResult.geoJson,
          preferredResolution: 7,
          minResolution: 2,
          maxH3Tags: 40,
        );

        _logger.i('H3 coverage built for "$trimmed": count=${h3Tags.length}');

        if (!mounted || requestId != _h3RequestId) return;

        setState(() {
          _formState = _formState.copyWith(h3Tags: h3Tags);
          _isResolvingH3 = false;
          _h3StatusError = h3Tags.isEmpty ? 'No H3 cells found' : null;
        });
      } catch (e, st) {
        _logger.e(
          'Failed to build H3 coverage for "$trimmed": $e',
          error: e,
          stackTrace: st,
        );
        if (!mounted || requestId != _h3RequestId) return;

        final message = e.toString();
        final looksLikeNativeH3LinkError =
            message.contains('degsToRads') ||
            message.contains('symbol not found');

        setState(() {
          _formState = _formState.copyWith(h3Tags: const []);
          _isResolvingH3 = false;
          _h3StatusError = looksLikeNativeH3LinkError
              ? 'H3 native library link error (degsToRads missing). Please fully restart the app.'
              : 'Could not build H3 coverage (${e.runtimeType})';
        });
      }
    });
  }

  void _onLocationChanged(String value) {
    final trimmed = value.trim();
    if (trimmed == _formState.location && _formState.h3Tags.isEmpty) {
      return;
    }

    setState(() {
      _formState = _formState.copyWith(location: value, h3Tags: const []);
      _h3StatusError = null;
      _isResolvingH3 = false;
    });
  }

  Future<void> _copyH3TagsToClipboard() async {
    if (_formState.h3Tags.isEmpty) return;
    final serialized = jsonEncode(_formState.h3Tags);
    await Clipboard.setData(ClipboardData(text: serialized));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${_formState.h3Tags.length} H3 tags')),
    );
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
  final List<String> h3Tags;

  const SearchFormState({
    this.location = '',
    this.availabilityRange,
    this.h3Tags = const [],
  });

  SearchFormState copyWith({
    String? location,
    DateTimeRange? availabilityRange,
    List<String>? h3Tags,
  }) {
    return SearchFormState(
      location: location ?? this.location,
      availabilityRange: availabilityRange ?? this.availabilityRange,
      h3Tags: h3Tags ?? this.h3Tags,
    );
  }
}
