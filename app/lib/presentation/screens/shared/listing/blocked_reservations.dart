import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class BlockedReservations extends StatelessWidget {
  final Stream<List<Validation<ReservationPair>>> reservationPairItemsStream;
  final KeyPair? hostKeyPair;
  final ValueChanged<Reservation> onCancelBlockedReservation;
  final VoidCallback onBlockDates;

  const BlockedReservations({
    super.key,
    required this.reservationPairItemsStream,
    required this.hostKeyPair,
    required this.onCancelBlockedReservation,
    required this.onBlockDates,
  });

  List<Reservation> _buildBlockedReservations(
    List<Validation<ReservationPair>> items,
  ) {
    final hostKey = hostKeyPair;
    if (hostKey == null) {
      return const <Reservation>[];
    }

    return [
          for (final pair in items.whereType<Valid<ReservationPair>>()) ...[
            if (pair.event.sellerReservation != null)
              pair.event.sellerReservation!,
            if (pair.event.buyerReservation != null)
              pair.event.buyerReservation!,
          ],
        ]
        .where(
          (reservation) =>
              reservation.isBlockedDate(hostKey) && !reservation.cancelled,
        )
        .fold<Map<String, Reservation>>({}, (acc, reservation) {
          acc[reservation.getDtag() ?? reservation.id] = reservation;
          return acc;
        })
        .values
        .toList(growable: false);
  }

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
    return StreamBuilder<List<Validation<ReservationPair>>>(
      stream: reservationPairItemsStream,
      builder: (context, snapshot) {
        final blockedReservations = _buildBlockedReservations(
          snapshot.data ?? const <Validation<ReservationPair>>[],
        );

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
      },
    );
  }
}
