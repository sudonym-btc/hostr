import 'package:injectable/injectable.dart';

import '../../config.dart';
import '../../util/custom_logger.dart';
import '../auth/auth.dart';
import '../lnurl/lnurl.dart';
import '../metadata/metadata.dart';
import '../nwc/nwc.dart';
import '../zaps/zaps.dart';
import 'operations/bolt11_operation.dart';
import 'operations/lnurl_operation.dart';
import 'operations/pay_models.dart';
import 'operations/pay_operation.dart';
import 'operations/zap_operation.dart';

enum AutomaticInvoiceDestinationType {
  nwc,
  profileLightningAddress,
  missingProfileLightningAddress,
  invalidProfileLightningAddress,
}

class AutomaticInvoiceDestination {
  final AutomaticInvoiceDestinationType type;
  final String? label;
  final String? error;

  const AutomaticInvoiceDestination._({
    required this.type,
    this.label,
    this.error,
  });

  const AutomaticInvoiceDestination.nwc(String label)
    : this._(type: AutomaticInvoiceDestinationType.nwc, label: label);

  const AutomaticInvoiceDestination.profileLightningAddress(String lud16)
    : this._(
        type: AutomaticInvoiceDestinationType.profileLightningAddress,
        label: lud16,
      );

  const AutomaticInvoiceDestination.missingProfileLightningAddress()
    : this._(
        type: AutomaticInvoiceDestinationType.missingProfileLightningAddress,
        error: 'Cannot sweep without a profile lightning address',
      );

  const AutomaticInvoiceDestination.invalidProfileLightningAddress()
    : this._(
        type: AutomaticInvoiceDestinationType.invalidProfileLightningAddress,
        error: 'Cannot run with invalid profile lightning address',
      );

  bool get canCreateAutomatically =>
      type == AutomaticInvoiceDestinationType.nwc ||
      type == AutomaticInvoiceDestinationType.profileLightningAddress;
}

@Singleton()
class Payments {
  final CustomLogger _logger;
  late final Zaps _zaps;
  late final Nwc _nwc;
  final LnurlUseCase _lnurl;
  final MetadataUseCase _metadata;
  final Auth _auth;
  final HostrConfig _config;

  Payments({
    required Zaps zaps,
    required Nwc nwc,
    required LnurlUseCase lnurl,
    required CustomLogger logger,
    required MetadataUseCase metadata,
    required Auth auth,
    required HostrConfig config,
  }) : _zaps = zaps,
       _nwc = nwc,
       _lnurl = lnurl,
       _metadata = metadata,
       _auth = auth,
       _config = config,
       _logger = logger.scope('payments');

  Future<String?> getMyInvoice(
    int amountSats, {
    String? description,
  }) => _logger.span('getMyInvoice', () async {
    final activeConnection = _nwc.getActiveConnection();
    if (activeConnection != null) {
      try {
        return (await _nwc.makeInvoice(
          activeConnection,
          amountSats: amountSats,
          description: description,
        )).invoice;
      } catch (e) {
        _logger.w(
          'Error creating invoice via NWC, continuing via profile lud url: $e',
        );
      }
    }
    // No NWC wallet connected – try LUD16 from user metadata first
    return await _tryCreateInvoiceFromLud16(
      amountSats,
      description: description,
    );
  });

