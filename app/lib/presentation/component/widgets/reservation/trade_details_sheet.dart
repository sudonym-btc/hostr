import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web3dart/web3dart.dart';

import 'trade_timeline.dart';

void showTradeDetailsSheet(BuildContext context, TradeReady tradeState) {
  final trade = context.read<Trade>();
  showAppModal(
    context,
    builder: (_) => StreamBuilder<dynamic>(
      stream: Rx.merge([
        trade.transitions$.stream.map((_) => null),
        trade.payments$.stream.map((_) => null),
        trade.reservationGroup$.stream.map((_) => null),
      ]),
      initialData: null,
      builder: (context, _) {
        final transitions = trade.transitions$.items;
        final paymentEvents = trade.payments$.items;
        final reservationValidation = trade.reservationGroup$.items.lastOrNull;
        final reservationGroup = reservationValidation?.event;

        return ModalBottomSheet(
          title: 'Information',
          content: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HydratedTradeTimeline(
                    transitions: transitions,
                    paymentEvents: paymentEvents,
                    reservationGroup: reservationGroup,
                  ),
                  if (reservationValidation is Invalid<ReservationGroup>) ...[
                    Gap.vertical.lg(),
                    _ReservationRecords(
                      validatedReservationGroup: reservationValidation,
                      listing: tradeState.listing,
                      sellerPubkey: tradeState.sellerPubkey,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _HydratedTradeTimeline extends StatefulWidget {
  final List<ReservationTransition> transitions;
  final List<PaymentEvent> paymentEvents;
  final ReservationGroup? reservationGroup;

  const _HydratedTradeTimeline({
    required this.transitions,
    required this.paymentEvents,
    this.reservationGroup,
  });

  @override
  State<_HydratedTradeTimeline> createState() => _HydratedTradeTimelineState();
}

class _HydratedTradeTimelineState extends State<_HydratedTradeTimeline> {
  late String _fingerprint;
  late Future<Map<String, DateTime>> _timestampsFuture;

  @override
  void initState() {
    super.initState();
    _fingerprint = _eventsFingerprint(widget.paymentEvents);
    _timestampsFuture = _resolveEscrowTimestamps(widget.paymentEvents);
  }

  @override
  void didUpdateWidget(covariant _HydratedTradeTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextFingerprint = _eventsFingerprint(widget.paymentEvents);
    if (nextFingerprint != _fingerprint) {
      _fingerprint = nextFingerprint;
      _timestampsFuture = _resolveEscrowTimestamps(widget.paymentEvents);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, DateTime>>(
      future: _timestampsFuture,
      builder: (context, snapshot) {
        final timestamps = snapshot.data ?? const <String, DateTime>{};
        final hasPendingBlocks =
            snapshot.connectionState != ConnectionState.done &&
            _hasResolvableMissingBlocks(widget.paymentEvents, timestamps);

        if (hasPendingBlocks) {
          return const SizedBox(
            height: 56,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return TradeTimeline(
          transitions: widget.transitions,
          paymentEvents: widget.paymentEvents,
          reservationGroup: widget.reservationGroup,
          paymentEventTimestamp: (event) {
            if (event is EscrowEvent) {
              return timestamps[_escrowEventKey(event)] ??
                  event.block?.timestamp;
            }
            return null;
          },
        );
      },
    );
  }

  Future<Map<String, DateTime>> _resolveEscrowTimestamps(
    List<PaymentEvent> paymentEvents,
  ) async {
    final timestamps = <String, DateTime>{};
    final escrowEvents = paymentEvents.whereType<EscrowEvent>().toList();

    await Future.wait(
      escrowEvents.map((event) async {
        final key = _escrowEventKey(event);
        final block = event.block;
        if (block != null) {
          timestamps[key] = block.timestamp;
          return;
        }

        final chain = event.chain;
        if (chain == null) return;

        try {
          final resolvedBlock = await chain.getBlockInformation(
            blockNumber: BlockNum.exact(event.blockNum).toBlockParam(),
          );
          timestamps[key] = resolvedBlock.timestamp;
        } catch (_) {
          // Keep the popup usable even if an explorer/RPC hiccups while
          // resolving cosmetic timestamps.
        }
      }),
    );

    return timestamps;
  }

  bool _hasResolvableMissingBlocks(
    List<PaymentEvent> paymentEvents,
    Map<String, DateTime> timestamps,
  ) {
    return paymentEvents.whereType<EscrowEvent>().any(
      (event) =>
          event.block == null &&
          event.chain != null &&
          !timestamps.containsKey(_escrowEventKey(event)),
    );
  }

  String _eventsFingerprint(List<PaymentEvent> paymentEvents) {
    return paymentEvents
        .whereType<EscrowEvent>()
        .map(_escrowEventKey)
        .join('|');
  }
}

String _escrowEventKey(EscrowEvent event) {
  final txHash = switch (event) {
    EscrowFundedEvent funded => funded.transactionHash,
    EscrowReleasedEvent released => released.transactionHash,
    EscrowArbitratedEvent arbitrated => arbitrated.transactionHash,
    EscrowClaimedEvent claimed => claimed.transactionHash,
    _ => '',
  };
  return '${event.runtimeType}:${event.tradeId}:${event.blockNum}:$txHash';
}

class _ReservationRecords extends StatelessWidget {
  final Validation<ReservationGroup> validatedReservationGroup;
  final Listing listing;
  final String sellerPubkey;

  const _ReservationRecords({
    required this.validatedReservationGroup,
    required this.listing,
    required this.sellerPubkey,
  });

  @override
  Widget build(BuildContext context) {
    final pair = validatedReservationGroup;
    if (pair is Invalid<ReservationGroup>) {
      final reason = pair.reason;
      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservation errors',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Gap.vertical.xs(),
          Text(reason),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
