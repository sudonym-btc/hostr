import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/forms/search/date_range_buttons.dart';
import 'package:hostr/presentation/forms/search/date_range_controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class BlockDatesWidget extends StatefulWidget {
  final String listingAnchor;

  const BlockDatesWidget({super.key, required this.listingAnchor});

  @override
  State<BlockDatesWidget> createState() => _BlockDatesWidgetState();
}

class _BlockDatesWidgetState extends State<BlockDatesWidget> {
  late final DateRangeController dateRangeController;

  @override
  void initState() {
    super.initState();
    dateRangeController = DateRangeController();
  }

  @override
  void dispose() {
    dateRangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: AppLocalizations.of(context)!.blockDates,
      subtitle: 'Select dates that will not be available for guests to book.',
      content: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DateRangeButtons(
              controller: dateRangeController,
              startText: 'Start',
              endText: 'End',
            ),
          ),
        ],
      ),
      buttons: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ListenableBuilder(
            listenable: dateRangeController,
            builder: (context, _) => FilledButton(
              onPressed: dateRangeController.dateRange == null
                  ? null
                  : () async {
                      final range = dateRangeController.dateRange!;
                      await getIt<Hostr>().reservations.createBlocked(
                        listingAnchor: widget.listingAnchor,
                        start: range.start,
                        end: range.end,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ),
        ],
      ),
    );
  }
}
