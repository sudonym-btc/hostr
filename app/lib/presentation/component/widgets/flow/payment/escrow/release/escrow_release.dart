import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../modal_bottom_sheet.dart';
import '../../onchain_operation.dart';

class ReleaseFlowWidget extends StatefulWidget {
  final EscrowReleaseOperation cubit;
  const ReleaseFlowWidget({super.key, required this.cubit});

  @override
  State<ReleaseFlowWidget> createState() => _ReleaseFlowWidgetState();
}

class _ReleaseFlowWidgetState extends State<ReleaseFlowWidget> {
  @override
  void dispose() {
    widget.cubit.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<EscrowReleaseOperation, OnchainOperationState>(
        builder: (context, state) {
          return OnchainOperationViewWidget(
            state,
            initialisedBuilder: (_) => ModalBottomSheet(
              type: ModalBottomSheetType.normal,
              title: 'Release Escrow Funds',
              subtitle:
                  'This action will release the escrowed funds to the counterparty.',
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
              title: 'Release Success',
              subtitle: 'Funds have been released to the counterparty.',
            ),
            errorBuilder: (s) =>
                OnchainTransactionSheet.error(s, title: 'Release Failed'),
          );
        },
      ),
    );
  }
}
