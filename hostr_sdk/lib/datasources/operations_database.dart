/// Cross-platform factory for the operations SQLite database.
///
/// On native (iOS / Android / macOS / Linux / Windows) this opens an
/// in-memory database via dart:ffi. On web it throws — the host app
/// must provide a [CommonDatabase] obtained from `WasmSqlite3`.
///
/// The SDK itself only imports `package:sqlite3/common.dart`, so it
/// compiles cleanly for every target.
library;

export 'operations_database_web.dart'
    if (dart.library.io) 'operations_database_native.dart';
