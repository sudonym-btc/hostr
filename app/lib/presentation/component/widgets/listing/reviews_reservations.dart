import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:ndk/ndk.dart';

class ReviewsReservationsWidget extends StatelessWidget {
  final String a;
  const ReviewsReservationsWidget({super.key, required this.a});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => FilterCubit()..updateFilter(Filter(aTags: [a])),
        child: Row(
          children: [
            BlocProvider(
              create: (context) => CountCubit(kinds: Review.kinds),
              child: BlocBuilder<CountCubit, CountCubitState>(
                builder: (context, state) {
                  return Text("${state.count} reviews");
                },
              ),
            ),
            BlocProvider(
              create: (context) => CountCubit(kinds: Reservation.kinds),
              child: BlocBuilder<CountCubit, CountCubitState>(
                builder: (context, state) {
                  return Text(" · ${state.count} stays");
                },
              ),
            ),
          ],
        ));
  }
}
