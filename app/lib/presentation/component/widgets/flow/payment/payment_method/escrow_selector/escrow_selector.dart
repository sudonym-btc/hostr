import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_chip.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:models/main.dart';

import 'escrow_selector.cubit.dart';

class EscrowSelectorWidget extends StatelessWidget {
  const EscrowSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EscrowSelectorCubit, EscrowSelectorState>(
      builder: (context, state) {
        switch (state) {
          case EscrowSelectorLoading():
            return const AppLoadingIndicator.medium();
          case EscrowSelectorError():
            return Text(AppLocalizations.of(context)!.errorLoadingEscrows);
          case EscrowSelectorLoaded():
            if (state.result.compatibleServices.isEmpty) {
              return Text(
                AppLocalizations.of(context)!.noCompatibleEscrowsFound,
              );
            }
            return DropdownButton<dynamic>(
              value: state.selectedEscrow,
              isExpanded: true,
              underline: Container(),
              selectedItemBuilder: (BuildContext context) {
                return state.result.compatibleServices
                    .map((e) => ProfileChipWidget(id: e.pubKey))
                    .toList();
              },
              items: state.result.compatibleServices
                  .map<DropdownMenuItem<dynamic>>((EscrowService escrow) {
                    return DropdownMenuItem(
                      value: escrow,
                      child: ProfileProvider(
                        pubkey: escrow.pubKey,
                        builder: (context, snapshot) {
                          final name =
                              snapshot.data?.metadata.name ?? escrow.pubKey;
                          return Text(
                            name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(overflow: TextOverflow.ellipsis),
                          );
                        },
                      ),
                    );
                  })
                  .toList(),
              onChanged: (dynamic value) {
                context.read<EscrowSelectorCubit>().changeSelection(
                  value as EscrowService,
                );
              },
            );
          default:
            throw UnimplementedError();
        }
      },
    );
  }
}
