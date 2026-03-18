import 'package:auto_route/auto_route.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/keys/backup_key.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

@RoutePage()
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<StatefulWidget> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _controller = TextEditingController();
  String _private = '';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValidInput {
    final trimmed = _private.trim();
    if (trimmed.isEmpty) return false;

    if (trimmed.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
      return true;
    }

    if (trimmed.startsWith('nsec1')) {
      try {
        final decoded = Helpers.decodeBech32(trimmed);
        return decoded[0].isNotEmpty && decoded[0].length == 64;
      } catch (_) {
        return false;
      }
    }

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 12 || words.length == 24) {
      try {
        Mnemonic.fromSentence(trimmed, Language.english);
        return true;
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  Future<void> _handleSignin() async {
    setState(() => _error = null);
    try {
      await getIt<Hostr>().auth.signin(_private);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      return;
    }
    // Don't navigate — the startup gate detects LoggedIn, re-bootstraps,
    // and consumes PendingNavigation when ready.
  }

  Future<void> _handleSignup() async {
    print('signup start ${DateTime.now()}');
    final mnemonic = Mnemonic(
      hex.decode(Helpers.getSecureRandomHex(32)),
      Language.english,
    );
    print('signup middle ${DateTime.now()}');

    final identity = await getIt<Hostr>().auth.previewResolvedIdentity(
      mnemonic.sentence,
    );
    print('signup end ${DateTime.now()}');

    await showAppModal(
      context,
      isDismissible: false,
      builder: (_) => BackupKeyWidget(
        publicKeyHex: identity.publicKeyHex!,
        privateKeyHex: identity.privateKeyHex!,
        mnemonic: mnemonic.sentence,
      ),
    );
    if (!mounted) return;
    try {
      await getIt<Hostr>().auth.signin(mnemonic.sentence);
    } catch (_) {
      return;
    }
    // Don't navigate — the startup gate handles post-auth routing.
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomPadding(
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo/generated/logo_base_1024.png',
            width: 120,
            height: 120,
          ),
          Gap.vertical.lg(),
          TextFormField(
            key: const ValueKey('key'),
            controller: _controller,
            onChanged: (value) {
              setState(() {
                _private = value;
                _error = null;
              });
            },
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'nsec',
              errorText: _error,
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _controller.text = data!.text!;
                    setState(() {
                      _private = data.text!;
                      _error = null;
                    });
                  }
                },
              ),
            ),
          ),
          Gap.vertical.sm(),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const ValueKey('login'),
                  onPressed: _isValidInput ? _handleSignin : null,
                  child: Text(l10n.signIn),
                ),
              ),
              Gap.horizontal.sm(),
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleSignup,
                  child: Text(l10n.signUp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppPageGutter(
        child: AppPaneLayout(
          panes: [
            AppPane(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: kAppFormMaxWidth),
                      child: _buildContent(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