  Future<AutomaticInvoiceDestination> resolveAutomaticInvoiceDestination({
    bool verifyLightningAddress = true,
  }) => _logger.span('resolveAutomaticInvoiceDestination', () async {
    if (_nwc.getActiveConnection() != null) {
      return AutomaticInvoiceDestination.nwc(
        _nwc.getActiveConnectionName() ?? 'connected wallet',
      );
    }

    final pubkey = _auth.activeKeyPair?.publicKey;
    if (pubkey == null) {
      return const AutomaticInvoiceDestination.missingProfileLightningAddress();
    }

    final profile = await _metadata.loadMetadata(pubkey);
    final lud16 = profile?.metadata.lud16?.trim();
    if (lud16 == null || lud16.isEmpty) {
      return const AutomaticInvoiceDestination.missingProfileLightningAddress();
    }

    final lud16Link = _lnurl.getLud16LinkFromLud16(lud16);
    if (lud16Link == null) {
      return const AutomaticInvoiceDestination.invalidProfileLightningAddress();
    }

    if (verifyLightningAddress) {
      final response = await _lnurl.getLnurlResponse(lud16Link);
      if (response == null ||
          response.callback == null ||
          response.tag != 'payRequest') {
        return const AutomaticInvoiceDestination.invalidProfileLightningAddress();
      }
    }

    return AutomaticInvoiceDestination.profileLightningAddress(lud16);
  });

  /// Attempts to create an invoice from the current user's LUD16 lightning
  /// address. Returns the bolt11 invoice string on success, or `null` if the
  /// user has no LUD16 set or the LNURL flow fails.
  Future<String?> _tryCreateInvoiceFromLud16(
    int amountSats, {
    String? description,
  }) => _logger.span('_tryCreateInvoiceFromLud16', () async {
    try {
      final pubkey = _auth.activeKeyPair?.publicKey;
      if (pubkey == null) return null;

      final profile = await _metadata.loadMetadata(pubkey);
      final lud16 = profile?.metadata.lud16;
      if (lud16 == null || lud16.isEmpty) {
        _logger.d('No LUD16 set on user metadata');
        return null;
      }

      final lud16Link = _lnurl.getLud16LinkFromLud16(lud16);
      if (lud16Link == null) {
        _logger.w('Failed to parse LUD16 address: $lud16');
        return null;
      }

      final lnurlResponse = await _lnurl.getLnurlResponse(lud16Link);
      _logger.d(
        'LNURL response for LUD16 $lud16: '
        'callback=${lnurlResponse?.callback}, '
        'tag=${lnurlResponse?.tag}, '
        'minSendable=${lnurlResponse?.minSendable}, '
        'maxSendable=${lnurlResponse?.maxSendable}, '
        'commentAllowed=${lnurlResponse?.commentAllowed}, '
        'allowsNostr=${lnurlResponse?.allowsNostr}, '
        'metadata=${lnurlResponse?.metadata}',
      );
      if (lnurlResponse == null || lnurlResponse.callback == null) {
        _logger.w('LNURL response invalid for $lud16');
        return null;
      }

      // @todo check allows comment
      final invoiceResponse = await _lnurl.fetchInvoice(
        lnurlResponse: lnurlResponse,
        amountSats: amountSats,
        comment: description,
      );
      if (invoiceResponse == null || invoiceResponse.invoice.isEmpty) {
        _logger.w('Failed to fetch invoice from LUD16 $lud16');
        return null;
      }

      _logger.i(
        'Successfully created invoice via LUD16 ($lud16, $description)',
      );
      return invoiceResponse.invoice;
    } catch (e) {
      _logger.w('Error creating invoice from LUD16: $e');
      return null;
    }
  });

  PayOperation pay(PayParameters params) => _logger.spanSync('pay', () {
    if (params is Bolt11PayParameters) {
      return Bolt11PayOperation(params: params, nwc: _nwc, logger: _logger);
    } else if (params is LnurlPayParameters) {
      return LnurlPayOperation(
        params: params,
        lnurl: _lnurl,
        nwc: _nwc,
        logger: _logger,
      );
    } else if (params is ZapPayParameters) {
      return ZapPayOperation(
        params: params,
        nwc: _nwc,
        zaps: _zaps,
        auth: _auth,
        lnurl: _lnurl,
        bootstrapRelays: _config.bootstrapRelays,
        logger: _logger,
      );
    } else {
      throw Exception('Unsupported payment type');
    }
  });
}
