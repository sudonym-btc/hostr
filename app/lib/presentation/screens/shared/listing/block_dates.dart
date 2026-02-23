import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr_sdk/hostr.dart';

class BlockDatesWidget extends StatelessWidget {
  final String listingAnchor;
  const BlockDatesWidget({super.key, required this.listingAnchor});

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      title: AppLocalizations.of(context)!.blockDates,
      content: Column(
        children: [
          Text(AppLocalizations.of(context)!.start),
          Text(AppLocalizations.of(context)!.end),
        ],
      ),
      buttons: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton(
            onPressed: () async {
              await getIt<Hostr>().reservations.createBlocked(
                listingAnchor: listingAnchor,
                start: DateTime.now(),
                end: DateTime.now().add(Duration(days: 7)),
              );
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
}
