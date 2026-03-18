import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';

import 'date_range_buttons.dart';
import 'location_input.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormLabel(label: 'Where are you going?'),
          Gap.vertical.md(),
          AreaLocationInput(controller: widget.controller.locationController),
          Gap.vertical.lg(),
          FormLabel(label: 'When?'),
          Gap.vertical.md(),

          SizedBox(
            width: double.infinity,
            child: DateRangeButtons(
              controller: widget.controller.dateRangeController,
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
