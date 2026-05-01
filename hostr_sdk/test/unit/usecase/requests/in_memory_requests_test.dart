@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/requests/in_memory.requests.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

void main() {
  group('inMemoryReplacementKeyFor', () {
    test('scopes d-tag replacement by kind, author, and d tag', () {
      final first = _event(
        pubKey: 'alice',
        kind: 30023,
        tags: [
          ['d', 'trade-1'],
        ],
      );
      final sameAddress = _event(
        pubKey: 'alice',
        kind: 30023,
        tags: [
          ['d', 'trade-1'],
        ],
      );
      final sameDTagDifferentAuthor = _event(
        pubKey: 'bob',
        kind: 30023,
        tags: [
          ['d', 'trade-1'],
        ],
      );

      expect(
        inMemoryReplacementKeyFor(sameAddress),
        inMemoryReplacementKeyFor(first),
      );
      expect(
        inMemoryReplacementKeyFor(sameDTagDifferentAuthor),
        isNot(inMemoryReplacementKeyFor(first)),
      );
    });

    test('replaces regular replaceable events by kind and author', () {
      expect(
        inMemoryReplacementKeyFor(_event(pubKey: 'alice', kind: 0)),
        inMemoryReplacementKeyFor(_event(pubKey: 'alice', kind: 0)),
      );
      expect(
        inMemoryReplacementKeyFor(_event(pubKey: 'bob', kind: 0)),
        isNot(inMemoryReplacementKeyFor(_event(pubKey: 'alice', kind: 0))),
      );
    });

    test('ignores d tags on regular replaceable events', () {
      expect(
        inMemoryReplacementKeyFor(
          _event(
            pubKey: 'alice',
            kind: 10017,
            tags: [
              ['d', 'one'],
            ],
          ),
        ),
        inMemoryReplacementKeyFor(
          _event(
            pubKey: 'alice',
            kind: 10017,
            tags: [
              ['d', 'two'],
            ],
          ),
        ),
      );
    });

    test('does not treat d tags on regular events as replacement keys', () {
      expect(
        inMemoryReplacementKeyFor(
          _event(
            kind: 1000,
            tags: [
              ['d', 'not-addressable'],
            ],
          ),
        ),
        isNull,
      );
    });

    test('does not replace ordinary non-addressed events', () {
      expect(inMemoryReplacementKeyFor(_event(kind: 1)), isNull);
    });
  });
}

Nip01Event _event({
  String pubKey = 'pubkey',
  required int kind,
  List<List<String>> tags = const [],
}) {
  return Nip01Event(
    pubKey: pubKey,
    kind: kind,
    tags: tags,
    content: '',
    createdAt: 1,
  );
}
