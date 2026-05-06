import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Ndk, Nip01Event;
import 'package:ndk/shared/nips/nip01/helpers.dart';

import '../../util/main.dart';
import '../../util/deterministic_key_derivation.dart';
import '../../config.dart';
import '../auth/auth.dart';
import '../requests/requests.dart';
import '../storage/storage.dart';

const _hostrSeedVersion = 1;

@Singleton()
class AccountSeedStore {
  final Auth _auth;
  final Ndk _ndk;
  final Requests _requests;
  final AccountSeedStorage _storage;
  final CustomLogger _logger;
  final HostrConfig _config;

  final Map<String, Future<String>> _inFlight = {};
  String? _activePubkey;
  String? _activeSeedHex;

  AccountSeedStore({
    required Auth auth,
    required Ndk ndk,
    required Requests requests,
    required AccountSeedStorage storage,
    required CustomLogger logger,
    required HostrConfig config,
  }) : _auth = auth,
       _ndk = ndk,
       _requests = requests,
       _storage = storage,
       _logger = logger.scope('account-seed'),
       _config = config;

  Future<void> ensureReady({String? pubkey}) async {
    await getActiveSeedHex(pubkey: pubkey);
  }

  Future<void> ensureRemoteSeedPublished({String? pubkey}) async {
    final resolvedPubkey = pubkey ?? _auth.activePubkey;
    if (resolvedPubkey == null || resolvedPubkey.isEmpty) {
      throw StateError('Cannot publish account seed without an active pubkey');
    }

    final storedSeed = await _storage.getSeed();
    final localSeed =
        storedSeed ?? await getActiveSeedHex(pubkey: resolvedPubkey);
    if (storedSeed != null) {
      _remember(resolvedPubkey, storedSeed);
    }
    final remoteSeed = await _fetchRemoteSeed(
      resolvedPubkey,
      timeoutSeconds: 5,
    );

    if (remoteSeed == localSeed) return;

    if (remoteSeed != null) {
      throw StateError(
        'Remote account seed mismatch for $resolvedPubkey; refusing to '
        'overwrite remote seed',
      );
    }

    final published = await _publishSeed(resolvedPubkey, localSeed);
    if (!published) {
      throw StateError(
        'Unable to verify published account seed for $resolvedPubkey',
      );
    }
  }

  Future<String> getActiveSeedHex({String? pubkey}) {
    final resolvedPubkey = pubkey ?? _auth.activePubkey;
    if (resolvedPubkey == null || resolvedPubkey.isEmpty) {
      throw StateError('Cannot resolve account seed without an active pubkey');
    }

    final cached = _activeSeedHex;
    if (_activePubkey == resolvedPubkey &&
        cached != null &&
        cached.isNotEmpty) {
      return Future.value(cached);
    }

    return _inFlight.putIfAbsent(resolvedPubkey, () async {
      try {
        return await _resolveSeed(resolvedPubkey);
      } finally {
        _inFlight.remove(resolvedPubkey);
      }
    });
  }

  Future<String> _resolveSeed(String pubkey) async {
    final localSeed = await _storage.getSeed();
    if (localSeed != null) {
      _remember(pubkey, localSeed);
      if (_config.syncAccountSeedRemotely) {
        unawaited(_reconcileRemote(pubkey, localSeed));
      }
      return localSeed;
    }

    final privateKey = _auth.activeKeyPair?.privateKey;
    if (!_config.syncAccountSeedRemotely) {
      final seedHex = privateKey != null
          ? await deriveHostrSeedHexFromPrivateKey(privateKey)
          : Helpers.getSecureRandomHex(32);

      if (privateKey == null) {
        await _storage.setSeed(seedHex);
      }
      _remember(pubkey, seedHex);
      return seedHex;
    }

    final remoteSeed = await _fetchRemoteSeed(pubkey);
    if (remoteSeed != null) {
      await _storage.setSeed(remoteSeed);
      _remember(pubkey, remoteSeed);
      return remoteSeed;
    }

    final seedHex = privateKey != null
        ? await deriveHostrSeedHexFromPrivateKey(privateKey)
        : Helpers.getSecureRandomHex(32);

    await _storage.setSeed(seedHex);
    _remember(pubkey, seedHex);

    late final bool publishResult;
    try {
      publishResult = await _publishSeed(pubkey, seedHex);
    } catch (e) {
      if (privateKey == null) {
        throw StateError(
          'Unable to publish a newly generated account seed for bunker login: '
          '$e',
        );
      }
      rethrow;
    }
    if (!publishResult && privateKey == null) {
      throw StateError(
        'Unable to publish a newly generated account seed for bunker login',
      );
    }

    return seedHex;
  }

