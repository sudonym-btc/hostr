import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';

import 'date_range_buttons.dart';
import 'location_field.dart';
import 'search_form_controller.dart';

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
                Gap.vertical.md(),
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
                Gap.vertical.lg(),
                FormLabel(label: 'When?'),
                Gap.vertical.lg(),

                SizedBox(
                  width: double.infinity,
                  child: DateRangeButtons(
                    controller: widget.controller.dateRangeController,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }
}
