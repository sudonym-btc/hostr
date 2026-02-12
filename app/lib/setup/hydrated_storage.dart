import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

Future<Storage> buildHydratedStorage() async {
  final storageDirectory = kIsWeb
      ? HydratedStorageDirectory.web
      : HydratedStorageDirectory((await getTemporaryDirectory()).path);

  if (storageDirectory == HydratedStorageDirectory.web) {
    return HydratedStorage.build(storageDirectory: storageDirectory);
  }

  await IsolatedHive.init(
    storageDirectory.path,
    isolateNameServer: const _FlutterIsolateNameServer(),
  );
  final box = await IsolatedHive.openBox<dynamic>('hydrated_box');
  final cache = await box.toMap();
  return _IsolatedHydratedStorage(box, Map<String, dynamic>.from(cache));
}

class _IsolatedHydratedStorage implements Storage {
  final IsolatedBox<dynamic> _box;
  final Map<String, dynamic> _cache;

  _IsolatedHydratedStorage(this._box, this._cache);

  @override
  dynamic read(String key) => _cache[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _cache[key] = value;
    await _box.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    _cache.remove(key);
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
    await _box.clear();
  }

  @override
  Future<void> close() async {
    await _box.close();
    await IsolatedHive.close();
  }
}

class _FlutterIsolateNameServer implements IsolateNameServer {
  const _FlutterIsolateNameServer();

  @override
  dynamic lookupPortByName(String name) {
    return ui.IsolateNameServer.lookupPortByName(name);
  }

  @override
  bool registerPortWithName(dynamic port, String name) {
    return ui.IsolateNameServer.registerPortWithName(port, name);
  }

  @override
  bool removePortNameMapping(String name) {
    return ui.IsolateNameServer.removePortNameMapping(name);
  }
}
