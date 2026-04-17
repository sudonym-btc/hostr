import 'package:flutter/material.dart';
import 'package:hostr/main.dart';

/// Content shown to new users who don't yet have a profile.
/// Rendered as a side-pane on wide viewports and as a modal on mobile.
class WelcomePaneContent extends StatelessWidget {
  /// Called when the user dismisses (e.g. taps "Got it").
  final VoidCallback? onDismiss;

  const WelcomePaneContent({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          Gap.vertical.md(),
          Text('Welcome to Hostr!', style: theme.textTheme.headlineSmall),
          Gap.vertical.sm(),
          Text(
            'We didn\'t find an existing profile for you. '
            'Fill in some details and hit save to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Gap.vertical.lg(),
          Text('Tips', style: theme.textTheme.titleSmall),
          Gap.vertical.sm(),
          _tip(
            context,
            Icons.person_outline,
            'Add a name and photo so hosts and guests can recognise you.',
          ),
          Gap.vertical.sm(),
          _tip(
            context,
            Icons.bolt_outlined,
            'Set a lightning address to receive payments.',
          ),
          Gap.vertical.sm(),
          _tip(
            context,
            Icons.verified_outlined,
            'A Nostr address helps others verify your identity.',
          ),
          if (onDismiss != null) ...[
            Gap.vertical.lg(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onDismiss,
                child: const Text('Got it'),
              ),
            ),
          ],
          // Gap.vertical.lg(),
          // SizedBox(
          //   width: double.infinity,
          //   child: TextButton.icon(
          //     icon: const Icon(Icons.cell_tower),
          //     label: const Text('Add My Relay'),
          //     onPressed: () {
          //       showModalBottomSheet(
          //         context: context,
          //         isScrollControlled: true,
          //         builder: (_) => RelayFlowWidget(
          //           onClose: () => Navigator.of(context).pop(),
          //         ),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _tip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        Gap.horizontal.sm(),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
