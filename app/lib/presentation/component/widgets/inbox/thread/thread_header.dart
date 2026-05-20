import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/util/main.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr_sdk/usecase/messaging/thread/thread.dart';
import 'package:models/main.dart';

class ThreadHeaderWidget extends StatelessWidget {
  final Widget? trailing;
  final ValueChanged<String>? onCounterpartyTap;
  const ThreadHeaderWidget({super.key, this.trailing, this.onCounterpartyTap});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return ListTile(
      contentPadding: EdgeInsets.all(0),
      leading: ProfileAvatars.sm(
        profiles: context.read<Thread>().state.value.counterpartyPubkeys,
        onProfileTap: onCounterpartyTap,
      ),
      title: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: titleStyle,
          children: _buildCounterpartySpans(
            counterparties: context
                .read<Thread>()
                .state
                .value
                .counterpartyPubkeys,
            baseStyle: titleStyle,
          ),
        ),
      ),
      // subtitle: RichText(
      //   maxLines: 1,
      //   overflow: TextOverflow.ellipsis,
      //   text: TextSpan(
      //     style: subtitleStyle,
      //     children: _buildCounterpartySpans(
      //       counterparties: counterparties,
      //       valueOf: (counterparty) =>
      //           counterparty.metadata.cleanNip05 ??
      //           counterparty.metadata.lud06 ??
      //           counterparty.metadata.lud16 ??
      //           counterparty.metadata.pubKey,
      //       baseStyle: subtitleStyle,
      //     ),
      //   ),
      // ),
      trailing: trailing,
    );
  }

  List<InlineSpan> _buildCounterpartySpans({
    required List<String> counterparties,
    TextStyle? baseStyle,
  }) {
    final linkStyle = baseStyle;

    final spans = <InlineSpan>[];

    for (var i = 0; i < counterparties.length; i++) {
      final counterparty = counterparties[i];

      if (i > 0) {
        spans.add(TextSpan(text: ', ', style: baseStyle));
      }

      spans.add(
        WidgetSpan(
          child: ProfileProvider(
            pubkey: counterparty,
            builder: (context, profile) {
              final label = _counterpartyLabel(counterparty, profile.data);
              return GestureDetector(
                onTap: onCounterpartyTap != null
                    ? () => onCounterpartyTap!(counterparty)
                    : null,
                child: Text(
                  label,
                  style: linkStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
      );
    }

    return spans;
  }

  String _counterpartyLabel(String pubkey, ProfileMetadata? profile) {
    final name = profile?.metadata.getName().trim() ?? '';
    if (name.isNotEmpty && name != pubkey) return name;
    return formatNpubPreview(pubkey);
  }
}

class ProfileAvatars extends StatelessWidget {
  final List<String> profiles;
  final ValueChanged<String>? onProfileTap;

  /// Circle radius in logical pixels (matches [AppAvatar] presets).
  final double radius;

  // ─── Size presets (mirror AppAvatar) ──────────────────────────

  /// 20 px diameter – tiny indicator dots / status badges.
  const ProfileAvatars.xxs({
    super.key,
    required this.profiles,
    this.onProfileTap,
  }) : radius = 10;

  /// 28 px diameter – message profile headers.
  const ProfileAvatars.xs({
    super.key,
    required this.profiles,
    this.onProfileTap,
  }) : radius = 14;

  /// 32 px diameter – chip avatars.
  const ProfileAvatars.sm({
    super.key,
    required this.profiles,
    this.onProfileTap,
  }) : radius = 16;

  /// 40 px diameter – list item leading widget (default).
  const ProfileAvatars.md({
    super.key,
    required this.profiles,
    this.onProfileTap,
  }) : radius = 20;

  /// 72 px diameter – profile popup.
  const ProfileAvatars.lg({
    super.key,
    required this.profiles,
    this.onProfileTap,
  }) : radius = 36;

  /// 80 px diameter – profile header / hero avatar.
  const ProfileAvatars.xl({
    super.key,
    required this.profiles,
    this.onProfileTap,
  }) : radius = 40;

  /// Escape hatch for one-off sizes.
  const ProfileAvatars.custom({
    super.key,
    required this.profiles,
    this.onProfileTap,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final overlap = radius * 0.6;

    return ClipOval(
      child: SizedBox(
        height: diameter,
        width: diameter,
        child: Stack(
          children: profiles.indexed.map((entry) {
            final pubkey = entry.$2;
            return ProfileProvider(
              pubkey: pubkey,
              builder: (context, profile) {
                final metadata = profile.data?.metadata;
                return Positioned(
                  left: entry.$1 * overlap,
                  child: GestureDetector(
                    onTap: onProfileTap != null
                        ? () => onProfileTap!(pubkey)
                        : null,
                    child: AppAvatar.custom(
                      radius: radius,
                      image: metadata?.picture,
                      pubkey: pubkey,
                      label: metadata?.name,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
