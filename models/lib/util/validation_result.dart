abstract class Validation<T> {
  final T event;
  const Validation(this.event);
}

class Valid<T> extends Validation<T> {
  const Valid(super.event);
}

class Invalid<T> extends Validation<T> {
  final String reason;
  const Invalid(super.event, this.reason);
}

/// Marks an item whose validation state is not yet known.
class Unvalidated<T> extends Validation<T> {
  const Unvalidated(super.event);
}

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
