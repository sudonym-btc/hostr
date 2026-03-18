import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_receipt.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/ndk.dart';

/// Displays a list of zap receipts for a given pubkey or lightning address.
///
/// Provide either [pubkey] directly, or [lud16] (e.g. `tips@lnbits1.example.com`)
/// which will be resolved via LNURL to discover the recipient's nostrPubkey.
class ZapListWidget extends StatefulWidget {
  final String? pubkey;
  final String? lud16;
  final String? eventId;
  final Widget Function(ZapReceipt) builder;

  const ZapListWidget({
    super.key,
    this.pubkey,
    this.lud16,
    this.eventId,
    required this.builder,
  }) : assert(
         pubkey != null || lud16 != null,
         'Either pubkey or lud16 must be provided',
       );
  // final String? originalEventId; @todo replaceable events

  @override
  ZapListWidgetState createState() => ZapListWidgetState();
}

class ZapListWidgetState extends State<ZapListWidget> {
  Stream<ZapReceipt>? _zapStream;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.pubkey != null) {
      _startFetch(widget.pubkey!);
    } else {
      _resolveLud16();
    }
  }

  Future<void> _resolveLud16() async {
    setState(() => _resolving = true);
    try {
      final lud16Link = Lnurl.getLud16LinkFromLud16(widget.lud16!);
      if (lud16Link == null) {
        setState(() {
          _error = 'Invalid lightning address: ${widget.lud16}';
          _resolving = false;
        });
        return;
      }
      final lnurl = Lnurl(
        transport: LnurlTransportHttpImpl(HttpRequestDS(http.Client())),
      );
      final response = await lnurl.getLnurlResponse(lud16Link);
      final nostrPubkey = response?.nostrPubkey;
      if (nostrPubkey == null || nostrPubkey.isEmpty) {
        setState(() {
          _error = 'Lightning address does not support Nostr zaps';
          _resolving = false;
        });
        return;
      }
      _startFetch(nostrPubkey);
      setState(() => _resolving = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _resolving = false;
      });
    }
  }

  void _startFetch(String pubkey) {
    final sws = getIt<Hostr>().zaps.subscribeZapReceipts(
      pubkey: pubkey,
      eventId: widget.eventId,
    );
    _zapStream = sws.stream.map((event) => ZapReceipt.fromEvent(event));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(AppLocalizations.of(context)!.errorWithDetails(_error!));
    }

    if (_resolving || _zapStream == null) {
      return const AppLoadingIndicator.medium();
    }

    return StreamBuilder(
      stream: _zapStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ZapReceiptWidget(zap: snapshot.data!);
        } else {
          if (snapshot.hasError) {
            return Text(
              AppLocalizations.of(
                context,
              )!.errorWithDetails(snapshot.error.toString()),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            return Container();
          }
          return const AppLoadingIndicator.medium();
        }
      },
    );
  }
}
