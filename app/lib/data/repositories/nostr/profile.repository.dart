import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/data/models/event.dart';
import 'package:injectable/injectable.dart';

import 'base.repository.dart';

// // work with nprofile
// final nprofile = Nostr.instance.utilsService.encodeNProfile(
//   pubkey: pubkey,
//   userRelays: [],
// );
/// verify a nip05 identifier
// final verified = await Nostr.instance.utilsService.verifyNip05(
//   internetIdentifier: "something@domain.com",
//   pubKey: pubKey,
// );

// print(verified); // true

// /// Validate a nip05 identifier format
// final isValid = Nostr.instance.utilsService.isValidNip05Identifier("work@gwhyyy.com");
// print(isValid); // true

// /// Get the pubKey from a nip05 identifier
// final pubKey = await Nostr.instance.utilsService.pubKeyFromIdentifierNip05(
//   internetIdentifier: "something@somain.c",
// );
abstract class ProfileRepository extends BaseRepository<Event> {}

@Injectable(as: ProfileRepository)
class ProdProfileRepository extends ProfileRepository {
  @override
  NostrFilter get eventTypeFilter => NostrFilter(kinds: [0]);
}
