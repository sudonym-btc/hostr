import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as ffi;

/// Opens an in-memory SQLite database (native platforms only).
///
/// Suitable for tests and services that don't need persistence across
/// restarts. For production, pass a file-based [CommonDatabase] via
/// `ffi.sqlite3.open('/path/to/hostr_ops.db')`.
CommonDatabase openOperationsDb() => ffi.sqlite3.openInMemory();
