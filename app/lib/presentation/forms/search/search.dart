import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/main.dart';

import 'date_range_buttons.dart';
import 'location_field.dart';

class SearchForm extends StatefulWidget {
  final Function(SearchFormState) onSubmit;

  const SearchForm({super.key, required this.onSubmit});

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _formKey = GlobalKey<FormState>();
  late SearchFormState _formState;

  @override
  void initState() {
    super.initState();
    _formState = SearchFormState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
              child: Column(
            children: [
              CustomPadding(
                child: LocationField(
                  value: _formState.location,
                  onChanged: (value) => setState(() {
                    _formState = _formState.copyWith(location: value);
                  }),
                ),
              ),
              CustomPadding(
                child: DateRangeButtons(
                    onTap: showDatePicker,
                    selectedDateRange: _formState.availabilityRange),
              ),
            ],
          )),
          CustomPadding(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(_formState);
                    BlocProvider.of<DateRangeCubit>(context)
                        .updateDateRange(_formState.availabilityRange);
                  }
                },
                child: Text('Search'),
              ),
            ],
          ))
        ],
      ),
    );
  }

  showDatePicker() async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 365)),

        /// Testing blocked days
        selectableDayPredicate:
            (day, DateTime? selectedStartDay, DateTime? selectedEndDay) =>
                day.isAfter(DateTime.now()) && day.day % 2 == 0,
        initialDateRange: _formState.availabilityRange);
    setState(() {
      _formState = _formState.copyWith(availabilityRange: picked);
    });
  }
}

class SearchFormState {
  final String location;
  final DateTimeRange? availabilityRange;

  const SearchFormState({
    this.location = '',
    this.availabilityRange,
  });

  SearchFormState copyWith({
    String? location,
    DateTimeRange? availabilityRange,
  }) {
    return SearchFormState(
      location: location ?? this.location,
      availabilityRange: availabilityRange ?? this.availabilityRange,
    );
  }
}
