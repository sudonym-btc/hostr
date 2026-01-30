// This is an example unit test.
//
// A unit test tests a single function, method, or class. To learn more about
// writing unit tests, visit
// https://flutter.dev/docs/cookbook/testing/unit/introduction

import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/data/main.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  group('Key Storage', () {
    test('EVM address is consistent when derived from private key', () {
      checkKey(String privateKey) {
        KeyPair k = Bip340.fromPrivateKey(privateKey);
        EthPrivateKey ethCredentials = getEthCredentials(k.privateKey!);

        expect(ethCredentials.address.eip55With0x, isNotEmpty);
      }

      checkKey(MockKeys.escrow.privateKey!);
      checkKey(MockKeys.guest.privateKey!);
      checkKey(MockKeys.hoster.privateKey!);
    });
  });
}
