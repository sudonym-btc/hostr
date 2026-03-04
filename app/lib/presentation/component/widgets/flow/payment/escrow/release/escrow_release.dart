import 'dart:async';

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
  void initState() {
    super.initState();
  }

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
          return ReleaseViewWidget(
            state,
            onConfirm: () async => widget.cubit.execute(),
          );
        },
      ),
    );
  }
}

class ReleaseViewWidget extends StatelessWidget {
  final OnchainOperationState state;
  final Future<void> Function()? onConfirm;
  const ReleaseViewWidget(this.state, {super.key, this.onConfirm});

  @override
  build(BuildContext context) {
    return switch (state) {
      OnchainInitialised() => ModalBottomSheet(
        type: ModalBottomSheetType.normal,
        title: 'Release Escrow Funds',
        subtitle:
            'This action will release the escrowed funds to the counterparty.',
        buttons: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(onPressed: onConfirm, child: Text('Confirm')),
          ],
        ),
        content: SizedBox.shrink(),
      ),
      OnchainOperationState() => OnchainOperationViewWidget(state),
    };
  }
}
