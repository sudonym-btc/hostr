import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/app_avatar.dart';

/// A unified list-item widget that standardises the look and feel of every
/// row-based item across the app (relays, escrows, inbox threads, etc.).
///
/// It wraps Flutter's [ListTile] and pins down the values that should be
/// consistent everywhere while keeping the parts that *do* vary (icon, title,
/// subtitle, trailing) fully customisable.
///
/// ## Quick examples
///
/// Minimal – just a title:
/// ```dart
/// AppListItem(title: Text('My relay'))
/// ```
///
/// With a leading avatar, subtitle, and trailing action:
/// ```dart
/// AppListItem(
///   leading: AppListItemAvatar.icon(Icons.security),
///   title: Text('Escrow agent'),
///   subtitle: Text('nip05@example.com'),
///   trailing: IconButton(icon: Icon(Icons.close), onPressed: _remove),
///   onTap: _openProfile,
/// )
/// ```
///
/// Selected state (e.g. inbox):
/// ```dart
/// AppListItem(
///   selected: true,
///   leading: ProfileAvatars.md(profiles: counterparties),
///   title: Text(name),
///   subtitle: Text(lastMessage),
///   trailing: Column(...),
///   onTap: () => onSelect(thread.anchor),
/// )
/// ```
class AppListItem extends StatelessWidget {
  /// Primary text for the item.
  final Widget title;

  /// Optional secondary text displayed below [title].
  final Widget? subtitle;

  /// Widget placed before the title block (avatar, icon, indicator, …).
  final Widget? leading;

  /// Widget placed after the title block (button, icon, badge, …).
  final Widget? trailing;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// Visual highlight – e.g. the currently selected inbox thread.
  final bool selected;

  /// Whether the list tile is dense (smaller vertical extent).
  final bool dense;

  /// Override content padding. Defaults to [EdgeInsets.zero] for consistent
  /// edge-to-edge alignment inside parent padding.
  final EdgeInsetsGeometry? contentPadding;

  const AppListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: contentPadding ?? EdgeInsets.zero,
      tileColor: selected
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.transparent,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      dense: dense,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Convenience helpers for the leading avatar in an [AppListItem].
///
/// These are thin wrappers around [AppAvatar.md] (40 px, the standard
/// list-item size). If you need a different size, use [AppAvatar] directly.
class AppListItemAvatar {
  AppListItemAvatar._();

  /// A list-item avatar with an icon.
  static AppAvatar icon(IconData iconData, {Key? key, Color? color}) {
    return AppAvatar.md(key: key, icon: iconData, color: color);
  }

  /// A list-item avatar with a blossom image + label fallback.
  static AppAvatar image({
    Key? key,
    required String? image,
    required String? pubkey,
    String? label,
    IconData? fallbackIcon,
    Color? color,
  }) {
    return AppAvatar.md(
      key: key,
      image: image,
      pubkey: pubkey,
      label: label,
      icon: fallbackIcon,
      color: color,
    );
  }

  /// A solid-colour dot with an optional foreground image (e.g. relay status).
  static AppAvatar status({
    Key? key,
    required Color color,
    ImageProvider? foregroundImage,
  }) {
    return AppAvatar.md(
      key: key,
      color: color,
      foregroundImage: foregroundImage,
    );
  }
}
