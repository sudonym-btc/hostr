import 'amount.dart';

class Price {
  Amount amount;
  Frequency frequency;

  Price({required this.amount, required this.frequency});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
        amount: Amount.fromJson(json['amount']),
        frequency: Frequency.values.firstWhere(
            (e) => e.toString() == 'Frequency.${json['frequency']}'));
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toJson(),
      'frequency': frequency.toString().split('.').last
    };
  }
}

enum Frequency { daily, weekly, monthly, yearly }

class FrequencyInDays {
  static const Map<Frequency, int> values = {
    Frequency.daily: 1,
    Frequency.weekly: 7,
    Frequency.monthly: 30,
    Frequency.yearly: 365,
  };

  static int of(Frequency frequency) {
    return values[frequency] ?? 0; // Return 0 if the frequency is not found
  }
}
