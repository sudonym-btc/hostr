import 'package:hostr/data/sources/nostr/nostr/usecase/crud.usecase.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip51List;

class Escrows extends CrudUseCase<Escrow> {
  Escrows({required super.requests}) : super(kind: Escrow.kinds[0]);

  Future<Nip51List?> trusted() async {
    Escrow? escrowList = await getOne(Filter(kinds: [EscrowTrust.kinds[0]]));
    // if (escrowList.parsedContent.) {
    // return null;
    // }
    // return Nip51List.fromEvent(escrowList.first, null);
    return null;
  }
}
