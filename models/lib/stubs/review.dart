import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_REVIEWS = [
  Review.fromNostrEvent(
    Nip01Utils.signWithPrivateKey(
        privateKey: MockKeys.guest.privateKey!,
        event: Nip01Event(
            pubKey: MockKeys.guest.publicKey,
            content: 'I had a great time staying here!',
            createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
            kind: NOSTR_KIND_REVIEW,
            tags: [
              ['commit_hash_preimage', 'commit_hash_preimage'],
              ['e', MOCK_LISTINGS[0].id],
              ['d', MOCK_LISTINGS[0].getDtag()!],
              ['a', MOCK_LISTINGS[0].anchor]
            ])),
  ),
].toList();
