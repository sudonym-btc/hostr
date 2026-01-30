import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

var MOCK_BLOSSOM_SERVER_LISTS = [
  Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.hoster.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.hoster.publicKey,
          kind: Blossom.kBlossomUserServerList,
          tags: [
            ['server', 'http://blossom.hostr.development']
          ],
          content: '')),
  Nip01Utils.signWithPrivateKey(
      privateKey: MockKeys.guest.privateKey!,
      event: Nip01Event(
          pubKey: MockKeys.guest.publicKey,
          kind: Blossom.kBlossomUserServerList,
          tags: [
            ['server', 'http://blossom.hostr.development']
          ],
          content: ''))
].toList();
