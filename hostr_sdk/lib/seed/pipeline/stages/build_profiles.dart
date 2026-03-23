import 'package:hostr_sdk/config.dart' show CoinlibEventSigner;
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
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

Future<List<ProfileMetadata>> buildProfiles({
  required SeedContext ctx,
  required List<SeedUser> users,
}) async {
  return Future.wait(
    users.map((user) async {
      final identity = _identityForUser(user, ctx.seed);
      final metadata = Metadata(
        pubKey: user.keyPair.publicKey,
        name: identity.fullName,
        displayName: identity.displayName,
        about: user.isHost
            ? '${identity.displayName} hosts thoughtfully designed stays and has welcomed guests since ${2015 + (user.index % 9)}.'
            : '${identity.displayName} is an avid traveler who loves local neighborhoods, great coffee, and easy check-ins.',
        lud16: user.isHost
            ? 'host${user.index + 1}@lnbits.hostr.development'
            : 'guest${user.index + 1}@lnbits.hostr.development',
        nip05: user.isHost
            ? 'host${user.index + 1}@lnbits.hostr.development'
            : 'guest${user.index + 1}@lnbits.hostr.development',
        picture: identity.pictureUrl,
      ).toEvent();

      final tags = List<List<String>>.from(metadata.tags);
      if (user.hasEvm) {
        final evmKey = await deriveEvmKey(user.keyPair.privateKey!);
        tags.add(['i', 'evm:address', evmKey.address.eip55With0x]);
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
    }),
  );
}

Future<ProfileMetadata> buildEscrowProfile({required SeedContext ctx}) async {
  final metadata = Metadata(
    pubKey: MockKeys.escrow.publicKey,
    name: 'Hostr',
    displayName: 'Hostr',
    about: 'Provides cheap escrow services for nostr',
    nip05: 'escrow@hostr.development',
    picture:
        'https://wp.decrypt.co/wp-content/uploads/2019/03/bitcoin-logo-bitboy.png',
  ).toEvent();

  final escrowEvmKey = await deriveEvmKey(MockKeys.escrow.privateKey!);

  final tags = List<List<String>>.from(metadata.tags)
    ..add(['i', 'evm:address', escrowEvmKey.address.eip55With0x]);

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

Future<List<EscrowService>> buildEscrowServices({
  required String contractAddress,
  required String multiEscrowBytecodeHash,
}) async {
  final escrowEvmKey = await deriveEvmKey(MockKeys.escrow.privateKey!);
  return MOCK_ESCROWS(
    contractAddress: contractAddress,
    evmAddress: escrowEvmKey.address.eip55With0x,
    byteCodeHash: multiEscrowBytecodeHash,
  ).toList(growable: false);
}

Future<List<EscrowMethod>> buildEscrowMethods({
  required SeedContext ctx,
  required List<SeedUser> users,
  required String multiEscrowBytecodeHash,
  required int chainId,
  String? tbtcAddress,
  int tbtcDecimals = 18,
  String? usdtAddress,
  int usdtDecimals = 6,
}) async {
  final methods = <EscrowMethod>[];
  final acceptedPaymentForms = [
    // Native chain token (e.g. ETH on Arbitrum).
    AcceptedPaymentForm(
      denomination: 'BTC',
      tokenTagId: Token.rbtc(chainId).tagId,
    ),
    // tBTC ERC-20 (if deployed).
    if (tbtcAddress != null && tbtcAddress.isNotEmpty)
      AcceptedPaymentForm(
        denomination: 'BTC',
        tokenTagId: Token(
          chainId: chainId,
          address: tbtcAddress,
          decimals: tbtcDecimals,
        ).tagId,
      ),
    // USDT ERC-20 (if deployed).
    if (usdtAddress != null && usdtAddress.isNotEmpty)
      AcceptedPaymentForm(
        denomination: 'USD',
        tokenTagId: Token(
          chainId: chainId,
          address: usdtAddress,
          decimals: usdtDecimals,
        ).tagId,
      ),
  ];
  if (acceptedPaymentForms.length < 2) {
    throw StateError(
      'Expected at least 2 accepted payment forms (native + ERC-20 token) '
      'but got ${acceptedPaymentForms.length}. '
      'tbtcAddress=$tbtcAddress, usdtAddress=$usdtAddress. '
      'Ensure token addresses are resolved before seeding.',
    );
  }
  for (final user in users) {
    final list =
        Nip51List(
            pubKey: user.keyPair.publicKey,
            createdAt: ctx.baseDate.millisecondsSinceEpoch ~/ 1000,
            kind: kNostrKindEscrowMethod,
            elements: [],
          )
          ..addElement('p', MockKeys.escrow.publicKey, false)
          ..addElement('c', multiEscrowBytecodeHash, false);

    final listEvent = await list.toEvent(
      CoinlibEventSigner(
        privateKey: user.keyPair.privateKey,
        publicKey: user.keyPair.publicKey,
      ),
    );

    // Build the complete tag list before creating the event so the
    // auto-computed id covers every tag.  Mutating tags on an existing
    // Nip01Event leaves the id stale because it is `late final` and
    // Nip01Utils.signWithPrivateKey does not recalculate it.
    final completeTags = [
      ...listEvent.tags,
      for (final form in acceptedPaymentForms) form.toTag(),
    ];

    final completeEvent = Nip01Event(
      pubKey: listEvent.pubKey,
      kind: listEvent.kind,
      tags: completeTags,
      content: listEvent.content,
      createdAt: listEvent.createdAt,
    );

    final signed = Nip01Utils.signWithPrivateKey(
      privateKey: user.keyPair.privateKey!,
      event: completeEvent,
    );
    methods.add(EscrowMethod.fromNostrEvent(signed));
  }
  return methods;
}
