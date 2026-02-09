import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/reservation/reservation_list_item.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.trips)),
      body: Center(
        child: StreamBuilder(
          stream: _reservationsStream.list,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }
            if (snapshot.data!.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final reservation = snapshot.data![index];
                  return ReservationListItem(reservation: reservation);
                },
              );
            } else {
              return Text(AppLocalizations.of(context)!.noTripsYet);
            }
          },
        ),
      ),
    );
  }
}
