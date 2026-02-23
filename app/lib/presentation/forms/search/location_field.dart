import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/sources/api/google_maps.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import 'location_controller.dart';

enum LocationFieldH3Mode { none, addressHierarchy, polygonCover }

class LocationField extends StatefulWidget {
  final LocationController controller;
  final String hintText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<LocationSuggestion>? onSelected;
  final Set<String>? featureTypes;
  final Set<String>? polygonFeatureTypes;
  final int minQueryLength;
  final int limit;
  final Duration debounceDuration;
  final bool clearable;
  final bool showH3Output;
  final LocationFieldH3Mode h3Mode;
  final int addressFinestResolution;
  final int addressMaxTags;
  final int polygonMaxTags;

  const LocationField({
    super.key,
    required this.controller,
    this.hintText = 'Enter a location',
    this.validator,
    this.onSelected,
    this.featureTypes,
    this.polygonFeatureTypes,
    this.minQueryLength = 3,
    this.limit = 5,
    this.debounceDuration = const Duration(milliseconds: 1000),
    this.clearable = true,
    this.showH3Output = false,
    this.h3Mode = LocationFieldH3Mode.none,
    this.addressFinestResolution = 15,
    this.addressMaxTags = 16,
    this.polygonMaxTags = 40,
  });

  @override
  State<StatefulWidget> createState() {
    return LocationFieldState();
  }
}

class LocationFieldState extends State<LocationField> {
  List<LocationSuggestion> _placeList = [];
  String _sessionToken = '';
  Timer? _debounce;
  int _suggestionRequestId = 0;
  int _h3RequestId = 0;
  bool _isLoadingSuggestions = false;
  bool _isSelectingSuggestion = false;

