import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

StreamWithStatus<Validation<Review>> subscribeVerifiedListingReviews(
  String listingAnchor,
) {
  return getIt<Hostr>().reviews.queryVerified(
    filter: Filter(
      tags: {
        kListingRefTag: [listingAnchor],
      },
    ),
  );
}

Stream<int> buildReviewCountStream(
  StreamWithStatus<Validation<Review>> reviewsStream,
) {
  return reviewsStream.itemsStream.map(
    (items) => items.whereType<Valid<Review>>().length,
  );
}

Stream<double> buildAverageReviewRatingStream(
  StreamWithStatus<Validation<Review>> reviewsStream,
) {
  return reviewsStream.itemsStream.map((items) {
    final reviews = items
        .whereType<Valid<Review>>()
        .map((validation) => validation.event)
        .toList();
    if (reviews.isEmpty) {
      return 0.0;
    }

    final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  });
}

class ListingReviewsList extends StatelessWidget {
  final StreamWithStatus<Validation<Review>> reviewsStream;

  const ListingReviewsList({super.key, required this.reviewsStream});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.minHeight > 0
            ? constraints.minHeight
            : null;

        return StreamBuilder<List<Validation<Review>>>(
          stream: reviewsStream.itemsStream,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            final reviewsStatus = reviewsStream.status.value;
            final reviewsLoading =
                reviewsStatus is StreamStatusIdle ||
                reviewsStatus is StreamStatusQuerying;

            if (items.isEmpty) {
              if (reviewsLoading ||
                  snapshot.connectionState == ConnectionState.waiting) {
                final loadingState = const Center(
                  child: AppLoadingIndicator.large(),
                );

                return availableHeight == null
                    ? loadingState
                    : SizedBox(height: availableHeight, child: loadingState);
              }

              final emptyState = EmtyResultsWidget(
                leading: Icon(
                  Icons.rate_review_outlined,
                  size: kIconHero,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: AppLocalizations.of(context)!.noReviewsYet,
                subtitle:
                    'Be the first guest to share feedback for this listing.',
              );

              return availableHeight == null
                  ? emptyState
                  : SizedBox(height: availableHeight, child: emptyState);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
      },
    );
  }
}

class ListingReviewsSection extends StatelessWidget {
  final Widget reviewsListWidget;

  const ListingReviewsSection({super.key, required this.reviewsListWidget});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [reviewsListWidget],
      ),
    );
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
