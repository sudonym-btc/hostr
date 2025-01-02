import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';

class DateRangeButtons extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final Function onTap;
  const DateRangeButtons(
      {super.key, required this.onTap, this.selectedDateRange});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      emptySelectionAllowed: true,
      multiSelectionEnabled: true,
      segments: [
        ButtonSegment(
            value: 'in',
            label: GestureDetector(
                onTap: () => onTap(),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                              'Check in'),
                          if (selectedDateRange != null)
                            Text(
                                style: Theme.of(context).textTheme.bodySmall,
                                formatDate(selectedDateRange!.start))
                        ])))),
        ButtonSegment(
            value: 'out',
            label: GestureDetector(
                onTap: () => onTap(),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                              'Check out'),
                          if (selectedDateRange != null)
                            Text(
                                style: Theme.of(context).textTheme.bodySmall,
                                formatDate(selectedDateRange!.end))
                        ])))),
      ],
      selected: <dynamic>{},
    );
  }
}
