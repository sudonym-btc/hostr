import 'denominated_amount.dart';

class Price {
  DenominatedAmount amount;

  /// The billing frequency. `null` means a one-time / fixed price.
  Frequency? frequency;

  Price({required this.amount, this.frequency});

  factory Price.fromJson(Map<String, dynamic> json) {
    final freqStr = json['frequency'] as String?;
    return Price(
        amount: DenominatedAmount.fromJson(json['amount']),
        frequency: freqStr != null
            ? Frequency.values
                .firstWhere((e) => e.toString() == 'Frequency.$freqStr')
            : null);
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toJson(),
      if (frequency != null) 'frequency': frequency.toString().split('.').last,
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

  /// Returns days-per-period. Returns 1 for null (one-time price).
  static int of(Frequency? frequency) {
    if (frequency == null) return 1;
    return values[frequency] ?? 0;
  }
}

/// NIP-99 noun-form frequency names (day, week, month, year).
extension FrequencyNip99 on Frequency {
  String get nip99Name {
    switch (this) {
      case Frequency.daily:
        return 'day';
      case Frequency.weekly:
        return 'week';
      case Frequency.monthly:
        return 'month';
      case Frequency.yearly:
        return 'year';
    }
  }

  /// Parse NIP-99 noun-form frequency. Returns null for unrecognised values
  /// (which means one-time / fixed price).
  static Frequency? fromNip99(String? name) {
    if (name == null) return null;
    switch (name) {
      case 'day':
        return Frequency.daily;
      case 'week':
        return Frequency.weekly;
      case 'month':
        return Frequency.monthly;
      case 'year':
        return Frequency.yearly;
      default:
        return null;
    }
  }
}
