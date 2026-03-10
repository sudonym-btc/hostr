import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class ReservationStatusSections {
  static bool isUpcoming(Validation<ReservationPairStatus> item) {
    final now = DateTime.now().toUtc();
    final end = item.event.end;
    if (end == null) return true;
    return !end.toUtc().isBefore(now);
  }

  static int compare(
    Validation<ReservationPairStatus> a,
    Validation<ReservationPairStatus> b,
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
    Validation<ReservationPairStatus>? previous,
    Validation<ReservationPairStatus> current,
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
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
