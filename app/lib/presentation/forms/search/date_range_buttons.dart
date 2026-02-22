import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/core/main.dart';

import 'date_range_controller.dart';

class DateRangeButtons extends StatelessWidget {
  /// Preferred: pass a controller for full lifecycle management.
  final DateRangeController? controller;

  /// Legacy / convenience: called when the widget is tapped.
  /// Ignored when [controller] is provided.
  final Function? onTap;

  /// Legacy / convenience: the range to display.
  /// Ignored when [controller] is provided.
  final DateTimeRange? selectedDateRange;

  const DateRangeButtons({
    super.key,
    this.controller,
    this.onTap,
    this.selectedDateRange,
  });

  DateTimeRange? get _effectiveRange =>
      controller?.dateRange ?? selectedDateRange;

  void _handleTap(BuildContext context) {
    if (controller != null) {
      controller!.pick(context);
    } else {
      onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(context),
      child: AbsorbPointer(
        child: SegmentedButton(
          emptySelectionAllowed: true,
          multiSelectionEnabled: true,
          segments: [
            ButtonSegment(
              value: 'in',
              label: Padding(
                padding: EdgeInsets.all(kDefaultPadding.toDouble() / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      'Check in',
                    ),
                    if (_effectiveRange != null)
                      Text(
                        style: Theme.of(context).textTheme.bodySmall,
                        formatDate(_effectiveRange!.start),
                      ),
                  ],
                ),
              ),
            ),
            ButtonSegment(
              value: 'out',
              label: Padding(
                padding: EdgeInsets.all(kDefaultPadding.toDouble() / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      'Check out',
                    ),
                    if (_effectiveRange != null)
                      Text(
                        style: Theme.of(context).textTheme.bodySmall,
                        formatDate(_effectiveRange!.end),
                      ),
                  ],
                ),
              ),
            ),
          ],
          selected: <dynamic>{},
        ),
      ),
    );
  }
}
