import 'dart:async';

import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Ndk, NdkResponse, Nip01Event;

/// Represents a response from a Nostr Development Kit (NDK) request.
class CustomNdkResponse<T extends Nip01Event> {
  /// The unique identifier for the request that generated this response.
  String requestId;

  /// A stream of [T] objects returned by the request.
  ///
  /// This stream can be listened to for real-time processing of events
  /// as they arrive from the nostr request.
  final Stream<T> stream;

  /// A future that resolves to a list of all [T] objects
  /// once the request is complete (EOSE rcv).
  final Future<List<T>> _future;
  Future<List<T>> get future => _future;

  /// Creates a new [NdkResponse] instance.
  CustomNdkResponse(this.requestId, this.stream, {Future<List<T>>? future})
    : _future = future ?? stream.toList();
}

abstract class RequestsModel {
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  });
  CustomNdkResponse<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  });
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  });

  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  });

  Future<void> mock();
}

@Singleton(env: Env.allButTestAndMock)
class Requests extends RequestsModel {
  final Ndk ndk;
  Requests({required this.ndk});

  // NDK does not let us subscribe to fetch old events, complete, and keep streaming, so we have to implement our own version
  @override
  CustomNdkResponse<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  }) {
    final controller = StreamController<T>();
    final completer = Completer<List<T>>();
    final parsedQueryEvents = <T>[];
    int? lastCreatedAt;

    final queryResponse = ndk.requests.query(
      filter: filter,
      cacheRead: false,
      cacheWrite: false,
    );

    final response = CustomNdkResponse<T>(
      queryResponse.requestId,
      controller.stream,
      future: completer.future,
    );

    queryResponse.stream.listen(
      (event) async {
        final parsedEvent = await parserWithGiftWrap<T>(event, ndk);
        parsedQueryEvents.add(parsedEvent);
        final createdAt = parsedEvent.createdAt;
        if (lastCreatedAt == null || createdAt > lastCreatedAt!) {
          lastCreatedAt = createdAt;
        }
        controller.add(parsedEvent);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        controller.addError(error, stackTrace);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(parsedQueryEvents);
        }

        final liveFilter = filter.clone();
        final baseSince = liveFilter.since;
        final computedSince = lastCreatedAt == null
            ? baseSince
            : lastCreatedAt! + 1;
        if (computedSince != null &&
            (baseSince == null || computedSince > baseSince)) {
          liveFilter.since = computedSince;
        }

        final subResponse = ndk.requests.subscription(
          filter: liveFilter,
          cacheRead: false,
          cacheWrite: false,
        );
        response.requestId = subResponse.requestId;

        subResponse.stream
            .asyncMap((event) async {
              return parserWithGiftWrap<T>(event, ndk);
            })
            .listen(controller.add, onError: controller.addError);
      },
    );

    return response;
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
  }) {
    return ndk.requests
        .query(
          filter: filter,
          cacheRead: false,
          cacheWrite: false,
          timeout: timeout,
        )
        .stream
        .asyncMap((event) async {
          return parserWithGiftWrap<T>(event, ndk);
        });
  }

  // @TODO: There must be a better way to do this
  @override
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) async {
    var results = await query(
      filter: filter,
      timeout: timeout,
      relays: relays,
    ).toList();
    return results.length;
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) {
    return ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;
  }

  @override
  Future<void> mock() {
    // TODO: implement mock
    throw UnimplementedError();
  }
}
