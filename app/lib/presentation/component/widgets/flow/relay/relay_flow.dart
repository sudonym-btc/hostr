import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class RelayFlowWidget extends StatelessWidget {
  final Function() onClose;
  const RelayFlowWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return RelayAddStep();
  }
}

/// Add a new relay connection.
class RelayAddStep extends StatefulWidget {
  const RelayAddStep({super.key});

  @override
  State<RelayAddStep> createState() => _RelayAddStepState();
}

class _RelayAddStepState extends State<RelayAddStep> {
  final TextEditingController _urlController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;
  final CustomLogger logger = CustomLogger();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _connectRelay() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a relay URL';
      });
      return;
    }

    // Basic validation
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      setState(() {
        _errorMessage = 'URL must start with ws:// or wss://';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await getIt<Hostr>().relays.add(url);
    } catch (e) {
      logger.e('Failed to connect to relay: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Failed to connect: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Relay',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            enabled: !_isConnecting,
            decoration: InputDecoration(
              labelText: 'Relay URL',
              hintText: 'wss://relay.example.com',
              errorText: _errorMessage,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            onSubmitted: _isConnecting ? null : (_) => _connectRelay(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isConnecting ? null : _connectRelay,
            child: _isConnecting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Connect'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isConnecting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
