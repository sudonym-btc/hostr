import 'package:ndk/ndk.dart';

import 'keypairs.dart';

// todo follow https://github.com/nostr-protocol/nips/blob/master/06.md for key derivation

var MOCK_PROFILES = [
  Metadata(
    pubKey: MockKeys.hoster.publicKey,
    name: 'Jeremy',
    nip05: 'jeremy@lnbits1.hostr.development',
    lud16: 'jeremy@lnbits1.hostr.development',
    about: 'We love weloming new guests into our home',
    picture:
        'https://plus.unsplash.com/premium_photo-1689530775582-83b8abdb5020?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cmFuZG9tJTIwcGVyc29ufGVufDB8fDB8fHww',
  ).toEvent()
    ..sign(MockKeys.hoster.privateKey!),
  Metadata(
    pubKey: MockKeys.guest.publicKey,
    name: 'Jasmine',
    about: 'Travelling the world!',
    nip05: 'jasmine@lnbits2.hostr.development',
    lud16: 'jasmine@lnbits2.hostr.development',
    picture:
        'https://r2.starryai.com/results/1005156662/01ea57ea-66bd-4bed-a467-11bbdedb43ea.webp',
  ).toEvent()
    ..sign(MockKeys.guest.privateKey!),
  Metadata(
    pubKey: MockKeys.escrow.publicKey,
    name: 'Escrow',
    about: 'Provides cheap escrow services for nostr',
    picture:
        'https://files.oaiusercontent.com/file-NbbHPRbFACbfS8BcAWDnju?se=2024-12-31T13%3A41%3A58Z&sp=r&sv=2024-08-04&sr=b&rscc=max-age%3D604800%2C%20immutable%2C%20private&rscd=attachment%3B%20filename%3D2cdcbb2c-f951-46af-91b6-547b74f2dc9d.webp&sig=advBN3XrKDJnND8EUsjJ0YKNI9OtCFTvBA4DIpOeQvA%3D',
  ).toEvent()
    ..sign(MockKeys.escrow.privateKey!),
].toList();
