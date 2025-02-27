import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';

var MOCK_REVIEWS = [
  Review.fromNostrEvent(
    Nip01Event(
        pubKey: MockKeys.hoster.publicKey,
        content: 'I had a great time staying here!',
        createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
        kind: NOSTR_KIND_REVIEW,
        tags: [
          ['commit_hash_preimage', 'commit_hash_preimage'],
          ['e', MOCK_LISTINGS[0].nip01Event.id],
          ['d', MOCK_LISTINGS[0].nip01Event.getDtag()!],
          ['a', MOCK_LISTINGS[0].anchor]
        ])
      ..sign(MockKeys.hoster.privateKey!),
  ),
].toList();
