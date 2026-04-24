import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/keys/backup_key.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart' show NostrConnect;
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  bool _isSigningIn = false;
  String? _progress;
  NostrConnect? _nostrConnect;
  String? _nostrConnectStatus;
  String? _nostrConnectError;
  Future<void>? _nostrConnectLoginFuture;

  @override
  void initState() {
    super.initState();
    _initializeNostrConnect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValidInput {
    final trimmed = _private.trim();
    if (trimmed.isEmpty) return false;

    if (trimmed.startsWith('bunker://')) {
      final uri = Uri.tryParse(trimmed);
      return uri != null && uri.scheme == 'bunker' && uri.host.isNotEmpty;
    }

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

  bool get _isBunkerInput => _private.trim().startsWith('bunker://');

  Future<void> _handleSignin() async {
    setState(() {
      _error = null;
      _isSigningIn = true;
      _progress = _isBunkerInput
          ? 'Waiting for bunker approval...'
          : 'Signing in...';
    });

    try {
      final auth = getIt<Hostr>().auth;
      if (_isBunkerInput) {
        await auth.signinWithBunkerUrl(
          _private,
          authCallback: (challenge) {
            if (!mounted) return;
            setState(() {
              _progress = challenge.trim().isEmpty
                  ? 'Waiting for bunker approval...'
                  : challenge;
            });
          },
        );
      } else {
        await auth.signin(_private);
      }
      if (mounted) {
        setState(() {
          _progress = 'Signed in. Finishing setup...';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSigningIn = false;
          _progress = null;
        });
      }
      return;
    }
    // Don't navigate — the startup gate detects LoggedIn, re-bootstraps,
    // and consumes PendingNavigation when ready.
  }

  Future<void> _handleSignup() async {
    final mnemonic = Mnemonic(
      hex.decode(Helpers.getSecureRandomHex(32)),
      Language.english,
    );

    final identity = await getIt<Hostr>().auth.previewResolvedIdentity(
      mnemonic.sentence,
    );
    if (!mounted) return;

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

  NostrConnect? _buildNostrConnect() {
    final hostr = getIt<Hostr>();
    final config = hostr.config;
    final relays = [
      if (config.hostrRelay.trim().isNotEmpty) config.hostrRelay.trim(),
    ];
    if (relays.isEmpty) return null;

    return NostrConnect(
      relays: relays,
      appName: 'Hostr',
      appUrl: 'https://hostr.network',
      appImageUrl:
          'https://hostr.network/assets/assets/images/logo/generated/logo_base_1024.png',
      perms: const [
        'sign_event',
        'nip44_encrypt',
        'nip44_decrypt',
        'nip04_encrypt',
        'nip04_decrypt',
      ],
    );
  }

  void _initializeNostrConnect() {
    if (_nostrConnectLoginFuture != null) return;

    final nostrConnect = _buildNostrConnect();
    if (nostrConnect == null) {
      setState(() {
        _nostrConnectError = 'No relay available for Nostr Connect login.';
      });
      return;
    }

    setState(() {
      _nostrConnect = nostrConnect;
      _nostrConnectError = null;
      _nostrConnectStatus = '';
    });

    _nostrConnectLoginFuture = _listenForNostrConnectLogin(nostrConnect);
  }

  Future<void> _listenForNostrConnectLogin(NostrConnect nostrConnect) async {
    final auth = getIt<Hostr>().auth;
    var shouldRetry = false;
    try {
      await auth.signinWithNostrConnect(
        nostrConnect,
        authCallback: (challenge) {
          if (!mounted) return;
          setState(() {
            _nostrConnectStatus = challenge.trim().isEmpty
                ? 'Waiting for signer approval...'
                : challenge;
          });
        },
      );
      if (mounted) {
        setState(() {
          _nostrConnectStatus = 'Signed in. Finishing setup...';
          _nostrConnectError = null;
        });
      }
    } on TimeoutException catch (e) {
      shouldRetry = true;
      if (mounted) {
        setState(() {
          _nostrConnectError = e.toString();
          _nostrConnectStatus = 'Signer timed out. Retrying in 5 seconds...';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nostrConnectError = e.toString();
          _nostrConnectStatus = 'Could not connect. Refresh and try again.';
        });
      }
    } finally {
      _nostrConnectLoginFuture = null;
    }

    if (!shouldRetry) return;

    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted || _nostrConnectLoginFuture != null) return;
    _initializeNostrConnect();
  }

  TextStyle? _sectionLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 2.4,
    );
  }

  Widget _buildQrPane(BuildContext context) {
    final nostrConnectUrl = _nostrConnect?.nostrConnectURL;
    final theme = Theme.of(context);

    return CustomPadding(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final qrSize = (constraints.maxWidth * 0.72).clamp(220.0, 360.0);
          final panelWidth = qrSize + 24;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 34,
                color: theme.colorScheme.primary,
              ),
              Gap.vertical.md(),
              Text(
                'SCAN OR COPY TO CONNECT',
                style: _sectionLabelStyle(context),
                textAlign: TextAlign.center,
              ),
              Gap.vertical.lg(),
              if (nostrConnectUrl != null)
                Container(
                  width: panelWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: QrImageView(
                      data: nostrConnectUrl,
                      version: QrVersions.auto,
                      size: qrSize,
                      backgroundColor: Colors.white,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: panelWidth,
                  height: 280,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              Gap.vertical.md(),
              if (nostrConnectUrl != null)
                SizedBox(
                  width: panelWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          nostrConnectUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      Gap.horizontal.sm(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: CopyFeedbackButton(
                          value: () => nostrConnectUrl,
                          label: 'Copy',
                          variant: CopyFeedbackButtonVariant.outlined,
                          showCopyIcon: true,
                          style: AppButtonStyles.outlined(context).copyWith(
                            minimumSize: WidgetStateProperty.all(
                              const Size(0, 40),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_nostrConnectStatus != null) ...[
                Gap.vertical.md(),
                Text(
                  _nostrConnectStatus!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              if (_nostrConnectError != null) ...[
                Gap.vertical.sm(),
                Text(
                  _nostrConnectError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildManualPane(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return CustomPadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo/generated/logo_base_1024.png',
              width: 120,
              height: 120,
            ),
          ),
          Gap.vertical.lg(),
          Text(
            'SIGN IN MANUALLY',
            style: _sectionLabelStyle(context),
            textAlign: TextAlign.center,
          ),
          Gap.vertical.xl(),
          TextFormField(
            key: const ValueKey('key'),
            controller: _controller,
            onChanged: (value) {
              setState(() {
                _private = value;
                _error = null;
              });
            },
            maxLines: 1,
            decoration: InputDecoration(
              hintText: 'bunker:// or nsec',
              errorText: _error,
            ),
            enabled: !_isSigningIn,
          ),
          if (_progress != null) ...[
            Gap.vertical.sm(),
            Row(
              children: [
                if (_isSigningIn) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Gap.horizontal.sm(),
                ],
                Expanded(
                  child: Text(_progress!, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ],
          Gap.vertical.lg(),
          FilledButton(
            key: const ValueKey('login'),
            onPressed: !_isSigningIn && _isValidInput ? _handleSignin : null,
            child: Text(l10n.signIn),
          ),
          Gap.vertical.xl(),
          Divider(color: theme.colorScheme.outline.withAlpha(80)),
          Gap.vertical.lg(),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: !_isSigningIn && _private.trim().isEmpty
                  ? _handleSignup
                  : null,
              child: const Text("I'm new to Nostr"),
            ),
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
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: kAppFormMaxWidth),
                      child: _buildQrPane(context),
                    ),
                  ),
                ],
              ),
            ),
            AppPane(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: kAppFormMaxWidth),
                      child: _buildManualPane(context),
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
