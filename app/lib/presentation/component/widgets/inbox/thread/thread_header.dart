import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:models/main.dart';

class ThreadHeaderWidget extends StatelessWidget {
  final List<ProfileMetadata> counterparties;
  final Widget? trailing;
  final ValueChanged<ProfileMetadata>? onCounterpartyTap;
  const ThreadHeaderWidget({
    super.key,
    required this.counterparties,
    this.trailing,
    this.onCounterpartyTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium;

    return ListTile(
      leading: ProfileAvatars(
        profiles: counterparties,
        onProfileTap: onCounterpartyTap,
      ),
      title: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: titleStyle,
          children: _buildCounterpartySpans(
            counterparties: counterparties,
            valueOf: (counterparty) => counterparty.metadata.getName(),
            baseStyle: titleStyle,
          ),
        ),
      ),
      subtitle: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: subtitleStyle,
          children: _buildCounterpartySpans(
            counterparties: counterparties,
            valueOf: (counterparty) =>
                counterparty.metadata.cleanNip05 ??
                counterparty.metadata.lud06 ??
                counterparty.metadata.lud16 ??
                counterparty.metadata.pubKey,
            baseStyle: subtitleStyle,
          ),
        ),
      ),
      trailing: trailing,
    );
  }

  List<InlineSpan> _buildCounterpartySpans({
    required List<ProfileMetadata> counterparties,
    required String Function(ProfileMetadata) valueOf,
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
        TextSpan(
          text: valueOf(counterparty),
          style: linkStyle,
          recognizer: onCounterpartyTap == null
              ? null
              : (TapGestureRecognizer()
                  ..onTap = () => onCounterpartyTap!(counterparty)),
        ),
      );
    }

    return spans;
  }
}

class ProfileAvatars extends StatelessWidget {
  final List<ProfileMetadata> profiles;
  final ValueChanged<ProfileMetadata>? onProfileTap;

  const ProfileAvatars({super.key, required this.profiles, this.onProfileTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // Adjust as needed for avatar size
      width: 40,
      child: Stack(
        children: profiles
            .map(
              (counterparty) => Positioned(
                left:
                    profiles.indexOf(counterparty) *
                    kSpace3, // overlap offset for each avatar
                child: GestureDetector(
                  onTap: onProfileTap != null
                      ? () => onProfileTap!(counterparty)
                      : null,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: counterparty.metadata.picture != null
                        ? NetworkImage(counterparty.metadata.picture!)
                        : null,
                    child: counterparty.metadata.picture == null
                        ? Text(counterparty.metadata.name?[0] ?? '')
                        : null,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
