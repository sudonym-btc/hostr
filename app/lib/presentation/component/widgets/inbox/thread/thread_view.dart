import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/requests/requests.dart';
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
    return BlocBuilder<ProfileCubit, ProfileCubitState>(
      builder: (context, profileState) {
        if (profileState.active) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context)!.loading)),
          );
        }
        if (profileState.data != null) {
          return BlocBuilder<ThreadCubit, ThreadCubitState>(
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(
                  title: ThreadHeaderWidget(
                    metadata: profileState.data!.metadata,
                  ),
                ),
                body: SafeArea(
                  child:
                      BlocBuilder<
                        EntityCubit<Listing>,
                        EntityCubitState<Listing>
                      >(
                        builder: (context, listingState) {
                          if (listingState.active) {
                            return Center(child: CircularProgressIndicator());
                          }
                          return Column(
                            children: [
                              StreamBuilder(
                                stream: context
                                    .read<CustomNdkResponse<Reservation>>()
                                    .stream,
                                builder: (context, snapshot) {
                                  return ReservationStatusWidget(
                                    reservation: snapshot.data,
                                    listing: listingState.data!,
                                  );
                                },
                              ),
                              ThreadContent(),
                              CustomPadding(child: ThreadReplyWidget()),
                            ],
                          );
                        },
                      ),
                ),
              );
            },
          );
        }
        return Placeholder();
      },
    );
  }
}
