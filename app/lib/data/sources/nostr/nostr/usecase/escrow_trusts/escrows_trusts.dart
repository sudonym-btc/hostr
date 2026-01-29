import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../auth/auth.dart';

@Singleton()
class EscrowTrusts extends CrudUseCase<EscrowTrust> {
  final Auth auth;
  EscrowTrusts({required super.requests, required this.auth})
    : super(kind: EscrowTrust.kinds[0]);

  Future<EscrowTrust> trusted(String pubkey) async {
    return await getOne(
      Filter(kinds: [EscrowTrust.kinds[0]], authors: [pubkey]),
    );
  }

  Future<EscrowTrust> myTrusted() async {
    String pubkey = auth.activeKeyPair!.publicKey;
    return trusted(pubkey);
  }
}
