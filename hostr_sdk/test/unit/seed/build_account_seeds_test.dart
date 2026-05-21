@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/seed/pipeline/seed_factory.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:hostr_sdk/util/coinlib_gift_wrap.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('buildAccountSeeds', () {
    test('publishes the deterministic Hostr seed used for trade IDs', () async {
      final factory = SeedFactory(
        config: const SeedPipelineConfig(
          seed: 77,
          userCount: 0,
          userOverrides: [
            SeedUserSpec.host(listingCount: 1),
            SeedUserSpec.guest(
              threadCount: 1,
              threadStages: ThreadStageSpec.pendingOnly(),
            ),
          ],
        ),
      );

      final data = await factory.buildAll(now: DateTime.utc(2026, 1, 1));
      final thread = data.threads.single;
      final guest = thread.guest;
      final seedEvent = data.accountSeeds.singleWhere(
        (event) => event.pubKey == guest.keyPair.publicKey,
      );

      expect(seedEvent.kind, kNostrKindHostrSeed);
      expect(data.allEvents, contains(seedEvent));
      expect(Nip01Utils.isIdValid(seedEvent), isTrue);

      final plaintext = await coinlibDecryptNip44(
        seedEvent.content,
        guest.keyPair.privateKey!,
        guest.keyPair.publicKey,
      );
      final payload = jsonDecode(plaintext) as Map<String, dynamic>;
      final seedHex = payload['seed'] as String;

      expect(payload['v'], 1);
      expect(
        seedHex,
        await deriveHostrSeedHexFromPrivateKey(guest.keyPair.privateKey!),
      );
      expect(
        await DeterministicKeyDerivation(
          seedHex,
        ).deriveTradeId(accountIndex: thread.guestTradeAccountIndex),
        thread.id,
      );
    });
  });
}
