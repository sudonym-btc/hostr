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
  late final ValidatedStreamWithStatus<ReservationPairStatus> _pairsStream;

  @override
  void initState() {
    super.initState();
    _pairsStream = getIt<Hostr>().reservationPairs.subscribeToMyVerifiedPairs();
  }

  @override
  void dispose() {
    _pairsStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.trips)),
      body: StreamBuilder<List<Validation<ReservationPairStatus>>>(
        stream: _pairsStream.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: AppLoadingIndicator.large());
          }

          final pairs = snapshot.data!
              .whereType<Valid<ReservationPairStatus>>()
              .map((v) => v.event)
              .toList();

          if (pairs.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noTripsYet),
            );
          }
          pairs.sort(
            (a, b) => (b.start ?? DateTime.now()).compareTo(
              a.start ?? DateTime.now(),
            ),
          );

          return ListView.separated(
            addAutomaticKeepAlives: true,
            itemCount: pairs.length,
            separatorBuilder: (_, __) => Container(),
            itemBuilder: (context, index) {
              return _KeepAliveReservationListItem(
                reservationPair: pairs[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _KeepAliveReservationListItem extends StatefulWidget {
  final ReservationPairStatus reservationPair;
  const _KeepAliveReservationListItem({required this.reservationPair});

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
    return ReservationListItem(reservationPair: widget.reservationPair);
  }
}
