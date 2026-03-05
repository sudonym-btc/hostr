import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/relay_connectivity.cubit.dart';

/// Listens to [RelayConnectivityCubit] and shows / hides a [SnackBar] when
/// more than 50% of relays are disconnected.
class RelayConnectivityBanner extends StatefulWidget {
  final Widget child;

  const RelayConnectivityBanner({super.key, required this.child});

  @override
  State<RelayConnectivityBanner> createState() =>
      _RelayConnectivityBannerState();
}

class _RelayConnectivityBannerState extends State<RelayConnectivityBanner> {
  bool _snackBarVisible = false;

  void _onStateChanged(BuildContext context, RelayConnectivityState state) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (state.majorityDisconnected && !_snackBarVisible) {
      _snackBarVisible = true;
      final colorScheme = Theme.of(context).colorScheme;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Relay connectivity issue — '
                  '${state.connectedRelays}/${state.totalRelays} relays connected',
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.errorContainer,
          duration: const Duration(days: 1), // persistent until dismissed
          dismissDirection: DismissDirection.down,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!state.majorityDisconnected && _snackBarVisible) {
      _snackBarVisible = false;
      messenger.hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RelayConnectivityCubit, RelayConnectivityState>(
      listener: _onStateChanged,
      child: widget.child,
    );
  }
}

/// Presentational view of the relay connectivity banner.
///
/// This is extracted so it can be rendered standalone in widgetbook / tests.
class RelayConnectivityBannerView extends StatelessWidget {
  final int connectedRelays;
  final int totalRelays;

  const RelayConnectivityBannerView({
    super.key,
    required this.connectedRelays,
    required this.totalRelays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Relay connectivity issue — '
                '$connectedRelays/$totalRelays relays connected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
