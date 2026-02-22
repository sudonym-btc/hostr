import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';

import '../seed_context.dart';
import '../seed_pipeline_models.dart';

/// Stage 2: Build kind-0 profile metadata events for all users.
///
/// Also builds the static escrow service profile.

// ─── Name data ──────────────────────────────────────────────────────────────

const List<String> _seedFirstNames = [
  'Alex',
  'Taylor',
  'Jordan',
  'Morgan',
  'Casey',
  'Riley',
  'Avery',
  'Jamie',
  'Cameron',
  'Skyler',
  'Quinn',
  'Parker',
  'Drew',
  'Reese',
  'Blake',
  'Kendall',
  'Rowan',
  'Logan',
  'Finley',
  'Sage',
  'Elliot',
  'Harper',
  'Emerson',
  'Dakota',
  'Sydney',
  'Charlie',
  'Phoenix',
  'Remy',
  'Micah',
  'Noel',
  'Robin',
  'Jules',
  'River',
  'Arden',
  'Lane',
  'Kai',
  'Marlowe',
  'Shawn',
  'Ari',
  'Mika',
  'Briar',
  'Rory',
  'Toby',
  'Nico',
  'Jesse',
  'Alden',
  'Shiloh',
  'Ainsley',
];

const List<String> _seedLastNames = [
  'Carter',
  'Brooks',
  'Hayes',
  'Morgan',
  'Parker',
  'Reed',
  'Bennett',
  'Foster',
  'Sullivan',
  'Ward',
  'Ellis',
  'Baker',
  'Turner',
  'Morris',
  'Price',
  'Coleman',
  'Bailey',
  'Griffin',
  'Hayden',
  'Wallace',
  'Bryant',
  'Stone',
  'West',
  'Keller',
  'Watson',
  'Hughes',
  'Palmer',
  'Wells',
  'Riley',
  'Bishop',
  'Warren',
  'Woods',
  'Jensen',
  'Porter',
  'Shaw',
  'Bates',
  'Flynn',
  'Sawyer',
  'Meyer',
  'Cross',
  'Brennan',
  'Nolan',
  'Holland',
  'Cruz',
  'Harper',
  'Vaughn',
  'Monroe',
  'Sloan',
];

class _SeedIdentity {
  final String fullName;
  final String displayName;
  final String pictureUrl;

  const _SeedIdentity({
    required this.fullName,
    required this.displayName,
    required this.pictureUrl,
  });
}

_SeedIdentity _identityForUser(SeedUser user, int seed) {
  final firstName = _seedFirstNames[user.index % _seedFirstNames.length];
  final lastName =
      _seedLastNames[(user.index * 7 + seed) % _seedLastNames.length];
  final fullName = '$firstName $lastName';

  final photoIndex = ((seed + user.index * 11) % 99) + 1;
  final useWomenPortrait = (user.index + seed).isEven;
  final bucket = useWomenPortrait ? 'women' : 'men';
  final pictureUrl =
      'https://randomuser.me/api/portraits/$bucket/$photoIndex.jpg';

  return _SeedIdentity(
    fullName: fullName,
    displayName: firstName,
    pictureUrl: pictureUrl,
  );
}

// ─── Profile building ───────────────────────────────────────────────────────

