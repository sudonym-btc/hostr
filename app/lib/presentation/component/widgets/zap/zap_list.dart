import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
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
  final List<ZapReceipt> _zaps = [];
  StreamSubscription<ZapReceipt>? _subscription;
  bool _resolving = false;
  bool _done = false;
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
      final lnurl = getIt<Hostr>().lnurl;
      final lud16Link = lnurl.getLud16LinkFromLud16(widget.lud16!);
      if (lud16Link == null) {
        setState(() {
          _error = 'Invalid lightning address: ${widget.lud16}';
          _resolving = false;
        });
        return;
      }
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
    _subscription = _zapStream!.listen(
      (zap) => setState(() => _zaps.add(zap)),
      onError: (e) => setState(() => _error = e.toString()),
      onDone: () => setState(() => _done = true),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(AppLocalizations.of(context)!.errorWithDetails(_error!));
    }

    if (_resolving || _zapStream == null) {
      return const AppLoadingIndicator.medium();
    }

    if (_zaps.isEmpty) {
      if (_done) return const SizedBox.shrink();
      return const AppLoadingIndicator.medium();
    }

    final spacing = AppSpacing.of(context);
    return Wrap(
      spacing: spacing.chipSpacing,
      runSpacing: spacing.chipRunSpacing,
      children: _zaps.map((zap) => widget.builder(zap)).toList(),
    );
  }
}
