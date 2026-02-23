import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

@RoutePage()
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late final StreamWithStatus<Reservation> _reservationsStream;

  @override
  void initState() {
    super.initState();
    _reservationsStream = getIt<Hostr>().reservations
        .subscribeToMyReservations();
  }

  /// Groups a flat list of reservations by their commitment hash.
  Map<String, List<Reservation>> _groupByCommitmentHash(
    List<Reservation> reservations,
  ) {
    final map = <String, List<Reservation>>{};
    for (final r in reservations) {
      final hash = r.parsedTags.commitmentHash;
      (map[hash] ??= []).add(r);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.trips)),
      body: StreamBuilder<List<Reservation>>(
        stream: _reservationsStream.list,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: AppLoadingIndicator.large());
          }

          final grouped = _groupByCommitmentHash(snapshot.data!);

          if (grouped.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noTripsYet),
            );
          }

          final entries = grouped.values.toList();

          return ListView.separated(
            addAutomaticKeepAlives: true,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _KeepAliveReservationListItem(
                reservations: entries[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _KeepAliveReservationListItem extends StatefulWidget {
  final List<Reservation> reservations;
  const _KeepAliveReservationListItem({required this.reservations});

  @override
  State<_KeepAliveReservationListItem> createState() =>
      _KeepAliveReservationListItemState();
}

class _KeepAliveReservationListItemState
    extends State<_KeepAliveReservationListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ReservationListItem(reservations: widget.reservations);
  }
}
