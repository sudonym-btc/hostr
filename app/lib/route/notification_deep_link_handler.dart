import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hostr/injection.dart';
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
  static final CustomLogger _targetLogger = CustomLogger(
    tag: 'notification-link-target',
  );

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

    if (uri.host == 'inbox') {
      return const _NotificationDeepLinkTarget(route: 'inbox');
    }

    return null;
  }

  PageRouteInfo toRoute() {
    switch (route) {
      case 'thread':
        final anchor = params['anchor'];
        if (anchor != null && anchor.isNotEmpty) {
          return TabShellRoute(
            children: [
              InboxRoute(children: [ThreadRoute(anchor: anchor)]),
            ],
          );
        }
        return const RootRoute();
      case 'root':
        return const RootRoute();
      case 'inbox':
        return const InboxRoute();
      default:
        return const RootRoute();
    }
  }

  Future<void> openOn(AppRouter router) async {
    switch (route) {
      case 'thread':
        final threadRef = params['anchor'];
        final anchor = await _resolveThreadAnchor(threadRef);
        if (anchor != null && anchor.isNotEmpty) {
          await router.navigate(
            TabShellRoute(
              children: [
                InboxRoute(children: [ThreadRoute(anchor: anchor)]),
              ],
            ),
          );
          return;
        }
        await router.navigate(TabShellRoute(children: [const InboxRoute()]));
        return;
      case 'root':
        await router.navigate(const RootRoute());
        return;
      case 'inbox':
        await router.navigate(TabShellRoute(children: [const InboxRoute()]));
        return;
      default:
        await router.navigate(const RootRoute());
        return;
    }
  }

  Future<String?> _resolveThreadAnchor(String? value) async {
    final ref = value?.trim();
    if (ref == null || ref.isEmpty) return null;

    for (var attempt = 0; attempt < 10; attempt++) {
      final anchor = _tryResolveThreadAnchor(ref);
      if (anchor != null) return anchor;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    return _tryResolveThreadAnchor(ref);
  }

  String? _tryResolveThreadAnchor(String ref) {
    try {
      final threads = getIt<Hostr>().messaging.threads;
      if (threads.threads.containsKey(ref)) return ref;

      // Older notification payloads used the trade id in hostr://thread/<id>.
      // ThreadRoute needs the conversation anchor, so map trade ids before
      // routing.
      return threads.findPreferredConversationIdByTradeId(ref);
    } catch (error, stackTrace) {
      // Startup can still be warming when a launch notification is handled.
      _targetLogger.d(
        'Unable to resolve notification thread ref yet: $ref',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
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
