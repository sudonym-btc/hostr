import 'package:hostr/data/models/amount.dart';

/** "price", "<number>", "<currency>", "<frequency>" */
class Price {
  Amount amount;
  Frequency frequency;

  Price({required this.amount, required this.frequency});

  factory Price.fromJson(List<dynamic> json) {
    return Price(
        amount: Amount.fromJson({"amount": json[1], "currency": json[2]}),
        frequency: Frequency.values
            .firstWhere((e) => e.toString() == 'Frequency.${json[3]}'));
  }

  List<dynamic> toJson() {
    return [
      amount.value,
      amount.currency.toString().split('.').last,
      frequency.toString().split('.').last
    ];
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
