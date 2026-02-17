part of 'deterministic_seed_builder.dart';

extension _DeterministicSeedUsers on DeterministicSeedBuilder {
  List<SeedUser> buildUsers() {
    final users = <SeedUser>[];
    final hostCount = _countByRatio(
      config.userCount,
      config.hostRatio,
    ).clamp(1, config.userCount - 1);

    for (var i = 0; i < config.userCount; i++) {
      final isHost = i < hostCount;
      final hasEvm = isHost && _pickByRatio(config.hostHasEvmRatio);
      users.add(
        SeedUser(
          index: i,
          keyPair: _deriveKeyPair(i),
          isHost: isHost,
          hasEvm: hasEvm,
        ),
      );
    }

    return users;
  }

  List<ProfileMetadata> buildProfiles(List<SeedUser> users) {
    return users
        .map((user) {
          final metadata = Metadata(
            pubKey: user.keyPair.publicKey,
            name: 'Seed User ${user.index + 1}',
            displayName: user.isHost
                ? 'Host ${user.index + 1}'
                : 'Guest ${user.index + 1}',
            about: user.isHost
                ? 'Welcoming guests since ${2015 + (user.index % 9)}!'
                : 'Guest traveler profile #${user.index + 1}',
            lud16: user.isHost
                ? 'host${user.index + 1}@lnbits1.hostr.development'
                : 'guest${user.index + 1}@lnbits2.hostr.development',
            nip05: 'seed${user.index + 1}@hostr.development',
            picture:
                'https://picsum.photos/seed/hostr-seed-${config.seed}-${user.index}/400/400',
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
            createdAt: _timestampDaysAfter(user.index + 1),
          );

          final signed = Nip01Utils.signWithPrivateKey(
            privateKey: user.keyPair.privateKey!,
            event: event,
          );

          return ProfileMetadata.fromNostrEvent(signed);
        })
        .toList(growable: false);
  }

  List<EscrowService> buildEscrowServices() {
    return MOCK_ESCROWS(
      contractAddress: contractAddress,
    ).toList(growable: false);
  }

  Future<List<EscrowTrust>> buildEscrowTrusts(List<SeedUser> hosts) async {
    final trusts = <EscrowTrust>[];
    for (final host in hosts) {
      if (!host.hasEvm) {
        continue;
      }

      final list = Nip51List(
        pubKey: host.keyPair.publicKey,
        createdAt: _baseDate.millisecondsSinceEpoch ~/ 1000,
        kind: kNostrKindEscrowTrust,
        elements: [],
      )..addElement('p', MockKeys.escrow.publicKey, false);

      final listEvent = await list.toEvent(
        Bip340EventSigner(
          privateKey: host.keyPair.privateKey,
          publicKey: host.keyPair.publicKey,
        ),
      );

      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: host.keyPair.privateKey!,
        event: listEvent,
      );
      trusts.add(EscrowTrust.fromNostrEvent(signed));
    }

    return trusts;
  }

  Future<List<EscrowMethod>> buildEscrowMethods(List<SeedUser> hosts) async {
    final methods = <EscrowMethod>[];

    for (final host in hosts) {
      if (!host.hasEvm) {
        continue;
      }

      final list =
          Nip51List(
              pubKey: host.keyPair.publicKey,
              createdAt: _baseDate.millisecondsSinceEpoch ~/ 1000,
              kind: kNostrKindEscrowMethod,
              elements: [],
            )
            ..addElement('t', EscrowType.EVM.name, false)
            ..addElement('c', 'MultiEscrow', false);

      final listEvent = await list.toEvent(
        Bip340EventSigner(
          privateKey: host.keyPair.privateKey,
          publicKey: host.keyPair.publicKey,
        ),
      );

      final signed = Nip01Utils.signWithPrivateKey(
        privateKey: host.keyPair.privateKey!,
        event: listEvent,
      );
      methods.add(EscrowMethod.fromNostrEvent(signed));
    }

    return methods;
  }

  KeyPair _deriveKeyPair(int index) {
    var nonce = 0;
    while (true) {
      final random = Random(config.seed * 100000 + index * 1000 + nonce);
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      try {
        return Bip340.fromPrivateKey(hex);
      } catch (_) {
        nonce++;
      }
    }
  }

  int _countByRatio(int total, double ratio) {
    final exact = total * ratio;
    final base = exact.floor();
    final remainder = exact - base;
    return base + (_random.nextDouble() < remainder ? 1 : 0);
  }

  bool _pickByRatio(double ratio) {
    return _random.nextDouble() < ratio;
  }
}
