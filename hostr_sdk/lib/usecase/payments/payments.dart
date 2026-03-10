import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';

import '../../util/custom_logger.dart';
import '../auth/auth.dart';
import '../escrow/escrow.dart';
import '../metadata/metadata.dart';
import '../nwc/nwc.dart';
import '../zaps/zaps.dart';
import 'operations/bolt11_operation.dart';
import 'operations/lnurl_operation.dart';
import 'operations/pay_models.dart';
import 'operations/pay_operation.dart';
import 'operations/zap_operation.dart';

@Singleton()
class Payments {
  final CustomLogger logger;
  late final Zaps zaps;
  late final Nwc nwc;
  final MetadataUseCase metadata;
  final EscrowUseCase escrow;
  final Auth auth;

  Payments({
    required this.zaps,
    required this.nwc,
    required CustomLogger logger,
    required this.escrow,
    required this.metadata,
    required this.auth,
  }) : logger = logger.scope('payments');

  Future<String?> getMyInvoice(
    int amountSats, {
    String? description,
  }) => logger.span('getMyInvoice', () async {
    if (nwc.getActiveConnection() != null) {
      try {
        return (await nwc.makeInvoice(
          nwc.getActiveConnection()!,
          amountSats: amountSats,
          description: description,
        )).invoice;
      } catch (e) {
        logger.w(
          'Error creating invoice via NWC, continuing via profile lud url: $e',
        );
      }
    }
    // No NWC wallet connected – try LUD16 from user metadata first
    return await _tryCreateInvoiceFromLud16(amountSats);
  });

  /// Attempts to create an invoice from the current user's LUD16 lightning
  /// address. Returns the bolt11 invoice string on success, or `null` if the
  /// user has no LUD16 set or the LNURL flow fails.
  Future<String?> _tryCreateInvoiceFromLud16(
    int amountSats, {
    String? description,
  }) => logger.span('_tryCreateInvoiceFromLud16', () async {
    try {
      final pubkey = auth.activeKeyPair?.publicKey;
      if (pubkey == null) return null;

      final profile = await metadata.loadMetadata(pubkey);
      final lud16 = profile?.metadata.lud16;
      if (lud16 == null || lud16.isEmpty) {
        logger.d('No LUD16 set on user metadata');
        return null;
      }

      final lud16Link = Lnurl.getLud16LinkFromLud16(lud16);
      if (lud16Link == null) {
        logger.w('Failed to parse LUD16 address: $lud16');
        return null;
      }

      final lnurl = Lnurl(
        transport: LnurlTransportHttpImpl(HttpRequestDS(http.Client())),
      );
      final lnurlResponse = await lnurl.getLnurlResponse(lud16Link);
      if (lnurlResponse == null || lnurlResponse.callback == null) {
        logger.w('LNURL response invalid for $lud16');
        return null;
      }

      // @todo check allows comment
      final invoiceResponse = await lnurl.fetchInvoice(
        lnurlResponse: lnurlResponse,
        amountSats: amountSats,
        comment: description,
      );
      if (invoiceResponse == null || invoiceResponse.invoice.isEmpty) {
        logger.w('Failed to fetch invoice from LUD16 $lud16');
        return null;
      }

      logger.i('Successfully created invoice via LUD16 ($lud16)');
      return invoiceResponse.invoice;
    } catch (e) {
      logger.w('Error creating invoice from LUD16: $e');
      return null;
    }
  });

  PayOperation pay(PayParameters params) => logger.spanSync('pay', () {
    if (params is Bolt11PayParameters) {
      return Bolt11PayOperation(params: params, nwc: nwc, logger: logger);
    } else if (params is LnurlPayParameters) {
      return LnurlPayOperation(params: params, nwc: nwc, logger: logger);
    } else if (params is ZapPayParameters) {
      return ZapPayOperation(
        params: params,
        nwc: nwc,
        zaps: zaps,
        logger: logger,
      );
    } else {
      throw Exception('Unsupported payment type');
    }
  });
}
