import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bip340/bip340.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:rxdart/rxdart.dart';

class MockRelay {
  String name;
  int? port;
  HttpServer? server;
  WebSocket? webSocket;
  List<Nip01Event> events = [];
  Subject<Nip01Event> onAddEvent = BehaviorSubject();
  bool signEvents;
  bool requireAuthForRequests;

  static int startPort = 4040;

  String get url => "ws://localhost:$port";

  MockRelay({
    required this.name,
    this.events = const [],
    this.signEvents = true,
    this.requireAuthForRequests = false,
    int? explicitPort,
  }) {
    if (explicitPort != null) {
      port = explicitPort;
    } else {
      port = startPort;
      startPort++;
    }
    log('MockRelay $name created on localhost:$port, events: ${json.encode(events)}');
  }

  Future<void> startServer({List<Nip01Event>? events}) async {
    var myPromise = Completer<void>();

    if (events != null) {
      this.events = events;
    }

    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, port!,
        shared: true);

    this.server = server;

    var stream = server.transform(WebSocketTransformer());

    String challenge = '';

    bool signedChallenge = false;
    stream.listen((webSocket) {
      this.webSocket = webSocket;
      if (requireAuthForRequests && !signedChallenge) {
        challenge = Helpers.getRandomString(10);
        webSocket.add(jsonEncode(["AUTH", challenge]));
      }
      webSocket.listen((message) {
        if (message == "ping") {
          webSocket.add("pong");
          return;
        }
        var eventJson = json.decode(message);
        if (eventJson[0] == "AUTH") {
          Nip01Event event = Nip01Event.fromJson(eventJson[1]);
          if (verify(event.pubKey, event.id, event.sig)) {
            String? relay = event.getFirstTag("relay");
            String? eventChallenge = event.getFirstTag("challenge");
            if (eventChallenge == challenge && relay == url) {
              signedChallenge = true;
            }
          }
          webSocket.add(jsonEncode([
            "OK",
            event.id,
            signedChallenge,
            signedChallenge
                ? ""
                : "auth-required: we can't serve requests to unauthenticated users"
          ]));
          return;
        }
        if (requireAuthForRequests && !signedChallenge) {
          webSocket.add(jsonEncode([
            "CLOSED",
            "sub_1",
            "auth-required: we can't serve requests to unauthenticated users"
          ]));
          return;
        }
        if (eventJson[0] == "REQ") {
          String requestId = eventJson[1];
          log('Received: $eventJson');
          Filter filter = Filter.fromMap(eventJson[2]);
          for (Nip01Event e in this.events) {
            if (matchEvent(e, filter)) {
              _respondEvent(requestId, e);
            }
          }
          List<dynamic> eose = [];
          eose.add("EOSE");
          eose.add(requestId);
          webSocket.add(jsonEncode(eose));
          // @todo not closing closed connections could lead to memory leaks
          onAddEvent
              // .takeUntil(webSocket.asBroadcastStream())
              .where((event) {
            return matchEvent(event, filter);
          }).listen((event) => _respondEvent(requestId, event));
        } else if (eventJson[0] == "EVENT") {
          log('Received: $eventJson');
          Nip01Event event = Nip01Event.fromJson(eventJson[1]);
          List<Nip01Event> existingEvents = this
              .events
              .where(
                (e) =>
                    e.pubKey == event.pubKey &&
                    e.getFirstTag('a') != null &&
                    event.getFirstTag('a') != null &&
                    e.getFirstTag('a') == event.getFirstTag('a'),
              )
              .toList();
          if (existingEvents.isNotEmpty) {
            for (var e in existingEvents) {
              this.events.remove(e);
              log('Updated existing event: ${e.id}');
            }
          }
          this.events.add(event);
          onAddEvent.add(event);
          webSocket.add(jsonEncode(["OK", event.id, true, '']));
        }
      });
    }, onError: (error) {
      log(' error: $error');
    });

    log('Listening on localhost:${server.port}');
    myPromise.complete();

    return myPromise.future;
  }

  _respondEvent(String requestId, Nip01Event event) {
    List<dynamic> json = [];
    json.add("EVENT");
    json.add(requestId);
    json.add(event.toJson());

    webSocket!.add(jsonEncode(json));
    log('Responding: $json');
  }

  Future<void> stopServer() async {
    if (server != null) {
      log('closing server on localhost:$url');
      return await server!.close();
    }
  }
}

matchEvent(Nip01Event event, Filter filter) {
  /// Only match the correct event kinds
  if (filter.kinds != null && !filter.kinds!.contains(event.kind)) {
    return false;
  }

  /// Only match events from that are addressable by kind:pubkey:string => "a" tag
  if (filter.pTags != null &&
      !event.pTags.any((tag) => filter.pTags!.contains(tag))) {
    return false;
  }

  /// Only match events from that are addressable by kind:pubkey:string => "a" tag
  if (filter.aTags != null &&
      !filter.aTags!.any(
          (a) => event.tags.any((tag) => tag[0] == "a" && tag.contains(a)))) {
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

  if (filter.authors != null &&
      (!filter.authors!.contains(event.pubKey) ||
          (event.tags.contains((tag) => tag[0] == "delegation") &&
              !filter.authors!.contains(
                  event.tags.lastWhere((tag) => tag[0] == "delegation")[1])))) {
    return false;
  }

  return true;
}
