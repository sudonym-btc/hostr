import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

/// A popup card that displays profile information with verification badges.
///
/// Shows:
/// - Avatar, display name, about text
/// - NIP-05 verification badge (verified/unverified/pending)
/// - LUD-16 (Lightning Address) reachability + nostr pubkey match
class ProfilePopup extends StatefulWidget {
  final String pubkey;

  const ProfilePopup({super.key, required this.pubkey});

  /// Show the profile popup as a modal bottom sheet.
  static Future<void> show(BuildContext context, String pubkey) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProfilePopup(pubkey: pubkey),
    );
  }

  @override
  State<ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  Nip05VerificationResult? _nip05Result;
  Lud16VerificationResult? _lud16Result;
  bool _nip05Loading = true;
  bool _lud16Loading = true;

  ProfileMetadata? _profile;

  @override
  void initState() {
    super.initState();
  }

  void _onProfileLoaded(ProfileMetadata? profile) {
    if (profile == null || _profile != null) return;
    _profile = profile;
    _verifyNip05(profile);
    _verifyLud16(profile);
  }

  Future<void> _verifyNip05(ProfileMetadata profile) async {
    final nip05 = profile.metadata.nip05;
    if (nip05 == null || nip05.isEmpty) {
      if (mounted) {
        setState(() {
          _nip05Loading = false;
          _nip05Result = const Nip05VerificationResult.invalid(
            error: 'No NIP-05 set',
          );
        });
      }
      return;
    }

    try {
      final result = await getIt<Hostr>().verification.verifyNip05(
        nip05: nip05,
        pubkey: widget.pubkey,
      );
      if (mounted) setState(() => _nip05Result = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _nip05Result = Nip05VerificationResult.invalid(
            error: e.toString(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _nip05Loading = false);
    }
  }

  Future<void> _verifyLud16(ProfileMetadata profile) async {
    final lud16 = profile.metadata.lud16;
    if (lud16 == null || lud16.isEmpty) {
      if (mounted) {
        setState(() {
          _lud16Loading = false;
          _lud16Result = const Lud16VerificationResult.unreachable(
            error: 'No Lightning Address set',
          );
        });
      }
      return;
    }

    try {
      final result = await getIt<Hostr>().verification.verifyLud16(
        lud16: lud16,
      );
      if (mounted) setState(() => _lud16Result = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _lud16Result = Lud16VerificationResult.unreachable(
            error: e.toString(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _lud16Loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      pubkey: widget.pubkey,
      onDone: _onProfileLoaded,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final metadata = profile?.metadata;

        return ModalBottomSheet(
          leading: CircleAvatar(
            radius: 36,
            backgroundImage: metadata?.picture != null
                ? NetworkImage(metadata!.picture!)
                : null,
            child: metadata?.picture == null
                ? Text(
                    (metadata?.name ?? '?').characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  )
                : null,
          ),
          title: metadata?.name ?? metadata?.displayName ?? 'Unknown',
          subtitle: metadata?.about,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Divider(height: 1),
              Gap.vertical.custom(kSpace3),

              // NIP-05 verification
              _Nip05Row(
                nip05: metadata?.nip05,
                result: _nip05Result,
                loading: _nip05Loading,
              ),

              Gap.vertical.sm(),

              // LUD-16 verification
              _Lud16Row(
                lud16: metadata?.lud16,
                result: _lud16Result,
                loading: _lud16Loading,
              ),

              Gap.vertical.md(),

              // Pubkey (truncated, copyable)
              _PubkeyRow(pubkey: widget.pubkey),
            ],
          ),
          buttons: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        );
      },
    );
  }
}

// ─── NIP-05 row ────────────────────────────────────────────────

class _Nip05Row extends StatelessWidget {
  final String? nip05;
  final Nip05VerificationResult? result;
  final bool loading;

  const _Nip05Row({this.nip05, this.result, this.loading = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (nip05 == null || nip05!.isEmpty) {
      return _verificationTile(
        context,
        icon: Icons.badge_outlined,
        iconColor: colorScheme.outline,
        title: 'NIP-05',
        subtitle: 'Not set',
      );
    }

    if (loading) {
      return _verificationTile(
        context,
        icon: Icons.badge_outlined,
        iconColor: colorScheme.outline,
        title: nip05!,
        trailing: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final valid = result?.valid ?? false;

    return _verificationTile(
      context,
      icon: valid ? Icons.verified : Icons.error_outline,
      iconColor: valid ? Colors.blue : colorScheme.error,
      title: nip05!,
      subtitle: valid ? 'Verified' : 'Verification failed',
      subtitleColor: valid ? Colors.blue : colorScheme.error,
    );
  }
}

// ─── LUD-16 row ────────────────────────────────────────────────

class _Lud16Row extends StatelessWidget {
  final String? lud16;
  final Lud16VerificationResult? result;
  final bool loading;

  const _Lud16Row({this.lud16, this.result, this.loading = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (lud16 == null || lud16!.isEmpty) {
      return _verificationTile(
        context,
        icon: Icons.bolt_outlined,
        iconColor: colorScheme.outline,
        title: 'Lightning Address',
        subtitle: 'Not set',
      );
    }

    if (loading) {
      return _verificationTile(
        context,
        icon: Icons.bolt,
        iconColor: Theme.of(context).colorScheme.error,
        title: lud16!,
        trailing: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final reachable = result?.reachable ?? false;
    final allowsNostr = result?.allowsNostr ?? false;

    // Build subtitle chips
    final chips = <_StatusChip>[];
    if (reachable) {
      chips.add(_StatusChip(label: 'Reachable', color: Colors.green));
      if (allowsNostr) {
        chips.add(_StatusChip(label: 'Zaps enabled', color: Colors.blue));
      }
    } else {
      chips.add(_StatusChip(label: 'Unreachable', color: colorScheme.error));
    }

    return _verificationTile(
      context,
      icon: reachable ? Icons.bolt : Icons.bolt_outlined,
      iconColor: reachable ? Colors.amber : colorScheme.error,
      title: lud16!,
      chipRow: chips,
    );
  }
}

// ─── Pubkey row ────────────────────────────────────────────────

class _PubkeyRow extends StatelessWidget {
  final String pubkey;

  const _PubkeyRow({required this.pubkey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final truncated =
        '${pubkey.substring(0, 8)}…${pubkey.substring(pubkey.length - 8)}';

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Clipboard.setData(ClipboardData(text: pubkey));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Public key copied'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: CustomPadding(
          top: 0.25,
          bottom: 0.25,
          left: 0.5,
          right: 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.key, size: 14, color: theme.colorScheme.outline),
              Gap.horizontal.custom(6),
              Text(
                truncated,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.outline,
                ),
              ),
              Gap.horizontal.xs(),
              Icon(Icons.copy, size: 12, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────

Widget _verificationTile(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  String? subtitle,
  Color? subtitleColor,
  Widget? trailing,
  List<_StatusChip>? chipRow,
}) {
  final theme = Theme.of(context);

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: iconColor, size: 20),
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
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (chipRow != null)
              CustomPadding.only(
                top: kSpace1,
                child: Wrap(spacing: 4, runSpacing: 4, children: chipRow),
              ),
          ],
        ),
      ),
      if (trailing != null) trailing,
    ],
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
