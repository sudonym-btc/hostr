import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Trips'),
        ),
        body: Center(child: Text("No trips yet")));
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
