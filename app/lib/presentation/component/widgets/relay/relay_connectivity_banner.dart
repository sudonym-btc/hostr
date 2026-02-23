import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/cubit/relay_connectivity.cubit.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';

/// A banner that slides up from the bottom of the screen when more than 50%
/// of relays are disconnected.
class RelayConnectivityBanner extends StatelessWidget {
  final Widget child;

  const RelayConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BlocBuilder<RelayConnectivityCubit, RelayConnectivityState>(
            builder: (context, state) {
              return AnimatedSlide(
                offset: state.majorityDisconnected
                    ? Offset.zero
                    : const Offset(0, 1),
                duration: kAnimationDuration,
                curve: kAnimationCurve,
                child: AnimatedOpacity(
                  opacity: state.majorityDisconnected ? 1.0 : 0.0,
                  duration: kAnimationDuration,
                  child: SafeArea(
                    top: false,
                    child: RelayConnectivityBannerView(
                      connectedRelays: state.connectedRelays,
                      totalRelays: state.totalRelays,
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(kSpace3),
      padding: const EdgeInsets.symmetric(
        horizontal: kSpace4,
        vertical: kSpace3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(kSpace3),
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
          Icon(Icons.wifi_off, color: theme.colorScheme.onError),
          Gap.horizontal.custom(kSpace3),
          Expanded(
            child: Text(
              'Relay connectivity issue — '
              '$connectedRelays/$totalRelays relays connected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
