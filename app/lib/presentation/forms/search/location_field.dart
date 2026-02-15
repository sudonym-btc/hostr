import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/data/sources/api/google_maps.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class LocationField extends StatefulWidget {
  final String value;
  final String hintText;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Set<String>? featureTypes;
  final int minQueryLength;
  final int limit;
  final Duration debounceDuration;
  final bool clearable;
  final ValueChanged<LocationSuggestion> onSelected;

  const LocationField({
    super.key,
    required this.value,
    this.hintText = 'Enter a location',
    this.controller,
    this.validator,
    this.onChanged,
    this.featureTypes,
    this.minQueryLength = 3,
    this.limit = 5,
    this.debounceDuration = const Duration(milliseconds: 1000),
    this.clearable = true,
    required this.onSelected,
  });

  @override
  State<StatefulWidget> createState() {
    return LocationFieldState();
  }
}

class LocationFieldState extends State<LocationField> {
  late TextEditingController _controller;
  bool _ownsController = false;
  List<LocationSuggestion> _placeList = [];
  String _sessionToken = '';
  Timer? _debounce;
  int _suggestionRequestId = 0;
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
    _sessionToken = _newSessionToken();
  }

  @override
  void didUpdateWidget(covariant LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller =
          widget.controller ?? TextEditingController(text: widget.value);
    } else if (widget.controller == null && oldWidget.value != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            hintText: widget.hintText,
            // prefixIcon: Icon(Icons.location_on),
            suffixIcon: widget.clearable
                ? IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                      setState(() {
                        _isLoadingSuggestions = false;
                        _placeList = [];
                      });
                    },
                  )
                : null,
          ),
          controller: _controller,
          onChanged: (value) {
            widget.onChanged?.call(value);
            _fetchSuggestions(value);
          },
          validator:
              widget.validator ??
              (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a location';
                }
                return null;
              },
        ),
        if (_isLoadingSuggestions)
          const ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
            leading: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Searching locations...'),
          )
        else if (_placeList.isNotEmpty)
          ConstrainedBox(
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
                    // Avoid context ancestor lookup after async gaps.
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _isLoadingSuggestions = true;
                      _placeList = [];
                    });
                    try {
                      final resolved = await _resolveCoordinates(selected);
                      if (!mounted) return;

                      _controller.text = resolved.displayName;
                      widget.onChanged?.call(_controller.text);
                      widget.onSelected(resolved);
                    } finally {
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
          ),
      ],
    );
  }
}
