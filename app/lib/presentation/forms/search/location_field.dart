import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class LocationField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const LocationField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() {
    return LocationFieldState();
  }
}

class LocationFieldState extends State<LocationField> {
  late TextEditingController _controller;
  List<LocationSuggestion> _placeList = [];
  Timer? _debounce;
  int _suggestionRequestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _fetchSuggestions(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      _debounce?.cancel();
      setState(() {
        _placeList = [];
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      final requestId = ++_suggestionRequestId;
      final res = await getIt<Hostr>().location.suggestions(trimmed);
      if (!mounted || requestId != _suggestionRequestId) return;
      setState(() {
        _placeList = res;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            hintText: "Where are you going?",
            labelText: 'Location',
            // prefixIcon: Icon(Icons.location_on),
            suffixIcon: IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _placeList = [];
                });
              },
            ),
          ),
          controller: _controller,
          onChanged: (value) {
            widget.onChanged(value);
            _fetchSuggestions(value);
          },
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter a location';
            }
            return null;
          },
        ),
        if (_placeList.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_placeList[index].displayName),
                  onTap: () {
                    _controller.text = _placeList[index].displayName;
                    widget.onChanged(_controller.text);
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _placeList = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
