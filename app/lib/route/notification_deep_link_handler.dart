import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

final StreamController<String> _notificationPayloadsController =
    StreamController<String>.broadcast();

void dispatchNotificationPayload(String payload) {
  if (payload.isEmpty) return;
  _notificationPayloadsController.add(payload);
}

void handleNotificationResponse(NotificationResponse notificationResponse) {
  final payload = notificationResponse.payload;
  if (payload == null || payload.isEmpty) return;
  dispatchNotificationPayload(payload);
}

class NotificationDeepLinkHandler {
  final AppRouter _router;
  final CustomLogger _logger = CustomLogger(tag: 'notification-link-handler');

  StreamSubscription<String>? _subscription;
  String? _activePayload;

  NotificationDeepLinkHandler({required AppRouter router}) : _router = router;

  void init() {
    _subscription ??= _notificationPayloadsController.stream.listen(
      _handlePayload,
      onError: (Object error, StackTrace stackTrace) {
        _logger.e(
          'Notification deeplink stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handlePayload(String payload) {
    if (payload.isEmpty || payload == _activePayload) return;

    final target = _NotificationDeepLinkTarget.tryParse(payload);
    if (target == null) {
      _logger.d('Ignoring unsupported notification payload: $payload');
      return;
    }

    _activePayload = payload;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.i('Opening notification deeplink: $payload');
      target.openOn(_router);
      _activePayload = null;
    });
  }
}

class _NotificationDeepLinkTarget {
  final String route;
  final Map<String, String> params;

  const _NotificationDeepLinkTarget({
    required this.route,
    this.params = const {},
  });

  static _NotificationDeepLinkTarget? tryParse(String payload) {
    final jsonTarget = _tryParseJson(payload);
    if (jsonTarget != null) return jsonTarget;

    final uri = Uri.tryParse(payload);
    if (uri == null || uri.scheme != 'hostr') return null;

    if (uri.host == 'thread') {
      final threadId = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
      if (threadId == null || threadId.isEmpty) return null;
      return _NotificationDeepLinkTarget(
        route: 'thread',
        params: {'anchor': threadId},
      );
    }

    if (uri.host == 'root') {
      return const _NotificationDeepLinkTarget(route: 'root');
    }

    return null;
  }

  PageRouteInfo toRoute() {
    switch (route) {
      case 'thread':
        final anchor = params['anchor'];
        if (anchor != null && anchor.isNotEmpty) {
          return ThreadRoute(anchor: anchor);
        }
        return const RootRoute();
      case 'root':
        return const RootRoute();
      default:
        return const RootRoute();
    }
  }

  Future<void> openOn(AppRouter router) async {
    switch (route) {
      case 'thread':
        final anchor = params['anchor'];
        if (anchor != null && anchor.isNotEmpty) {
          await router.push(ThreadRoute(anchor: anchor));
          return;
        }
        await router.navigate(const RootRoute());
        return;
      case 'root':
        await router.navigate(const RootRoute());
        return;
      default:
        await router.navigate(const RootRoute());
        return;
    }
  }

  static _NotificationDeepLinkTarget? _tryParseJson(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;

      final route = decoded['route'];
      if (route is! String || route.isEmpty) return null;

      final params = <String, String>{};
      final rawParams = decoded['params'];
      if (rawParams is Map) {
        for (final entry in rawParams.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key is String && value is String) {
            params[key] = value;
          }
        }
      }

      return _NotificationDeepLinkTarget(route: route, params: params);
    } catch (_) {
      return null;
    }
  }
}
