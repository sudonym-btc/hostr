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
/// Provide either [pubkey] directly, or [lud16] (e.g. `tips@lnbits.example.com`)
/// which will be resolved via LNURL to discover the recipient's nostrPubkey.
class ZapListWidget extends StatefulWidget {
  final String? pubkey;
  final String? lud16;
  final String? eventId;
  final int? limit;
  final Widget Function(ZapReceipt) builder;

  const ZapListWidget({
    super.key,
    this.pubkey,
    this.lud16,
    this.eventId,
    this.limit = 5,
    required this.builder,
  }) : assert(
         pubkey != null || lud16 != null,
         'Either pubkey or lud16 must be provided',
       ),
       assert(limit == null || limit > 0, 'limit must be greater than zero');
  // final String? originalEventId; @todo replaceable events

  @override
  ZapListWidgetState createState() => ZapListWidgetState();
}

class ZapListWidgetState extends State<ZapListWidget> {
  StreamWithStatus<Nip01Event>? _sws;
  Stream<ZapReceipt>? _zapStream;
  final List<ZapReceipt> _zaps = [];
  StreamSubscription<ZapReceipt>? _subscription;
  StreamSubscription<StreamStatus>? _statusSub;
  bool _resolving = false;
  bool _live = false;
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
        if (!mounted) return;
        setState(() {
          _error = 'Invalid lightning address: ${widget.lud16}';
          _resolving = false;
        });
        return;
      }
      final response = await lnurl.getLnurlResponse(lud16Link);
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _resolving = false;
      });
    }
  }

  void _startFetch(String pubkey) {
    _sws = getIt<Hostr>().zaps.subscribeZapReceipts(
      pubkey: pubkey,
      eventId: widget.eventId,
      limit: widget.limit,
    );
    // ZapReceipt.fromEvent calls jsonDecode on the inner `description` tag.
    // Some zap clients embed literal control characters (e.g. newlines) in the
    // zap request content, producing invalid JSON that Dart's strict parser
    // rejects.  Skip those events rather than crashing the whole list.
    _zapStream = _sws!.stream.expand((event) {
      try {
        return [ZapReceipt.fromEvent(event)];
      } on FormatException {
        // Malformed zap request JSON – silently drop this receipt.
        return <ZapReceipt>[];
      }
    });
    _subscription = _zapStream!.listen(
      _addZap,
      onError: (e) => setState(() => _error = e.toString()),
    );
    // Track when the relay subscription goes live so we can
    // distinguish "still waiting" from "zero results".
    _statusSub = _sws!.status.listen((status) {
      if (!_live &&
          (status is StreamStatusLive || status is StreamStatusQueryComplete)) {
        if (mounted) setState(() => _live = true);
      }
    });
  }

  void _addZap(ZapReceipt zap) {
    if (!mounted) return;
    setState(() {
      _zaps.add(zap);
      _zaps.sort((a, b) => (b.paidAt ?? 0).compareTo(a.paidAt ?? 0));

      final limit = widget.limit;
      if (limit != null && _zaps.length > limit) {
        _zaps.removeRange(limit, _zaps.length);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_statusSub?.cancel());
    unawaited(_sws?.close());
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
      if (_live) return const SizedBox.shrink();
      return const AppLoadingIndicator.medium();
    }

    final spacing = AppSpacing.of(context);
    final children = <Widget>[];
    for (final zap in _zaps) {
      if (children.isNotEmpty) {
        children.add(SizedBox(width: spacing.chipSpacing));
      }
      children.add(widget.builder(zap));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
