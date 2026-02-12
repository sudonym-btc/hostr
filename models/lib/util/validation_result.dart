class ValidationResult {
  final bool isValid;
  final Map<String, FieldValidation> fields;

  ValidationResult({required this.isValid, required this.fields});
}

class FieldValidation {
  final bool ok;
  final String? message;

  FieldValidation({required this.ok, this.message});
}
