import 'package:injectable/injectable.dart' hide Order;
import 'package:sqlite3/common.dart';

/// Persistent log of notification IDs that have already been displayed.
///
/// Backed by the `displayed_notifications` table (added in schema v2).
/// Call [hasBeenDisplayed] before showing an OS notification, then
/// [markDisplayed] immediately after showing it.
///
/// This is intentionally generic — any subsystem can use it by choosing a
/// namespaced ID string (e.g. `trip-review-request:<tradeId>`).
@singleton
class NotificationLog {
  final CommonDatabase _db;

  NotificationLog(this._db);

  /// Returns `true` if a notification with [id] has been shown before.
  bool hasBeenDisplayed(String id) {
    final rows = _db.select(
      'SELECT 1 FROM displayed_notifications WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isNotEmpty;
  }

  /// Records that a notification with [id] has been shown.
  /// Idempotent — calling multiple times with the same [id] is a no-op.
  void markDisplayed(String id) {
    _db.execute(
      "INSERT OR IGNORE INTO displayed_notifications (id) VALUES (?)",
      [id],
    );
  }

  /// Convenience: returns `true` and marks the [id] if it has **not** been
  /// displayed before. Returns `false` (no side-effect) if already shown.
  bool tryMarkDisplayed(String id) {
    if (hasBeenDisplayed(id)) return false;
    markDisplayed(id);
    return true;
  }
}
