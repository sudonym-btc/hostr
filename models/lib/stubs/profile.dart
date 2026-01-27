import 'package:ndk/ndk.dart';

import 'keypairs.dart';

// todo follow https://github.com/nostr-protocol/nips/blob/master/06.md for key derivation

var MOCK_PROFILES = [
  Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Metadata(
        pubKey: MockKeys.hoster.publicKey,
        name: 'Jeremy',
        nip05: 'jeremy@lnbits1.hostr.development',
        lud16: 'jeremy@lnbits1.hostr.development',
        about: 'We love weloming new guests into our home',
        picture:
            'https://plus.unsplash.com/premium_photo-1689530775582-83b8abdb5020?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cmFuZG9tJTIwcGVyc29ufGVufDB8fDB8fHww',
      ).toEvent()),
  Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.guest.privateKey!,
      event: Metadata(
        pubKey: MockKeys.guest.publicKey,
        name: 'Jasmine',
        about: 'Travelling the world!',
        nip05: 'jasmine@lnbits2.hostr.development',
        lud16: 'jasmine@lnbits2.hostr.development',
        picture:
            'https://r2.starryai.com/results/1005156662/01ea57ea-66bd-4bed-a467-11bbdedb43ea.webp',
      ).toEvent()),
  Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.escrow.privateKey!,
      event: Metadata(
        pubKey: MockKeys.escrow.publicKey,
        name: 'Hostr Escrow',
        about: 'Provides cheap escrow services for nostr',
        nip05: 'escrow@hostr.development',
        picture:
            'https://wp.decrypt.co/wp-content/uploads/2019/03/bitcoin-logo-bitboy.png',
      ).toEvent()),
].toList();
