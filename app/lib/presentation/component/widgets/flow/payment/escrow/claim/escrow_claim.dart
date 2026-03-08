import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../modal_bottom_sheet.dart';
import '../../onchain_operation.dart';

class ClaimFlowWidget extends StatefulWidget {
  final EscrowClaimOperation cubit;
  const ClaimFlowWidget({super.key, required this.cubit});

  @override
  State<ClaimFlowWidget> createState() => _ClaimFlowWidgetState();
}

class _ClaimFlowWidgetState extends State<ClaimFlowWidget> {
  @override
  void dispose() {
    widget.cubit.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<EscrowClaimOperation, OnchainOperationState>(
        builder: (context, state) {
          return OnchainOperationViewWidget(
            state,
            initialisedBuilder: (_) => ModalBottomSheet(
              type: ModalBottomSheetType.normal,
              title: 'Claim Escrow Funds',
              subtitle:
                  'This action will claim the escrowed funds from the counterparty.',
              buttons: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () async => widget.cubit.execute(),
                    child: Text('Confirm'),
                  ),
                ],
              ),
              content: SizedBox.shrink(),
            ),
            confirmedBuilder: (_) => OnchainTransactionSheet.success(
              title: 'Claim Success',
              subtitle:
                  'Funds have been claimed from the escrow service and transferred to your account.',
            ),
            errorBuilder: (s) =>
                OnchainTransactionSheet.error(s, title: 'Claim Failed'),
          );
        },
      ),
    );
  }
}
