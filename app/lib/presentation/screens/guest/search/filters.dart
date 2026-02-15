import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/forms/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

@RoutePage()
class FiltersScreen extends StatefulWidget {
  final bool asBottomSheet;

  const FiltersScreen({super.key, this.asBottomSheet = false});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late final SearchFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchFormController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SearchForm(controller: _controller),
          CustomPadding(
            top: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: _controller.canSubmit ? _submit : null,
                  child: Text(AppLocalizations.of(context)!.search),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.asBottomSheet) {
      return content;
    }

    return Scaffold(body: content);
  }

  void _submit() {
    if (!_controller.validate()) return;

    final state = _controller.buildSubmitState();
    BlocProvider.of<DateRangeCubit>(
      context,
    ).updateDateRange(state.availabilityRange);
    context.read<FilterCubit>().updateFilter(
      Filter(
        kinds: [Listing.kinds[0]],
        tags: {'g': state.h3Tags.map((tag) => tag.index).toList()},
      ),
      location: state.location,
    );
    Navigator.pop(context);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }
}
