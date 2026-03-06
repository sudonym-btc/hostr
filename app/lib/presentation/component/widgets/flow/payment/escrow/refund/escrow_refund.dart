import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../onchain_operation.dart';

class RefundFlowWidget extends StatefulWidget {
  final EscrowReleaseOperation cubit;
  const RefundFlowWidget({super.key, required this.cubit});

  @override
  State<RefundFlowWidget> createState() => _RefundFlowWidgetState();
}

class _RefundFlowWidgetState extends State<RefundFlowWidget> {
  @override
  void dispose() {
    // Allow in-flight swaps to complete before closing the cubit.
    widget.cubit.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<OnchainOperation, OnchainOperationState>(
        builder: (context, state) {
          return OnchainOperationViewWidget(
            state,
            initialisedBuilder: (_) =>
                OnchainTransactionSheet.loading(title: 'Refund Escrow Funds'),
            confirmedBuilder: (_) => OnchainTransactionSheet.success(
              title: 'Refund Success',
              subtitle: 'Funds have been refunded.',
            ),
            errorBuilder: (s) =>
                OnchainTransactionSheet.error(s, title: 'Refund Failed'),
          );
        },
      ),
    );
  }
}
