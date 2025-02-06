# List cubit

A list cubit listens to a filter and starts a subscription stream instance with a specific filter. Emitting from the filter cubit will trigger the list state to reset.
Use a postFilter cubit to emit a predicate that filters fetched results based on parameters that can't be filtered for via Nostr requests directly.
A sort cubit determines how the results are ordered.

```dart
class ListCubit<NostrEvent> {
  FilterCubit filter;
  PostResultFilterCubit postFilter;
  SortCubit sort;
}
```

It has the following methods:

`Load new`

```dart
startRequestAndCloseOnEOSE
{
  until: null,
  since: max(items.createdAt)
}
```

`Load next`

```dart
startRequestAndCloseOnEOSE
{
  until: min(items.createdAt),
  since: null
}
```

`Load all`

```dart
// Limit not required, will load all.
loadNew()

//If limit was imposed by the relay, try fetching next batch until nothing returnes
while(await loadNext()) do

emit(State.copyWith({status: Synching}))
```

The class emits:

```dart
Idle          // Used when not doing anything or listening
Listening     // Used when synched and awaiting new events
LoadingNext   // Used when fetching older events
Synching      // Used when loading next in a loop
Failed        // Used when all relays fail to respond correctly
```

### Messaging cubit (Hydrated)

The messaging cubit is responsible for loading and storing all `kind 14` private and encrypted DMs. Since messages include reservation offers made & received, it's vital that this stays up-to-date and is synched upon app login. Since private DMs are sent using a random pubkey for added privacy, it is not possible to search for messages from/to our OWN pubkey to load relevant messages. Nostr NIP [17](https://github.com/nostr-protocol/nips/blob/master/17.md) recomemends giftwrapping the message and sending it from randomized keys to us and to the real receiver.

Before a user can interact in the inbox, the message stream must have received `EOSE` for all connected relays using filter

```json
{
  kinds [1059],
  tags: [
    ["p", userPubkey]
  ]
}
```

This stream, when completed, will hold a state of all messages ever received.

```dart
/// This list should stay in memory for the duration of a user sign in
class MessagingCubit extends ListCubit<Message> with HydratedMixin {
  kinds: [14],
  List<ThreadCubit> threads

  init() {
    items.listen((message) {
      addToThread(message)
    })
  }

  addToThread(NostrEvent message) {

  }
}
class MessagingCubitState {
  List<ThreadCubit>
}
```

```dart
class ThreadCubit extends Cubit<> {

}
```

### Search

### Reservation Checker Cubit

The reservation checker cubit can listen to the search list results, and query corresponding reservations as needed.

For each search result which matches the postResultFilter filter we need to fetch reservations to check availability.
This is difficult, because one listing could have hundreds of reservations, or many listings could have no reservations.
In the first iteration, we can just query each listing individually.

We could potentially load multiple listing's reservations using one `NostrFilter` by inputting multiple `d` tags.

For each result in our results list, we need to query all reservations as there is no way to filter based on date range.

Once each synch event fires, indicating that reservations have completely loaded for a set of listings, we need to update the search postResultFilter predicate to exclude those items, or reorder the list.

### Reviews

Reviews use Nostr kind 14. They can include tags such as tags: [['cleanliness', 1], ['checkIn', 0.6]]. The content can be the comment that the guest wishes to leave.

The review event should include a tag with commitment pre-image, that only the owner of the reservation knows, 

```dart
tags.append(["e", liked.id])
tags.append(["p", liked.pubkey])
tags.append(["a", liked.tags[a]]),
tags.append(["commit_preimage", reservation.reservation_request.preimage])

```