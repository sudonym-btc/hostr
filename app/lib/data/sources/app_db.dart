import 'package:sqlite3/common.dart';

import 'app_db_web.dart'
    if (dart.library.io) 'app_db_native.dart'
    as impl;

Future<CommonDatabase> openAppDb() => impl.openAppDb();
