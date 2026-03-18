import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'profile_verification_controller.dart';

// ─── NIP-05 Badge ──────────────────────────────────────────────

/// Displays NIP-05 verification status.
///
/// Two layout modes:
/// - **tile** (default): icon + title row + subtitle/loading indicator.
///   Used in profile_popup and similar detail views.
/// - **inline**: compact icon + text. Used in profile_header.
class Nip05Badge extends StatelessWidget {
  final String? nip05;
  final Nip05VerificationResult? result;
  final bool loading;

  /// When true, renders the compact inline variant.
  final bool inline;

  /// When true and [nip05] is null/empty the widget renders [SizedBox.shrink].
  /// When false it renders a "Not set" placeholder row.
  final bool hideWhenEmpty;

  const Nip05Badge({
    super.key,
    this.nip05,
    this.result,
    this.loading = false,
    this.inline = false,
    this.hideWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ── Empty ──────────────────────────────────────────────────
    if (nip05 == null || nip05!.isEmpty) {
      if (hideWhenEmpty) return const SizedBox.shrink();
      if (inline) {
        return _inlineRow(
          context,
          icon: Icons.badge_outlined,
          iconColor: colorScheme.outline,
          text: 'NIP-05',
        );
      }
      return VerificationTile(
        icon: Icons.badge_outlined,
        iconColor: colorScheme.outline,
        title: 'Nostr address',
        subtitle: 'Not set',
      );
    }

    // ── Loading ────────────────────────────────────────────────
    if (loading) {
      if (inline) {
        return _inlineRow(
          context,
          icon: Icons.badge_outlined,
          iconColor: colorScheme.outline,
          text: nip05!,
          loading: true,
        );
      }
      return VerificationTile(
        icon: Icons.badge_outlined,
        iconColor: colorScheme.outline,
        title: nip05!,
        trailing: const AppLoadingIndicator.small(),
      );
    }

    // ── Result ─────────────────────────────────────────────────
    final valid = result?.valid ?? false;

    if (inline) {
      return _inlineRow(
        context,
        icon: valid ? Icons.verified : Icons.error_outline,
        iconColor: valid ? Colors.blue : colorScheme.error,
        text: nip05!,
      );
    }

    final chips = <StatusChip>[];
    if (valid) {
      chips.add(StatusChip(label: 'Verified', color: Colors.blue));
    } else {
      chips.add(
        StatusChip(
          label: result?.error ?? 'Verification failed',
          color: colorScheme.error,
        ),
      );
    }

    return VerificationTile(
      icon: Icons.badge_outlined,
      iconColor: colorScheme.outline,
      title: nip05!,
      chipRow: chips,
    );
  }
}

// ─── LUD-16 Badge ──────────────────────────────────────────────

/// Displays LUD-16 (Lightning Address) verification status.
///
/// Same two layout modes as [Nip05Badge].
class Lud16Badge extends StatelessWidget {
  final String? lud16;
  final Lud16VerificationResult? result;
  final bool loading;
  final bool inline;
  final bool hideWhenEmpty;

  const Lud16Badge({
    super.key,
    this.lud16,
    this.result,
    this.loading = false,
    this.inline = false,
    this.hideWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ── Empty ──────────────────────────────────────────────────
    if (lud16 == null || lud16!.isEmpty) {
      if (hideWhenEmpty) return const SizedBox.shrink();
      if (inline) {
        return _inlineRow(
          context,
          icon: Icons.bolt_outlined,
          iconColor: colorScheme.outline,
          text: 'Lightning Address',
        );
      }
      return VerificationTile(
        icon: Icons.bolt_outlined,
        iconColor: colorScheme.outline,
        title: 'Lightning Address',
        subtitle: 'Not set',
      );
    }

    // ── Loading ────────────────────────────────────────────────
    if (loading) {
      if (inline) {
        return _inlineRow(
          context,
          icon: Icons.bolt_outlined,
          iconColor: colorScheme.outline,
          text: lud16!,
          loading: true,
        );
      }
      return VerificationTile(
        icon: Icons.bolt_outlined,
        iconColor: colorScheme.outline,
        title: lud16!,
        trailing: const AppLoadingIndicator.small(),
      );
    }

    // ── Result ─────────────────────────────────────────────────
    final reachable = result?.reachable ?? false;
    final allowsNostr = result?.allowsNostr ?? false;

    if (inline) {
      return _inlineRow(
        context,
        icon: reachable ? Icons.bolt : Icons.bolt_outlined,
        iconColor: reachable ? Colors.amber : colorScheme.error,
        text: lud16!,
      );
    }

    final chips = <StatusChip>[];
    if (reachable) {
      chips.add(StatusChip(label: 'Reachable', color: Colors.green));
      if (allowsNostr) {
        chips.add(StatusChip(label: 'Zaps enabled', color: Colors.blue));
      }
    } else {
      chips.add(StatusChip(label: 'Unreachable', color: colorScheme.error));
    }

    return VerificationTile(
      icon: Icons.bolt_outlined,
      iconColor: colorScheme.outline,
      title: lud16!,
      chipRow: chips,
    );
  }
}

class VerifiedNip05Badge extends StatefulWidget {
  final String? nip05;
  final String pubkey;
  final bool inline;
  final bool hideWhenEmpty;

