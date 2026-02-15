import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';

import 'date_range_buttons.dart';
import 'location_field.dart';
import 'search_form_controller.dart';
import 'search_form_state.dart';

class SearchForm extends StatefulWidget {
  final SearchFormController controller;

  const SearchForm({super.key, required this.controller});

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.controller.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormLabel(label: 'Where are you going?'),
                SizedBox(height: kDefaultPadding.toDouble() / 2),
                LocationField(
                  controller: widget.controller.locationController,
                  featureTypes: const {
                    'country',
                    'state',
                    'region',
                    'city',
                    'town',
                  },
                  h3Mode: LocationFieldH3Mode.polygonCover,
                  showH3Output: false,
                  polygonMaxTags: 1000,
                  debounceDuration: const Duration(milliseconds: 400),
                ),
                SizedBox(height: kDefaultPadding.toDouble()),
                FormLabel(label: 'When?'),
                SizedBox(height: kDefaultPadding.toDouble()),

                SizedBox(
                  width: double.infinity,
                  child: DateRangeButtons(
                    onTap: showDatePicker,
                    selectedDateRange:
                        widget.controller.state.availabilityRange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),

      /// Testing blocked days
      selectableDayPredicate:
          (day, DateTime? selectedStartDay, DateTime? selectedEndDay) =>
              day.isAfter(DateTime.now()),
      initialDateRange: widget.controller.state.availabilityRange,
    );
    widget.controller.updateAvailabilityRange(
      ensureStartDateIsBeforeEndDate(picked),
    );
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }
}
