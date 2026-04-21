import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'profile_verification_controller.dart';

// ─── Self-contained tile badges (profile popup) ───────────────

/// Manages NIP-05 verification and renders a [VerificationTile].
class VerifiedNip05Badge extends StatefulWidget {
  final String? nip05;
  final String pubkey;
  final bool centered;

  const VerifiedNip05Badge({
    super.key,
    this.nip05,
    required this.pubkey,
    this.centered = false,
  });

  @override
  State<VerifiedNip05Badge> createState() => _VerifiedNip05BadgeState();
}

class _VerifiedNip05BadgeState extends State<VerifiedNip05Badge> {
  final _v = ProfileVerificationController();

  @override
  void initState() {
    super.initState();
    _v.addListener(_onChanged);
    _verify();
  }

  @override
  void didUpdateWidget(covariant VerifiedNip05Badge old) {
    super.didUpdateWidget(old);
    if (old.nip05 != widget.nip05 || old.pubkey != widget.pubkey) _verify();
  }

  @override
  void dispose() {
    _v
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _verify() =>
      _v.verifyNip05Only(nip05: widget.nip05 ?? '', pubkey: widget.pubkey);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nip05 = widget.nip05;

    if (nip05 == null || nip05.isEmpty) {
      return VerificationTile(
        icon: Icons.badge_outlined,
        iconColor: cs.outline,
        title: 'Nostr address',
        subtitle: 'Not set',
        centered: widget.centered,
      );
    }
    if (_v.nip05Loading) {
      return VerificationTile(
        icon: Icons.badge_outlined,
        iconColor: cs.outline,
        title: nip05,
        trailing: const AppLoadingIndicator.small(),
        centered: widget.centered,
      );
    }
    final valid = _v.nip05Result?.valid ?? false;
    return VerificationTile(
      icon: Icons.badge_outlined,
      iconColor: cs.outline,
      title: nip05,
      centered: widget.centered,
      chipRow: valid
          ? [AppChip.success.xs(label: const Text('Verified'))]
          : [
              AppChip.error.xs(
                label: Text(_v.nip05Result?.error ?? 'Verification failed'),
              ),
            ],
    );
  }
}

/// Manages LUD-16 verification and renders a [VerificationTile].
class VerifiedLud16Badge extends StatefulWidget {
  final String? lud16;
  final bool centered;

  const VerifiedLud16Badge({super.key, this.lud16, this.centered = false});

  @override
  State<VerifiedLud16Badge> createState() => _VerifiedLud16BadgeState();
}

class _VerifiedLud16BadgeState extends State<VerifiedLud16Badge> {
  final _v = ProfileVerificationController();

  @override
  void initState() {
    super.initState();
    _v.addListener(_onChanged);
    _verify();
  }

  @override
  void didUpdateWidget(covariant VerifiedLud16Badge old) {
    super.didUpdateWidget(old);
    if (old.lud16 != widget.lud16) _verify();
  }

  @override
  void dispose() {
    _v
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _verify() => _v.verifyLud16Only(lud16: widget.lud16 ?? '');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lud16 = widget.lud16;

    if (lud16 == null || lud16.isEmpty) {
      return VerificationTile(
        icon: Icons.bolt_outlined,
        iconColor: cs.outline,
        title: 'Lightning Address',
        subtitle: 'Not set',
        centered: widget.centered,
      );
    }
    if (_v.lud16Loading) {
      return VerificationTile(
        icon: Icons.bolt_outlined,
        iconColor: cs.outline,
        title: lud16,
        trailing: const AppLoadingIndicator.small(),
        centered: widget.centered,
      );
    }
    final reachable = _v.lud16Result?.reachable ?? false;
    final allowsNostr = _v.lud16Result?.allowsNostr ?? false;
    return VerificationTile(
      icon: Icons.bolt_outlined,
      iconColor: cs.outline,
      title: lud16,
      centered: widget.centered,
      chipRow: [
        if (reachable) ...[
          AppChip.success.xs(label: const Text('Reachable')),
          if (allowsNostr)
            AppChip.success.xs(label: const Text('Zaps enabled')),
        ] else
          AppChip.error.xs(label: const Text('Unreachable')),
      ],
    );
  }
}

// ─── Chip-only badges (profile header, forms) ────────────────

/// A row of status chips for NIP-05 verification.
///
/// Returns [SizedBox.shrink] when there is no result and not loading.
/// Used beneath text fields and in compact profile contexts.
class Nip05Badges extends StatelessWidget {
  final Nip05VerificationResult? result;
  final bool loading;

  const Nip05Badges({super.key, this.result, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) return AppChip.info.xs(label: const Text('Verifying…'));
    if (result == null) return const SizedBox.shrink();
    return result!.valid
        ? AppChip.success.xs(label: const Text('Verified'))
        : AppChip.error.xs(label: Text(result!.error ?? 'Verification failed'));
  }
}

/// A row of status chips for LUD-16 verification.
///
/// Returns [SizedBox.shrink] when there is no result and not loading.
class Lud16Badges extends StatelessWidget {
  final Lud16VerificationResult? result;
  final bool loading;

  const Lud16Badges({super.key, this.result, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) return AppChip.info.xs(label: const Text('Verifying…'));
    if (result == null) return const SizedBox.shrink();
    if (!result!.reachable) {
      return AppChip.error.xs(label: Text(result!.error ?? 'Unreachable'));
    }
    return Wrap(
      spacing: AppSpacing.of(context).xs,
      children: [
        AppChip.success.xs(label: const Text('Reachable')),
        if (result!.allowsNostr)
          AppChip.success.xs(label: const Text('Zaps enabled')),
      ],
    );
  }
}

// ─── VerificationTile ─────────────────────────────────────────

/// Full icon + title + optional chips/subtitle row.
/// Used by [VerifiedNip05Badge] and [VerifiedLud16Badge].
class VerificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final List<AppChip>? chipRow;
  final bool centered;

  const VerificationTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.chipRow,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    final contentCrossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final chipAlignment = centered ? WrapAlignment.center : WrapAlignment.start;
    final content = Column(
      crossAxisAlignment: contentCrossAxisAlignment,
      children: [
        Text(title, overflow: TextOverflow.ellipsis, textAlign: textAlign),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: textAlign,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (chipRow != null) ...[
          Gap.vertical.xs(),
          Wrap(
            alignment: chipAlignment,
            spacing: AppSpacing.of(context).xs,
            runSpacing: AppSpacing.of(context).xs,
            children: chipRow!,
          ),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (!centered) ...[
          Icon(icon, color: iconColor, size: kIconMd),
          Gap.horizontal.sm(),
        ],
        if (centered) Flexible(child: content) else Expanded(child: content),
        ?trailing,
      ],
    );
  }
}
