import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart'
    show ThreadCubitState, ThreadCubit;
import 'package:hostr/logic/thread/thread_header_resolver.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/reservation/timeline.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import '../flow/payment/payment_method/payment_method.dart';
import 'payment_status_chip.dart';

class ReservationListItem extends StatelessWidget {
  final ThreadHeaderResolution? resolution;
  final ProfileMetadata listingProfile;

  const ReservationListItem({
    super.key,
    this.resolution,
    required this.listingProfile,
  });

  List<Widget> _buildActionButtons(
    BuildContext context,
    ThreadCubitState state,
  ) {
    final resolvedActions =
        resolution?.actions ?? const <ThreadHeaderActionType>[];
    if (resolvedActions.isEmpty) {
      return const [];
    }

    FilledButton actionButton(String label, VoidCallback? onPressed) {
      return FilledButton.tonal(
        onPressed: onPressed,
        child: Text(label),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    void notImplemented() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action not implemented yet')),
      );
    }

    final escrowPubkey = resolution?.escrowPubkey;

    final children = <Widget>[];

    for (final action in resolvedActions) {
      switch (action) {
        case ThreadHeaderActionType.cancel:
          children.add(
            actionButton(
              'Cancel',
              state.isCancellingReservation
                  ? null
                  : () => context.read<ThreadCubit>().cancelMyReservation(),
            ),
          );
          break;
        case ThreadHeaderActionType.messageEscrow:
          if (escrowPubkey != null) {
            children.add(
              actionButton('Message Escrow', () {
                context.read<ThreadCubit>().addParticipant(escrowPubkey);
              }),
            );
          }
          break;
        case ThreadHeaderActionType.refund:
          children.add(actionButton('Refund', notImplemented));
          break;
        case ThreadHeaderActionType.claim:
          final escrowService = resolution?.escrowService;
          final tradeId = resolution?.lastReservationRequest?.getDtag();

          print(
            'building claim button for escrowService: $escrowService, tradeId: $tradeId',
          );

          if (escrowService == null || tradeId == null || tradeId.isEmpty) {
            break;
          }

          final hostr = getIt<Hostr>();
          final contract = hostr.evm
              .getChainForEscrowService(escrowService)
              .getSupportedEscrowContract(escrowService);

          final claimParams = EscrowClaimParams(
            tradeId: tradeId,
            escrowService: escrowService,
          );

          children.add(
            FutureBuilder<bool>(
              future: contract.canClaim(
                claimParams.toContractParams(hostr.auth.getActiveEvmKey()),
              ),
              builder: (context, snapshot) {
                print(
                  'canClaim snapshot: ${snapshot.data}, error: ${snapshot.error}',
                );
                final canClaim = snapshot.data == true;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                return actionButton(
                  isLoading ? 'Claiming…' : 'Claim',
                  (true && !state.isClaimingEscrow)
                      ? () => hostr.escrow.claim(claimParams).execute()
                      : null,
                );
              },
            ),
          );
          break;
        case ThreadHeaderActionType.accept:
          final reservationRequest = resolution?.lastReservationRequest;
          if (reservationRequest != null) {
            children.add(
              actionButton('Accept', () async {
                final threadState = context.read<ThreadCubit>().state;
                final reservationMessage =
                    threadState.threadState.reservationRequests.last;
                await context.read<Hostr>().reservations.accept(
                  reservationMessage,
                  reservationRequest,
                  reservationRequest.pubKey,
                );
              }),
            );
          }
          break;
        case ThreadHeaderActionType.counter:
          children.add(actionButton('Counter', notImplemented));
          break;
        case ThreadHeaderActionType.pay:
          children.add(
            actionButton('Pay', () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return PaymentMethodWidget(
                    counterparty: listingProfile,
                    reservationRequest: resolution!.lastReservationRequest!,
                  );
                },
              );
            }),
          );
          break;
      }
    }

    return children;
  }

  Widget buildActions(BuildContext context, ThreadCubitState state) {
    final children = _buildActionButtons(context, state);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }

  Widget buildActionsRight(BuildContext context, ThreadCubitState state) {
    final children = _buildActionButtons(context, state);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThreadCubit, ThreadCubitState>(
      builder: (context, state) {
        final isReservationRequestOnly =
            resolution?.source == ThreadHeaderSource.reservationRequest;

        if (isReservationRequestOnly) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: CustomPadding(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: buildDescription(context, state)),
                  const SizedBox(width: 12),
                  buildActionsRight(context, state),
                ],
              ),
            ),
          );
        }

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: ExpansionTile(
            splashColor: Colors.transparent,
            tilePadding: EdgeInsets.all(kDefaultPadding.toDouble()),
            shape: const Border(),
            collapsedShape: const Border(),
            title: buildDescription(context, state),
            children: [
              CustomPadding(
                top: 0,
                bottom: 0,
                child: ReservationTimeline(
                  state: state.threadState,
                  hostPubKey: listingProfile.pubKey,
                ),
              ),
              CustomPadding(child: buildActions(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget buildDescription(BuildContext context, ThreadCubitState state) {
    final reservationStart = resolution?.reservation?.parsedContent.start;
    final reservationEnd = resolution?.reservation?.parsedContent.end;
    final requestStart =
        resolution?.lastReservationRequest?.parsedContent.start;
    final requestEnd = resolution?.lastReservationRequest?.parsedContent.end;

    final dateStart =
        reservationStart ??
        requestStart ??
        state.threadState.subscriptions.reservations.first.parsedContent.start;
    final dateEnd =
        reservationEnd ??
        requestEnd ??
        state.threadState.subscriptions.reservations.first.parsedContent.end;
    return Row(
      children: [
        SmallListingCarousel(width: 100, height: 100, listing: state.listing!),

        Expanded(
          child: CustomPadding(
            left: 1,
            right: 0,
            bottom: 0,
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.listing!.parsedContent.title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4.0),
                Text(
                  formatDateRangeShort(
                    DateTimeRange(start: dateStart, end: dateEnd),
                    Localizations.localeOf(context),
                  ),
                ),
                const CustomPadding(top: 0.2, bottom: 0),

                if (resolution?.lastReservationRequest != null) ...[
                  Text(
                    formatAmount(
                      resolution!.lastReservationRequest!.parsedContent.amount,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const CustomPadding(top: 0.2, bottom: 0),
                ],

                PaymentStatusChip(
                  state:
                      state.threadState.subscriptions.paymentEvents.isNotEmpty
                      ? state.threadState.subscriptions.paymentEvents.last
                      : null,
                ),

                if (resolution?.isBlocked == true) ...[
                  const CustomPadding(top: 0.2, bottom: 0),
                  Text(
                    resolution?.blockedReason ??
                        'This reservation is not available.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],

                // const CustomPadding(top: 0.2, bottom: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
