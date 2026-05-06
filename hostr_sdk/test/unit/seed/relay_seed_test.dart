@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/pipeline/seed_context.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_models.dart';
import 'package:hostr_sdk/seed/relay_seed.dart';
import 'package:models/stubs/main.dart' show MockKeys;
import 'package:test/test.dart';

void main() {
  group('selectSignetBunkerSeedUsers', () {
    test('selects only the first host and first guest', () {
      final users = [
        _seedUser(index: 0, isHost: true),
        _seedUser(index: 1, isHost: true),
        _seedUser(index: 2, isHost: false),
        _seedUser(index: 3, isHost: false),
      ];

      final selected = selectSignetBunkerSeedUsers(users);

      expect(selected.map((user) => user.index), [0, 2]);
    });

    test('selects by role even when guests appear first', () {
      final users = [
        _seedUser(index: 0, isHost: false),
        _seedUser(index: 1, isHost: false),
        _seedUser(index: 2, isHost: true),
        _seedUser(index: 3, isHost: true),
      ];

      final selected = selectSignetBunkerSeedUsers(users);

      expect(selected.map((user) => user.index), [2, 0]);
    });

    test('handles a single available role', () {
      final selected = selectSignetBunkerSeedUsers([
        _seedUser(index: 0, isHost: true),
        _seedUser(index: 1, isHost: true),
      ]);

      expect(selected.map((user) => user.index), [0]);
    });
  });

  group('selectSignetBunkerSeedKeyTargets', () {
    test('adds escrow after first host and first guest', () {
      final users = [
        _seedUser(index: 0, isHost: true),
        _seedUser(index: 1, isHost: true),
        _seedUser(index: 2, isHost: false),
        _seedUser(index: 3, isHost: false),
      ];

      final targets = selectSignetBunkerSeedKeyTargets(users);

      expect(targets.map((target) => target.role), ['host', 'guest', 'escrow']);
      expect(targets.map((target) => target.userIndex), [0, 2, null]);
      expect(targets.last.keyPair.publicKey, MockKeys.escrow.publicKey);
    });
  });
}

SeedUser _seedUser({required int index, required bool isHost}) {
  final ctx = SeedContext(seed: 42);
  return SeedUser(
    index: index,
    keyPair: ctx.deriveKeyPair(index),
    isHost: isHost,
    hasEvm: isHost,
  );
}
