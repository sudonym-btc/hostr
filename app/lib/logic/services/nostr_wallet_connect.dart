import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

/**
 * There are four event kinds:

NIP-47 info event: 13194
NIP-47 request: 23194
NIP-47 response: 23195
NIP-47 notification event: 23196
 */
@Injectable(env: Env.allButTestAndMock)
class NostrWalletConnectService {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();
  NwcStorage nwcStorage = getIt<NwcStorage>();
  NostrProvider nostr = getIt<NostrProvider>();

  parseNWC(String nwcString) {
    Uri nwcUri = Uri.parse(nwcString);
    assert(nwcUri.scheme == 'nostr+walletconnect');
    assert(nwcUri.queryParameters.containsKey('relay'));

// check that relay url correct as well
    Uri.parse(nwcUri.queryParameters['relay']!);
    return nwcUri;
  }

  // User fetched a NWC from their wallet
  // e.g. nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  save(String uri) async {
    // Parse the NWC string, check protocol, secret, relay
    // Attempt to connect to the specified relay
    // Get information about the relay, check that support pay_invoice

    // Uri relayUri = parseRelayUriFromNWC(uri);
    // await getWalletInfo(relayUri);

    // Nostr.instance.relaysService.relaysList!.add(relayUri.toString());
    // Nostr.instance.relaysService.reconnectToRelays(onRelayListening: onRelayListening, onRelayConnectionError: onRelayConnectionError, onRelayConnectionDone: onRelayConnectionDone, retryOnError: retryOnError, retryOnClose: retryOnClose, shouldReconnectToRelayOnNotice: shouldReconnectToRelayOnNotice, connectionTimeout: connectionTimeout, ignoreConnectionException: ignoreConnectionException, lazyListeningToRelays: lazyListeningToRelays)
    logger.i('Saving NWC: $uri');
    await nwcStorage.set([uri.toString()]);
  }

  getWalletInfo(Uri nwc) async {
    /**
     * {
  "id": "df467db0a9f9ec77ffe6f561811714ccaa2e26051c20f58f33c3d66d6c2b4d1c",
  "pubkey": "c04ccd5c82fc1ea3499b9c6a5c0a7ab627fbe00a0116110d4c750faeaecba1e2",
  "created_at": 1713883677,
  "kind": 13194,
  "tags": [
    [
      "notifications",
      "payment_received payment_sent"
    ]
  ],
  "content": "pay_invoice pay_keysend get_balance get_info make_invoice lookup_invoice list_transactions multi_pay_invoice multi_pay_keysend sign_message notifications",
  "sig": "31f57b369459b5306a5353aa9e03be7fbde169bc881c3233625605dd12f53548179def16b9fe1137e6465d7e4d5bb27ce81fd6e75908c46b06269f4233c845d8"
}
     */
    var infoEvents = await nostr.startRequestAsync(
      relays: [nwc.queryParameters['relay']!],
      request: NostrRequest(filters: [
        NostrFilter(kinds: [13194], p: [nwc.host], limit: 1)
      ]),
    );
    var firstInfoEvent = infoEvents.first;
    assert(firstInfoEvent.content != null);
    assert(firstInfoEvent.content!.contains('pay_invoice'));
    return firstInfoEvent;
  }

  Future<NostrEvent> generateRequestEvent(String invoice) async {
    var nwc = await nwcStorage.get();

    // Check that still connected to relay
    // var info = await getWalletInfo(parseRelayUriFromNWC(s.nwc[0]));

    Uri uri = parseNWC(nwc.first);

    logger.i('NWC creds: ${uri}');

    String content = JsonEncoder().convert({
      "method": "pay_invoice", // method, string
      "params": {
        // params, object
        "invoice": invoice // command-related data
      }
    });
    print("content: $content");
    print("key: ${uri.queryParameters['secret']!}");
    String encryptedContent =
        Nip04().encrypt(uri.queryParameters['secret']!, uri.host, content);

    // print("encryptedContent: $encryptedContent");

    NostrEvent paymentRequest = NostrEvent.fromPartialData(
        tags: [
          ['p', uri.host]
        ],
        kind: 23194,
        content: encryptedContent,
        keyPairs: Nostr.instance.keysService
            .generateKeyPairFromExistingPrivateKey(
                uri.queryParameters['secret']!));

    logger.i('PaymentRequest event contstructed $paymentRequest');
    return paymentRequest;
  }

  payInvoice(String invoice) async {
    logger.i('Attempting to pay invoice with NWC: $invoice');

    NostrEvent paymentRequest = await generateRequestEvent(invoice);
    var nwc = await nwcStorage.get();
    Uri uri = parseNWC(nwc.first);

    // Listen for the "paid" response
    /**
       * {
    "result_type": "pay_invoice", //indicates the structure of the result field
    "error": { //object, non-null in case of error
        "code": "UNAUTHORIZED", //string error code, see below
        "message": "human readable error message"
    },
    "result": { // result, object. null in case of error.
        "preimage": "0123456789abcdef..." // command-related data
    }
}
       */
    var responseProm = nostr
        .startRequest(
          relays: [uri.queryParameters['relay']!],
          onEose: (relay, ease) => false,
          request: NostrRequest(filters: [
            NostrFilter(kinds: [23195], e: [paymentRequest.id!], limit: 1)
          ]),
        )
        .stream
        .map((e) {
          print('Received from relay: $e');
          var response = Nip04().decrypt(
            uri.queryParameters['secret']!,
            uri.host,
            e.content!,
          );
        })
        .first;

    // Trigger the pa_invoice request
    NostrEventOkCommand resp = await nostr.sendEventToRelaysAsync(
        event: paymentRequest, relays: [uri.queryParameters['relay']!]);

    if (resp.isEventAccepted!) {
      logger.i('Sent payment request to relay: $resp');
    } else {
      throw Exception(
          'Failed to send payment request to relay: ${resp.message}');
    }

    await responseProm;
  }
}

