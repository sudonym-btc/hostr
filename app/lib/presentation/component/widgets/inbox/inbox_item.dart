import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class InboxItemView extends StatelessWidget {
  final List<ProfileMetadata> counterparties;
  final String title;
  final String subtitle;
  final DateTime lastDateTime;
  final bool sentByUs;
  final bool read;
  final bool received;
  final bool selected;
  final bool isLoading;
  final VoidCallback? onTap;

  const InboxItemView({
    super.key,
    required this.counterparties,
    required this.title,
    required this.subtitle,
    required this.lastDateTime,
    this.sentByUs = false,
    this.read = false,
    this.received = false,
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
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RelativeTimeText(dateTime: lastDateTime),
          if (sentByUs && received)
            Icon(
              Icons.done,
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

class InboxItem extends StatelessWidget {
  final ThreadCubit cubit;
  final Thread thread;
  final bool selected;
  final ValueChanged<String> onSelect;

  const InboxItem({
    super.key,
    required this.cubit,
    required this.thread,
    this.selected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<ThreadCubit, ThreadCubitState>(
        builder: (context, state) {
          final lastDateTime = state.threadState.getLastDateTime;
          final lastMessage = state.threadState.getLatestMessage;
          final counterparties = state.counterpartyStates
              .where((c) => c.data != null)
              .map((c) => c.data!)
              .toList();

          final title = counterparties.isEmpty
              ? 'Unknown user'
              : counterparties.map((c) => c.metadata.getName()).join(', ');

          final subtitle =
              (lastMessage != null &&
                      lastMessage.pubKey ==
                          getIt<Hostr>().auth.getActiveKey().publicKey
                  ? 'You: '
                  : '') +
              (lastMessage?.child is Reservation &&
                      (lastMessage?.child as Reservation).isNegotiation
                  ? 'Reservation Proposal'
                  : lastMessage?.content ?? '');

          return InboxItemView(
            counterparties: counterparties,
            title: title,
            subtitle: subtitle,
            lastDateTime: lastDateTime,
            selected: selected,
            isLoading: counterparties.isEmpty,
            sentByUs:
                lastMessage?.pubKey ==
                getIt<Hostr>().auth.getActiveKey().publicKey,
            read: state.threadState.read,
            received: state.threadState.received,
            onTap: () => onSelect(thread.anchor),
          );
        },
      ),
    );
  }
}
