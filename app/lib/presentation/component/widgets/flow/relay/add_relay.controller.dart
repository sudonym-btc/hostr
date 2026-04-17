import 'package:hostr/injection.dart';
import 'package:hostr/logic/forms/text_field_controller.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class AddRelayController extends UpsertFormController {
  final TextFieldController urlField = TextFieldController(
    validator: _validateRelayUrl,
  );

  AddRelayController() {
    registerField(urlField);
  }

  @override
  Future<void> upsert() async {
    final url = urlField.text.trim();
    await getIt<Hostr>().relays.add(url);
  }

  static String? _validateRelayUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a relay URL';
    if (!trimmed.startsWith('ws://') && !trimmed.startsWith('wss://')) {
      return 'URL must start with ws:// or wss://';
    }
    return null;
  }
}
