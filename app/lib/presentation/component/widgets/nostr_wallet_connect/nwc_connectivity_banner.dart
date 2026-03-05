import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/nwc_connectivity.cubit.dart';

/// Listens to [NwcConnectivityCubit] and shows / hides a [SnackBar] when
/// the user has a wallet saved but all NWC connections have failed.
class NwcConnectivityBanner extends StatefulWidget {
  final Widget child;

  const NwcConnectivityBanner({super.key, required this.child});

  @override
  State<NwcConnectivityBanner> createState() => _NwcConnectivityBannerState();
}

class _NwcConnectivityBannerState extends State<NwcConnectivityBanner> {
  bool _snackBarVisible = false;

  void _onStateChanged(BuildContext context, NwcConnectivityState state) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (state.walletDisconnected && !_snackBarVisible) {
      _snackBarVisible = true;
      final colorScheme = Theme.of(context).colorScheme;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Wallet connection failed',
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
    } else if (!state.walletDisconnected && _snackBarVisible) {
      _snackBarVisible = false;
      messenger.hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NwcConnectivityCubit, NwcConnectivityState>(
      listener: _onStateChanged,
      child: widget.child,
    );
  }
}

/// Presentational view of the NWC connectivity banner.
///
/// Extracted so it can be rendered standalone in widgetbook / tests.
class NwcConnectivityBannerView extends StatelessWidget {
  final int connectedCount;
  final int totalConnections;

  const NwcConnectivityBannerView({
    super.key,
    required this.connectedCount,
    required this.totalConnections,
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
            Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Wallet connection failed — '
                '$connectedCount/$totalConnections wallets connected',
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