@Injectable(as: NostrWalletConnectService, env: [Env.test, Env.mock])
class MockNostrWalletConnectService extends NostrWalletConnectService {
  getWalletInfo(Uri nwc) async {
    return NostrEvent.fromPartialData(
        kind: 13194,
        content:
            "pay_invoice pay_keysend get_balance get_info make_invoice lookup_invoice list_transactions multi_pay_invoice multi_pay_keysend sign_message notifications",
        keyPairs: NostrKeyPairs.generate());
  }

  payInvoice(String invoice) async {
    logger.i('Attempting to pay invoice with NWC: $invoice');

    var nwc = await nwcStorage.get();

    Uri uri = parseNWC(nwc.first);

    NostrEvent paymentRequest = await generateRequestEvent(invoice);

    // Listen for the "paid" response
    /**
       * {
    "result_type": "pay_invoice", //indicates the structure of the result field
    "error": { //object, non-null in case of error
        "code": "UNAUTHORIZED", //string error code, see below
        "message": "human readable error message"
    },
    "result": { // result, object. null in case of error.
        "preimage": "0123456789abcdef..." // command-related data
    }
}
       */
    var responseProm = Nostr.instance.relaysService
        .startEventsSubscription(
          relays: [uri.queryParameters['relay']!],
          request: NostrRequest(filters: [
            NostrFilter(kinds: [23195], e: [paymentRequest.id!], limit: 1)
          ]),
        )
        .stream
        .map((e) {
          print('Received from relay: $e');
          var response = Nip04().decrypt(
            uri.queryParameters['secret']!,
            uri.host,
            e.content!,
          );
        })
        .first;

    // Trigger the pa_invoice request
    NostrEventOkCommand resp = await Nostr.instance.relaysService
        .sendEventToRelaysAsync(paymentRequest,
            timeout: Duration(seconds: 5),
            relays: [uri.queryParameters['relay']!]);

    if (resp.isEventAccepted!) {
      logger.i('Sent payment request to relay: $resp');
    } else {
      throw Exception(
          'Failed to send payment request to relay: ${resp.message}');
    }

    await responseProm;
  }
}
