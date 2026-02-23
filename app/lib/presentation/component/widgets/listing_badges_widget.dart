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

/// Widget to display badges for a listing
class ListingBadgesWidget extends StatelessWidget {
  final String listingAnchor;

  const ListingBadgesWidget({required this.listingAnchor, super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch badge awards that target this listing
    return BlocProvider<ListCubit<BadgeAward>>(
      create: (context) => ListCubit<BadgeAward>(
        kinds: BadgeAward.kinds,
        nostrService: getIt(),
        filter: Filter(
          tags: {
            kListingRefTag: [listingAnchor],
          },
        ),
      )..next(),
      child: BlocBuilder<ListCubit<BadgeAward>, ListCubitState<BadgeAward>>(
        builder: (context, state) {
          // Show placeholder when fetching or no badges found
          if (state.fetching && state.results.isEmpty) {
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

          if (state.results.isEmpty && !state.fetching) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: kIconSm,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Gap.horizontal.sm(),
                  Text(
                    'No badges',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return Wrap(
            spacing: kSpace2,
            runSpacing: kSpace2,
            children: state.results.map((award) {
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
        final badgeName = definition?.parsedContent.name ?? 'Badge';
        final badgeImage = definition?.parsedContent.image;

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
      child: BadgeDetailsSheet(award: award, definition: definition),
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
    final badgeName = definition?.parsedContent.name ?? 'Badge';
    final badgeDescription = definition?.parsedContent.description;
    final badgeImage = definition?.parsedContent.image;
    final badgeAnchor = award.badgeDefinitionAnchor;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(kSpace4),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: kSpace1,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (badgeImage != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      badgeImage,
                      width: kIconHero,
                      height: kIconHero,
                      fit: BoxFit.cover,
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
                                    width: kIconHero,
                                    height: kIconHero,
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
                          const ImageLoadError(
                            width: kIconHero,
                            height: kIconHero,
                          ),
                    ),
                  ),
                ),
              Gap.vertical.md(),
              Text(
                badgeName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (badgeDescription != null) ...[
                Gap.vertical.custom(kSpace3),
                Text(
                  badgeDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              Gap.vertical.custom(kSpace5),
              const Divider(),
              Gap.vertical.md(),
              Text(
                'Badge Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Gap.vertical.custom(kSpace3),
              _InfoRow(
                label: 'Issued by',
                child: ProfileChipWidget(id: award.pubKey),
              ),
              Gap.vertical.sm(),
              _InfoRow(label: 'Award ID', value: _truncateHash(award.id)),
              if (badgeAnchor != null) ...[
                Gap.vertical.sm(),
                _InfoRow(
                  label: 'Badge Anchor',
                  value: _truncateAnchor(badgeAnchor),
                ),
              ],
              Gap.vertical.md(),
              Container(
                padding: const EdgeInsets.all(kSpace3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: kIconSm,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Gap.horizontal.sm(),
                        Text(
                          'About Badges',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    Gap.vertical.sm(),
                    Text(
                      'Badges are immutable awards that cannot be revoked by the issuer. '
                      'The listing owner can choose to hide badges from their display, '
                      'but the award itself remains on the Nostr network.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _truncateHash(String hash) {
    if (hash.length <= 16) return hash;
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  String _truncateAnchor(String anchor) {
    final parts = anchor.split(':');
    if (parts.length != 3) return anchor;
    return '${parts[0]}:${_truncateHash(parts[1])}:${parts[2]}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _InfoRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Gap.horizontal.custom(kSpace3),
        Expanded(
          child:
              child ??
              Text(value ?? '', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
