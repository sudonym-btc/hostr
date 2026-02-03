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

class ThreadProvider extends StatefulWidget {
  final String threadId;
  final Widget child;

  const ThreadProvider({
    super.key,
    required this.threadId,
    required this.child,
  });

  @override
  State<ThreadProvider> createState() => _ThreadProviderState();
}

class _ThreadProviderState extends State<ThreadProvider> {
  SubscriptionResponse<Reservation>? _reservationsResponse;
  String? _listingAnchor;

  @override
  void initState() {
    super.initState();
    _ensureReservationsSubscription();
  }

  void _ensureReservationsSubscription() {
    final threads = getIt<Hostr>().messaging.threads;
    final thread = threads.threads[widget.threadId];
    if (thread == null) return;

    final listingAnchor = MessagingListings.getThreadListing(thread: thread);
    if (_reservationsResponse == null || _listingAnchor != listingAnchor) {
      _reservationsResponse?.close();
      _listingAnchor = listingAnchor;
      _reservationsResponse = getIt<Hostr>().requests.subscribe<Reservation>(
        filter: Filter(kinds: Reservation.kinds, aTags: [listingAnchor]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final threads = getIt<Hostr>().messaging.threads;
    final thread = threads.threads[widget.threadId];

    if (thread == null) {
      assert(false, 'Thread not found for id: ${widget.threadId}');
      return const SizedBox.shrink();
    }
    final listingAnchor = MessagingListings.getThreadListing(thread: thread);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Thread>.value(value: thread),
        RepositoryProvider<SubscriptionResponse<Reservation>>.value(
          value: _reservationsResponse!,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThreadCubit>(
            create: (_) => ThreadCubit(
              ThreadCubitState(id: widget.threadId, messages: thread.messages),
              nostrService: getIt<Hostr>(),
              thread: thread,
            ),
          ),
          BlocProvider<EntityCubit<Listing>>(
            create: (_) => EntityCubit<Listing>(
              crud: getIt<Hostr>().listings,
              filter: Filter(dTags: [Event.getDFromATag(listingAnchor)]),
            )..get(),
          ),
          BlocProvider<ProfileCubit>(
            create: (_) =>
                ProfileCubit(metadataUseCase: getIt<Hostr>().metadata)
                  ..load(thread.counterpartyPubkey()),
          ),
        ],
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _reservationsResponse?.close();
    super.dispose();
  }
}
