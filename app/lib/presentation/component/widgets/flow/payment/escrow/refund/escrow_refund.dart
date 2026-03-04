import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import '../../../modal_bottom_sheet.dart';
import '../../onchain_operation.dart';

class RefundFlowWidget extends StatefulWidget {
  final EscrowReleaseOperation cubit;
  const RefundFlowWidget({super.key, required this.cubit});

  @override
  State<RefundFlowWidget> createState() => _RefundFlowWidgetState();
}

class _RefundFlowWidgetState extends State<RefundFlowWidget> {
  @override
  void initState() {
    super.initState();
  }

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
            onConfirm: () async => widget.cubit.execute(),
          );
        },
      ),
    );
  }
}

class RefundViewWidget extends StatelessWidget {
  final OnchainOperationState state;
  final Future<void> Function()? onConfirm;
  const RefundViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    return switch (state) {
      OnchainInitialised() => ModalBottomSheet(
        type: ModalBottomSheetType.normal,
        title: 'Refund Escrow Funds',
        content: Center(child: AppLoadingIndicator.large()),
      ),
      OnchainOperationState() => OnchainOperationViewWidget(state),
    };
  }
}
