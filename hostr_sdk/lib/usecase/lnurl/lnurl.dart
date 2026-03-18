import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart' as ndk;
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/ndk.dart';

import '../../injection.dart';

/// Exposes LNURL utilities (LUD-16 resolution, invoice fetching) as a
/// singleton use case so callers don't have to wire up the HTTP transport
/// themselves.
@Singleton(env: Env.allButTestAndMock)
class LnurlUseCase {
  late final ndk.Lnurl _lnurl;

  LnurlUseCase() {
    _lnurl = ndk.Lnurl(
      transport: LnurlTransportHttpImpl(HttpRequestDS(http.Client())),
    );
  }

  /// Convert a LUD-16 address (e.g. `tips@domain.com`) to its
  /// `.well-known/lnurlp/` HTTPS link.
  ///
  /// Returns `null` if the format is invalid.
  String? getLud16LinkFromLud16(String lud16) {
    return ndk.Lnurl.getLud16LinkFromLud16(lud16);
  }

  /// Fetch the LNURL-pay parameters from a `.well-known/lnurlp/` link.
  Future<LnurlResponse?> getLnurlResponse(String link) {
    return _lnurl.getLnurlResponse(link);
  }

  /// Fetch a bolt11 invoice from the LNURL callback.
  Future<InvoiceResponse?> fetchInvoice({
    required LnurlResponse lnurlResponse,
    required int amountSats,
    ZapRequest? zapRequest,
    String? comment,
  }) {
    return _lnurl.fetchInvoice(
      lnurlResponse: lnurlResponse,
      amountSats: amountSats,
      zapRequest: zapRequest,
      comment: comment,
    );
  }
}

@Singleton(as: LnurlUseCase, env: [Env.test, Env.mock])
class MockLnurlUseCase extends LnurlUseCase {
  MockLnurlUseCase();

  @override
  String? getLud16LinkFromLud16(String lud16) {
    return ndk.Lnurl.getLud16LinkFromLud16(lud16);
  }

  @override
  Future<LnurlResponse?> getLnurlResponse(String link) async {
    return null;
  }

  @override
  Future<InvoiceResponse?> fetchInvoice({
    required LnurlResponse lnurlResponse,
    required int amountSats,
    ZapRequest? zapRequest,
    String? comment,
  }) async {
    return InvoiceResponse(invoice: '', amountSats: amountSats);
  }
}
