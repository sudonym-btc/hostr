import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';

@RoutePage()
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.trips),
        ),
        body: Center(child: Text(AppLocalizations.of(context)!.noTripsYet)));
    // BlocBuilder<ThreadOrganizerCubit, ThreadOrganizerState>(
    //     builder: (context, state) {
    //   return ListView.builder(
    //       itemCount: state.threads.length,
    //       itemBuilder: (context, index) {
    //         return InboxItem(
    //           threadCubit: state.threads[index],
    //         );
    //       });
    // }));
  }
}
