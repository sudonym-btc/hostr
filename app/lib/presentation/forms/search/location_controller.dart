import 'package:flutter/material.dart';
import 'package:hostr/logic/location/h3_tag.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class LocationController extends ChangeNotifier {
  final TextEditingController textController;
  final FocusNode focusNode;

  List<H3Tag> _h3Tags = const [];
  String? _h3Error;
  bool _isResolvingH3 = false;
  LocationSuggestion? _selectedSuggestion;
  String _lastResolvedText = '';

  LocationController({String initialText = ''})
    : textController = TextEditingController(text: initialText),
      focusNode = FocusNode();

  String get text => textController.text;
  List<H3Tag> get h3Tags => _h3Tags;
  String? get h3Error => _h3Error;
  bool get isResolvingH3 => _isResolvingH3;
  LocationSuggestion? get selectedSuggestion => _selectedSuggestion;
  String get lastResolvedText => _lastResolvedText;

  bool get isValid => !_isResolvingH3 && _h3Error == null;
  bool get canSubmit =>
      !_isResolvingH3 && _h3Error == null && _h3Tags.isNotEmpty;

  String? validateText(
    String? value, {
    String emptyMessage = 'Please enter a location',
  }) {
    if (_h3Error != null) {
      return _h3Error;
    }
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }
    return null;
  }

  void updateTextFromUser(String value) {
    _selectedSuggestion = null;
    _clearH3State(notify: false);
    if (textController.text != value) {
      textController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    notifyListeners();
  }

  void applySelection(LocationSuggestion suggestion) {
    _selectedSuggestion = suggestion;
    textController.value = TextEditingValue(
      text: suggestion.displayName,
      selection: TextSelection.collapsed(offset: suggestion.displayName.length),
    );
    notifyListeners();
  }

  void beginH3Resolving() {
    _isResolvingH3 = true;
    _h3Error = null;
    notifyListeners();
  }

  void setH3Result(List<H3Tag> tags, String resolvedText) {
    _h3Tags = tags;
    _h3Error = tags.isEmpty ? 'No H3 cells found' : null;
    _isResolvingH3 = false;
    _lastResolvedText = resolvedText;
    notifyListeners();
  }

  void setH3Error(String message) {
    _h3Tags = const [];
    _h3Error = message;
    _isResolvingH3 = false;
    notifyListeners();
  }

  void clearAll() {
    textController.clear();
    _selectedSuggestion = null;
    _lastResolvedText = '';
    _clearH3State(notify: true);
  }

  void clearH3() {
    _clearH3State(notify: true);
  }

  void _clearH3State({required bool notify}) {
    _h3Tags = const [];
    _h3Error = null;
    _isResolvingH3 = false;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
