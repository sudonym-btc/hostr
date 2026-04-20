import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_chip.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../amount/amount_input.dart';

class ZapReceiptWidget extends StatelessWidget {
  final ZapReceipt zap;
  const ZapReceiptWidget({super.key, required this.zap});

  @override
  Widget build(BuildContext context) {
    final sender = zap.sender;
    final comment = zap.comment?.trim();
    final hasComment = comment != null && comment.isNotEmpty;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sender != null && sender.isNotEmpty)
            ProfileChipWidget(id: sender)
          else
            AppChip.neutral.sm(
              avatar: const Icon(Icons.flash_on, size: 16),
              label: const Text('Anonymous'),
            ),
          Gap.vertical.xs(),
          MessageContainer(
            isSentByMe: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatZapAmount(zap),
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (hasComment) ...[
                  Gap.vertical.xxs(),
                  Text(
                    comment,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatZapAmount(ZapReceipt zap) {
    final amountSats = zap.amountSats;
    if (amountSats == null) return 'Zap';

    return formatAmount(
      DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(amountSats),
        decimals: 8,
      ),
      exact: false,
    );
  }
}
