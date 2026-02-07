import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_chip.dart';
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
            return const CircularProgressIndicator();
          case EscrowSelectorError():
            return const Text('Error loading escrows');
          case EscrowSelectorLoaded():
            return DropdownButton<dynamic>(
              value: state.selectedEscrow,
              isExpanded: true,
              underline: Container(),
              selectedItemBuilder: (BuildContext context) {
                return [ProfileChipWidget(id: state.selectedEscrow.pubKey)];
              },
              items: state.result.compatibleServices
                  .map<DropdownMenuItem<dynamic>>((EscrowService escrow) {
                    return DropdownMenuItem(
                      value: escrow,
                      child: Text(
                        escrow.pubKey,
                        style: TextStyle(
                          fontSize: 20,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  })
                  .toList(),
              onChanged: (dynamic size) {
                // emit(EscrowSelectorLoaded(selectedEscrow: size, result: state.result));
              },
            );
          default:
            throw UnimplementedError();
        }
      },
    );
  }
}
