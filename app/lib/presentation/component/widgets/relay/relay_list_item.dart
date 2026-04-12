import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/app_list_item.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/entities.dart';

class RelayListItemView extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? iconUrl;
  final ImageProvider? iconImage;
  final bool isConnected;
  final bool canRemove;
  final VoidCallback? onRemove;

  const RelayListItemView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconUrl,
    this.iconImage,
    required this.isConnected,
    required this.canRemove,
    this.onRemove,
  });

  @override
  State<RelayListItemView> createState() => _RelayListItemViewState();
}

class _RelayListItemViewState extends State<RelayListItemView> {
  bool _iconFailed = false;

  @override
  void didUpdateWidget(covariant RelayListItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconUrl != widget.iconUrl) {
      _iconFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveImage = _iconFailed ? null : widget.iconImage;
    return AppListItem(
      leading: AppListItemAvatar.status(
        color: widget.isConnected ? Colors.green : Colors.orange,
        foregroundImage: effectiveImage,
        onForegroundImageError: effectiveImage != null
            ? (_, _) {
                if (widget.iconUrl != null) {
                  _RelayIconCache.markFailed(widget.iconUrl!);
                }
                if (mounted && !_iconFailed) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_iconFailed) {
                      setState(() => _iconFailed = true);
                    }
                  });
                }
              }
            : null,
      ),
      trailing: widget.canRemove
          ? IconButton(icon: Icon(Icons.close), onPressed: widget.onRemove)
          : null,
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
    );
  }
}

/// Caches [NetworkImage] instances by URL so that parent rebuilds
/// (driven by the relay-connectivity stream) reuse the same provider.
///
/// URLs that have previously failed (404, etc.) are remembered in
/// [_failed] so we never create a second [NetworkImage] for them.
class _RelayIconCache {
  _RelayIconCache._();
  static final Map<String, NetworkImage> _cache = {};
  static final Set<String> _failed = {};

  /// Returns a cached [NetworkImage] for [url], or `null` if the URL
  /// previously failed to load.
  static NetworkImage? get(String url) {
    if (_failed.contains(url)) return null;
    return _cache.putIfAbsent(
      url,
      () => NetworkImage(
        url,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      ),
    );
  }

  /// Record that [url] should not be retried.
  static void markFailed(String url) {
    _failed.add(url);
    _cache.remove(url);
  }
}

class RelayListItemWidget extends StatelessWidget {
  final RelayInfo? relay;
  final RelayConnectivity connectivity;
  final bool canRemove;

  const RelayListItemWidget({
    super.key,
    required this.relay,
    required this.connectivity,
    this.canRemove = false,
  });

  static final RegExp _protocolPrefix = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

  @override
  Widget build(BuildContext context) {
    Uri uri = Uri.parse(connectivity.url);
    String displayHost = uri.host;
    final displayUrl = connectivity.url.replaceFirst(_protocolPrefix, '');
    final isConnected = connectivity.relayTransport?.isOpen() == true;
    final rawIcon = relay?.icon;
    final iconUrl = rawIcon != null && rawIcon.isNotEmpty ? rawIcon : null;
    final iconImage = iconUrl != null ? _RelayIconCache.get(iconUrl) : null;
    return RelayListItemView(
      title: relay?.name ?? displayHost,
      subtitle: displayUrl,
      iconUrl: iconUrl,
      iconImage: iconImage,
      isConnected: isConnected,
      canRemove: canRemove,
      onRemove: canRemove
          ? () async {
              await getIt<Hostr>().relays.remove(connectivity.url);
            }
          : null,
    );
  }
}
