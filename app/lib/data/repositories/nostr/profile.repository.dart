import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/data/models/event.dart';
import 'package:injectable/injectable.dart';

import 'base.repository.dart';

abstract class ProfileRepository extends BaseRepository<Event> {}

@Injectable(as: ProfileRepository)
class ProdProfileRepository extends ProfileRepository {
  @override
  NostrFilter get eventTypeFilter => NostrFilter(kinds: [0]);
}
