import 'dart:convert';

import 'package:dart_nostr/nostr/core/key_pairs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

abstract class SecureStorage {
  Future<SecureStorageState> readAll();

  Future set(String key, dynamic val);

  Future wipe();
}

@Singleton(as: SecureStorage, env: Env.allButTest)
class ImplSecureStorage implements SecureStorage {
  final storage = const FlutterSecureStorage();

  @override
  Future<SecureStorageState> readAll() async {
    SecureStorageState s = SecureStorageState.fromJson(
        jsonDecode(await storage.read(key: 'blob') ?? '{}'));
    return s;
  }

  @override
  Future set(String key, dynamic val) async {
    Map curJson = (await readAll()).toJson();
    curJson[key] = val;
    await storage.write(key: 'blob', value: jsonEncode(curJson));
  }

  @override
  Future wipe() async {
    await storage.deleteAll();
  }
}

@Singleton(as: SecureStorage, env: [Env.test])
class MockSecureStorage implements SecureStorage {
  SecureStorageState state = const SecureStorageState(keys: [], relays: []);
  @override
  Future<SecureStorageState> readAll() {
    return Future.value(state);
  }

  @override
  Future set(String key, val) async {
    Map<String, dynamic> curJson = (await readAll()).toJson();
    curJson[key] = val;
    state = SecureStorageState.fromJson(curJson);
  }

  @override
  Future wipe() {
    state = const SecureStorageState(keys: [], relays: []);
    return Future.value();
  }
}

class SecureStorageState extends Equatable {
  final bool mode;
  final String? delegationToken;
  final List<NostrKeyPairs> keys;
  final List<String> relays;

  const SecureStorageState(
      {this.mode = false,
      required this.keys,
      this.delegationToken,
      required this.relays});

  Map<String, dynamic> toJson() {
    return {
      "mode": mode,
      "keys": keys,
      "delegationToken": delegationToken,
      "relays": relays,
    };
  }

  static SecureStorageState fromJson(Map<String, dynamic> json) {
    return SecureStorageState(
      mode: json["mode"] ?? false,
      delegationToken: json["delegationToken"],
      keys: List<NostrKeyPairs>.from(json["keys"] ?? []),
      relays: List<String>.from(json["relays"] ?? []),
    );
  }

  @override
  List<Object?> get props => [mode, keys, relays];
}