  @override
  void initState() {
    super.initState();
    widget.controller.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onControllerChanged);
    _sessionToken = _newSessionToken();
    _scheduleInitialH3Resolve();
  }

  @override
  void didUpdateWidget(covariant LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.focusNode.removeListener(_onFocusChanged);
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.focusNode.addListener(_onFocusChanged);
      widget.controller.addListener(_onControllerChanged);
      _scheduleInitialH3Resolve();
    }
  }

  void _scheduleInitialH3Resolve() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.h3Mode == LocationFieldH3Mode.none) return;
      if (widget.controller.text.trim().isEmpty) return;
      if (widget.controller.h3Tags.isNotEmpty) return;
      if (widget.controller.isResolvingH3) return;
      _resolveH3ForInput();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onFocusChanged() {
    if (widget.controller.focusNode.hasFocus) {
      return;
    }
    if (mounted) {
      setState(() {
        _placeList = [];
        _isLoadingSuggestions = false;
      });
    }
    if (_isSelectingSuggestion) {
      return;
    }
    _resolveH3ForInput();
  }

  void _fetchSuggestions(String value) {
    final trimmed = value.trim();
    if (trimmed.length < widget.minQueryLength) {
      _debounce?.cancel();
      setState(() {
        _isLoadingSuggestions = false;
        _placeList = [];
      });
      return;
    }

    _debounce?.cancel();
    setState(() {
      _isLoadingSuggestions = true;
    });
    _debounce = Timer(widget.debounceDuration, () async {
      final requestId = ++_suggestionRequestId;
      try {
        final googleResults = await getIt<GoogleMaps>().getLocationResults(
          trimmed,
          _sessionToken,
          limit: widget.limit,
          featureTypes: widget.featureTypes,
        );
        final res = googleResults.map(_toLocationSuggestion).toList();
        if (!mounted || requestId != _suggestionRequestId) return;
        setState(() {
          _isLoadingSuggestions = false;
          _placeList = res;
        });
      } catch (_) {
        if (!mounted || requestId != _suggestionRequestId) return;
        setState(() {
          _isLoadingSuggestions = false;
          _placeList = [];
        });
      }
    });
  }

  String _newSessionToken() =>
      '${DateTime.now().microsecondsSinceEpoch}-${hashCode.abs()}';

  Future<void> _copyH3IndexesToClipboard() async {
    final tags = widget.controller.h3Tags;
    if (tags.isEmpty) return;

    final csv = tags.map((tag) => tag.index).join(',');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.copiedH3Indexes(tags.length),
        ),
      ),
    );
  }

  LocationSuggestion _toLocationSuggestion(Map<String, dynamic> prediction) {
    final text = prediction['text'];
    final structuredFormat = prediction['structuredFormat'];
    final structuredMap = structuredFormat is Map
        ? Map<String, dynamic>.from(structuredFormat)
        : null;

    final fullText =
        (text is Map ? text['text'] : null)?.toString() ??
        (prediction['description']?.toString() ?? '');

    String displayName = fullText;
    final main =
        (structuredMap?['mainText'] is Map
                ? (structuredMap?['mainText'] as Map)['text']
                : null)
            ?.toString();
    final secondary =
        (structuredMap?['secondaryText'] is Map
                ? (structuredMap?['secondaryText'] as Map)['text']
                : null)
            ?.toString();
    if ((main ?? '').isNotEmpty && (secondary ?? '').isNotEmpty) {
      displayName = '$main, $secondary';
    } else if ((main ?? '').isNotEmpty) {
      displayName = main!;
    }

    return LocationSuggestion(
      displayName: displayName,
      placeId:
          prediction['placeId']?.toString() ??
          prediction['place_id']?.toString(),
      latitude: null,
      longitude: null,
    );
  }

  Future<LocationSuggestion> _resolveCoordinates(
    LocationSuggestion suggestion,
  ) async {
    LatLng? coordinates;

    final placeId = suggestion.placeId;
    if (placeId != null && placeId.isNotEmpty) {
      coordinates = await getIt<GoogleMaps>().getCoordinatesFromPlaceId(
        placeId,
      );
    }
    coordinates ??= await getIt<GoogleMaps>().getCoordinatesFromAddress(
      suggestion.displayName,
    );

    if (coordinates == null) {
      return suggestion;
    }

    return LocationSuggestion(
      displayName: suggestion.displayName,
      placeId: suggestion.placeId,
      osmClass: suggestion.osmClass,
      osmType: suggestion.osmType,
      addressType: suggestion.addressType,
      placeRank: suggestion.placeRank,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  }

  Future<void> _resolveH3ForInput({
    LocationSuggestion? selectedSuggestion,
  }) async {
    if (widget.h3Mode == LocationFieldH3Mode.none) {
      return;
    }

    final input = widget.controller.text.trim();
    if (input.isEmpty) {
      widget.controller.clearH3();
      return;
    }

    if (!widget.controller.focusNode.hasFocus &&
        input == widget.controller.lastResolvedText) {
      return;
    }

    final requestId = ++_h3RequestId;
    widget.controller.beginH3Resolving();

    try {
      List<H3Tag> tags;
      if (widget.h3Mode == LocationFieldH3Mode.addressHierarchy) {
        final selected =
            selectedSuggestion ?? widget.controller.selectedSuggestion;
        final point =
            selected != null &&
                selected.displayName.trim() == input &&
                selected.latitude != null &&
                selected.longitude != null
            ? GeoPoint(
                latitude: selected.latitude!,
                longitude: selected.longitude!,
              )
            : await getIt<Hostr>().location.point(input);

        tags = getIt<H3Engine>().hierarchy.hierarchyForPointTags(
          latitude: point.latitude,
          longitude: point.longitude,
          finestResolution: widget.addressFinestResolution,
          maxTags: widget.addressMaxTags,
        );
      } else {
        final polygonResult = await getIt<Hostr>().location.polygon(
          input,
          featureTypes:
              widget.polygonFeatureTypes ??
              widget.featureTypes ??
              const {'country', 'state', 'region', 'city', 'town'},
        );

        tags = await getIt<H3Engine>().polygonCover.fromGeoJsonTagsInBackground(
          geoJson: polygonResult.geoJson,
          maxH3Tags: widget.polygonMaxTags,
          kIsWeb: kIsWeb,
        );
      }

      if (!mounted || requestId != _h3RequestId) return;
      widget.controller.setH3Result(tags, input);
    } catch (e) {
      if (!mounted || requestId != _h3RequestId) return;
      widget.controller.setH3Error(
        'Could not resolve location ${e.toString()}',
      );
    }
  }

  // ── Unified below-field area (loading / suggestions / empty) ──────────

  bool get _isBusy => _isLoadingSuggestions || widget.controller.isResolvingH3;

  String get _busyText {
    if (widget.controller.isResolvingH3) return 'Resolving location…';
    return 'Searching locations…';
  }

  Widget _buildBelowField() {
    if (_isBusy) {
      return CustomPadding.only(
        key: const ValueKey('loading'),
        left: kSpace2,
        right: kSpace2,
        top: kSpace3,
        bottom: kSpace3,
        child: Row(
          children: [
            const AppLoadingIndicator.small(),
            Gap.horizontal.custom(kSpace3),
            AnimatedSwitcher(
              duration: kAnimationDuration,
              child: Text(
                _busyText,
                key: ValueKey(_busyText),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    if (_placeList.isNotEmpty) {
      return ConstrainedBox(
        key: const ValueKey('suggestions'),
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: _placeList.length,
          itemBuilder: (context, index) {
            return ListTile(
              dense: true,
              title: Text(_placeList[index].displayName),
              onTap: () async {
                final selected = _placeList[index];
                _isSelectingSuggestion = true;
                // Avoid context ancestor lookup after async gaps.
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() {
                  _isLoadingSuggestions = true;
                  _placeList = [];
                });
                try {
                  final resolved = await _resolveCoordinates(selected);
                  if (!mounted) return;

                  widget.controller.applySelection(resolved);
                  widget.onSelected?.call(resolved);
                  await _resolveH3ForInput(selectedSuggestion: resolved);
                } finally {
                  _isSelectingSuggestion = false;
                  if (!mounted) return;
                  setState(() {
                    _isLoadingSuggestions = false;
                    _placeList = [];
                    _sessionToken = _newSessionToken();
                  });
                }
              },
            );
          },
        ),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          autocorrect: false,
          enableSuggestions: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hintText,
            // prefixIcon: Icon(Icons.location_on),
            suffixIcon:
                widget.clearable && widget.controller.text.trim().isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      widget.controller.clearAll();
                      setState(() {
                        _isLoadingSuggestions = false;
                        _placeList = [];
                      });
                    },
                  )
                : null,
          ),
          controller: widget.controller.textController,
          focusNode: widget.controller.focusNode,
          forceErrorText: widget.controller.h3Error,
          onChanged: (value) {
            widget.controller.updateTextFromUser(value);
            _fetchSuggestions(value);
          },
          validator:
              widget.validator ??
              (value) {
                return widget.controller.validateText(value);
              },
        ),
        AnimatedSwitcher(
          duration: kAnimationDuration,
          switchInCurve: kAnimationCurve,
          switchOutCurve: kAnimationCurve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: _buildBelowField(),
        ),
        if (widget.showH3Output)
          CustomPadding.only(
            top: kSpace2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.controller.h3Tags.isEmpty
                        ? 'h3'
                        : 'h3 tags: ${widget.controller.h3Tags.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.controller.h3Tags.isNotEmpty)
                    CustomPadding.only(
                      top: kSpace2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.controller.h3Tags
                                .take(6)
                                .map(
                                  (tag) => Chip(
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    label: Text(
                                      'r${tag.resolution}: ${tag.index}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          Gap.vertical.sm(),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: kIconSm),
                            label: Text(
                              AppLocalizations.of(context)!.copyH3Indexes,
                            ),
                            onPressed: _copyH3IndexesToClipboard,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
