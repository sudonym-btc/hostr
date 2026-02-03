import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';

@RoutePage()
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late final Stream<Reservation> _reservationsStream;

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
          stream: _reservationsStream,
          builder: (BuildContext context, AsyncSnapshot<Reservation> snapshot) {
            print(snapshot.data);
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasData) {
              ListingProvider(
                a: snapshot.data!.getFirstTag('a'),
                builder: (context, state) => ListingListItemWidget(
                  listing: state.data!,
                  showPrice: false,
                  showFeedback: false,
                  smallImage: true,
                ),
              );

              // return ListView.builder(
              //   itemCount: snapshot.data!.length,
              //   itemBuilder: (context, index) {
              //     final reservation = snapshot.data![index];
              //     return ListTile(
              //       title: Text('Reservation with ID: ${reservation.id}'),
              //       subtitle: Text('Status: ${reservation.status}'),
              //     );
              //   },
              // );
            } else {
              return Text(AppLocalizations.of(context)!.noTripsYet);
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
