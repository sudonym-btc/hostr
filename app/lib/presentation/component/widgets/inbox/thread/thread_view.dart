import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_content.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/thread_reply.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';

import 'reservation_status.dart';

class ThreadView extends StatelessWidget {
  const ThreadView({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<StreamWithStatus<Reservation>>().status,
      builder: (context, snapshot) {
        return BlocBuilder<ProfileCubit, ProfileCubitState>(
          builder: (context, profileState) {
            // When to display loading
            if (profileState.active ||
                profileState.data == null ||
                snapshot.data is! StreamStatusLive) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.loading),
                ),
                body: SafeArea(
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            // When loaded successfully
            return BlocBuilder<ThreadCubit, ThreadCubitState>(
              builder: (context, state) {
                return Scaffold(
                  appBar: AppBar(
                    title: ThreadHeaderWidget(
                      metadata: profileState.data!.metadata,
                    ),
                  ),
                  body:
                      BlocBuilder<
                        EntityCubit<Listing>,
                        EntityCubitState<Listing>
                      >(
                        builder: (context, listingState) {
                          if (listingState.active ||
                              listingState.data == null) {
                            return Center(child: CircularProgressIndicator());
                          }
                          return Column(
                            children: [
                              StreamBuilder<List<Reservation>>(
                                stream: context
                                    .read<StreamWithStatus<Reservation>>()
                                    .list,
                                builder: (context, snapshot) {
                                  return ReservationStatusWidget(
                                    reservation:
                                        Reservation.getSeniorReservation(
                                          reservations: snapshot.data ?? [],
                                          listing: listingState.data!,
                                        ),
                                    listing: listingState.data!,
                                  );
                                },
                              ),
                              Expanded(child: ThreadContent()),
                              SafeArea(
                                top: false,
                                child: CustomPadding(
                                  child: ThreadReplyWidget(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                );
              },
            );
          },
        );
      },
    );
  }
}
