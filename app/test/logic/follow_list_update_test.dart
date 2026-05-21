import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/logic/nostr/follow_list_update.dart';
import 'package:ndk/ndk.dart' show ContactList, Nip01Event;

const _owner =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _existingFollow =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _newFollow =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _secondNewFollow =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  group('buildFollowListUpdate', () {
    test('preserves an existing list and appends missing p tags', () {
      final existing = Nip01Event(
        id: 'existing',
        pubKey: _owner,
        kind: ContactList.kKind,
        tags: [
          ['p', _existingFollow, 'wss://old.example', 'Old friend'],
          ['t', 'hostr'],
          ['client', 'other-client'],
        ],
        content: '{"wss://old.example":{"read":true,"write":true}}',
        createdAt: 10,
        sig: 'signature',
      );

      final update = buildFollowListUpdate(
        ownerPubkey: _owner,
        existingEvent: existing,
        createdAt: 20,
        targets: const [
          FollowListTarget(pubkey: _existingFollow),
          FollowListTarget(
            pubkey: _newFollow,
            relayHint: 'wss://relay.hostr.example',
            petname: 'Hostr',
          ),
        ],
      );

      expect(update.createsNewList, isFalse);
      expect(update.addedPubkeys, [_newFollow]);
      expect(update.event.id, isEmpty);
      expect(update.event.sig, isNull);
      expect(update.event.pubKey, _owner);
      expect(update.event.kind, ContactList.kKind);
      expect(update.event.createdAt, 20);
      expect(update.event.content, existing.content);
      expect(update.event.tags, [
        ['p', _existingFollow, 'wss://old.example', 'Old friend'],
        ['t', 'hostr'],
        ['client', 'other-client'],
        ['p', _newFollow, 'wss://relay.hostr.example', 'Hostr'],
      ]);
    });

    test('creates a new list only when no existing event is supplied', () {
      final update = buildFollowListUpdate(
        ownerPubkey: _owner,
        createdAt: 30,
        targets: const [
          FollowListTarget(pubkey: _newFollow),
          FollowListTarget(pubkey: _secondNewFollow),
        ],
      );

      expect(update.createsNewList, isTrue);
      expect(update.addedPubkeys, [_newFollow, _secondNewFollow]);
      expect(update.event.content, isEmpty);
      expect(update.event.tags, [
        ['p', _newFollow],
        ['p', _secondNewFollow],
      ]);
    });

    test('normalizes and deduplicates pubkeys', () {
      final update = buildFollowListUpdate(
        ownerPubkey: _owner.toUpperCase(),
        createdAt: 40,
        targets: [
          FollowListTarget(pubkey: _newFollow.toUpperCase()),
          const FollowListTarget(pubkey: _newFollow),
          const FollowListTarget(pubkey: 'not-a-pubkey'),
        ],
      );

      expect(update.event.pubKey, _owner);
      expect(update.addedPubkeys, [_newFollow]);
      expect(update.event.tags, [
        ['p', _newFollow],
      ]);
    });
  });
}
