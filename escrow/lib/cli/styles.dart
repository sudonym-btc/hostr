import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Number formatting
// ─────────────────────────────────────────────────────────────────────────────

/// Formats an integer with comma-separated thousands.
///
/// ```dart
/// formatSats(50000)   // '50,000'
/// formatSats(1234567) // '1,234,567'
/// ```
String formatSats(int sats) {
  final negative = sats < 0;
  final digits = (negative ? -sats : sats).toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return negative ? '-${buf.toString()}' : buf.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Style palette
// ─────────────────────────────────────────────────────────────────────────────

/// Header / title style — bold cyan.
final kHeaderStyle = Style().bold().foreground(Colors.cyan);

/// Dimmed secondary text.
final kDimStyle = Style().foreground(Colors.muted);

/// Key (label) style for key-value displays.
final kKeyStyle = Style().foreground(Colors.info);

/// Value style — bright white.
final kValueStyle = Style().foreground(Colors.white);

/// Warning text.
final kWarnStyle = Style().bold().foreground(Colors.warning);

// ─────────────────────────────────────────────────────────────────────────────
// Status colouring
// ─────────────────────────────────────────────────────────────────────────────

/// Map of lowercase status keywords → colors.
const Map<String, Color> kStatusColors = {
  'funded': Colors.success,
  'active': Colors.success,
  'ok': Colors.success,
  'arbitrated': Colors.info,
};

/// Returns a coloured rendering of [status] based on keyword matching.
String colorStatus(String status) {
  final lower = status.toLowerCase();
  for (final entry in kStatusColors.entries) {
    if (lower.contains(entry.key)) {
      return Style().foreground(entry.value).render(status);
    }
  }
  return status;
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

/// Prints a styled section header: `── Title ──`
String sectionHeader(String title) {
  return kHeaderStyle.render('── $title ──');
}

// ─────────────────────────────────────────────────────────────────────────────
// Key-value table
// ─────────────────────────────────────────────────────────────────────────────

/// Renders a key-value map as a neat [HorizontalTableComponent].
String kvTable(Map<String, String> data) {
  return HorizontalTableComponent(
    data: data,
    padding: 1,
    separator: '│',
  ).render();
}

// ─────────────────────────────────────────────────────────────────────────────
// Relative time
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a human-readable relative-time string from [dt].
String relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
