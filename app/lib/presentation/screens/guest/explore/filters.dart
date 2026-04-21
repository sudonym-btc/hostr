import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/forms/main.dart';

@RoutePage()
class FiltersScreen extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const FiltersScreen();

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late final SearchFormController _controller;

  @override
  void initState() {
    super.initState();
    final filterState = context.read<FilterCubit>().state;
    final dateRange = context.read<DateRangeCubit>().state.dateRange;

    _controller = SearchFormController();
    _controller.setStateFromFilter(
      location: filterState.location,
      dateRange: dateRange,
      filter: filterState.filter,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SearchForm(controller: _controller),
        ),
      ),
      buttons: ListenableBuilder(
        listenable: _controller.submitListenable,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_controller.isDirty) ...[
              TextButton(
                onPressed: _clear,
                child: Text(AppLocalizations.of(context)!.clear),
              ),
              const SizedBox(height: kSpace2),
            ],
            ModalBottomSheetPrimaryButton(
              onPressed: _controller.canSubmit ? _submit : null,
              child: Text(AppLocalizations.of(context)!.search),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final formState = _controller.formKey.currentState;
    if (formState != null && !formState.validate()) return;

    context.read<DateRangeCubit>().updateDateRange(
      _controller.dateRangeField.dateRange,
    );
    context.read<FilterCubit>().updateFilter(
      _controller.buildFilter(),
      location: _controller.locationField.text,
    );
    Navigator.pop(context);
  }

  void _clear() {
    _controller.clearAll();
    context.read<DateRangeCubit>().updateDateRange(null);
    context.read<FilterCubit>().clear();
  }
}
