import 'package:sqlite3/wasm.dart';

Future<CommonDatabase>? _databaseFuture;

Future<CommonDatabase> openOperationsDb() =>
    _databaseFuture ??= _openOperationsDb();

Future<CommonDatabase> _openOperationsDb() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fileSystem = await IndexedDbFileSystem.open(dbName: 'hostr_operations');
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return sqlite.open('/hostr_operations.db');
}
