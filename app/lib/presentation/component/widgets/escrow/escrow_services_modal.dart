import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/discover_escrow_services.cubit.dart';
import 'package:hostr/logic/cubit/escrow_services.cubit.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

/// Shows a [ModalBottomSheet] listing all [EscrowService] events published by
/// the escrow operator identified by [pubkey].
void showEscrowServicesModal(BuildContext context, String pubkey) {
  showAppModal(
    context,
    builder: (_) => BlocProvider(
      create: (_) =>
          EscrowServicesCubit(hostr: getIt<Hostr>(), pubkey: pubkey)..load(),
      child: _EscrowServicesModalContent(pubkey: pubkey),
    ),
  );
}

/// Shows a [ModalBottomSheet] that discovers escrow services matching
/// supported methods (e.g. EVM) and lets the user pick an operator to trust.
///
/// [trustedPubkeys] are the pubkeys the user already trusts – these appear
/// with a checkmark and cannot be selected again.
///
/// [onTrusted] is called after a new escrow is successfully trusted so the
/// caller can refresh its own state (e.g. the trusted escrows list).
void showTrustEscrowModal(
  BuildContext context, {
  List<String> trustedPubkeys = const [],
  VoidCallback? onTrusted,
}) {
  showAppModal(
    context,
    builder: (_) => BlocProvider(
      create: (_) => DiscoverEscrowServicesCubit(hostr: getIt<Hostr>())..load(),
      child: _TrustEscrowModalContent(
        trustedPubkeys: trustedPubkeys,
        onTrusted: onTrusted,
      ),
    ),
  );
}

// ─── Trust an escrow service modal ──────────────────────────────────────────

class _TrustEscrowModalContent extends StatefulWidget {
  final List<String> trustedPubkeys;
  final VoidCallback? onTrusted;

  const _TrustEscrowModalContent({
    this.trustedPubkeys = const [],
    this.onTrusted,
  });

  @override
  State<_TrustEscrowModalContent> createState() =>
      _TrustEscrowModalContentState();
}

class _TrustEscrowModalContentState extends State<_TrustEscrowModalContent> {
  String _filter = '';
  late final Set<String> _trustedSet;

  @override
  void initState() {
    super.initState();
    _trustedSet = {...widget.trustedPubkeys};
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      DiscoverEscrowServicesCubit,
      DiscoverEscrowServicesState
    >(
      builder: (context, state) {
        final Widget content;

        if (state.loading && state.data == null) {
          content = const Center(child: AppLoadingIndicator.large());
        } else if (state.error != null) {
          content = Text(
            'Failed to discover escrow services.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state.distinctPubkeys.isEmpty) {
          content = Text(
            'No compatible escrow services found.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        } else {
          content = _buildFilterableList(
            context,
            state.distinctPubkeys,
            widget.trustedPubkeys,
          );
        }

        return ModalBottomSheet(
          title: 'Trust an escrow service',
          subtitle:
              'Select an escrow service to trust to broker your transactions',
          content: content,
        );
      },
    );
  }

  Widget _buildFilterableList(
    BuildContext context,
    List<String> pubkeys,
    List<String> trustedPubkeys,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Filter by name…',
            prefixIcon: Icon(Icons.search),
            prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (value) => setState(() => _filter = value),
        ),
        Gap.vertical.md(),
        // Each pubkey gets resolved via ProfileProvider; filtering happens
        // inside the builder once the profile metadata is available.
        ...pubkeys.map((pubkey) {
          final alreadyTrusted = _trustedSet.contains(pubkey);
          return ProfileProvider(
            pubkey: pubkey,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final displayName =
                  profile?.metadata.name ?? profile?.metadata.displayName ?? '';

              // Hide entries that don't match the filter.
              if (_filter.isNotEmpty &&
                  !displayName.toLowerCase().contains(_filter.toLowerCase())) {
                return const SizedBox.shrink();
              }

              final picture = profile?.metadata.picture;
              final label = displayName.isNotEmpty
                  ? displayName
                  : '${pubkey.substring(0, 8)}…';

              return Card(
                child: ListTile(
                  leading: AppAvatar.xl(
                    image: picture,
                    pubkey: pubkey,
                    label: label,
                    icon: Icons.security,
                  ),
                  title: Text(
                    label,
                    style: alreadyTrusted
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          )
                        : null,
                  ),
                  subtitle: Text(
                    '${pubkey.substring(0, 8)}…${pubkey.substring(pubkey.length - 4)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: alreadyTrusted
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.add_circle_outline),
                  enabled: !alreadyTrusted,
                  onTap: alreadyTrusted
                      ? null
                      : () async {
                          await getIt<Hostr>().escrowTrusts.ensureEscrowTrust([
                            pubkey,
                          ]);
                          widget.onTrusted?.call();
                          if (mounted) {
                            setState(() => _trustedSet.add(pubkey));
                          }
                        },
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// ─── Existing: escrow services for a given operator ─────────────────────────

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
          content = Text(
            'Failed to load escrow services.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state.data == null || state.data!.isEmpty) {
          content = Text(
            'No escrow services found for this operator.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        } else {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: state.data!
                .map((s) => _buildServiceTile(context, s))
                .toList(),
          );
        }

        return ModalBottomSheet(title: 'Escrow Services', content: content);
      },
    );
  }

  Widget _buildServiceTile(BuildContext context, EscrowService service) {
    final feeDesc = [
      if (service.feeBase > 0) '${service.feeBase} sats base',
      if (service.feePercent > 0) '${service.feePercent}%',
    ].join(' + ');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.security),
        title: Text(service.escrowType.name),
        subtitle: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contract: ${_truncate(service.contractAddress)}',
                overflow: TextOverflow.ellipsis,
              ),
              Text('Chain ID: ${service.chainId}'),
              Text('Max duration: ${service.maxDuration.inHours}h'),
              if (feeDesc.isNotEmpty) Text('Fee: $feeDesc'),
              Text(
                'Min: ${service.minAmount} sats'
                '${service.maxAmount != null ? ' · Max: ${service.maxAmount} sats' : ''}',
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _truncate(String s) =>
      s.length > 14 ? '${s.substring(0, 6)}…${s.substring(s.length - 4)}' : s;
}
