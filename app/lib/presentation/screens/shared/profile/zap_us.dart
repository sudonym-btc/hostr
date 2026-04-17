import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/env/base.config.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_list.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_receipt.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

class ZapUsWidget extends StatelessWidget {
  const ZapUsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final config = getIt<Config>();
    final tipsAddress = config.tipsAddress;
    final twitterHandle = config.hostrTwitterHandle;
    final socialNpub = config.hostrSocialNpub;
    return CustomPadding(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: HelpText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  'Hostr is open source software maintained by the community with ❤️',
                ),
              ),
              Gap.horizontal.md(),
              FilledButton(
                child: Text(AppLocalizations.of(context)!.zapUs),
                onPressed: () {
                  final params = ZapPayParameters(
                    to: tipsAddress,
                    amount: rbtcFromSats(BigInt.from(10000)),
                  );
                  showAppModal(
                    context,
                    builder: (_) => PaymentFlowWidget(
                      cubit: getIt<Hostr>().payments.pay(params)..resolve(),
                    ),
                  );
                },
              ),
            ],
          ),
          Gap.vertical.sm(),
          Row(
            children: [
              const Spacer(),
              if (twitterHandle.isNotEmpty)
                IconButton(
                  tooltip: '@$twitterHandle',
                  icon: CustomPaint(
                    size: const Size(18, 18),
                    painter: _XLogoPainter(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse('https://x.com/$twitterHandle'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              if (socialNpub.isNotEmpty)
                IconButton(
                  tooltip: 'Nostr',
                  icon: const Icon(Icons.electric_bolt, size: 20),
                  onPressed: () => launchUrl(
                    Uri.parse('https://njump.me/$socialNpub'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
          Gap.vertical.md(),
          Row(
            children: [
              ZapListWidget(
                lud16: tipsAddress,
                builder: (p0) => ZapReceiptWidget(zap: p0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the 𝕏 (Twitter / X) logo as two crossing strokes.
class _XLogoPainter extends CustomPainter {
  final Color color;
  const _XLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left → bottom-right stroke
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      paint,
    );
    // Top-right → bottom-left stroke
    canvas.drawLine(
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width * 0.1, size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(_XLogoPainter oldDelegate) => color != oldDelegate.color;
}
