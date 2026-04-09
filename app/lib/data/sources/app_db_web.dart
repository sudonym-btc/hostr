import 'package:sqlite3/wasm.dart';

Future<CommonDatabase>? _databaseFuture;

Future<CommonDatabase> openAppDb() => _databaseFuture ??= _openAppDb();

Future<CommonDatabase> _openAppDb() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fileSystem = await IndexedDbFileSystem.open(dbName: 'hostr');
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return sqlite.open('/hostr.db');
}
