import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/thread.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging_listings/messaging_listings.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/requests/requests.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/entity/entity.cubit.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class ThreadProvider extends StatelessWidget {
  final String threadId;
  final Widget child;

  const ThreadProvider({
    super.key,
    required this.threadId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final threads = getIt<Hostr>().messaging.threads;
    final thread = threads.threads[threadId];

    if (thread == null) {
      assert(false, 'Thread not found for id: $threadId');
      return const SizedBox.shrink();
    }

    final listingAnchor = MessagingListings.getThreadListing(thread: thread);
    final reservationsResponse = getIt<Hostr>().requests.subscribe<Reservation>(
      filter: Filter(
        kinds: Reservation.kinds,
        tags: {
          REFERENCE_LISTING_TAG: [listingAnchor],
        },
      ),
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Thread>.value(value: thread),
        RepositoryProvider<CustomNdkResponse<Reservation>>.value(
          value: reservationsResponse,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThreadCubit>(
            create: (_) => ThreadCubit(
              ThreadCubitState(id: threadId, messages: thread.messages),
              nostrService: getIt<Hostr>(),
              thread: thread,
            ),
          ),
          BlocProvider<EntityCubit<Listing>>(
            create: (_) => EntityCubit<Listing>(
              crud: getIt<Hostr>().listings,
              filter: Filter(aTags: [listingAnchor]),
            )..get(),
          ),
          BlocProvider<ProfileCubit>(
            create: (_) =>
                ProfileCubit(metadataUseCase: getIt<Hostr>().metadata)
                  ..load(thread.counterpartyPubkey()),
          ),
        ],
        child: child,
      ),
    );
  }
}
