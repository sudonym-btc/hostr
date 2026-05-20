import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/core/util/format_date.dart';
import 'package:hostr/core/util/npub_formatter.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class InboxItemView extends StatelessWidget {
  final List<String> counterparties;
  final String subtitle;
  final DateTime lastDateTime;
  final bool sentByUs;
  final bool read;
  final bool received;
  final bool hasUnread;
  final bool selected;
  final bool isLoading;
  final VoidCallback? onTap;

  const InboxItemView({
    super.key,
    required this.counterparties,
    required this.subtitle,
    required this.lastDateTime,
    this.sentByUs = false,
    this.read = false,
    this.received = false,
    this.hasUnread = false,
    this.selected = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AppListItem.loading(
        selected: selected,
        contentPadding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding.toDouble(),
          vertical: 0,
        ),
        onTap: onTap,
      );
    }

    final theme = Theme.of(context);
    return AppListItem(
      selected: selected,
      contentPadding: EdgeInsets.symmetric(
        horizontal: kDefaultPadding.toDouble(),
        vertical: 0,
      ),
      leading: ProfileAvatars.md(profiles: counterparties),
      title: _CounterpartyNamesText(
        counterparties: counterparties,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hasUnread
            ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
            : null,
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RelativeTimeText(dateTime: lastDateTime),
          if (sentByUs && received)
            Icon(
              read ? Icons.done_all : Icons.done,
              size: 16,
              color: read
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hintColor,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _CounterpartyNamesText extends StatelessWidget {
  final List<String> counterparties;
  final TextStyle? style;

  const _CounterpartyNamesText({required this.counterparties, this.style});

  @override
  Widget build(BuildContext context) =>
      _buildNameProviders(index: 0, namesByPubkey: const {});

  Widget _buildNameProviders({
    required int index,
    required Map<String, String> namesByPubkey,
  }) {
    if (index >= counterparties.length) {
      final joinedNames = counterparties
          .map((pubkey) => namesByPubkey[pubkey] ?? formatNpubPreview(pubkey))
          .join(', ');
      return Text(
        joinedNames,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: style,
      );
    }

    final pubkey = counterparties[index];
    return ProfileProvider(
      pubkey: pubkey,
      builder: (context, profile) {
        final nextNamesByPubkey = {
          ...namesByPubkey,
          pubkey: _resolvedName(profile.data, fallbackPubkey: pubkey),
        };
        return _buildNameProviders(
          index: index + 1,
          namesByPubkey: nextNamesByPubkey,
        );
      },
    );
  }

  String _resolvedName(
    ProfileMetadata? profile, {
    required String fallbackPubkey,
  }) {
    final name = profile?.metadata.getName().trim() ?? '';
    if (name.isNotEmpty && name != fallbackPubkey) return name;
    return formatNpubPreview(fallbackPubkey);
  }
}

class InboxItem extends StatefulWidget {
  final Thread thread;
  final bool selected;
  final ValueChanged<String> onSelect;

  const InboxItem({
    super.key,
    required this.thread,
    this.selected = false,
    required this.onSelect,
  });

  @override
  State<InboxItem> createState() => _InboxItemState();
}

class _InboxItemState extends State<InboxItem> {
  String? _listingAnchor;
  Future<Listing?>? _listingFuture;

  Future<Listing?> _listingForAnchor(String listingAnchor) {
    if (_listingAnchor != listingAnchor || _listingFuture == null) {
      _listingAnchor = listingAnchor;
      _listingFuture = getIt<Hostr>().listings.getOneByAnchor(listingAnchor);
    }

    return _listingFuture!;
  }

  String _reservationDateRange(BuildContext context, Order reservation) {
    final start = reservation.start;
    final end = reservation.end;
    if (start == null || end == null) return '';

    return formatDateRangeShort(
      DateTimeRange(start: start.toLocal(), end: end.toLocal()),
      Localizations.localeOf(context),
    );
  }

  String _reservationPreview(
    BuildContext context, {
    required Order reservation,
    required Listing? listing,
  }) {
    if (reservation.stage == OrderStage.cancel) {
      return 'Order cancelled';
    }

    final listingTitle = (listing ?? reservation.proof?.listing)?.title.trim();
    final dateRange = _reservationDateRange(context, reservation);
    final action =
        reservation.pubKey ==
            getPubKeyFromAnchor(reservation.parsedTags.listingAnchor)
        ? 'proposed'
        : 'requested';

    final details = [
      if (dateRange.isNotEmpty) dateRange,
      if (listingTitle != null && listingTitle.isNotEmpty) listingTitle,
    ].join(' ');

    return details.isEmpty ? 'Order $action' : 'Order $action for $details';
  }

  Widget _buildItem({
    required BuildContext context,
    required ThreadState state,
    required Message? lastEvent,
    required String subtitleBody,
  }) {
    final activePubkey = getIt<Hostr>().auth.getActiveKey().publicKey;
    final sentByUs = lastEvent?.pubKey == activePubkey;
    final subtitlePrefix = sentByUs ? 'You: ' : '';

    return InboxItemView(
      counterparties: [...state.counterpartyPubkeys],
      subtitle: subtitlePrefix + subtitleBody,
      lastDateTime: state.getLastDateTime,
      selected: widget.selected,
      sentByUs: sentByUs,
      read: state.read,
      received: state.received,
      hasUnread: state.unreadCount(activePubkey) > 0,
      onTap: () => widget.onSelect(widget.thread.anchor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.thread.state,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        final state = snapshot.data!;
        final lastEvent = state.readableEvents.isNotEmpty
            ? state.readableEvents.last
            : null;

        String subtitleBody = '';
        if (lastEvent is Message) {
          subtitleBody = lastEvent.content;
          final reservation = lastEvent.child;
          if (reservation is Order) {
            final listing = reservation.proof?.listing;
            if (listing != null || reservation.stage == OrderStage.cancel) {
              subtitleBody = _reservationPreview(
                context,
                reservation: reservation,
                listing: listing,
              );
            } else {
              return FutureBuilder<Listing?>(
                future: _listingForAnchor(reservation.parsedTags.listingAnchor),
                builder: (context, listingSnapshot) {
                  return _buildItem(
                    context: context,
                    state: state,
                    lastEvent: lastEvent,
                    subtitleBody: _reservationPreview(
                      context,
                      reservation: reservation,
                      listing: listingSnapshot.data,
                    ),
                  );
                },
              );
            }
          }
        }

        return _buildItem(
          context: context,
          state: state,
          lastEvent: lastEvent,
          subtitleBody: subtitleBody,
        );
      },
    );
  }
}
