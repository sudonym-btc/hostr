import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';

Uri parseNwc(String nwcString) {
  Uri nwcUri = Uri.parse(nwcString);
  assert(nwcUri.scheme == 'nostr+walletconnect');
  assert(nwcUri.queryParameters.containsKey('relay'));

  /// Check that relay url correct as well
  Uri.parse(nwcUri.queryParameters['relay']!);
  return nwcUri;
}

String parseSecret(Uri nwc) {
  return nwc.queryParameters['secret']!;
}

String parsePubkey(Uri nwc) {
  return nwc.host;
}

@Injectable(env: Env.allButTestAndMock)
class NwcService {
  CustomLogger logger = CustomLogger();
  KeyStorage keyStorage = getIt<KeyStorage>();
  NwcStorage nwcStorage = getIt<NwcStorage>();
  NostrService nostr = getIt<NostrService>();

  /// User pasted/scanned a NWC from their wallet
  /// e.g. nostr+walletconnect://b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c
  save(String uri) async {
    // Parse the NWC string, check protocol, secret, relay
    parseNwc(uri);
    await nwcStorage.set([uri.toString()]);
  }

  Future<NwcResponse> methodAndResponse(NwcMethod request) async {
    var nwc = await nwcStorage.getUri();
    if (nwc == null) {
      throw Exception('No NWC found');
    }

    NostrKeyPairs keyPair = Nostr.instance.keysService
        .generateKeyPairFromExistingPrivateKey(parseSecret(nwc));

    String content = JsonEncoder().convert({
      "method": request.method.toString().split('.').last, // method, string
      "params": request.params.toJson()
    });

    print(
        'Content: $content, secret: ${parseSecret(nwc)}, pubkey: ${parsePubkey(nwc)}');

    String encryptedContent =
        Nip04().encrypt(parseSecret(nwc), parsePubkey(nwc), content);

    NostrEvent requestEvent = NostrEvent.fromPartialData(
        tags: [
          /// Address the relay pubkey
          ['p', parsePubkey(nwc)]
        ],
        kind: NOSTR_KIND_NWC_REQUEST,
        content: encryptedContent,
        keyPairs: keyPair);
    logger.i('Request event constructed: $requestEvent');

    var responseProm = nostr
        .startRequest(
          relays: [nwc.queryParameters['relay']!],
          onEose: (relay, ease) => false,
          request: NostrRequest(filters: [
            NostrFilter(
                kinds: [NOSTR_KIND_NWC_RESPONSE],
                authors: [parsePubkey(nwc)],
                e: [requestEvent.id!],
                limit: 1)
          ]),
        )
        .stream
        .take(1)
        .first;

    /// Trigger the NWC request
    NostrEventOkCommand resp = await nostr.sendEventToRelaysAsync(
        event: requestEvent, relays: [nwc.queryParameters['relay']!]);

    print('resp $resp');
    if (resp.isEventAccepted!) {
      logger.i('Sent command request to relay: $resp');
    } else {
      throw Exception(
          'Failed to send command request to relay: ${resp.message}');
    }
    NwcResponse response = await responseProm as NwcResponse;
    logger.i('Response received: ${response.parsedContent}');
    return response;
  }

  Future<NwcResponse> payInvoice(NwcMethodPayInvoiceParams p) async {
    return methodAndResponse(NwcMethodPayInvoice(params: p));
  }

  lookupInvoice(NwcMethodLookupInvoiceParams p) async {
    return methodAndResponse(NwcMethodLookupInvoice(params: p));
  }

  makeInvoice(NwcMethodMakeInvoiceParams p) async {
    return methodAndResponse(NwcMethodMakeInvoice(params: p));
  }

  Future<NwcResponse> getInfo() async {
    return methodAndResponse(NwcMethodGetInfo());
  }

  getBalance() async {
    return methodAndResponse(NwcMethodGetBalance());
  }

  /// Looks up wallet info without relying on request/response
  Future<NwcInfo> getWalletInfo(Uri nwc) async {
    logger.i('Getting wallet info ${nwc.queryParameters['relay']}');
    var infoEvents = await nostr
        .startRequest<NwcInfo>(
          relays: [nwc.queryParameters['relay']!],
          onEose: (relay, ease) => false,
          request: NostrRequest(filters: [
            NostrFilter(
                kinds: [NOSTR_KIND_NWC_INFO],
                authors: [parsePubkey(nwc)],
                limit: 1)
          ]),
        )
        .stream
        .first;
    var firstInfoEvent = infoEvents;
    return firstInfoEvent as NwcInfo;
  }
}

@Injectable(as: NwcService, env: [Env.test, Env.mock])
class MockNostrWalletConnectService extends NwcService {
  // getWalletInfo(Uri nwc) async {
  //   return NostrEvent.fromPartialData(
  //       kind: 13194,
  //       content:
  //           "pay_invoice pay_keysend get_balance get_info make_invoice lookup_invoice list_transactions multi_pay_invoice multi_pay_keysend sign_message notifications",
  //       keyPairs: NostrKeyPairs.generate());
  // }

  @override
  Future<NwcResponse> methodAndResponse(NwcMethod request) async {
    Uri nwc = (await nwcStorage.getUri())!;
    NostrKeyPairs keyPair = Nostr.instance.keysService
        .generateKeyPairFromExistingPrivateKey(parseSecret(nwc));

    switch (request.method) {
      case NwcMethods.get_info:
        return NwcResponse.create(
            'e-random-id',
            parsePubkey(nwc),
            NwcResponseContent(
                result_type: NwcMethods.get_info,
                result: NwcMethodGetInfoResponse(
                    alias: 'Alby',

                    /// Yellow color
                    color: '#FFFF00',
                    pubkey: parsePubkey(nwc),
                    network: 'mainnet',
                    block_height: 1,
                    block_hash: "0101010",
                    methods: [
                      NwcMethods.pay_invoice,
                      NwcMethods.lookup_invoice,
                      NwcMethods.make_invoice
                    ],
                    notifications: [])),
            nwc);
      case NwcMethods.pay_invoice:
        return NwcResponse.create(
            'e-random-id',
            parsePubkey(nwc),
            NwcResponseContent(
                result_type: NwcMethods.pay_invoice,
                result: NwcMethodPayInvoiceResponse(
                    fees_paid: 10, preimage: 'lalalala')),
            nwc);
      default:
        throw Exception('Method not implemented');
    }
  }
}
