import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../auth/auth.dart';
import '../crud.usecase.dart';

@Singleton()
class EscrowTrusts extends CrudUseCase<EscrowTrust> {
  final Auth auth;
  EscrowTrusts({
    required super.requests,
    required super.logger,
    required this.auth,
  })
    : super(kind: EscrowTrust.kinds[0]);

  Future<EscrowTrust?> trusted(String pubkey) async {
    return await getOne(Filter(authors: [pubkey]));
  }

  Future<EscrowTrust?> myTrusted() async {
    String pubkey = auth.activeKeyPair!.publicKey;
    return trusted(pubkey);
  }
}
