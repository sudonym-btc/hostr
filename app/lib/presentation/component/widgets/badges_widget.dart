import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/list/list.cubit.dart';
import 'package:hostr/presentation/component/providers/nostr/badge_definition.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_chip.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

/// Widget to display badges for a listing or a host pubkey.
///
/// Filters by:
/// - `p` tag → [pubKey] (the badge recipient — typically the host)
/// - `a` tag → [listingAnchor] (the specific listing this badge targets),
///   when provided
class BadgesWidget extends StatelessWidget {
  final String pubKey;
  final String? listingAnchor;

  const BadgesWidget({required this.pubKey, this.listingAnchor, super.key});

  List<BadgeAward> _visibleAwards(List<BadgeAward> awards) {
    final targetAnchor = listingAnchor;
    if (targetAnchor != null) {
      return awards
          .where((award) => award.targetAnchor == targetAnchor)
          .toList();
    }

    // Profile-level badge rows should only show badges awarded directly to the
    // pubkey. Awards with a second `a` tag are scoped to a specific
    // addressable event, such as one listing owned by the same host.
    return awards.where((award) => award.targetAnchor == null).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch badge awards whose p-tag matches the host pubkey.
    // When a listingAnchor is provided also filter by the a-tag so we only
    // show badges scoped to this specific listing.
    return BlocProvider<ListCubit<BadgeAward>>(
      create: (context) => ListCubit<BadgeAward>(
        kinds: BadgeAward.kinds,
        nostrService: getIt(),
        filter: Filter(
          pTags: [pubKey],
          tags: listingAnchor != null
              ? {
                  'a': [listingAnchor!],
                }
              : null,
        ),
      )..next(),
      child: BlocBuilder<ListCubit<BadgeAward>, ListCubitState<BadgeAward>>(
        builder: (context, state) {
          final awards = _visibleAwards(state.results);

          // Show placeholder when fetching or no badges found
          if (state.fetching && awards.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const AppLoadingIndicator.small(),
                  Gap.horizontal.sm(),
                  Text(
                    'Loading badges...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Hide completely when there are no badges.
          if (awards.isEmpty && !state.fetching) {
            return const SizedBox.shrink();
          }

          return Wrap(
            spacing: kSpace2,
            runSpacing: kSpace2,
            children: awards.map((award) {
              return BadgeChip(award: award);
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Individual badge chip widget
class BadgeChip extends StatelessWidget {
  final BadgeAward award;

  const BadgeChip({required this.award, super.key});

  @override
  Widget build(BuildContext context) {
    final badgeAnchor = award.badgeDefinitionAnchor;
    if (badgeAnchor == null) {
      return const SizedBox.shrink();
    }

    // Fetch the badge definition for this award
    return BadgeDefinitionProvider(
      a: badgeAnchor,
      builder: (context, state) {
        final definition = state.data;
        final badgeName = definition?.name ?? 'Badge';
        final badgeImage = definition?.image;

        return InkWell(
          onTap: () => _showBadgeDetails(context, definition),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badgeImage != null) ...[
                  ClipOval(
                    child: Image.network(
                      badgeImage,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            final loaded =
                                wasSynchronouslyLoaded || frame != null;
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                AnimatedOpacity(
                                  opacity: loaded ? 0 : 1,
                                  duration: kAnimationDuration,
                                  curve: kAnimationCurve,
                                  child: const ImageLoadingShimmer(
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                                AnimatedOpacity(
                                  opacity: loaded ? 1 : 0,
                                  duration: kAnimationDuration,
                                  curve: kAnimationCurve,
                                  child: child,
                                ),
                              ],
                            );
                          },
                      errorBuilder: (context, error, stackTrace) =>
                          const ImageLoadError(width: 20, height: 20),
                    ),
                  ),
                  Gap.horizontal.custom(6),
                ] else
                  Icon(
                    Icons.verified,
                    size: kIconMd,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                Gap.horizontal.xs(),
                Text(
                  badgeName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeDefinition? definition) {
    showAppModal(
      context,
      builder: (_) => BadgeDetailsSheet(award: award, definition: definition),
    );
  }
}

/// Bottom sheet showing badge details
class BadgeDetailsSheet extends StatelessWidget {
  final BadgeAward award;
  final BadgeDefinition? definition;

  const BadgeDetailsSheet({required this.award, this.definition, super.key});

  @override
  Widget build(BuildContext context) {
    final badgeName = definition?.name ?? 'Badge';
    final badgeDescription = definition?.description;
    final badgeImage = definition?.image;
    final issuedAt = DateTime.fromMillisecondsSinceEpoch(
      award.createdAt * 1000,
    );

    return ModalBottomSheet(
      leading: badgeImage != null
          ? Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  badgeImage,
                  width: kIconHero,
                  height: kIconHero,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (context, error, stackTrace) =>
                      const ImageLoadError(width: kIconHero, height: kIconHero),
                ),
              ),
            )
          : Icon(
              Icons.verified,
              size: kIconHero,
              color: Theme.of(context).colorScheme.primary,
            ),
      title: badgeName,
      subtitle: badgeDescription,
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: kSpace3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Awarded by  ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Flexible(child: ProfileChipWidget(id: award.pubKey)),
              ],
            ),
            Gap.vertical.xs(),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: kIconSm,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                Gap.horizontal.xs(),
                _AwardedTimeText(
                  dateTime: issuedAt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      buttons: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.secondary(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Displays "Awarded X ago" with auto-refreshing relative time.
class _AwardedTimeText extends StatelessWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const _AwardedTimeText({required this.dateTime, this.style});

  @override
  Widget build(BuildContext context) {
    return RelativeTimeText(
      dateTime: dateTime,
      locale: Localizations.localeOf(context).languageCode,
      builder: (context, text) => Text('Awarded $text', style: style),
    );
  }
}