  const VerifiedNip05Badge({
    super.key,
    this.nip05,
    required this.pubkey,
    this.inline = false,
    this.hideWhenEmpty = false,
  });

  @override
  State<VerifiedNip05Badge> createState() => _VerifiedNip05BadgeState();
}

class _VerifiedNip05BadgeState extends State<VerifiedNip05Badge> {
  final ProfileVerificationController _verification =
      ProfileVerificationController();

  @override
  void initState() {
    super.initState();
    _verification.addListener(_onChanged);
    _verify();
  }

  @override
  void didUpdateWidget(covariant VerifiedNip05Badge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nip05 != widget.nip05 || oldWidget.pubkey != widget.pubkey) {
      _verify();
    }
  }

  @override
  void dispose() {
    _verification
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _verify() {
    _verification.verifyNip05Only(
      nip05: widget.nip05 ?? '',
      pubkey: widget.pubkey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Nip05Badge(
      nip05: widget.nip05,
      result: _verification.nip05Result,
      loading: _verification.nip05Loading,
      inline: widget.inline,
      hideWhenEmpty: widget.hideWhenEmpty,
    );
  }
}

class VerifiedLud16Badge extends StatefulWidget {
  final String? lud16;
  final bool inline;
  final bool hideWhenEmpty;

  const VerifiedLud16Badge({
    super.key,
    this.lud16,
    this.inline = false,
    this.hideWhenEmpty = false,
  });

  @override
  State<VerifiedLud16Badge> createState() => _VerifiedLud16BadgeState();
}

class _VerifiedLud16BadgeState extends State<VerifiedLud16Badge> {
  final ProfileVerificationController _verification =
      ProfileVerificationController();

  @override
  void initState() {
    super.initState();
    _verification.addListener(_onChanged);
    _verify();
  }

  @override
  void didUpdateWidget(covariant VerifiedLud16Badge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lud16 != widget.lud16) {
      _verify();
    }
  }

  @override
  void dispose() {
    _verification
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _verify() {
    _verification.verifyLud16Only(lud16: widget.lud16 ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Lud16Badge(
      lud16: widget.lud16,
      result: _verification.lud16Result,
      loading: _verification.lud16Loading,
      inline: widget.inline,
      hideWhenEmpty: widget.hideWhenEmpty,
    );
  }
}

// ─── NIP-05 Status (for edit forms) ───────────────────────────

/// Compact status row shown beneath a text field.
/// Shows only when there is a result or loading state — returns
/// [SizedBox.shrink] when idle with no result.
class Nip05StatusRow extends StatelessWidget {
  final Nip05VerificationResult? result;
  final bool loading;

  const Nip05StatusRow({super.key, this.result, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return StatusChip.verifying(context);
    }

    if (result == null) return const SizedBox.shrink();

    final valid = result!.valid;
    return StatusChip(
      label: valid ? 'Verified' : (result!.error ?? 'Verification failed'),
      color: valid ? Colors.blue : Theme.of(context).colorScheme.error,
    );
  }
}

// ─── LUD-16 Status (for edit forms) ───────────────────────────

/// Compact status row shown beneath a text field.
class Lud16StatusRow extends StatelessWidget {
  final Lud16VerificationResult? result;
  final bool loading;

  const Lud16StatusRow({super.key, this.result, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return StatusChip.verifying(context);
    }

    if (result == null) return const SizedBox.shrink();

    final reachable = result!.reachable;
    final allowsNostr = result!.allowsNostr;

    if (!reachable) {
      return StatusChip(
        label: result!.error ?? 'Unreachable',
        color: Theme.of(context).colorScheme.error,
      );
    }

    return Row(
      children: [
        StatusChip(label: 'Reachable', color: Colors.green),
        if (allowsNostr) ...[
          Gap.horizontal.sm(),
          StatusChip(label: 'Zaps enabled', color: Colors.blue),
        ],
      ],
    );
  }
}

// ─── Shared building blocks ───────────────────────────────────

/// A tile row with an icon, title, optional subtitle/chips, and trailing widget.
/// Used by [Nip05Badge] and [Lud16Badge] in their tile layout mode.
class VerificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final List<StatusChip>? chipRow;

  const VerificationTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.chipRow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: kIconMd),
        Gap.horizontal.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (chipRow != null) ...[
                Gap.vertical.xs(),
                Wrap(spacing: 4, runSpacing: 4, children: chipRow!),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Small colored chip used in verification rows.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpace2,
        vertical: kSpace1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static StatusChip verifying(BuildContext context) {
    return StatusChip(
      label: 'Verifying…',
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────

/// Compact inline row: icon + text. Used by inline badge variants.
Widget _inlineRow(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String text,
  bool loading = false,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (loading)
        const AppLoadingIndicator.small()
      else
        Icon(icon, size: kIconSm, color: iconColor),
      Gap.horizontal.xs(),
      Flexible(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
