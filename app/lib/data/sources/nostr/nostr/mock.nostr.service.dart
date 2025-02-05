import 'dart:async';
import 'dart:math';

import 'package:hostr/data/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

// todo: must filter by since, before, and limit, must implement count, must implement replaceable events
@Singleton(as: NostrService, env: [Env.mock])
class MockNostrService extends NostrService {
  final shouldDelay = true;

  @override
  Stream<T> startRequest<T extends Event>(
      {required List<Filter> filters, List<String>? relays}) {
    logger.i("startRequest $filters");
    // Create filtered events stream with artificial delay
    return events.stream
        // .doOnData(logger.t)

        /// Nostr filters act as OR, so we need to check if any filter matches
        .where((event) =>
            filters.any((filter) => matchEvent(event.nip01Event, filter)))
        .doOnData((event) => logger.t("matched event $event"))
        .asyncMap((event) async {
          return parser<T>(
              event.nip01Event, await getIt<KeyStorage>().getActiveKeyPair());
        })
        .doOnData((event) => logger.t("filtered event $event"))

        /// Simulate network delay for each event
        // .transform(simulateNetworkDelay(shouldDelay))
        .doOnData((event) => logger.t("filtered event delay $event"))

        /// Limit the number of events, Max int if no limit defined
        .take(filters.any((f) => f.limit != null)
            ? filters.map((f) => f.limit ?? 999999999999).reduce(min).toInt()
            : 999999999999)
        .doOnData((event) => logger.t("filtered event final $event"));
  }

  @override
  Future<List<T>> startRequestAsync<T extends Event>(
      {required List<Filter> filters,
      List<String>? relays,
      Duration? timeout}) {
    return startRequest<T>(
      filters: filters,
    ).toList();
  }

  @override
  Future<int> count(Filter filter) async {
    return events.values
        .where((event) => matchEvent(event.nip01Event, filter))
        .length;
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast(
      {required Nip01Event event, List<String>? relays}) async {
    logger.i("sendEventToRelaysAsync $event");
    events.add(parser(event, await getIt<KeyStorage>().getActiveKeyPair()));
    return [
      RelayBroadcastResponse(
          relayUrl: 'test',
          okReceived: true,
          broadcastSuccessful: true,
          msg: "")
    ];
  }

  matchEvent(Nip01Event event, Filter filter) {
    /// Only match the correct event kinds
    if (filter.kinds != null && !filter.kinds!.contains(event.kind)) {
      return false;
    }

    /// Only match events from a specific pubkey
    if (filter.pTags != null && !filter.pTags!.contains(event.pubKey)) {
      return false;
    }

    /// Only match events from that are addressable by kind:pubkey:string => "a" tag
    if (filter.aTags != null &&
        !filter.aTags!.any(
            (a) => event.tags.any((tag) => tag[0] == "a" && tag[1] == a))) {
      return false;
    }

    // logger.t("keys ${filter.additionalFilters.values}");

    // /// Only match events that contain a tag
    // if (filter.additionalFilters != null &&
    //     filter.additionalFilters!.keys.isNotEmpty &&

    //     /// Loop through all the additional filters
    //     !filter.additionalFilters!.keys
    //         .any((tagType) => event.tags!.any((eventTag) {
    //               /// Returns true if the event contains
    //               return (filter.additionalFilters![tagType] as List<String>)
    //                   .any(eventTag.contains);
    //             }))) {
    //   return false;
    // }

    // if (filter.authors != null &&
    //     (!filter.authors!.contains(event.pubkey) ||
    //         (event.tags!.contains((tag) => tag[0] == "delegation") &&
    //             !filter.authors!.contains(event.tags!
    //                 .lastWhere((tag) => tag[0] == "delegation")[1])))) {

    //   return false;
    // }

    return true;
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
