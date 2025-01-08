class Amount {
  final double value;
  final Currency currency;

  Amount({required this.value, required this.currency});

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount(
        value: json['value'],
        currency: Currency.values
            .firstWhere((e) => e.toString() == 'Currency.${json['currency']}'));
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'currency': currency.toString().split('.').last};
  }
}

enum Currency { BTC, USD }
