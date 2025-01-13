import 'package:flutter/material.dart';
import 'package:hostr/data/models/amount.dart';

class AmountInputWidget extends FormField<Amount> {
  AmountInputWidget()
      : super(
          builder: (field) {
            return TextFormField(
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
              ),
              onChanged: (value) {
                field.didChange(Amount(value: 1, currency: Currency.USD));
              },
            );
          },
        );
}
