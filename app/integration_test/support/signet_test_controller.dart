import 'dart:async';
import 'dart:math';

import 'package:hostr_sdk/seed/signet_bunker_client.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

class SignetTestUser {
  final String keyName;
  final KeyPair keyPair;
  final String bunkerUri;

  const SignetTestUser({
    required this.keyName,
    required this.keyPair,
    required this.bunkerUri,
  });
}

typedef SignetRequest = SignetBunkerRequest;
typedef SignetHttpException = SignetBunkerException;

class SignetTestController {
  SignetTestController({
    Uri? baseUri,
    Duration requestTimeout = const Duration(seconds: 20),
  }) : _client = SignetBunkerClient(
         baseUri:
             baseUri ?? Uri.parse('https://bunker-nostr.hostr.development/'),
         requestTimeout: requestTimeout,
       );

  final SignetBunkerClient _client;

  Future<void> dispose() => _client.close();

  Future<SignetTestUser> createRandomUser({String prefix = 'hostr-e2e'}) async {
    final keyPair = Bip340.generatePrivateKey();
    final random = Random.secure();
    final nonce =
        '${random.nextInt(1 << 16).toRadixString(16)}'
        '${random.nextInt(1 << 16).toRadixString(16)}';
    final keyName = '$prefix-${DateTime.now().microsecondsSinceEpoch}-$nonce';
    return importUser(keyName: keyName, keyPair: keyPair);
  }

  Future<List<String>> keyNames() => _client.keyNames();

  Future<void> deleteKeysWithPrefix(String prefix) =>
      _client.deleteKeysWithPrefix(prefix);

  Future<SignetTestUser> importUser({
    required String keyName,
    required KeyPair keyPair,
  }) async {
    final imported = await _client.importNsec(
      keyName: keyName,
      nsec: keyPair.privateKeyBech32!,
    );
    // Signet reports the key as online even though nostr-tools may not have
    // finished registering the backend relay subscription. The first bunker
    // connect is an ephemeral kind 24133 event, so logging in immediately can
    // publish it just before Signet is actually listening.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return SignetTestUser(
      keyName: keyName,
      keyPair: keyPair,
      bunkerUri: imported.bunkerUri,
    );
  }

  Future<Map<String, dynamic>> connectNostrConnect({
    required String uri,
    required String keyName,
    String trustLevel = 'full',
    String description = 'Hostr e2e nostrconnect approval',
  }) => _client.connectNostrConnect(
    uri: uri,
    keyName: keyName,
    trustLevel: trustLevel,
    description: description,
  );

  Future<List<Map<String, dynamic>>> apps() => _client.apps();

  Future<void> revokeApp(int appId) => _client.revokeApp(appId);

  Future<void> revokeAppsForKey(String keyName) =>
      _client.revokeAppsForKey(keyName);

  Future<void> updateAppTrustLevelForKey(String keyName, String trustLevel) =>
      _client.updateAppTrustLevelForKey(keyName, trustLevel);

  Future<List<SignetRequest>> requests({String status = 'pending'}) =>
      _client.requests(status: status);

  Future<SignetRequest> waitForPendingRequest({
    required String keyName,
    String? method,
    int? eventKind,
    Duration timeout = const Duration(seconds: 90),
  }) => _client.waitForPendingRequest(
    keyName: keyName,
    method: method,
    eventKind: eventKind,
    timeout: timeout,
  );

  Future<void> approve(
    SignetRequest request, {
    String trustLevel = 'paranoid',
    bool alwaysAllow = false,
    int? allowKind,
    String appName = 'Hostr',
  }) => _client.approve(
    request,
    trustLevel: trustLevel,
    alwaysAllow: alwaysAllow,
    allowKind: allowKind,
    appName: appName,
  );

  Future<void> approveBatch(
    List<SignetRequest> requests, {
    String trustLevel = 'full',
    bool alwaysAllow = true,
  }) => _client.approveBatch(
    requests,
    trustLevel: trustLevel,
    alwaysAllow: alwaysAllow,
  );

  Future<void> approveNext({
    required String keyName,
    String? method,
    int? eventKind,
    String trustLevel = 'paranoid',
    bool alwaysAllow = false,
    int? allowKind,
    Duration timeout = const Duration(seconds: 90),
  }) => _client.approveNext(
    keyName: keyName,
    method: method,
    eventKind: eventKind,
    trustLevel: trustLevel,
    alwaysAllow: alwaysAllow,
    allowKind: allowKind,
    timeout: timeout,
  );

  Future<void> deny(SignetRequest request) => _client.deny(request);

  Future<void> lockKey(String keyName) => _client.lockKey(keyName);

  Future<void> deleteKey(String keyName) => _client.deleteKey(keyName);
}
