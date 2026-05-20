import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../trade_details_sheet.dart';

typedef _TradeMenuItem = ({
  Key? key,
  String label,
  IconData icon,
  VoidCallback onTap,
});

class CommitMenu extends StatelessWidget {
  final TradeReady tradeState;
  const CommitMenu({super.key, required this.tradeState});

  @override
  Widget build(BuildContext context) {
    final items = _buildCommitMenuItems(context);

    return PopupMenuButton<void>(
      key: ValueKey(
        'trade_live_${tradeState.role.name}_actions_menu_button_${tradeState.tradeId}',
      ),
      padding: EdgeInsets.zero,
      iconSize: 20,
      tooltip: '',
      icon: const Icon(Icons.more_vert),
      itemBuilder: (ctx) => [
        ...items.map(
          (item) => PopupMenuItem<void>(
            key: item.key,
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
          onTap: () => showTradeDetailsSheet(context, tradeState),
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

  List<_TradeMenuItem> _buildCommitMenuItems(BuildContext context) {
    final trade = context.read<Trade>();
    final l10n = AppLocalizations.of(context)!;
    final destructiveStyle = AppButtonStyles.destructive(context);
    final cancelPrefix =
        'trade_live_${tradeState.role.name}_cancel_${trade.tradeId}';
    final messageEscrowItem = _buildMessageEscrowItem(context, trade);

    final List<_TradeMenuItem> items = tradeState.actions
        .map((action) {
          switch (action) {
            case TradeAction.cancel:
              return (
                key: ValueKey('${cancelPrefix}_menu_item'),
                label: 'Cancel',
                icon: Icons.cancel_outlined,
                onTap: () => showAppModal(
                  context,
                  builder: (modalContext) => ModalBottomSheet(
                    title: l10n.cancelReservation,
                    subtitle: l10n.areYouSure,
                    content: const SizedBox.shrink(),
                    buttons: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FutureButton.filled(
                          key: ValueKey('${cancelPrefix}_confirm_button'),
                          style: destructiveStyle,
                          onPressed: () async {
                            await trade.execute(TradeAction.cancel);
                            if (modalContext.mounted) {
                              Navigator.of(modalContext).pop();
                            }
                          },
                          child: Text(l10n.ok),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            case TradeAction.messageEscrow:
              return messageEscrowItem;
            case TradeAction.refund:
              return null; // Hidden for now
            case TradeAction.claim:
              return null; // Hidden for now
            case TradeAction.review:
              final commitStage = tradeState.stage;
              if (commitStage is! CommitStage) return null;
              final group = commitStage.orderGroup;
              // Use the buyer's reservation as the anchor for the review.
              final reservation =
                  group.buyerOrder ?? group.sellerOrder ?? group.escrowOrder;
              return (
                key: ValueKey(
                  'trade_live_${tradeState.role.name}_review_menu_item_${trade.tradeId}',
                ),
                label: 'Review',
                icon: Icons.star_outline,
                onTap: () => showAppModal(
                  context,
                  builder: (modalContext) => CustomPadding(
                    child: EditReview(
                      listing: tradeState.listing,
                      reservation: reservation,
                      onSaved: () {
                        Navigator.of(modalContext).pop();
                      },
                    ),
                  ),
                ),
              );
            default:
              return null;
          }
        })
        .whereType<_TradeMenuItem>()
        .toList();
    if (!tradeState.actions.contains(TradeAction.messageEscrow) &&
        messageEscrowItem != null) {
      items.add(messageEscrowItem);
    }
    return items;
  }

  _TradeMenuItem? _buildMessageEscrowItem(BuildContext context, Trade trade) {
    final commitStage = tradeState.stage;
    if (commitStage is! CommitStage) return null;
    final escrowPubkey =
        commitStage.orderGroup.escrowPubkey ?? trade.getEscrowPubkey();
    if (escrowPubkey == null || escrowPubkey.isEmpty) return null;

    return (
      key: ValueKey(
        'trade_live_${tradeState.role.name}_message_escrow_menu_item_${trade.tradeId}',
      ),
      label: 'Message Escrow',
      icon: Icons.support_agent_outlined,
      onTap: () async {
        final thread = await trade.resolveEscrowThread();
        if (!context.mounted) return;
        AutoRouter.of(context).push(ThreadRoute(anchor: thread.anchor));
      },
    );
  }
}
