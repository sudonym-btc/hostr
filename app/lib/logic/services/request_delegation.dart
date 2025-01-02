import 'dart:async';
import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class DelegationProgress {
  int step;
  DelegationProgress(this.step);
}

class LaunchedUrl extends DelegationProgress {
  LaunchedUrl(super.step);
}

class ReceivedAckMsg extends DelegationProgress {
  ReceivedAckMsg(super.step);
}

class SendDescribeRequest extends DelegationProgress {
  SendDescribeRequest(super.step);
}

class ReceivedDescribeResponse extends DelegationProgress {
  ReceivedDescribeResponse(super.step);
}

class SendDelegateRequest extends DelegationProgress {
  SendDelegateRequest(super.step);
}

class ReceivedDelegateResponse extends DelegationProgress {
  ReceivedDelegateResponse(super.step);
}

abstract class UrlLauncher {
  Future<bool> launch(Uri uri);
}

@Singleton(as: UrlLauncher, env: Env.allButTest)
class ImplUrlLauncher implements UrlLauncher {
  @override
  Future<bool> launch(Uri uri) {
    return launchUrl(uri);
  }
}

@Singleton(as: UrlLauncher, env: [Env.test])
class MockUrlLauncher extends Mock implements UrlLauncher {
  @override
  Future<bool> launch(Uri uri) {
    getIt<NostrProvider>().sendEventToRelays(NostrEvent.fromPartialData(
        kind: NOSTR_KIND_CONNECT,
        content: jsonEncode({'test': true}),
        keyPairs: NostrKeyPairs.generate()));
    return Future.value(true);
  }
}

@injectable
class RequestDelegation {
  MessageRepository messageRepo = getIt<MessageRepository>();
  SecureStorage secureStorage = getIt<SecureStorage>();
  UrlLauncher urlLauncher = getIt<UrlLauncher>();

  Stream<DelegationProgress> requestDelegation(NostrKeyPairs keyPair) {
    final BehaviorSubject<DelegationProgress> progress =
        BehaviorSubject<DelegationProgress>();

    getNostrConnectUri(keyPair)

        // Trigger initial connection with the nostr provider
        .asyncMap(urlLauncher.launch)
        .doOnData((value) {
          progress.add(LaunchedUrl(1));
        })
        // Await the connect message from the nostr provider
        .switchMap((value) => waitForConnectMessage())
        .doOnData((event) {
          progress.add(ReceivedAckMsg(2));
          progress.add(SendDescribeRequest(3));
        })
        .switchMap((event) => describe())
        .doOnData((event) {
          progress.add(ReceivedDescribeResponse(4));
          progress.add(SendDelegateRequest(5));
        })
        .switchMap((event) => delegate())
        .doOnData((event) {
          progress.add(ReceivedDelegateResponse(6));
        })
        .switchMap(saveDelegationToken)
        .doOnDone(() {
          progress.close();
        })
        .listen((event) {});
    return progress;
  }

  Stream<Uri> getNostrConnectUri(NostrKeyPairs keyPair) async* {
    yield Uri.parse(
        'nostrconnect://${keyPair.public}?relay=${Uri.encodeComponent("wss://relay.damus.io")}&metadata=${Uri.encodeComponent(jsonEncode({
          "name": "Hostr"
        }))}');
  }

  Stream waitForConnectMessage() {
    return secureStorage.readAll().asStream().switchMap((value) {
      return messageRepo
          .list(
              filter: NostrFilter(
            p: [value.keys.first.public],
            kinds: const [NOSTR_KIND_CONNECT],
            since: DateTime.now().subtract(Duration(seconds: 10)),
          ))
          .take(1);
    });
  }

  Stream describe() {
    return commandAndWait(24133, "describe", []);
  }

  Stream<MessageType> delegate() {
    return secureStorage.readAll().asStream().switchMap((value) {
      return commandAndWait(24133, "delegate", [
        value.keys.first.public,
        {
          "kind": [4, 20000],
          "since": DateTime.now().millisecondsSinceEpoch,
          "until": DateTime.now()
              .add(const Duration(days: 10000))
              .millisecondsSinceEpoch
        }
      ]);
    });
  }

  Stream saveDelegationToken(MessageType event) {
    return secureStorage.set("delegationToken", event.event.content).asStream();
  }

  Stream<MessageType> commandAndWait(
      int kind, String method, List<dynamic> params) {
    return secureStorage.readAll().asStream().switchMap((value) {
      String id = Nostr.instance.utilsService.random64HexChars();
      messageRepo.create(NostrEvent.fromPartialData(
        kind: kind,
        content: jsonEncode({
          "id": id,
          "method": method,
          "params": params,
        }),
        keyPairs: NostrKeyPairs.generate(),
      ));
      return messageRepo
          .list(
              filter: NostrFilter(
            p: [value.keys.first.public],
            kinds: [kind],
          ))
          .whereType<Data<MessageType>>()
          .map((event) => event.value)
          .where((event) {
        return event.jsonUsed;
      }).where((event) => event.json['id'] == id);
    }).take(1);
  }
}
