import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/escrow_services.cubit.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

/// Shows a [ModalBottomSheet] listing all [EscrowService] events published by
/// the escrow operator identified by [pubkey].
void showEscrowServicesModal(BuildContext context, String pubkey) {
  showAppModal(
    context,
    child: BlocProvider(
      create: (_) =>
          EscrowServicesCubit(hostr: getIt<Hostr>(), pubkey: pubkey)..load(),
      child: _EscrowServicesModalContent(pubkey: pubkey),
    ),
  );
}

class _EscrowServicesModalContent extends StatelessWidget {
  final String pubkey;

  const _EscrowServicesModalContent({required this.pubkey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EscrowServicesCubit, EscrowServicesState>(
      builder: (context, state) {
        final Widget content;

        if (state.loading && state.data == null) {
          content = const Center(child: AppLoadingIndicator.large());
        } else if (state.error != null) {
          content = Text('Failed to load escrow services.');
        } else if (state.data == null || state.data!.isEmpty) {
          content = const Text('No escrow services found for this operator.');
        } else {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: state.data!.map(_buildServiceTile).toList(),
          );
        }

        return ModalBottomSheet(title: 'Escrow Services', content: content);
      },
    );
  }

  Widget _buildServiceTile(EscrowService service) {
    final c = service.parsedContent;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.security),
        title: Text(c.type.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contract: ${_truncate(c.contractAddress)}',
              overflow: TextOverflow.ellipsis,
            ),
            Text('Chain ID: ${c.chainId}'),
            Text('Max duration: ${c.maxDuration.inHours}h'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _truncate(String s) =>
      s.length > 14 ? '${s.substring(0, 6)}…${s.substring(s.length - 4)}' : s;
}
