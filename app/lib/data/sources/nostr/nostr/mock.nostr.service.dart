import 'dart:async';
import 'dart:math';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/nwc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

// todo: must filter by since, before, and limit, must implement count, must implement replaceable events
@Singleton(as: NostrService, env: [Env.mock])
class MockNostrService extends NostrService {
  final shouldDelay = true;

  @override
  NostrEventsStream startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays}) {
    logger.i("startRequest $request");
    // Create filtered events stream with artificial delay
    final filteredEvents = events.stream
        .doOnData(logger.t)

        /// Nostr filters act as OR, so we need to check if any filter matches
        .where((event) =>
            request.filters.any((filter) => matchEvent(event, filter)))
        .doOnData((event) => logger.t("matched event $event"))
        .asyncMap((event) async {
          Uri nwcUri = parseNwc((await getIt<NwcStorage>().get()).first);
          NostrKeyPairs? keyPair = await getIt<KeyStorage>().getActiveKeyPair();
          return parser(event, keyPair, nwcUri);
        })

        /// Simulate network delay for each event
        .transform(simulateNetworkDelay(shouldDelay))

        /// Limit the number of events, Max int if no limit defined
        .take(request.filters.any((f) => f.limit != null)
            ? request.filters
                .map((f) => f.limit ?? 999999999999)
                .reduce(min)
                .toInt()
            : 999999999999);
    onEose(
        'mock',
        NostrRequestEoseCommand(
            subscriptionId: request.subscriptionId ?? "mock-subscription-id"));

    return NostrEventsStream(
        stream: filteredEvents,
        subscriptionId: request.subscriptionId ?? "mock-subscription-id",
        request: request);
  }

  @override
  Future<int> count(NostrFilter filter) async {
    return events.values.where((event) => matchEvent(event, filter)).length;
  }

  @override
  Future<NostrEventOkCommand> sendEventToRelaysAsync(
      {required NostrEvent event, List<String>? relays}) async {
    logger.i("sendEventToRelaysAsync $event");
    events.add(event);
    return Future.value(NostrEventOkCommand(
        eventId: event.id!, isEventAccepted: true, message: ""));
  }

  matchEvent(NostrEvent event, NostrFilter filter) {
    /// Only match the correct event kinds
    if (filter.kinds != null && !filter.kinds!.contains(event.kind)) {
      return false;
    }

    /// Only match events from a specific pubkey
    if (filter.p != null && !filter.p!.contains(event.pubkey)) {
      return false;
    }

    /// Only match events from that are addressable by kind:pubkey:string => "a" tag
    if (filter.a != null &&
        !filter.a!.any(
            (a) => event.tags!.any((tag) => tag[0] == "a" && tag[1] == a))) {
      return false;
    }

    logger.t("keys ${filter.additionalFilters?.values}");

    /// Only match events that contain a tag
    if (filter.additionalFilters != null &&
        filter.additionalFilters!.keys.isNotEmpty &&

        /// Loop through all the additional filters
        !filter.additionalFilters!.keys
            .any((tagType) => event.tags!.any((eventTag) {
                  /// Returns true if the event contains
                  return (filter.additionalFilters![tagType] as List<String>)
                      .any(eventTag.contains);
                }))) {
      return false;
    }

    // if (filter.authors != null &&
    //     (!filter.authors!.contains(event.pubkey) ||
    //         (event.tags!.contains((tag) => tag[0] == "delegation") &&
    //             !filter.authors!.contains(event.tags!
    //                 .lastWhere((tag) => tag[0] == "delegation")[1])))) {

    //   return false;
    // }

    return true;
  }

  @override
  Future<List<NostrEvent>> startRequestAsync(
      {required NostrRequest request, List<String>? relays}) {
    return startRequest(
      request: request,
      onEose: (relay, ease) => false,
    ).stream.asyncMap((event) async {
      Uri nwcUri = parseNwc((await getIt<NwcStorage>().get()).first);
      NostrKeyPairs? keyPair = await getIt<KeyStorage>().getActiveKeyPair();
      return parser(event, keyPair, nwcUri);
    }).toList();
  }
}

@Singleton(as: NostrService, env: [Env.test])
class TestNostrSource extends MockNostrService {
  @override
  final shouldDelay = false;
}

StreamTransformer<T, T> simulateNetworkDelay<T>(bool applyDelay) {
  return StreamTransformer<T, T>.fromBind((stream) {
    if (applyDelay) {
      return stream.asyncExpand((event) async* {
        await Future.delayed(Duration(milliseconds: 500));
        yield event;
      });
    } else {
      return stream;
    }
  });
}
