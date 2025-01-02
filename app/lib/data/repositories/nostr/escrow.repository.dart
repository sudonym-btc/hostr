import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/models/escrow.dart';
import 'package:injectable/injectable.dart';

import 'base.repository.dart';

abstract class EscrowRepository extends BaseRepository<Escrow> {
  EscrowRepository() : super() {
    creator = (NostrEvent event) {
      return Escrow.fromNostrEvent(event);
    };
  }
  @override
  NostrFilter get eventTypeFilter => NostrFilter(kinds: [NOSTR_KIND_ESCROW]);
}

@Injectable(as: EscrowRepository)
class ProdEscrowRepository extends EscrowRepository {}
