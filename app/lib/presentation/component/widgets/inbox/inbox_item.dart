import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
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
          .map((pubkey) => namesByPubkey[pubkey] ?? _fallbackName(pubkey))
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
    if (name.isNotEmpty) return name;
    return _fallbackName(fallbackPubkey);
  }

  String _fallbackName(String pubkey) =>
      pubkey.length <= 8 ? pubkey : pubkey.substring(0, 8);
}

class InboxItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: thread.state,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        final state = snapshot.data!;
        final lastDateTime = state.getLastDateTime;
        final lastEvent = state.readableEvents.isNotEmpty
            ? state.readableEvents.last
            : null;

        final subtitlePrefix =
            lastEvent != null &&
                lastEvent.pubKey == getIt<Hostr>().auth.getActiveKey().publicKey
            ? 'You: '
            : '';
        String subtitleBody = '';
        if (lastEvent is Message) {
          subtitleBody = lastEvent.content;
          if (lastEvent.child is Reservation) {
            subtitleBody = 'Reservation Proposal';
          }
        }

        final subtitle = subtitlePrefix + subtitleBody;

        return InboxItemView(
          counterparties: [...state.counterpartyPubkeys],
          subtitle: subtitle,
          lastDateTime: lastDateTime,
          selected: selected,
          sentByUs:
              lastEvent?.pubKey == getIt<Hostr>().auth.getActiveKey().publicKey,
          read: state.read,
          received: state.received,
          hasUnread:
              state.unreadCount(getIt<Hostr>().auth.getActiveKey().publicKey) >
              0,
          onTap: () => onSelect(thread.anchor),
        );
      },
    );
  }
}
