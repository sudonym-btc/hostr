import 'dart:async';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_operation.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/repositories/lnurl_transport.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/ndk.dart' hide Zaps;

import 'pay_models.dart';

// Callback/completed details are defined in LnUrlWorkflow

class ZapPayOperation
    extends
        PayOperation<
          ZapPayParameters,
          ZapResolvedDetails,
          LightningCallbackDetails,
          ZapCompletedDetails
        > {
  final Zaps zaps;
  final LnurlTransport lnurlTransport = LnurlTransportHttpImpl(
    HttpRequestDS(http.Client()),
  );
  late final Lnurl lnurl = Lnurl(transport: lnurlTransport);

  StreamWithStatus<Nip01Event>? _zapReceiptStream;
  StreamSubscription<Nip01Event>? _zapReceiptSubscription;
  Timer? _receiptTimeout;
  String? _zapReceiptId;

  ZapPayOperation({
    required super.params,
    required this.zaps,
    required super.nwc,
  });

  @override
  Future<ZapCompletedDetails> completer() async {
    final activeConnection = nwc.getActiveConnection();
    if (activeConnection == null) {
      throw Exception('No active NWC connection');
    }

    final response = await nwc.payInvoice(
      activeConnection,
      callbackDetails!.invoice.paymentRequest,
    );
    return ZapCompletedDetails(
      preimage: response.preimage,
      zapReceiptId: _zapReceiptId,
      confirmedByZapReceipt: false,
    );
  }

  @override
  Future<void> complete() async {
    emit(PayInFlight(params: params));

    if (nwc.getActiveConnection() == null) {
      emit(
        PayExternalRequired(params: params, callbackDetails: callbackDetails!),
      );

      await _listenForExternalZapReceipt();
      return;
    }

    try {
      completedDetails = await completer();
      emit(PayCompleted(params: params, details: completedDetails!));
    } catch (e) {
      emit(PayFailed(e.toString(), params: params));
      rethrow;
    } finally {
      await close();
    }
  }

  @override
  Future<LightningCallbackDetails> finalizer() async {
    final lnurlProviderPubKey =
        (resolvedDetails as ZapResolvedDetails).response.nostrPubkey;
    if (lnurlProviderPubKey == null || lnurlProviderPubKey.isEmpty) {
      throw Exception('LNURL does not expose a Nostr recipient pubkey');
    }

    final zapTargetPubKey = _zapTargetPubKey(
      fallbackPubKey: lnurlProviderPubKey,
    );

    _zapReceiptId ??= 'hostr-zap-${DateTime.now().microsecondsSinceEpoch}';

    final activeKeyPair = getIt<Hostr>().auth.activeKeyPair;
    if (activeKeyPair == null || activeKeyPair.privateKey == null) {
      throw Exception('Cannot create zap request without active signing key');
    }

    final relayTags = _relayTags();
    if (relayTags.isEmpty) {
      throw Exception('Cannot create zap request without at least one relay');
    }

    final zapRequest = Nip01Utils.signWithPrivateKey(
      privateKey: activeKeyPair.privateKey!,
      event: ZapRequest(
        pubKey: activeKeyPair.publicKey,
        tags: [
          ['p', zapTargetPubKey],
          ['amount', (params.amount!.getInSats.toInt() * 1000).toString()],
          ['relays', ...relayTags],
          ['lnurl', params.to],
          if (params.event?.id != null) ['e', params.event!.id],
        ],
        content: [
          if ((params.comment ?? '').trim().isNotEmpty) params.comment!.trim(),
          _zapReceiptId!,
        ].join(' | '),
      ),
    );

    logger.d('Fetching invoice for zap with params: ${state.params}');
    final invoice = await lnurl.fetchInvoice(
      lnurlResponse: (resolvedDetails as ZapResolvedDetails).response,
      amountSats: params.amount!.getInSats.toInt(),
      zapRequest: ZapRequest.nip01Event(event: zapRequest),
    );
    logger.i('Fetched invoice for zap: $invoice');
    if (invoice == null) {
      throw Exception('Failed to fetch invoice for zap');
    }
    return LightningCallbackDetails(
      invoice: Bolt11PaymentRequest(invoice.invoice),
    );
  }

  @override
  Future<ZapResolvedDetails> resolver() async {
    final lnurlParams = await lnurl.getLnurlResponse(
      Lnurl.getLud16LinkFromLud16(state.params.to)!,
    );
    // @todo: verify nostr pubkey same as in params

    logger.i('Resolved LNURL params: ${lnurlParams}');
    // lnurlParams.
    if (lnurlParams == null || lnurlParams.callback == null) {
      throw Exception('Failed to resolve LNURL parameters');
    }

    logger.i(
      'Resolved LNURL params: minSendable ${lnurlParams.minSendable}, maxSendable ${lnurlParams.maxSendable}, commentAllowed ${lnurlParams.commentAllowed}, nostrPubkey ${lnurlParams.nostrPubkey}, metadata ${lnurlParams.metadata}, callback ${lnurlParams.callback}',
    );

    return ZapResolvedDetails(
      response: lnurlParams,
      minAmount: lnurlParams.minSendable!,
      maxAmount: lnurlParams.maxSendable!,
      commentAllowed: lnurlParams.commentAllowed ?? 0,
    );
  }

  Future<void> _listenForExternalZapReceipt() async {
    final lnurlProviderPubKey =
        (resolvedDetails as ZapResolvedDetails).response.nostrPubkey;
    if (lnurlProviderPubKey == null || lnurlProviderPubKey.isEmpty) {
      emit(
        PayFailed(
          'Cannot track external zap completion without recipient nostr pubkey',
          params: params,
        ),
      );
      await close();
      return;
    }

    final zapTargetPubKey = _zapTargetPubKey(
      fallbackPubKey: lnurlProviderPubKey,
    );

    logger.d(
      'Subscribing to zap receipts for pubkey $zapTargetPubKey with receipt id $_zapReceiptId',
    );

    final expectedInvoice = callbackDetails!.invoice.paymentRequest;
    final expectedHash = _paymentHash(callbackDetails!.invoice);

    await _cancelReceiptWatch();

    _zapReceiptStream = zaps.subscribeZapReceipts(
      pubkey: zapTargetPubKey,
      // eventId: params.event?.id,
    );

    _receiptTimeout = Timer(const Duration(minutes: 5), () {
      if (isClosed) {
        return;
      }
      emit(PayExpired(params: params));
      unawaited(close());
    });

    _zapReceiptSubscription = _zapReceiptStream!.stream.listen(
      (event) async {
        logger.d('Received zap receipt event: ${event}');
        if (isClosed) {
          return;
        }

        final receipt = ZapReceipt.fromEvent(event);
        if (!_matchesReceipt(
          receipt: receipt,
          expectedInvoice: expectedInvoice,
          expectedHash: expectedHash,
          expectedReceiptId: _zapReceiptId,
          expectedProviderPubKey: lnurlProviderPubKey,
          expectedRecipientPubKey: zapTargetPubKey,
        )) {
          return;
        }

        completedDetails = ZapCompletedDetails(
          preimage: receipt.preimage,
          zapReceiptEventId: event.id,
          zapReceiptId: _zapReceiptId,
          confirmedByZapReceipt: true,
        );

        emit(PayCompleted(params: params, details: completedDetails!));
        await close();
      },
      onError: (error, stackTrace) {
        if (isClosed) {
          return;
        }
        emit(PayFailed(error.toString(), params: params));
        unawaited(close());
      },
    );
  }

  bool _matchesReceipt({
    required ZapReceipt receipt,
    required String expectedInvoice,
    required String? expectedHash,
    required String? expectedReceiptId,
    required String expectedProviderPubKey,
    required String expectedRecipientPubKey,
  }) {
    if ((receipt.pubKey ?? '').toLowerCase() !=
        expectedProviderPubKey.toLowerCase()) {
      return false;
    }

    if ((receipt.recipient ?? '').toLowerCase() !=
        expectedRecipientPubKey.toLowerCase()) {
      return false;
    }

    if (expectedReceiptId != null && expectedReceiptId.isNotEmpty) {
      final comment = receipt.comment ?? '';
      if (!comment.contains(expectedReceiptId)) {
        return false;
      }
    }

    if (receipt.bolt11 == expectedInvoice) {
      return true;
    }

    if (expectedHash == null ||
        receipt.bolt11 == null ||
        receipt.bolt11!.isEmpty) {
      return false;
    }

    try {
      final receiptInvoice = Bolt11PaymentRequest(receipt.bolt11!);
      final receiptHash = _paymentHash(receiptInvoice);
      return receiptHash != null && receiptHash == expectedHash;
    } catch (_) {
      return false;
    }
  }

  String? _paymentHash(Bolt11PaymentRequest invoice) {
    try {
      return invoice.tags
          .firstWhere((tag) => tag.type == 'payment_hash')
          .data
          .toLowerCase();
    } catch (_) {
      return null;
    }
  }

  String _zapTargetPubKey({required String fallbackPubKey}) {
    final eventPubKey = params.event?.pubKey;
    if (eventPubKey != null && eventPubKey.isNotEmpty) {
      return eventPubKey;
    }
    return fallbackPubKey;
  }

  List<String> _relayTags() {
    final relays = <String>{};

    for (final relay in getIt<Hostr>().config.bootstrapRelays) {
      final url = relay.trim();
      if (!(url.startsWith('ws://') || url.startsWith('wss://'))) {
        continue;
      }

      relays.add(url);

      // In local Docker, relay.hostr.development is usually plain WS on the
      // internal network. Add ws:// fallback so LNbits can publish zap receipts.
      try {
        final uri = Uri.parse(url);
        final host = uri.host.toLowerCase();
        final isLocalHost =
            host == 'localhost' || host.endsWith('.development');
        if (uri.scheme == 'wss' && isLocalHost) {
          relays.add(uri.replace(scheme: 'ws').toString());
        }
      } catch (_) {
        // ignore malformed URL here; NDK validation happens elsewhere.
      }
    }

    return relays.toList();
  }

  Future<void> _cancelReceiptWatch() async {
    _receiptTimeout?.cancel();
    _receiptTimeout = null;

    await _zapReceiptSubscription?.cancel();
    _zapReceiptSubscription = null;

    await _zapReceiptStream?.close();
    _zapReceiptStream = null;
  }

  @override
  Future<void> close() async {
    await _cancelReceiptWatch();
    await super.close();
  }
}
