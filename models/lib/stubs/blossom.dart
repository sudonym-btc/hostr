import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_BLOSSOM_SERVER_LISTS = [
  Nip01Event(
      pubKey: MockKeys.hoster.publicKey,
      kind: Blossom.kBlossomUserServerList,
      tags: [
        ['server', 'http://localhost:3000']
      ],
      content: '')
    ..sign(MockKeys.hoster.privateKey!),
  Nip01Event(
      pubKey: MockKeys.guest.publicKey,
      kind: Blossom.kBlossomUserServerList,
      tags: [
        ['server', 'http://localhost:3000']
      ],
      content: '')
    ..sign(MockKeys.guest.privateKey!)
].toList();
