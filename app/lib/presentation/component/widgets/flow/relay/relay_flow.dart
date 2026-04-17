import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';

import 'add_relay.controller.dart';

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
  final AddRelayController controller = AddRelayController();
  String? _errorMessage;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _connectRelay() async {
    final saved = await controller.save();
    if (saved && mounted) {
      Navigator.of(context).pop();
    } else if (!saved && mounted) {
      setState(() {
        _errorMessage = controller.urlField.validate(controller.urlField.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: ModalBottomSheet(
        title: 'Add Relay',
        content: CustomPadding.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // FormLabel(label: 'Relay URL'),
              TextFormField(
                controller: controller.urlField.textController,
                enabled: !controller.isSaving,
                validator: controller.urlField.validate,
                decoration: const InputDecoration(
                  hintText: 'wss://relay.example.com',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onFieldSubmitted: controller.isSaving
                    ? null
                    : (_) => _connectRelay(),
              ),
              if (_errorMessage != null) ...[
                Gap.vertical.sm(),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        buttons: ListenableBuilder(
          listenable: controller.submitListenable,
          builder: (context, _) => Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: controller.isSaving ? null : _connectRelay,
                  child: controller.isSaving
                      ? const AppLoadingIndicator.small(color: Colors.white)
                      : Text(AppLocalizations.of(context)!.connect),
                ),
              ),
              Gap.horizontal.custom(kSpace3),
              Expanded(
                child: TextButton(
                  onPressed: controller.isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
