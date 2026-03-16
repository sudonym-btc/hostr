import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:models/nostr/reservation.dart';

class BlockedReservations extends StatelessWidget {
  final List<Reservation> blockedReservations;
  final ValueChanged<Reservation> onCancelBlockedReservation;
  final VoidCallback onBlockDates;

  const BlockedReservations({
    super.key,
    required this.blockedReservations,
    required this.onCancelBlockedReservation,
    required this.onBlockDates,
  });

  Widget _buildBlockedReservationTile(
    BuildContext context,
    Reservation reservation,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        formatDateRangeShort(
          DateTimeRange(start: reservation.start, end: reservation.end),
          Localizations.localeOf(context),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.cancel),
        onPressed: () => onCancelBlockedReservation(reservation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      horizontalPadding: false,
      action: OutlinedButton(
        onPressed: onBlockDates,
        child: Text(AppLocalizations.of(context)!.blockDates),
      ),
      body: blockedReservations.isEmpty
          ? Text(
              AppLocalizations.of(context)!.noBlockedDates,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 0),
              itemCount: blockedReservations.length,
              itemBuilder: (context, index) => _buildBlockedReservationTile(
                context,
                blockedReservations[index],
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
      title: AppLocalizations.of(context)!.blockedDates,
    );
  }
}
