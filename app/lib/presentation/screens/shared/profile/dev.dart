import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/in/swap_in.dart';
import 'package:hostr/presentation/component/widgets/keys/keys.dart';
import 'package:hostr/presentation/component/widgets/ui/section.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';

import 'background_tasks.dart';

class DevWidget extends StatelessWidget {
  const DevWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(AppLocalizations.of(context)!.dev),
      children: [
        BackgroundTasks(),
        FilledButton(
          onPressed: () {
            showAppModal(
              context,
              child: SwapInFlowWidget(
                cubit: getIt<Hostr>().evm.supportedEvmChains[0].swapIn(
                  SwapInParams(
                    amount: BitcoinAmount.fromInt(BitcoinUnit.sat, 1000000),
                    evmKey: getIt<Hostr>().auth.getActiveEvmKey(),
                  ),
                )..estimateFees(),
              ),
            );
          },
          child: Text(AppLocalizations.of(context)!.swapIn),
        ),
        Section(
          title: 'bolt11',
          body: FilledButton(
            child: Text(AppLocalizations.of(context)!.bolt11),
            onPressed: () {
              final params = Bolt11PayParameters(
                to: 'lnbcrt1m1pnuh2h0sp53d22pxeg0wy5ugcaxkxqylph7xxgpur7x4yvr8ehmeljplr8mj8qpp5rjfq96tmtwwe2vdxmpltue5rl8y45ch3cnkd9rygcpr4u37tucdqdpq2djkuepqw3hjq5jz23pjqctyv3ex2umnxqyp2xqcqz959qyysgqdfhvjvfdve0jhfsjj90ta34449h5zqr8genctuc5ek09g0274gp39pa8lg2pt2dgz0pt7y3lcxh8k24tp345kv8sf2frkdc0zvp8npsqayww8f',
              );
              getIt<Hostr>().payments.pay(params).resolve();
            },
          ),
        ),
        Section(
          title: 'Swap',
          body: Column(
            children: [
              // FilledButton(
              //   child: Text('Swap in'),
              //   onPressed: () {
              //     getIt<Hostr>().evm.supportedEvmChains.first
              //         .swapIn(
              //           key: key,
              //           amount: Amount(
              //             currency: Currency.BTC,
              //             value: 0.0001,
              //           ),
              //         );
              //   },
              // ),
              FilledButton(
                child: Text(AppLocalizations.of(context)!.escrow),
                onPressed: () async {
                  // getIt<Hostr>().escrow.escrow(
                  //   EscrowCubitParams(
                  //     evmChain:
                  //         getIt<Hostr>().evm.supportedEvmChains[0],
                  //     amount: Amount(
                  //       currency: Currency.BTC,
                  //       value: 0.001,
                  //     ),
                  //     eventId: Helpers.getSecureRandomHex(32),
                  //     timelock: 200,
                  //     escrowContractAddress:
                  //         (await getIt<Hostr>().escrows.list(
                  //           Filter(),
                  //         )).first.parsedContent.contractAddress,

                  //     ///Host
                  //     sellerEvmAddress:
                  //         ProfileMetadata.fromNostrEvent(
                  //           MOCK_PROFILES[0],
                  //         ).evmAddress!,

                  //     /// Escrow profile
                  //     escrowEvmAddress:
                  //         ProfileMetadata.fromNostrEvent(
                  //           MOCK_PROFILES[2],
                  //         ).evmAddress!, // @TO);)
                  //   ),
                  // );
                },
              ),
              // FilledButton(
              //   child: Text('ListEvents'),
              //   onPressed: () {
              //     context.read<SwapManager>().listEvents();
              //   },
              // ),
              // FilledButton(
              //   child: Text('Swap out'),
              //   onPressed: () {
              //     context.read<SwapManager>().swapOutAll();
              //   },
              // ),
            ],
          ),
        ),
        KeysWidget(),
        FilledButton(
          child: const Text('Clear Swap & Lock Stores'),
          onPressed: () async {
            final swapStore = getIt<SwapStore>();
            final lockRegistry = getIt<EscrowLockRegistry>();

            final swaps = await swapStore.getAll();
            for (final swap in swaps) {
              await swapStore.remove(swap.id);
            }

            final locks = await lockRegistry.getAll();
            for (final lock in locks) {
              await lockRegistry.release(lock.tradeId);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cleared ${swaps.length} swap(s) and ${locks.length} lock(s)',
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
