import 'package:sqlite3/common.dart';

import 'operations_db_web.dart'
    if (dart.library.io) 'operations_db_native.dart'
    as impl;

Future<CommonDatabase> openOperationsDb() => impl.openOperationsDb();
