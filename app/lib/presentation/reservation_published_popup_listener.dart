import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/reservation/trade_header.dart';
import 'package:hostr/presentation/component/widgets/ui/gap.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class ReservationPublishedPopupListener extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const ReservationPublishedPopupListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  @override
  State<ReservationPublishedPopupListener> createState() =>
      _ReservationPublishedPopupListenerState();
}

class _ReservationPublishedPopupListenerState
    extends State<ReservationPublishedPopupListener> {
  final Set<String> _shownReservationIds = {};
  StreamSubscription<Order>? _subscription;
  bool _popupVisible = false;

  @override
  void initState() {
    super.initState();
    // CrudUseCase only emits updates after relay broadcast succeeds. Listening
    // here keeps the popup tied to a real reservation publish instead of relay
    // replays or pre-broadcast optimistic state.
    _subscription = getIt<Hostr>().orders.updates
        .where((reservation) => reservation.isCommit)
        .where((reservation) => reservation.proof != null)
        .listen(_showTripBookedPopup);
  }

  void _showTripBookedPopup(Order reservation) {
    final id = reservation.id;
    final tradeId = reservation.getDtag();
    if (id.isEmpty ||
        tradeId == null ||
        tradeId.isEmpty ||
        _popupVisible ||
        !_shownReservationIds.add(id)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final navigator = widget.navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) {
        _shownReservationIds.remove(id);
        return;
      }

      _popupVisible = true;
      await navigator.push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => TripBookedPopupPage(
            tradeId: tradeId,
            participants: {
              reservation.pubKey,
              ...reservation.parsedTags.getTags('p'),
            },
          ),
        ),
      );
      _popupVisible = false;
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class TripBookedPopupPage extends StatelessWidget {
  final String tradeId;
  final Iterable<String> participants;

  const TripBookedPopupPage({
    super.key,
    required this.tradeId,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    // The trade-scoped key lets drive tests assert that the popup belongs to
    // the reservation being paid, rather than accidentally dismissing a stale
    // popup from another trade.
    return TripBookedPopupView(
      key: ValueKey('trip_booked_popup_$tradeId'),
      tradeSummary: TradeHeader(
        tradeId: tradeId,
        participants: participants,
        showActions: false,
      ),
      doneButtonKey: ValueKey('trip_booked_done_button_$tradeId'),
      onDone: () => Navigator.of(context).pop(),
    );
  }
}

class TripBookedPopupView extends StatelessWidget {
  final Widget tradeSummary;
  final Key? doneButtonKey;
  final VoidCallback onDone;

  const TripBookedPopupView({
    super.key,
    required this.tradeSummary,
    this.doneButtonKey,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: AppPane(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 40,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                    Gap.vertical.lg(),
                    Text(
                      'Trip booked! Your host should confirm soon.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap.vertical.lg(),
                    tradeSummary,
                    Gap.vertical.lg(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key:
                            doneButtonKey ??
                            const ValueKey('trip_booked_done_button'),
                        onPressed: onDone,
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
