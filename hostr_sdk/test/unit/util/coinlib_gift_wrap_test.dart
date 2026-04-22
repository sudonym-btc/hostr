@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/util/coinlib_gift_wrap.dart';
import 'package:models/bip340.dart' as models_bip340;
import 'package:models/nostr_kinds.dart';
import 'package:models/secp256k1.dart';
import 'package:ndk/data_layer/models/nip_01_event_model.dart';
import 'package:ndk/domain_layer/entities/nip_01_utils.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:test/test.dart';

void main() {
  test('coinlibToGiftWrap creates a signed NIP-59 seal', () async {
    const senderPriv =
        '0beebd062ec8735f4243466049d7747ef5d6594ee838de147f8aab842b15e273';
    const recipientPriv =
        'e108399bd8424357a710b606ae0c13166d853d327e47a6e5e038197346bdbf45';
    final senderPub = models_bip340.Bip340.getPublicKey(senderPriv);
    final recipientPub = models_bip340.Bip340.getPublicKey(recipientPriv);

    final rumor = Nip01Event(
      pubKey: senderPub,
      kind: kNostrKindDM,
      tags: [
        ['p', recipientPub],
      ],
      content: 'hello',
      createdAt: 1700000000,
    );

    final wrap = await coinlibToGiftWrap(
      rumor: rumor,
      recipientPubkey: recipientPub,
      senderPrivKey: senderPriv,
      senderPubKey: senderPub,
    );

    expect(wrap.kind, kNostrKindGiftWrap);
    expect(wrap.sig, isNotEmpty);
    expect(Nip01Utils.isIdValid(wrap), isTrue);
    expect(
      verifySchnorrSignatureSync(
        publicKey: wrap.pubKey,
        message: wrap.id,
        signature: wrap.sig!,
      ),
      isTrue,
    );

    final sealJson = await coinlibDecryptNip44(
      wrap.content,
      recipientPriv,
      wrap.pubKey,
    );
    final seal = Nip01EventModel.fromJson(jsonDecode(sealJson));

    expect(seal.kind, kNostrKindSeal);
    expect(seal.pubKey, senderPub);
    expect(seal.sig, isNotEmpty);
    expect(Nip01Utils.isIdValid(seal), isTrue);
    expect(
      verifySchnorrSignatureSync(
        publicKey: senderPub,
        message: seal.id,
        signature: seal.sig!,
      ),
      isTrue,
    );

    final rumorJson = await coinlibDecryptNip44(
      seal.content,
      recipientPriv,
      senderPub,
    );
    final unsealedRumor = Nip01EventModel.fromJson(jsonDecode(rumorJson));

    expect(unsealedRumor.id, rumor.id);
    expect(unsealedRumor.sig, isNull);
    expect(Nip01Utils.isIdValid(unsealedRumor), isTrue);
  });
}
