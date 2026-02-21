import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.cubit.dart';
import 'package:ndk/domain_layer/usecases/nwc/nostr_wallet_connect_uri.dart';

enum NostrWalletConnectConnectionUiState { loading, connected, failure }

class NostrWalletConnectConnectionTileView extends StatelessWidget {
  final NostrWalletConnectConnectionUiState state;
  final bool canClose;
  final VoidCallback? onClose;
  final String? alias;
  final String? subtitle;
  final String? errorText;
  final Color? avatarColor;

  const NostrWalletConnectConnectionTileView({
    super.key,
    required this.state,
    required this.canClose,
    this.onClose,
    this.alias,
    this.subtitle,
    this.errorText,
    this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = canClose
        ? IconButton(icon: const Icon(Icons.close), onPressed: onClose)
        : null;

    if (state == NostrWalletConnectConnectionUiState.loading) {
      return ListTile(
        leading: const CircularProgressIndicator(),
        trailing: trailing,
        contentPadding: EdgeInsets.all(0),
      );
    }

    if (state == NostrWalletConnectConnectionUiState.connected) {
      return ListTile(
        contentPadding: EdgeInsets.all(0),
        leading: CircleAvatar(backgroundColor: avatarColor ?? Colors.orange),
        trailing: trailing,
        title: Text(alias ?? 'Unknown wallet'),
        subtitle: Text(
          subtitle ?? AppLocalizations.of(context)!.connected,
          maxLines: 1,
          style: const TextStyle(overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.error),
      trailing: trailing,
      contentPadding: EdgeInsets.all(0),
      title: Text(
        alias ?? 'Connection Error',
        style: const TextStyle(overflow: TextOverflow.ellipsis),
      ),
      subtitle: Text(
        errorText ?? 'Unknown error',
        style: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class NostrWalletConnectConnectionView extends StatelessWidget {
  final List<NwcCubit> connections;
  final bool canClose;
  final ValueChanged<NwcCubit>? onRemove;

  const NostrWalletConnectConnectionView({
    super.key,
    required this.connections,
    this.canClose = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) {
      return const Text('No wallet connected');
    }

    return Column(
      children: connections.map((reactiveConnection) {
        return BlocBuilder<NwcCubit, NwcCubitState>(
          bloc: reactiveConnection,
          builder: (context, state) {
            if (state is Idle || state is Loading) {
              return NostrWalletConnectConnectionTileView(
                state: NostrWalletConnectConnectionUiState.loading,
                canClose: canClose,
                onClose: canClose
                    ? () => onRemove?.call(reactiveConnection)
                    : null,
              );
            }

            if (state is NwcSuccess) {
              return NostrWalletConnectConnectionTileView(
                state: NostrWalletConnectConnectionUiState.connected,
                canClose: canClose,
                onClose: canClose
                    ? () => onRemove?.call(reactiveConnection)
                    : null,
                alias: state.data.alias,
                subtitle: AppLocalizations.of(context)!.connected,
                avatarColor: state.data.color != null
                    ? Color(
                        int.parse(
                              state.data.color!.substring(1, 7),
                              radix: 16,
                            ) +
                            0xFF000000,
                      )
                    : Colors.orange,
              );
            }

            if (state is NwcFailure) {
              return NostrWalletConnectConnectionTileView(
                state: NostrWalletConnectConnectionUiState.failure,
                canClose: canClose,
                onClose: canClose
                    ? () => onRemove?.call(reactiveConnection)
                    : null,
                alias: reactiveConnection.url == null
                    ? 'Invalid connection URL'
                    : NostrWalletConnectUri.parseConnectionUri(
                        reactiveConnection.url!,
                      ).relays.first,
                errorText: state.e.toString(),
              );
            }

            return const NostrWalletConnectConnectionTileView(
              state: NostrWalletConnectConnectionUiState.loading,
              canClose: false,
            );
          },
        );
      }).toList(),
    );
  }
}

class NostrWalletConnectConnectionWidget extends StatelessWidget {
  final bool canClose;

  const NostrWalletConnectConnectionWidget({super.key, this.canClose = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt<Hostr>().nwc.connectionsStream,
      builder: (context, connectionsSnapshot) {
        if (!connectionsSnapshot.hasData) {
          return const NostrWalletConnectConnectionTileView(
            state: NostrWalletConnectConnectionUiState.loading,
            canClose: false,
          );
        }
        return NostrWalletConnectConnectionView(
          connections: connectionsSnapshot.data!,
          canClose: canClose,
          onRemove: (reactiveConnection) {
            getIt<Hostr>().nwc.remove(reactiveConnection);
          },
        );
      },
    );
  }
}
