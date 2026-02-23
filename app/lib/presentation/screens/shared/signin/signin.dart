import 'package:auto_route/auto_route.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/keys/backup_key.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

@RoutePage()
class SignInScreen extends StatefulWidget {
  final Function? onSuccess;
  // ignore: use_key_in_widget_constructors
  const SignInScreen({this.onSuccess});

  @override
  State<StatefulWidget> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  String _private = '';
  String? _error;

  /// Returns true if the current input looks like a valid nsec, hex key, or mnemonic.
  bool get _isValidInput {
    final trimmed = _private.trim();
    if (trimmed.isEmpty) return false;

    // 64-char hex
    if (trimmed.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
      return true;
    }

    // nsec bech32
    if (trimmed.startsWith('nsec1')) {
      try {
        final decoded = Helpers.decodeBech32(trimmed);
        return decoded[0].isNotEmpty && decoded[0].length == 64;
      } catch (_) {
        return false;
      }
    }

    // 12 or 24-word mnemonic
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
    final router = AutoRouter.of(context);
    try {
      await context.read<AuthCubit>().signin(_private);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      return;
    }
    if (!mounted) return;
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      router.replaceAll([OnboardingRoute()]);
    }
  }

  Future<void> _handleSignup() async {
    setState(() => _error = null);
    // Generate key pair first, show backup modal, THEN sign in.
    final keyPair = Bip340.generatePrivateKey();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => BackupKeyWidget(
        publicKeyHex: keyPair.publicKey,
        privateKeyHex: keyPair.privateKey!,
      ),
    );
    if (!mounted) return;
    final router = AutoRouter.of(context);
    try {
      await context.read<AuthCubit>().signin(keyPair.privateKey!);
    } catch (_) {
      return;
    }
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      router.replaceAll([OnboardingRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return SafeArea(
            child: CustomPadding(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // ── Logo ──
                  Image.asset('assets/images/logo/logo.png', height: 80),
                  Gap.vertical.custom(40),
                  // ── Private key field ──
                  TextFormField(
                    key: const ValueKey('key'),
                    onChanged: (value) {
                      setState(() {
                        _private = value;
                        _error = null;
                      });
                    },
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'nsec or recovery phrase',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.key),
                    ),
                  ),
                  Gap.vertical.custom(kSpace5),
                  // ── Sign In button ──
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('login'),
                      onPressed: _isValidInput ? _handleSignin : null,
                      child: Text(l10n.signIn),
                    ),
                  ),
                  Gap.vertical.md(),
                  // ── OR divider ──
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      CustomPadding.horizontal.md(
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  Gap.vertical.md(),
                  // ── Sign Up button ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleSignup,
                      child: Text(l10n.signUp),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
