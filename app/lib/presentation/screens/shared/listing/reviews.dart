import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

class ListingReviewsList extends StatelessWidget {
  final StreamWithStatus<Validation<Review>> reviewsStream;
  final Stream<List<Validation<Review>>>? itemsStream;
  final bool isOwner;

  const ListingReviewsList({
    super.key,
    required this.reviewsStream,
    this.itemsStream,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    // Combine items + status so the builder re-runs whenever either changes.
    final combinedStream =
        Rx.combineLatest2<
          List<Validation<Review>>,
          StreamStatus,
          (List<Validation<Review>>, StreamStatus)
        >(
          itemsStream ?? reviewsStream.itemsStream,
          reviewsStream.status,
          (items, status) => (items, status),
        );

    return StreamBuilder<(List<Validation<Review>>, StreamStatus)>(
      stream: combinedStream,
      builder: (context, snapshot) {
        final items = snapshot.data?.$1 ?? [];
        final reviewsStatus = snapshot.data?.$2 ?? reviewsStream.status.value;
        final reviewsLoading =
            reviewsStatus is StreamStatusIdle ||
            reviewsStatus is StreamStatusQuerying;

        if (items.isEmpty) {
          if (reviewsLoading ||
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingIndicator.large());
          }

          return EmtyResultsWidget(
            leading: Icon(
              Icons.rate_review_outlined,
              size: kIconHero,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: AppLocalizations.of(context)!.noReviewsYet,
            subtitle: isOwner
                ? null
                : 'Be the first guest to share feedback for this listing.',
          );
        }

        return AdaptiveList(
          children: [
            for (final item in items) ...[
              Gap.vertical.lg(),
              if (item is Invalid<Review>)
                InvalidReviewWrapper(
                  reason: item.reason,
                  child: ReviewListItem(review: item.event),
                )
              else
                ReviewListItem(review: item.event),
            ],
          ],
        );
      },
    );
  }
}

class ListingReviewsSection extends StatelessWidget {
  final Widget reviewsListWidget;

  const ListingReviewsSection({super.key, required this.reviewsListWidget});

  @override
  Widget build(BuildContext context) {
    return reviewsListWidget;
  }
}

class InvalidReviewWrapper extends StatelessWidget {
  final String reason;
  final Widget child;

  const InvalidReviewWrapper({
    super.key,
    required this.reason,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: child),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reason,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ),
      ],
    );
  }
}
