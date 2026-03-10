import 'package:sqlite3/common.dart';

/// Web stub — always throws.
///
/// On web the host app must open a database via `WasmSqlite3` and pass
/// it to [HostrConfig.operationsDb].
CommonDatabase openOperationsDb() => throw UnsupportedError(
  'On web, pass an explicit CommonDatabase '
  '(e.g. from WasmSqlite3) to HostrConfig.operationsDb.',
);
