import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as native_sqlite3;

Future<CommonDatabase> openAppDb() async {
  final dbDir = await getApplicationSupportDirectory();
  return native_sqlite3.sqlite3.open('${dbDir.path}/hostr.db');
}
