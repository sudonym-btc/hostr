import 'package:sqlite3/common.dart';

/// Web stub — always throws.
///
/// On web the host app must open a database via `WasmSqlite3` and pass
/// it to [HostrConfig.appDatabase] wrapped in an [AppDatabase].
CommonDatabase openAppDb() => throw UnsupportedError(
  'On web, pass an explicit CommonDatabase '
  '(e.g. from WasmSqlite3) to AppDatabase, then to HostrConfig.appDatabase.',
);
