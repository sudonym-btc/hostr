// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hostr/core/main.dart';
// import 'package:hostr/data/main.dart';
// import 'package:hostr/injection.dart';

// import '../flow.dart';

// /// Relay connection flow definition that manages relay connection steps.
// class RelayFlow extends FlowDefinition {
//   @override
//   String get id => 'relay-flow';

//   @override
//   List<FlowStep> buildSteps() => [const RelayAddStep()];
// }

// /// Renders the relay flow using FlowHost for step navigation.
// class RelayFlowWidget extends StatefulWidget {
//   final VoidCallback onClose;

//   const RelayFlowWidget({super.key, required this.onClose});

//   @override
//   State<RelayFlowWidget> createState() => _RelayFlowWidgetState();
// }

// class _RelayFlowWidgetState extends State<RelayFlowWidget> {
//   late FlowHost _flowHost;

//   @override
//   void initState() {
//     super.initState();
//     _flowHost = FlowHost(widget.onClose);
//     _flowHost.init(RelayFlow());
//   }

//   @override
//   void dispose() {
//     if (!_flowHost.isClosed) {
//       _flowHost.close();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider<FlowHost>.value(
//       value: _flowHost,
//       child: BlocBuilder<FlowHost, FlowState>(
//         builder: (context, state) {
//           return _RelayFlowScaffold(
//             flowHost: _flowHost,
//             child:
//                 _flowHost.currentStep?.build(context) ??
//                 const SizedBox.shrink(),
//           );
//         },
//       ),
//     );
//   }
// }

// class _RelayFlowScaffold extends StatelessWidget {
//   final Widget child;
//   final FlowHost flowHost;

//   const _RelayFlowScaffold({required this.child, required this.flowHost});

//   @override
//   Widget build(BuildContext context) {
//     return child;
//   }
// }

// /// Add a new relay connection.
// class RelayAddStep extends StatefulWidget implements FlowStep {
//   const RelayAddStep({super.key});

//   @override
//   String get id => 'relay-add';

//   @override
//   State<RelayAddStep> createState() => _RelayAddStepState();

//   @override
//   Widget build(BuildContext context) {
//     return this;
//   }
// }

// class _RelayAddStepState extends State<RelayAddStep> {
//   final TextEditingController _urlController = TextEditingController();
//   bool _isConnecting = false;
//   String? _errorMessage;
//   final CustomLogger logger = CustomLogger();

//   @override
//   void dispose() {
//     _urlController.dispose();
//     super.dispose();
//   }

//   Future<void> _connectRelay() async {
//     final url = _urlController.text.trim();

//     if (url.isEmpty) {
//       setState(() {
//         _errorMessage = 'Please enter a relay URL';
//       });
//       return;
//     }

//     // Basic validation
//     if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
//       setState(() {
//         _errorMessage = 'URL must start with ws:// or wss://';
//       });
//       return;
//     }

//     setState(() {
//       _isConnecting = true;
//       _errorMessage = null;
//     });

//     try {
//       await getIt<Hostr>().relays.add(url);

//       if (mounted) {
//         // Success - close the flow
//         context.read<FlowHost>().close();
//       }
//     } catch (e) {
//       logger.e('Failed to connect to relay: $e');
//       if (mounted) {
//         setState(() {
//           _isConnecting = false;
//           _errorMessage = 'Failed to connect: ${e.toString()}';
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         left: 16.0,
//         right: 16.0,
//         top: 16.0,
//         bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(
//             'Add Relay',
//             style: Theme.of(context).textTheme.headlineSmall,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           TextField(
//             controller: _urlController,
//             enabled: !_isConnecting,
//             decoration: InputDecoration(
//               labelText: 'Relay URL',
//               hintText: 'wss://relay.example.com',
//               errorText: _errorMessage,
//               border: const OutlineInputBorder(),
//             ),
//             keyboardType: TextInputType.url,
//             autocorrect: false,
//             onSubmitted: _isConnecting ? null : (_) => _connectRelay(),
//           ),
//           const SizedBox(height: 16),
//           FilledButton(
//             onPressed: _isConnecting ? null : _connectRelay,
//             child: _isConnecting
//                 ? const SizedBox(
//                     height: 20,
//                     width: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Text('Connect'),
//           ),
//           const SizedBox(height: 8),
//           TextButton(
//             onPressed: _isConnecting
//                 ? null
//                 : () => context.read<FlowHost>().close(),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }
// }
