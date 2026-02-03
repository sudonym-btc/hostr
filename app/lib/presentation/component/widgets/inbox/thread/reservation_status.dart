import 'package:flutter/material.dart';
import 'package:models/main.dart';

class ReservationStatusWidget extends StatelessWidget {
  final Reservation? reservation;
  final Listing listing;
  const ReservationStatusWidget({
    super.key,
    this.reservation,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    if (reservation == null) {
      return const SizedBox.shrink();
    }

    final statusTag = reservation?.getFirstTag('status');
    final isCancelled = statusTag == 'cancelled' || statusTag == 'canceled';

    if (isCancelled) {
      return _banner(
        context,
        text: 'Reservation cancelled',
        background: Colors.red.shade100,
        foreground: Colors.red.shade900,
      );
    }

    final isHostReservation = reservation!.pubKey == listing.pubKey;
    if (isHostReservation) {
      return _banner(
        context,
        text: 'Host has confirmed your reservation',
        background: Colors.green.shade100,
        foreground: Colors.green.shade900,
      );
    }

    return _banner(
      context,
      text: 'Reservation published, waiting for host to confirm',
      background: Colors.blue.shade100,
      foreground: Colors.blue.shade900,
    );
  }

  Widget _banner(
    BuildContext context, {
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