List<ProfileMetadata> buildProfiles({
  required SeedContext ctx,
  required List<SeedUser> users,
}) {
  return users
      .map((user) {
        final identity = _identityForUser(user, ctx.seed);
        final metadata = Metadata(
          pubKey: user.keyPair.publicKey,
          name: identity.fullName,
          displayName: identity.displayName,
          about: user.isHost
              ? '${identity.displayName} hosts thoughtfully designed stays and has welcomed guests since ${2015 + (user.index % 9)}.'
              : '${identity.displayName} is an avid traveler who loves local neighborhoods, great coffee, and easy check-ins.',
          lud16: user.isHost
              ? 'host${user.index + 1}@lnbits1.hostr.development'
              : 'guest${user.index + 1}@lnbits2.hostr.development',
          nip05: user.isHost
              ? 'host${user.index + 1}@lnbits1.hostr.development'
              : 'guest${user.index + 1}@lnbits2.hostr.development',
          picture: identity.pictureUrl,
        ).toEvent();

        final tags = List<List<String>>.from(metadata.tags);
        if (user.hasEvm) {
          tags.add([
            'i',
            'evm:address',
            getEvmCredentials(user.keyPair.privateKey!).address.eip55With0x,
          ]);
        }

        final event = Nip01Event(
          pubKey: metadata.pubKey,
          kind: metadata.kind,
          tags: tags,
          content: metadata.content,
          createdAt: ctx.timestampDaysAfter(user.index + 1),
        );

        final signed = Nip01Utils.signWithPrivateKey(
          privateKey: user.keyPair.privateKey!,
          event: event,
        );

        return ProfileMetadata.fromNostrEvent(signed);
      })
      .toList(growable: false);
}

ProfileMetadata buildEscrowProfile({required SeedContext ctx}) {
  final metadata = Metadata(
    pubKey: MockKeys.escrow.publicKey,
    name: 'Hostr Escrow',
    displayName: 'Hostr Escrow',
    about: 'Provides cheap escrow services for nostr',
    nip05: 'escrow@hostr.development',
    picture:
        'https://wp.decrypt.co/wp-content/uploads/2019/03/bitcoin-logo-bitboy.png',
  ).toEvent();

  final tags = List<List<String>>.from(metadata.tags)
    ..add([
      'i',
      'evm:address',
      getEvmCredentials(MockKeys.escrow.privateKey!).address.eip55With0x,
    ]);

  final event = Nip01Event(
    pubKey: metadata.pubKey,
    kind: metadata.kind,
    tags: tags,
    content: metadata.content,
    createdAt: ctx.baseDate.millisecondsSinceEpoch ~/ 1000,
  );

  final signed = Nip01Utils.signWithPrivateKey(
    privateKey: MockKeys.escrow.privateKey!,
    event: event,
  );

  return ProfileMetadata.fromNostrEvent(signed);
}

// ─── Escrow trust / method lists ────────────────────────────────────────────

List<EscrowService> buildEscrowServices({required String contractAddress}) {
  return MOCK_ESCROWS(contractAddress: contractAddress).toList(growable: false);
}

Future<List<EscrowTrust>> buildEscrowTrusts({
  required SeedContext ctx,
  required List<SeedUser> users,
}) async {
  final trusts = <EscrowTrust>[];
  for (final user in users) {
    final list = Nip51List(
      pubKey: user.keyPair.publicKey,
      createdAt: ctx.baseDate.millisecondsSinceEpoch ~/ 1000,
      kind: kNostrKindEscrowTrust,
      elements: [],
    )..addElement('p', MockKeys.escrow.publicKey, false);

    final listEvent = await list.toEvent(
      Bip340EventSigner(
        privateKey: user.keyPair.privateKey,
        publicKey: user.keyPair.publicKey,
      ),
    );

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: user.keyPair.privateKey!,
      event: listEvent,
    );
    trusts.add(EscrowTrust.fromNostrEvent(signed));
  }
  return trusts;
}

Future<List<EscrowMethod>> buildEscrowMethods({
  required SeedContext ctx,
  required List<SeedUser> users,
}) async {
  final methods = <EscrowMethod>[];
  for (final user in users) {
    final list =
        Nip51List(
            pubKey: user.keyPair.publicKey,
            createdAt: ctx.baseDate.millisecondsSinceEpoch ~/ 1000,
            kind: kNostrKindEscrowMethod,
            elements: [],
          )
          ..addElement('t', EscrowType.EVM.name, false)
          ..addElement('c', 'MultiEscrow', false);

    final listEvent = await list.toEvent(
      Bip340EventSigner(
        privateKey: user.keyPair.privateKey,
        publicKey: user.keyPair.publicKey,
      ),
    );

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: user.keyPair.privateKey!,
      event: listEvent,
    );
    methods.add(EscrowMethod.fromNostrEvent(signed));
  }
  return methods;
}
