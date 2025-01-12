import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

abstract class SecureStorage {
  Future<dynamic> set(String key, dynamic val);
  Future<dynamic> get(String key);
  Future wipe();
}

@Singleton(as: SecureStorage, env: Env.allButTest)
class ImplSecureStorage implements SecureStorage {
  final storage = const FlutterSecureStorage();

  @override
  Future set(String key, dynamic val) async {
    if (val is! String) {
      val = json.encode(val);
    }
    await storage.write(key: key, value: val);
  }

  @override
  Future<dynamic> get(String key) async {
    var res = await storage.read(key: key);
    if (res == null) {
      return null;
    }
    try {
      return json.decode(res);
    } catch (e) {
      return res; // Return raw string if JSON decode fails
    }
  }

  @override
  Future wipe() async {
    await storage.deleteAll();
  }
}

@Singleton(as: SecureStorage, env: [Env.test])
class MockSecureStorage implements SecureStorage {
  dynamic state = {};

  @override
  Future<dynamic> get(String key) async {
    return state[key];
  }

  @override
  Future set(String key, val) async {
    state[key] = val;
  }

  @override
  Future wipe() {
    state = {};
    return Future.value();
  }
}
