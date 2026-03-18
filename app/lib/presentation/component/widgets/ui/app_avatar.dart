import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';

/// A unified avatar widget with size presets that match the app's spacing
/// tokens.
///
/// Use the named constructors to pick a size:
///
/// ```dart
/// AppAvatar.sm(image: pictureUrl, pubkey: pk, label: 'Alice')
/// AppAvatar.md(label: 'B', color: Colors.orange)
/// AppAvatar.xl(image: pictureHash, pubkey: pk)
/// ```
///
/// ## Parameters
/// - [image] — optional blossom hash or URL; rendered via [BlossomImage].
/// - [pubkey] — required when [image] is set so blossom can resolve it.
/// - [label] — text shown when no [image] is provided (typically an initial).
/// - [icon] — fallback icon shown when neither [image] nor [label] is set.
/// - [color] — background colour; falls back to the theme's
///   `surfaceContainerHighest`.
/// - [foregroundImage] — if you already have an [ImageProvider] (e.g. for NWC
///   wallet colours) pass it here and skip [image]/[pubkey].
class AppAvatar extends StatelessWidget {
  /// Blossom hash or URL. Rendered via [BlossomImage] when non-null.
  final String? image;

  /// Required when [image] is provided so blossom can resolve the URL.
  final String? pubkey;

  /// Fallback text (typically a single character) shown when [image] is null.
  final String? label;

  /// Fallback icon shown when both [image] and [label] are null.
  final IconData? icon;

  /// Background colour. Defaults to `surfaceContainerHighest` from the theme.
  final Color? color;

  /// If you already have a resolved [ImageProvider] use this instead of
  /// [image]/[pubkey].
  final ImageProvider? foregroundImage;

  /// Circle radius in logical pixels.
  final double radius;

  // ─── Size presets ─────────────────────────────────────────────

  /// 20 px diameter – tiny indicator dots / status badges.
  const AppAvatar.xxs({
    super.key,
    this.image,
    this.pubkey,
    this.label,
    this.icon,
    this.color,
    this.foregroundImage,
  }) : radius = 10;

  /// 28 px diameter – message profile headers.
  const AppAvatar.xs({
    super.key,
    this.image,
    this.pubkey,
    this.label,
    this.icon,
    this.color,
    this.foregroundImage,
  }) : radius = 14;

  /// 32 px diameter – chip avatars.
  const AppAvatar.sm({
    super.key,
    this.image,
    this.pubkey,
    this.label,
    this.icon,
    this.color,
    this.foregroundImage,
  }) : radius = 16;

  /// 40 px diameter – list item leading widget (default).
  const AppAvatar.md({
    super.key,
    this.image,
    this.pubkey,
    this.label,
    this.icon,
    this.color,
    this.foregroundImage,
  }) : radius = 20;

  /// 72 px diameter – profile popup.
  const AppAvatar.lg({
    super.key,
    this.image,
    this.pubkey,
    this.label,
    this.icon,
    this.color,
    this.foregroundImage,
  }) : radius = 36;

  /// 80 px diameter – profile header / hero avatar.
  const AppAvatar.xl({
    super.key,
    this.image,
    this.pubkey,
    this.label,
    this.icon,
    this.color,
    this.foregroundImage,
  }) : radius = 40;

  /// Escape hatch for one-off sizes.
  const AppAvatar.custom({
    super.key,
    required this.radius,
    this.image,
    this.pubkey,
    this.label,
    this.icon,
    this.color,
    this.foregroundImage,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        color ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final diameter = radius * 2;

    // Resolved BlossomImage takes priority.
    if (image != null && pubkey != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: ClipOval(
          child: BlossomImage(
            image: image!,
            pubkey: pubkey!,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Raw ImageProvider (e.g. NetworkImage for wallet colour dots).
    if (foregroundImage != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        foregroundImage: foregroundImage,
      );
    }

    // Label fallback.
    if (label != null && label!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          label!.characters.first.toUpperCase(),
          style: _labelStyle(context),
        ),
      );
    }

    // Icon fallback.
    if (icon != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Icon(icon, size: radius),
      );
    }

    // Empty coloured dot (status indicator).
    return CircleAvatar(radius: radius, backgroundColor: bgColor);
  }

  /// Picks a reasonable text style based on the radius so the letter scales
  /// with the avatar.
  TextStyle? _labelStyle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    if (radius <= 14) return theme.labelSmall;
    if (radius <= 20) return theme.bodySmall;
    if (radius <= 36) return theme.headlineMedium;
    return theme.headlineLarge;
  }
}
