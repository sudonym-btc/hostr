import 'dart:convert';

import 'package:hostr_sdk/util/coinlib_gift_wrap.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../seed_context.dart';
import '../seed_pipeline_models.dart';

const _hostrSeedVersion = 1;

/// Build encrypted account seed backup events for seeded users.
///
/// Seeded trade IDs and trade keypairs are derived from the user's Hostr seed.
/// Publishing that same seed lets remote-signer/bunker sessions recover the
/// deterministic trade account indices without seeing the user's private key.
Future<List<Nip01Event>> buildAccountSeeds({
  required SeedContext ctx,
  required List<SeedUser> users,
  int? createdAt,
}) async {
  final timestamp =
      createdAt ?? DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  return Future.wait(
    users.map((user) async {
      final privateKey = user.keyPair.privateKey;
      if (privateKey == null || privateKey.isEmpty) {
        throw StateError(
          'Cannot build account seed event for read-only seeded user '
          '${user.keyPair.publicKey}',
        );
      }

      final seedHex = await deriveHostrSeedHexFromPrivateKey(privateKey);
      final payload = jsonEncode({'v': _hostrSeedVersion, 'seed': seedHex});
      final ciphertext = await coinlibEncryptNip44(
        payload,
        privateKey,
        user.keyPair.publicKey,
      );
      final event = Nip01Event(
        pubKey: user.keyPair.publicKey,
        kind: kNostrKindHostrSeed,
        content: ciphertext,
        createdAt: timestamp,
        tags: const [],
      );

      return Nip01Utils.signWithPrivateKey(
        privateKey: privateKey,
        event: event,
      );
    }),
  );
}
