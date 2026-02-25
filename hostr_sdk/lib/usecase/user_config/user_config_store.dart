import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../datasources/storage.dart';
import '../../util/custom_logger.dart';
import 'hostr_user_config.dart';

/// Persistent store for [HostrUserConfig].
///
/// Follows the same pattern as [SwapStore] / [EscrowLockRegistry]: a single
/// JSON value under one [KeyValueStorage] key, with an in-memory cache loaded
/// lazily on first access and flushed to disk after every mutation.
///
/// Exposes a reactive [stream] so cubits and services can rebuild when the
/// config changes (e.g. mode toggle, auto-withdraw toggle).
@singleton
class UserConfigStore {
  static const _storageKey = 'hostr_user_config';

  final KeyValueStorage _storage;
  final CustomLogger _logger;

  /// In-memory cache. Loaded lazily via [initialize].
  HostrUserConfig? _cache;

  /// Reactive stream of the current config. Seeded with [HostrUserConfig.defaults]
  /// and updated on every [update] call.
  final BehaviorSubject<HostrUserConfig> _subject = BehaviorSubject.seeded(
    HostrUserConfig.defaults,
  );

  UserConfigStore(this._storage, this._logger);

  // ── Public API ──────────────────────────────────────────────────────────

  /// Load the user config from disk. Idempotent.
  Future<void> initialize() async {
    if (_cache != null) return;
    try {
      final raw = await _storage.read(_storageKey);
      if (raw == null) {
        _cache = HostrUserConfig.defaults;
        _subject.add(_cache!);
        return;
      }

      final String jsonStr = raw is String ? raw : raw.toString();
      final Map<String, dynamic> map =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      _cache = HostrUserConfig.fromJson(map);
      _subject.add(_cache!);
      _logger.i('UserConfigStore loaded: $_cache');
    } catch (e) {
      _logger.e('Failed to load user config: $e');
      _cache = HostrUserConfig.defaults;
      _subject.add(_cache!);
    }
  }

  /// The current config. Triggers [initialize] if not yet loaded.
  Future<HostrUserConfig> get state async {
    await initialize();
    return _cache!;
  }

  /// Reactive stream of config changes. Always emits the current value first
  /// (BehaviorSubject).
  Stream<HostrUserConfig> get stream => _subject.stream;

  /// Replace the entire config. Persists to disk and notifies listeners.
  Future<void> update(HostrUserConfig config) async {
    await initialize();
    _cache = config;
    await _flush();
    _subject.add(config);
    _logger.d('UserConfigStore updated: $config');
  }

  /// Reset to defaults. Wipes storage.
  Future<void> reset() async {
    _cache = HostrUserConfig.defaults;
    await _flush();
    _subject.add(_cache!);
    _logger.i('UserConfigStore reset to defaults');
  }

  /// Dispose the reactive stream. Call on app shutdown.
  void dispose() {
    _subject.close();
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<void> _flush() async {
    await _storage.write(_storageKey, jsonEncode(_cache!.toJson()));
  }
}
