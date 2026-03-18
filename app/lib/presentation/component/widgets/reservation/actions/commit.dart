import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/messaging/thread.cubit.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/claim/escrow_claim.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/escrow/release/escrow_release.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../trade_timeline.dart';

typedef _TradeMenuItem = ({String label, IconData icon, VoidCallback onTap});

class CommitMenu extends StatelessWidget {
  final TradeReady tradeState;
  const CommitMenu({super.key, required this.tradeState});

  @override
  Widget build(BuildContext context) {
    final items = _buildCommitMenuItems(context);

    return PopupMenuButton<void>(
      padding: EdgeInsets.zero,
      iconSize: 20,
      tooltip: '',
      icon: const Icon(Icons.more_vert),
      itemBuilder: (ctx) => [
        ...items.map(
          (item) => PopupMenuItem<void>(
            onTap: item.onTap,
            child: Row(
              children: [
                Icon(item.icon, size: 18),
                Gap.horizontal.md(),
                Text(item.label),
              ],
            ),
          ),
        ),
        if (items.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () => _showTradeDetailsSheet(context),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18),
              Gap.horizontal.md(),
              Text('Information'),
            ],
          ),
        ),
      ],
    );
  }

  void _showTradeDetailsSheet(BuildContext context) {
    final trade = context.read<Trade>();
    showAppModal(
      context,
      builder: (_) => StreamBuilder<dynamic>(
        stream: Rx.merge([
          trade.transitions$.stream.map((_) => null),
          trade.payments$.stream.map((_) => null),
          trade.reservationPair$.stream.map((_) => null),
        ]),
        initialData: null,
        builder: (context, transitionsSnapshot) {
          final transitions = trade.transitions$.items;
          final paymentEvents = trade.payments$.items;
          final reservationValidation = trade.reservationPair$.items;

          return ModalBottomSheet(
            title: 'Information',
            content: SingleChildScrollView(
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TradeTimeline(
                      transitions: transitions,
                      paymentEvents: paymentEvents,
                      hostPubKey: tradeState.hostPubKey,
                    ),
                    if (reservationValidation is Invalid<ReservationPair>) ...[
                      Gap.vertical.lg(),
                      _ReservationRecords(
                        validatedReservationPair: reservationValidation.last,
                        listing: tradeState.listing,
                        hostPubKey: tradeState.hostPubKey,
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

  List<_TradeMenuItem> _buildCommitMenuItems(BuildContext context) {
    final trade = context.read<Trade>();

    final List<_TradeMenuItem> items = tradeState.actions
        .map((action) {
          switch (action) {
            case TradeAction.cancel:
              return (
                label: 'Cancel',
                icon: Icons.cancel_outlined,
                onTap: () => showAppModal(
                  context,
                  builder: (_) => ModalBottomSheet(
                    title: AppLocalizations.of(context)!.cancelReservation,
                    subtitle: AppLocalizations.of(context)!.areYouSure,
                    content: const SizedBox.shrink(),
                    buttons: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            trade.execute(TradeAction.cancel);
                          },
                          child: Text(AppLocalizations.of(context)!.ok),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            case TradeAction.messageEscrow:
              return (
                label: 'Message Escrow',
                icon: Icons.support_agent_outlined,
                onTap: () {
                  final pubkey = trade.getEscrowPubkey();
                  if (pubkey != null) {
                    context.read<ThreadCubit>().addParticipant(pubkey);
                    trade.refreshActions();
                  }
                },
              );
            case TradeAction.refund:
              return (
                label: 'Refund',
                icon: Icons.undo_outlined,
                onTap: () {
                  final cubit = context.read<ThreadCubit>();
                  final selectedEscrows =
                      cubit.state.threadState.selectedEscrows;
                  if (selectedEscrows.isEmpty) return;
                  final escrowService = selectedEscrows.first.service;
                  final releaseOp = getIt<Hostr>().escrow.release(
                    EscrowReleaseParams(
                      escrowService: escrowService,
                      tradeId: trade.tradeId,
                    ),
                  );
                  showAppModal(
                    context,
                    builder: (_) => ReleaseFlowWidget(cubit: releaseOp),
                  );
                },
              );
            case TradeAction.claim:
              return (
                label: 'Claim',
                icon: Icons.download_outlined,
                onTap: () {
                  final cubit = context.read<ThreadCubit>();
                  final selectedEscrows =
                      cubit.state.threadState.selectedEscrows;
                  if (selectedEscrows.isEmpty) return;
                  final escrowService = selectedEscrows.first.service;
                  final claimOp = getIt<Hostr>().escrow.claim(
                    EscrowClaimParams(
                      escrowService: escrowService,
                      tradeId: trade.tradeId,
                    ),
                  );
                  showAppModal(context, builder: (_) => ClaimFlowWidget(cubit: claimOp));
                },
              );
            case TradeAction.review:
              return (
                label: 'Review',
                icon: Icons.star_outline,
                onTap: () => showAppModal(
                  context,
                  builder: (_) => CustomPadding(
                    child: EditReview(
                      listing: tradeState.listing,
                      tweakMaterial: const ReservationTweakMaterial(
                        salt: 'thread_salt',
                        parity: false,
                      ),
                    ),
                  ),
                ),
              );
            default:
              return null;
          }
        })
        .cast<_TradeMenuItem>()
        .toList();
    return items;
  }
}

class _ReservationRecords extends StatelessWidget {
  final Validation<ReservationPair> validatedReservationPair;
  final Listing listing;
  final String hostPubKey;

  const _ReservationRecords({
    required this.validatedReservationPair,
    required this.listing,
    required this.hostPubKey,
  });

  @override
  Widget build(BuildContext context) {
    final pair = validatedReservationPair;
    if (pair is Invalid<ReservationPair>) {
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
