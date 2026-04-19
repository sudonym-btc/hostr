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
          Gap.vertical.md(),
          ZapListWidget(
            lud16: tipsAddress,
            builder: (p0) => ZapReceiptWidget(zap: p0),
          ),
          Gap.vertical.sm(),
          Row(
            children: [
              const Spacer(),
              if (twitterHandle.isNotEmpty)
                TextButton(
                  style: _socialButtonStyle(context),
                  onPressed: () => launchUrl(
                    Uri.parse('https://x.com/$twitterHandle'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text('@$twitterHandle'),
                ),
              if (socialNpub.isNotEmpty)
                TextButton(
                  style: _socialButtonStyle(context),
                  onPressed: () => launchUrl(
                    Uri.parse('https://njump.me/$socialNpub'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Nostr'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

ButtonStyle _socialButtonStyle(BuildContext context) {
  final color = Theme.of(context).colorScheme.onSurfaceVariant;

  return TextButton.styleFrom(
    foregroundColor: color,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    minimumSize: const Size(0, 36),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: color,
    ),
  );
}
