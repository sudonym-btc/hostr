import 'package:flutter/material.dart';
import 'package:hostr/presentation/theme.dart';
import 'package:hostr/route/notification_deep_link_handler.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:toastification/toastification.dart';

typedef NotificationOverlayStateProvider = OverlayState? Function();

class InAppNotificationToast {
  static final _logger = CustomLogger(tag: 'in-app-notification-toast');
  static NotificationOverlayStateProvider? _overlayStateProvider;

  static void setOverlayStateProvider(
    NotificationOverlayStateProvider provider,
  ) {
    _overlayStateProvider = provider;
  }

  static void clearOverlayStateProvider(
    NotificationOverlayStateProvider provider,
  ) {
    if (identical(_overlayStateProvider, provider)) {
      _overlayStateProvider = null;
    }
  }

  static void show({String? title, String? body, String? payload}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNow(title: title, body: body, payload: payload);
    });
  }

  static void _showNow({String? title, String? body, String? payload}) {
    final overlayState = _overlayStateProvider?.call();
    if (overlayState == null || !overlayState.mounted) {
      _logger.w('No overlay state available for in-app notification toast');
      return;
    }

    final colorScheme = _notificationColorScheme();
    final notificationPayload = payload;
    final hasPayload =
        notificationPayload != null && notificationPayload.isNotEmpty;

    try {
      toastification.show(
        overlayState: overlayState,
        type: ToastificationType.info,
        style: ToastificationStyle.minimal,
        title: Text(title?.isNotEmpty == true ? title! : 'Hostr'),
        description: body?.isNotEmpty == true ? Text(body!) : null,
        primaryColor: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHigh,
        foregroundColor: colorScheme.onSurface,
        borderSide: BorderSide(color: colorScheme.outlineVariant),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 10),
        showIcon: false,
        showProgressBar: true,
        closeOnClick: hasPayload,
        callbacks: hasPayload
            ? ToastificationCallbacks(
                onTap: (notification) {
                  toastification.dismiss(notification);
                  dispatchNotificationPayload(notificationPayload);
                },
              )
            : const ToastificationCallbacks(),
        onHoverMouseCursor: hasPayload ? SystemMouseCursors.click : null,
      );
    } catch (e, st) {
      _logger.e(
        'Failed to show in-app notification toast',
        error: e,
        stackTrace: st,
      );
    }
  }

  static ColorScheme _notificationColorScheme() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return getTheme(brightness == Brightness.dark).colorScheme;
  }
}
