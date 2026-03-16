@Tags(['unit'])
library;

import 'package:coinlib/coinlib.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:models/secp256k1.dart';
import 'package:test/test.dart';

void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  const nostrPrivateKeyHex =
      '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

  setUpAll(loadCoinlib);

  tearDown(() {
    setSecp256k1LoaderOverride(null);
  });

  group('deterministic key derivation', () {
    test('derivation loads secp256k1 backend on demand', () async {
      var loadCount = 0;
      setSecp256k1LoaderOverride(() async {
        loadCount++;
        await loadCoinlib();
      }, label: 'test loader');

      final key = await deriveEvmKey(nostrPrivateKeyHex, accountIndex: 1);

      expect(key.address.eip55With0x, isNotEmpty);
      expect(loadCount, 1);
      expect(isFastSecp256k1BackendLoaded(), isTrue);
    });

    test('caches important derivation futures', () {
      final derivation = DeterministicKeyDerivation(nostrPrivateKeyHex);

      expect(
        identical(derivation.deriveAppEntropy(), derivation.deriveAppEntropy()),
        isTrue,
      );
      expect(
        identical(
          derivation.deriveAccountMnemonicWords(),
          derivation.deriveAccountMnemonicWords(),
        ),
        isTrue,
      );
      expect(
        identical(
          derivation.deriveAccountMnemonic(),
          derivation.deriveAccountMnemonic(),
        ),
        isTrue,
      );
      expect(
        identical(derivation.deriveAppMaster(), derivation.deriveAppMaster()),
        isTrue,
      );
      expect(
        identical(
          derivation.deriveEvmKey(accountIndex: 2),
          derivation.deriveEvmKey(accountIndex: 2),
        ),
        isTrue,
      );
      expect(
        identical(
          derivation.deriveTradeId(accountIndex: 2),
          derivation.deriveTradeId(accountIndex: 2),
        ),
        isTrue,
      );
      expect(
        identical(
          derivation.deriveTradeSalt(accountIndex: 2),
          derivation.deriveTradeSalt(accountIndex: 2),
        ),
        isTrue,
      );
    });

    test('class-based derivation matches top-level helpers', () async {
      final derivation = DeterministicKeyDerivation(nostrPrivateKeyHex);

      expect(
        await derivation.deriveAccountMnemonicWords(),
        await deriveAccountMnemonicWords(nostrPrivateKeyHex),
      );
      expect(
        await derivation.deriveTradeId(accountIndex: 2),
        await deriveTradeId(nostrPrivateKeyHex, accountIndex: 2),
      );
      expect(
        await derivation.deriveTradeSalt(accountIndex: 2),
        await deriveTradeSalt(nostrPrivateKeyHex, accountIndex: 2),
      );

      final asyncKey = await derivation.deriveEvmKey(accountIndex: 2);
      final syncKey = await deriveEvmKey(nostrPrivateKeyHex, accountIndex: 2);
      expect(asyncKey.privateKeyInt, syncKey.privateKeyInt);
    });

    test('nostr derivation is deterministic', () async {
      final key1 = await deriveNostrPrivateKeyFromMnemonic(mnemonic);
      final key2 = await deriveNostrPrivateKeyFromMnemonic(mnemonic);

      expect(key2, key1);
    });

    test('evm derivation is deterministic', () async {
      final key1 = await deriveEvmKey(nostrPrivateKeyHex, accountIndex: 3);
      final key2 = await deriveEvmKey(nostrPrivateKeyHex, accountIndex: 3);

      expect(key2.privateKeyInt, key1.privateKeyInt);
      expect(key2.address, key1.address);
    });

    test('trade material derivation is deterministic', () async {
      final tradeId1 = await deriveTradeId(nostrPrivateKeyHex, accountIndex: 5);
      final tradeId2 = await deriveTradeId(nostrPrivateKeyHex, accountIndex: 5);
      final tradeSalt1 = await deriveTradeSalt(
        nostrPrivateKeyHex,
        accountIndex: 5,
      );
      final tradeSalt2 = await deriveTradeSalt(
        nostrPrivateKeyHex,
        accountIndex: 5,
      );

      expect(tradeId2, tradeId1);
      expect(tradeSalt2, tradeSalt1);
    });
  });
}
