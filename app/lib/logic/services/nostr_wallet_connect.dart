import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/config/main.dart';
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
  NostrSource nostr = getIt<NostrSource>();

  parseNWC(String nwcString) {
    Uri nwcUri = Uri.parse(nwcString);
    assert(nwcUri.scheme == 'nostr+walletconnect');
    assert(nwcUri.queryParameters.containsKey('relay'));

    /// Check that relay url correct as well
    Uri.parse(nwcUri.queryParameters['relay']!);
    return nwcUri;
  }

  /// User pasted/scanned a NWC from their wallet
  /// e.g. nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  save(String uri) async {
    // Parse the NWC string, check protocol, secret, relay
    parseNWC(uri);
    logger.i('Saving NWC: $uri');
    await nwcStorage.set([uri.toString()]);
  }

  methodAndResponse(NwcMethod request) async {
    var nwc = await nwcStorage.get();
    Uri uri = parseNWC(nwc.first);

    NostrKeyPairs keyPair = Nostr.instance.keysService
        .generateKeyPairFromExistingPrivateKey(uri.queryParameters['secret']!);

    String content = JsonEncoder().convert({
      "method": request.method, // method, string
      "params": request.params.toJson()
    });
    String encryptedContent =
        Nip04().encrypt(uri.queryParameters['secret']!, uri.host, content);

    NostrEvent requestEvent = NostrEvent.fromPartialData(
        tags: [
          ['p', uri.host]
        ],
        kind: NOSTR_KIND_NWC_REQUEST,
        content: encryptedContent,
        keyPairs: keyPair);
    logger.i('Request event constructed: $requestEvent');

    var responseProm = nostr
        .startRequest(
          relays: [uri.queryParameters['relay']!],
          onEose: (relay, ease) => false,
          request: NostrRequest(filters: [
            NostrFilter(
                kinds: [NOSTR_KIND_NWC_RESPONSE],
                e: [requestEvent.id!],
                limit: 1)
          ]),
        )
        .stream
        .map((e) {
          logger.t('Received from relay: $e');
          var response = Nip04().decrypt(
            uri.queryParameters['secret']!,
            uri.host,
            e.content!,
          );

          /// TODO encrypted content, how to pass secret to the unwrap event?
          return NwcRequest.fromNostrEvent(e);
        })
        .first;

    /// Trigger the NWC request
    NostrEventOkCommand resp = await nostr.sendEventToRelaysAsync(
        event: requestEvent, relays: [uri.queryParameters['relay']!]);

    if (resp.isEventAccepted!) {
      logger.i('Sent payment request to relay: $resp');
    } else {
      throw Exception(
          'Failed to send payment request to relay: ${resp.message}');
    }

    await responseProm;
  }

  payInvoice(NwcMethodPayInvoiceParams p) async {
    return methodAndResponse(NwcMethodPayInvoice(params: p));
  }

  lookupInvoice(NwcMethodLookupInvoiceParams p) async {
    return methodAndResponse(NwcMethodLookupInvoice(params: p));
  }

  makeInvoice(NwcMethodMakeInvoiceParams p) async {
    return methodAndResponse(NwcMethodMakeInvoice(params: p));
  }

  getInfo() async {
    return methodAndResponse(NwcMethodGetInfo());
  }

  getBalance() async {
    return methodAndResponse(NwcMethodGetBalance());
  }

  /// Looks up wallet info without relying on request/response
  getWalletInfo(Uri nwc) async {
    var infoEvents = await nostr.startRequestAsync(
      relays: [nwc.queryParameters['relay']!],
      request: NostrRequest(filters: [
        NostrFilter(kinds: [NOSTR_KIND_NWC_INFO], p: [nwc.host], limit: 1)
      ]),
    );
    var firstInfoEvent = infoEvents.first;
    assert(firstInfoEvent.content != null);
    assert(firstInfoEvent.content!.contains('pay_invoice'));
    return firstInfoEvent;
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
}
