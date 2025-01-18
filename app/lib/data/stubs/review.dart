import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';

var MOCK_REVIEWS = [
  Review.fromNostrEvent(NostrEvent.fromPartialData(
      keyPairs: MockKeys.hoster,
      content: 'I had a great time staying here!',
      createdAt: DateTime.now(),
      kind: NOSTR_KIND_REVIEW,
      tags: [
        ['commit_hash_preimage', 'commit_hash_preimage'],
        ['e', MOCK_LISTINGS[0].id!]
      ])),
].toList();
