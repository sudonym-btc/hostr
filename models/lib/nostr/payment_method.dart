enum PaymentMethod {
  zap,
  evm;

  String get wireName => name;

  static PaymentMethod fromJson(Object? value) {
    final wireName = value?.toString().toLowerCase();
    return PaymentMethod.values.firstWhere(
      (method) => method.wireName == wireName,
      orElse: () => throw FormatException('Unsupported payment method: $value'),
    );
  }
}