  Future<void> _reconcileRemote(String pubkey, String localSeed) async {
    try {
      final remoteSeed = await _fetchRemoteSeed(pubkey, timeoutSeconds: 5);
      if (remoteSeed == null) {
        final restored = await _publishSeed(pubkey, localSeed);
        if (!restored) {
          _logger.w('Remote seed missing and republish failed for $pubkey');
        }
        return;
      }

      if (remoteSeed != localSeed) {
        _logger.e(
          'Remote seed mismatch for $pubkey; keeping local cached seed active',
        );
      }
    } catch (e) {
      _logger.w('Remote seed reconciliation skipped for $pubkey: $e');
    }
  }

  Future<String?> _fetchRemoteSeed(
    String pubkey, {
    int timeoutSeconds = 12,
  }) async {
    final events = await _requests
        .query<Nip01Event>(
          filter: Filter(
            authors: [pubkey],
            kinds: [kNostrKindHostrSeed],
            limit: 10,
          ),
          timeout: Duration(seconds: timeoutSeconds),
          name: 'hostr-seed-fetch',
        )
        .toList();

    if (events.isEmpty) return null;

    final sorted = [...events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final event in sorted) {
      try {
        return await _decryptPayload(
          ciphertext: event.content,
          ownerPubkey: pubkey,
        );
      } catch (e) {
        _logger.w('Skipping unreadable seed event ${event.id}: $e');
      }
    }
    return null;
  }

  Future<bool> _publishSeed(String pubkey, String seedHex) async {
    final ciphertext = await _encryptPayload(
      seedHex: seedHex,
      ownerPubkey: pubkey,
    );
    final event = Nip01Event(
      pubKey: pubkey,
      kind: kNostrKindHostrSeed,
      content: ciphertext,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: const [],
    );

    final broadcast = await _requests.broadcastEvent(event: event);
    final responses = broadcast.responses;
    final remoteSeed = await _fetchPublishedSeed(pubkey, seedHex);
    final verified = remoteSeed == seedHex;
    if (verified) {
      _logger.d(
        'Hostr seed publish verified for $pubkey: '
        '${formatBroadcastResponses(responses)}',
      );
    } else {
      _logger.w(
        'Hostr seed publish accepted but readback failed for $pubkey: '
        'remote=${remoteSeed == null ? 'missing' : 'different'} '
        'responses=${formatBroadcastResponses(responses)}',
      );
    }
    return verified;
  }

  Future<String?> _fetchPublishedSeed(
    String pubkey,
    String expectedSeed,
  ) async {
    const delays = [
      Duration.zero,
      Duration(milliseconds: 300),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];

    String? latestSeed;
    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      latestSeed = await _fetchRemoteSeed(pubkey, timeoutSeconds: 4);
      if (latestSeed == expectedSeed) return latestSeed;
    }
    return latestSeed;
  }

  Future<String> _encryptPayload({
    required String seedHex,
    required String ownerPubkey,
  }) async {
    _validateSeedHex(seedHex);
    final signer = _ndk.accounts.getLoggedAccount()?.signer;
    final payload = jsonEncode({'v': _hostrSeedVersion, 'seed': seedHex});
    final ciphertext = await signer?.encryptNip44(
      plaintext: payload,
      recipientPubKey: ownerPubkey,
    );
    if (ciphertext == null || ciphertext.isEmpty) {
      throw StateError('Active signer does not support NIP-44 self-encryption');
    }
    return ciphertext;
  }

  Future<String> _decryptPayload({
    required String ciphertext,
    required String ownerPubkey,
  }) async {
    final signer = _ndk.accounts.getLoggedAccount()?.signer;
    final plaintext = await signer?.decryptNip44(
      ciphertext: ciphertext,
      senderPubKey: ownerPubkey,
    );
    if (plaintext == null || plaintext.isEmpty) {
      throw StateError('Active signer does not support NIP-44 self-decryption');
    }

    final decoded = jsonDecode(plaintext);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Seed payload must be a JSON object');
    }

    final seedHex = decoded['seed'] as String?;
    if (seedHex == null) {
      throw const FormatException('Seed payload missing seed');
    }
    _validateSeedHex(seedHex);
    return seedHex;
  }

  void _validateSeedHex(String seedHex) {
    final normalized = seedHex.trim().toLowerCase();
    if (normalized.length != 64 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      throw FormatException('Invalid Hostr seed: $seedHex');
    }
    if (hex.decode(normalized).length != 32) {
      throw FormatException('Hostr seed must decode to 32 bytes');
    }
  }

  void _remember(String pubkey, String seedHex) {
    _activePubkey = pubkey;
    _activeSeedHex = seedHex;
  }
}
