import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/animated_list_item.dart';
import 'package:hostr/presentation/component/widgets/ui/status_stream_list.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_inputs.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

@RoutePage()
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late final ListCubit<Listing> _listCubit;
  StreamSubscription? _updatesSub;
  bool _placeholderPrecached = false;

  @override
  void initState() {
    super.initState();
    _listCubit = ListCubit<Listing>(
      kinds: Listing.kinds,
      nostrService: getIt(),
      filter: Filter(authors: [getIt<Hostr>().auth.activeKeyPair!.publicKey]),
    )..next();

    // Update the list item in-place when a listing is mutated elsewhere.
    _updatesSub = getIt<Hostr>().listings.updates.listen((listing) {
      _listCubit.upsertItem(listing);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_placeholderPrecached) {
      _placeholderPrecached = true;
      precacheImage(AssetImage(ImagesInput.placeholderAsset), context);
    }
  }

  @override
  void dispose() {
    _updatesSub?.cancel();
    _listCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = AppLayoutSpec.of(context).isExpanded;

    final content = SafeArea(
      top: false,
      child: BlocBuilder<ListCubit<Listing>, ListCubitState>(
        builder: (context, state) {
          // Initial loading
          if (state.results.isEmpty &&
              (state.synching || state.fetching || state.hasMore == null)) {
            return const Center(child: AppLoadingIndicator.large());
          }

          // Empty state
          if (state.results.isEmpty) {
            return StatusStreamListWidget.empty(
              context,
              leading: Icon(
                Icons.house_outlined,
                size: kIconHero,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: 'Ready to list your place?',
              subtitle:
                  'Create a listing to start welcoming guests to your property today!',
              action: FilledButton.tonal(
                onPressed: () {
                  AutoRouter.of(context).pushPath('edit-listing/new');
                },
                child: Text('Create a listing'),
              ),
            );
          }

          final isLoading = state.synching || state.fetching;
          final crossAxisCount = isExpanded ? 2 : 1;

          return LoadNextOnScroll(
            onLoadNext: () => _listCubit.next(),
            isLoading: isLoading,
            hasMore: state.hasMore ?? true,
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: kSpace6),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 360,
              ),
              itemCount: state.results.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.results.length) {
                  return Center(child: AppLoadingIndicator.medium());
                }
                final listing = state.results[index] as Listing;
                return AnimatedListItem(
                  index: index,
                  child: ListingListItemWidget(listing: listing),
                );
              },
            ),
          );
        },
      ),
    );

    return BlocProvider.value(
      value: _listCubit,
      child: AppPageGutter(
        maxWidth: kAppWideContentMaxWidth,
        padding: EdgeInsets.zero,
        child: AppPaneLayout(
          panes: [
            AppPane(
              flex: 1,
              appBarBuilder: (context) => AppBar(
                automaticallyImplyLeading: false,
                title: Text(AppLocalizations.of(context)!.myListings),
                actions: [
                  IconButton.outlined(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      AutoRouter.of(context).pushPath('edit-listing/new');
                    },
                  ),
                ],
              ),
              promoteChromeWhenStacked: true,
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
