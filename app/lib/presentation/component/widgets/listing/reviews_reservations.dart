import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class ReviewsReservationsWidget extends StatelessWidget {
  final Listing listing;
  const ReviewsReservationsWidget({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FilterCubit()
        ..updateFilter(
          Filter(
            tags: {
              kListingRefTag: [listing.anchor!],
            },
          ),
        ),
      child: Row(
        children: [
          BlocProvider(
            create: (context) => CountCubit(
              kinds: Review.kinds,
              nostrService: getIt(),
              filterCubit: context.read<FilterCubit>(),
            )..count(),
            child: BlocBuilder<CountCubit, CountCubitState>(
              builder: (context, state) {
                return Text("${state.count} reviews");
              },
            ),
          ),
          BlocProvider(
            create: (context) => CountCubit(
              kinds: Reservation.kinds,
              nostrService: getIt(),
              filterCubit: context.read<FilterCubit>(),
            )..count(),
            child: BlocBuilder<CountCubit, CountCubitState>(
              builder: (context, state) {
                return Text(" · ${state.count} stays");
              },
            ),
          ),
        ],
      ),
    );
  }
}
