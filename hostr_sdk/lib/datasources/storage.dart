abstract class Storage<T> {
  Future<void> save(T value);
  Future<T?> read();
  Future<void> wipe();
}

abstract class KeyValueStorage {
  Future<void> write(String key, dynamic value);
  Future<dynamic> read(String key);
  Future<void> delete(String key);
}

class InMemoryKeyValueStorage implements KeyValueStorage {
  final Map<String, dynamic> _store = {};

  @override
  Future<void> write(String key, dynamic value) async {
    _store[key] = value;
  }

  @override
  Future<dynamic> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}

class InMemoryStorage<T> implements Storage<T> {
  T? _value;

  @override
  Future<void> save(T value) async {
    _value = value;
  }

  @override
  Future<T?> read() async {
    return _value;
  }

  @override
  Future<void> wipe() async {
    _value = null;
  }
}

class HostrSDKStorage {
  static const relaysKey = 'relays';
  static const nwcKey = 'nwc';
  static const authKey = 'auth';

  final Storage<List<String>> relays;
  final Storage<List<String>> nwc;
  final Storage<List<String>> auth;

  const HostrSDKStorage({
    required this.relays,
    required this.nwc,
    required this.auth,
  });

  factory HostrSDKStorage.fromKeyValue(KeyValueStorage storage) {
    return HostrSDKStorage(
      relays: _KeyedStringListStorage(storage, relaysKey),
      nwc: _KeyedStringListStorage(storage, nwcKey),
      auth: _KeyedStringListStorage(storage, authKey),
    );
  }

  factory HostrSDKStorage.inMemory() => HostrSDKStorage(
    relays: InMemoryStorage<List<String>>(),
    nwc: InMemoryStorage<List<String>>(),
    auth: InMemoryStorage<List<String>>(),
  );
}

class _KeyedStringListStorage implements Storage<List<String>> {
  final KeyValueStorage _storage;
  final String _key;

  _KeyedStringListStorage(this._storage, this._key);

  @override
  Future<void> save(List<String> value) async {
    await _storage.write(_key, value);
  }

  @override
  Future<List<String>?> read() async {
    final raw = await _storage.read(_key);
    if (raw == null) {
      return null;
    }
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return null;
  }

  @override
  Future<void> wipe() async {
    await _storage.delete(_key);
  }
}
