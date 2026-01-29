import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

import '../../nostr_wallet_connect/add_wallet.dart';
import '../flow.dart';

/// NWC (Nostr Wallet Connect) flow definition that manages wallet connection steps.
class NwcFlow extends FlowDefinition {
  @override
  String get id => 'nwc-flow';

  @override
  List<FlowStep> buildSteps() => [const NwcAddWalletStep()];
}

/// Renders the NWC flow using FlowHost for step navigation.
class NwcFlowWidget extends StatefulWidget {
  final VoidCallback onClose;

  const NwcFlowWidget({super.key, required this.onClose});

  @override
  State<NwcFlowWidget> createState() => _NwcFlowWidgetState();
}

class _NwcFlowWidgetState extends State<NwcFlowWidget> {
  late FlowHost _flowHost;
  late NwcCubit _nwcCubit;

  @override
  void initState() {
    super.initState();
    _nwcCubit = NwcCubit(nwc: getIt<Hostr>().nwc);
    _flowHost = FlowHost(widget.onClose);
    _flowHost.init(NwcFlow());
  }

  @override
  void dispose() {
    if (!_flowHost.isClosed) {
      _flowHost.close();
    }
    _nwcCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FlowHost>.value(value: _flowHost),
        BlocProvider<NwcCubit>.value(value: _nwcCubit),
      ],
      child: BlocBuilder<FlowHost, FlowState>(
        builder: (context, state) {
          return _NwcFlowScaffold(
            flowHost: _flowHost,
            child:
                _flowHost.currentStep?.build(context) ??
                const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _NwcFlowScaffold extends StatelessWidget {
  final Widget child;
  final FlowHost flowHost;

  const _NwcFlowScaffold({required this.child, required this.flowHost});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Add a new wallet connection via NWC auth.
class NwcAddWalletStep extends StatelessWidget implements FlowStep {
  const NwcAddWalletStep({super.key});

  @override
  String get id => 'nwc-add-wallet';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              onPressed: () {
                context.read<FlowHost>().onBack();
              },
            ),
            const SizedBox(height: 16),
            // Reuse existing add wallet widget
            const AddWalletWidget(),
          ],
        ),
      ),
    );
  }
}

/// Attempt to connect to an NWC provider with the given connection string.
class NwcConnectingStep extends StatefulWidget {
  final String connectionString;

  const NwcConnectingStep({super.key, required this.connectionString});

  @override
  State<NwcConnectingStep> createState() => _NwcConnectingStepState();
}

class _NwcConnectingStepState extends State<NwcConnectingStep>
    implements FlowStep {
  late Future<void> _connectFuture;

  @override
  String get id => 'nwc-connecting';

  @override
  void initState() {
    super.initState();
    _connectFuture = _attemptConnection();
  }

  Future<void> _attemptConnection() async {
    final nwcCubit = context.read<NwcCubit>();
    await nwcCubit.connect(widget.connectionString);
    if (nwcCubit.state is Success && nwcCubit.connection != null) {
      await getIt<Hostr>().nwc.add(nwcCubit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<void>(
        future: _connectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Connecting to wallet...'),
              ],
            );
          }

          return BlocBuilder<NwcCubit, NwcCubitState>(
            builder: (context, state) {
              if (state is Success) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connected to ${state.content.alias}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<FlowHost>().close();
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                );
              } else if (state is Error) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Failed',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Could not connect to NWC provider: ${state.e}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<FlowHost>().onBack();
                            },
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<FlowHost>().close();
                            },
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
