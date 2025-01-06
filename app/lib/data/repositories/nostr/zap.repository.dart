import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/data/models/zap.dart';
import 'package:injectable/injectable.dart';

import 'base.repository.dart';

abstract class ZapRepository extends BaseRepository<Zap> {
  ZapRepository() : super() {
    creator = (NostrEvent event) {
      return Zap.fromNostrEvent(event);
    };
  }
}

@Injectable(as: ZapRepository)
class ProdZapRepository extends ZapRepository {
  @override
  NostrFilter get eventTypeFilter => NostrFilter(kinds: [9735]);
}
