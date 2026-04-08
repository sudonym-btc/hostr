import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:models/main.dart';

class ReservationStatusSections {
  static bool isUpcoming(Validation<ReservationGroup> item) {
    final now = DateTime.now().toUtc();
    final end = item.event.end;
    if (end == null) return true;
    return !end.toUtc().isBefore(now);
  }

  static int compare(
    Validation<ReservationGroup> a,
    Validation<ReservationGroup> b,
  ) {
    final aUpcoming = isUpcoming(a);
    final bUpcoming = isUpcoming(b);

    if (aUpcoming != bUpcoming) {
      return aUpcoming ? -1 : 1;
    }

    final fallback = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final aStart = a.event.start?.toUtc() ?? fallback;
    final bStart = b.event.start?.toUtc() ?? fallback;

    if (aUpcoming) {
      return aStart.compareTo(bStart);
    }

    return bStart.compareTo(aStart);
  }

  static Widget? buildHeader(
    BuildContext context,
    Validation<ReservationGroup>? previous,
    Validation<ReservationGroup> current,
  ) {
    final currentUpcoming = isUpcoming(current);
    final previousUpcoming = previous != null ? isUpcoming(previous) : null;

    if (previousUpcoming == currentUpcoming) {
      return null;
    }

    return CustomPadding(
      bottom: 0,
      child: Text(
        currentUpcoming ? 'Upcoming' : 'Past',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
