import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/nwc_connectivity.cubit.dart';

/// A banner that slides up from the bottom of the screen when the user has
/// a wallet saved but all NWC connections have failed.
class NwcConnectivityBanner extends StatelessWidget {
  final Widget child;

  const NwcConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BlocBuilder<NwcConnectivityCubit, NwcConnectivityState>(
            builder: (context, state) {
              return AnimatedSlide(
                offset: state.walletDisconnected
                    ? Offset.zero
                    : const Offset(0, 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: state.walletDisconnected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: SafeArea(
                    top: false,
                    child: NwcConnectivityBannerView(
                      connectedCount: state.connectedCount,
                      totalConnections: state.totalConnections,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
    );
  }
}
