import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
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
    return ModalBottomSheet(
      title: 'Add Relay',
      content: CustomPadding.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        child: TextField(
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
      ),
      buttons: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _isConnecting ? null : _connectRelay,
              child: _isConnecting
                  ? const AppLoadingIndicator.small(color: Colors.white)
                  : Text(AppLocalizations.of(context)!.connect),
            ),
          ),
          Gap.horizontal.custom(kSpace3),
          Expanded(
            child: TextButton(
              onPressed: _isConnecting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ),
        ],
      ),
    );
  }
}
