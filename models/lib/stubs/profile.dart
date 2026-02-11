import 'package:models/stubs/main.dart';
import 'package:models/util/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_PROFILES = [
  () {
    final metadata = Metadata(
      pubKey: MockKeys.hoster.publicKey,
      name: 'Jeremy',
      nip05: 'jeremy@lnbits1.hostr.development',
      lud16: 'jeremy@lnbits1.hostr.development',
      about: 'We love weloming new guests into our home',
      picture:
          'https://plus.unsplash.com/premium_photo-1689530775582-83b8abdb5020?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cmFuZG9tJTIwcGVyc29ufGVufDB8fDB8fHww',
    ).toEvent();
    final tags = List<List<String>>.from(metadata.tags);
    tags.add([
      'i',
      'evm:address',
      getEvmCredentials(MockKeys.hoster.privateKey!).address.eip55With0x
    ]);
    // Create new event with all tags to ensure ID is calculated correctly
    final event = Nip01Event(
      pubKey: metadata.pubKey,
      kind: metadata.kind,
      tags: tags,
      content: metadata.content,
      createdAt: metadata.createdAt,
    );
    return Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.hoster.privateKey!, event: event);
  }(),
  () {
    final metadata = Metadata(
      pubKey: MockKeys.guest.publicKey,
      name: 'Jasmine',
      about: 'Travelling the world!',
      nip05: 'jasmine@lnbits2.hostr.development',
      lud16: 'jasmine@lnbits2.hostr.development',
      picture:
          'https://r2.starryai.com/results/1005156662/01ea57ea-66bd-4bed-a467-11bbdedb43ea.webp',
    ).toEvent();
    final tags = List<List<String>>.from(metadata.tags);
    tags.add([
      'i',
      'evm:address',
      getEvmCredentials(MockKeys.guest.privateKey!).address.eip55With0x
    ]);
    // Create new event with all tags to ensure ID is calculated correctly
    final event = Nip01Event(
      pubKey: metadata.pubKey,
      kind: metadata.kind,
      tags: tags,
      content: metadata.content,
      createdAt: metadata.createdAt,
    );
    return Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.guest.privateKey!, event: event);
  }(),
  () {
    final metadata = Metadata(
      pubKey: MockKeys.escrow.publicKey,
      name: 'Hostr Escrow',
      about: 'Provides cheap escrow services for nostr',
      nip05: 'escrow@hostr.development',
      picture:
          'https://wp.decrypt.co/wp-content/uploads/2019/03/bitcoin-logo-bitboy.png',
    ).toEvent();
    final tags = List<List<String>>.from(metadata.tags);
    tags.add([
      'i',
      'evm:address',
      getEvmCredentials(MockKeys.escrow.privateKey!).address.eip55With0x
    ]);
    // Create new event with all tags to ensure ID is calculated correctly
    final event = Nip01Event(
      pubKey: metadata.pubKey,
      kind: metadata.kind,
      tags: tags,
      content: metadata.content,
      createdAt: metadata.createdAt,
    );
    return Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.escrow.privateKey!, event: event);
  }(),
].toList();

final FAKED_PROFILES = List.generate(10, (count) {
  final key = mockKeys[count];
  final metadata = Metadata(
    pubKey: key.publicKey,
    displayName: faker.internet.username(),
    name: faker.person.firstName(),
    about: faker.person.bio(),
  ).toEvent();
  final tags = List<List<String>>.from(metadata.tags);

  final event = Nip01Event(
    pubKey: metadata.pubKey,
    kind: metadata.kind,
    tags: tags,
    content: metadata.content,
    createdAt: metadata.createdAt,
  );
  return Nip01Utils.signWithPrivateKey(
      privateKey: key.privateKey!, event: event);
});
