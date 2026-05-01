import 'dart:async';
import 'dart:convert';

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
import 'package:ndk/data_layer/repositories/signers/default_event_signer_factory.dart';
import 'package:ndk/domain_layer/usecases/bunkers/models/bunker_request.dart';
import 'package:ndk/ndk.dart'
    show BunkerConnection, Bunkers, Filter, NdkResponse, NostrConnect;
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:qr_flutter/qr_flutter.dart';

@RoutePage()
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<StatefulWidget> createState() => SignInScreenState();
}

enum _SignInPane { connect, manual }

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
  // Nostr Connect login opens a live bunker-request subscription. Keep the
  // handle and explicit relay list so refresh/dispose can send CLOSE to the
  // actual relay instead of leaving stale Signet subscriptions behind.
  NdkResponse? _nostrConnectSubscription;
  List<String>? _nostrConnectSubscriptionRelays;
  _SignInPane _stackedPane = _SignInPane.connect;
  // Each QR refresh increments this token. Async callbacks compare against it
  // so an old timed-out subscription cannot update the current login screen.
  var _nostrConnectDisposed = false;
  var _nostrConnectAttempt = 0;

  @override
  void initState() {
    super.initState();
    _initializeNostrConnect();
  }

  @override
  void dispose() {
    _nostrConnectDisposed = true;
    final subscription = _nostrConnectSubscription;
    if (subscription != null) {
      unawaited(
        _closeNostrConnectSubscription(
          subscription,
          relays: _nostrConnectSubscriptionRelays ?? const [],
        ),
      );
    }
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

    final attempt = ++_nostrConnectAttempt;
    setState(() {
      _nostrConnect = nostrConnect;
      _nostrConnectError = null;
      _nostrConnectStatus = '';
    });

    _nostrConnectLoginFuture = _listenForNostrConnectLogin(
      nostrConnect,
      attempt,
    );
  }

  Future<void> restartNostrConnect() async {
    // Restart must close the old relay subscription first; otherwise Signet
    // keeps serving approvals to an abandoned nostrconnect URI.
    _nostrConnectAttempt++;
    final subscription = _nostrConnectSubscription;
    final subscriptionRelays = _nostrConnectSubscriptionRelays ?? const [];
    _nostrConnectSubscription = null;
    _nostrConnectSubscriptionRelays = null;
    _nostrConnectLoginFuture = null;
    if (mounted) {
      setState(() {
        _nostrConnect = null;
        _nostrConnectStatus = null;
        _nostrConnectError = null;
      });
    }
    if (subscription != null) {
      await _closeNostrConnectSubscription(
        subscription,
        relays: subscriptionRelays,
      );
    }
    if (!mounted) return;
    _initializeNostrConnect();
  }

  bool _isActiveNostrConnectAttempt(int attempt) {
    return !_nostrConnectDisposed && mounted && attempt == _nostrConnectAttempt;
  }

  Future<void> _listenForNostrConnectLogin(
    NostrConnect nostrConnect,
    int attempt,
  ) async {
    var shouldRetry = false;
    try {
      await _signinWithCancellableNostrConnect(
        nostrConnect,
        attempt: attempt,
        authCallback: (challenge) {
          if (!_isActiveNostrConnectAttempt(attempt)) return;
          setState(() {
            _nostrConnectStatus = challenge.trim().isEmpty
                ? 'Waiting for signer approval...'
                : challenge;
          });
        },
      );
      if (_isActiveNostrConnectAttempt(attempt)) {
        setState(() {
          _nostrConnectStatus = 'Signed in. Finishing setup...';
          _nostrConnectError = null;
        });
      }
    } on TimeoutException catch (e) {
      shouldRetry = true;
      if (_isActiveNostrConnectAttempt(attempt)) {
        setState(() {
          _nostrConnectError = e.toString();
          _nostrConnectStatus = 'Signer timed out. Retrying in 5 seconds...';
        });
      }
    } catch (e) {
      if (_isActiveNostrConnectAttempt(attempt)) {
        setState(() {
          _nostrConnectError = e.toString();
          _nostrConnectStatus = 'Could not connect. Refresh and try again.';
        });
      }
    } finally {
      if (attempt == _nostrConnectAttempt) {
        _nostrConnectLoginFuture = null;
      }
    }

    if (!shouldRetry || attempt != _nostrConnectAttempt) return;

    await Future<void>.delayed(const Duration(seconds: 5));
    if (!_isActiveNostrConnectAttempt(attempt) ||
        _nostrConnectLoginFuture != null) {
      return;
    }
    _initializeNostrConnect();
  }

  Future<void> _signinWithCancellableNostrConnect(
    NostrConnect nostrConnect, {
    required int attempt,
    void Function(String challenge)? authCallback,
  }) async {
    // Auth.signinWithNostrConnect hides the subscription handle, which makes it
    // impossible for the UI to cancel a stale QR attempt. This local copy keeps
    // the same protocol steps but exposes cancellation to the widget lifecycle.
    final hostr = getIt<Hostr>();
    final relays = nostrConnect.relays;
    if (relays.isEmpty) {
      throw ArgumentError('At least one relay is required');
    }

    final keyPair = nostrConnect.keyPair;
    final localEventSigner = defaultEventSignerFactory(
      publicKey: keyPair.publicKey,
      privateKey: keyPair.privateKey,
    );
    final subscription = hostr.ndk.requests.subscription(
      explicitRelays: relays,
      filter: Filter(
        kinds: [BunkerRequest.kKind],
        pTags: [localEventSigner.getPublicKey()],
        since: hostr.ndk.bunkers.someTimeAgo(),
      ),
      name: 'signin-nostrconnect',
    );
    _nostrConnectSubscription = subscription;
    _nostrConnectSubscriptionRelays = relays.toList(growable: false);

    BunkerConnection? connection;
    try {
      await for (final event in subscription.stream.timeout(
        const Duration(seconds: Bunkers.kMaxWaitingTimeForConnectionSeconds),
      )) {
        if (!_isActiveNostrConnectAttempt(attempt)) return;

        final decryptedContent = await localEventSigner.decryptNip44(
          ciphertext: event.content,
          senderPubKey: event.pubKey,
        );
        if (decryptedContent == null || decryptedContent.isEmpty) continue;

        final response = jsonDecode(decryptedContent);
        if (response is! Map || response['result'] != nostrConnect.secret) {
          continue;
        }

        connection = BunkerConnection(
          privateKey: keyPair.privateKey!,
          remotePubkey: event.pubKey,
          relays: relays,
        );
        break;
      }
    } finally {
      if (identical(_nostrConnectSubscription, subscription)) {
        _nostrConnectSubscription = null;
        _nostrConnectSubscriptionRelays = null;
      }
      await _closeNostrConnectSubscription(subscription, relays: relays);
    }

    if (!_isActiveNostrConnectAttempt(attempt) || connection == null) return;
    await hostr.auth.signinWithBunkerConnection(
      connection,
      authCallback: authCallback,
    );
  }

  Future<void> _closeNostrConnectSubscription(
    NdkResponse subscription, {
    required Iterable<String> relays,
  }) async {
    final hostr = getIt<Hostr>();
    final requests = hostr.ndk.requests;
    for (var attempt = 0; attempt < 5; attempt++) {
      // NDK can lose the relay-url mapping for this short-lived subscription,
      // so send CLOSE directly to the nostrconnect relays before asking the
      // request manager to clean up its local bookkeeping.
      for (final relay in relays) {
        hostr.ndk.relays.sendCloseToRelay(relay, subscription.requestId);
      }
      await requests.closeSubscription(
        subscription.requestId,
        debugLabel: 'signin-nostrconnect-close-$attempt',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  TextStyle? _sectionLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      // letterSpacing: 2.4,
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
                'Connect with Nostr',
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
                          key: const ValueKey('signin_nostrconnect_uri'),
                          nostrConnectUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
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
                          variant: CopyFeedbackButtonVariant.material,
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
          // Center(
          //   child: Image.asset(
          //     'assets/images/logo/generated/logo_base_1024.png',
          //     width: 120,
          //     height: 120,
          //   ),
          // ),
          // Gap.vertical.lg(),
          Icon(Icons.key_rounded, size: 34, color: theme.colorScheme.primary),
          Gap.vertical.md(),
          Text(
            'Sign in manually',
            style: _sectionLabelStyle(context),
            textAlign: TextAlign.center,
          ),
          Gap.vertical.xl(),
          TextFormField(
            key: const ValueKey('signin_private_key_input'),
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
            key: const ValueKey('signin_manual_login_button'),
            onPressed: !_isSigningIn && _isValidInput ? _handleSignin : null,
            child: Text(l10n.signIn),
          ),
          Gap.vertical.xl(),
          Divider(color: theme.colorScheme.outline.withAlpha(80)),
          Gap.vertical.lg(),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: const ValueKey('signin_signup_button'),
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

  Widget _buildStackedTabSelector(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('signin_stacked_tabs'),
      height: 58,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withAlpha(90)),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withAlpha(120),
      ),
      child: Row(
        children: [
          _buildStackedTab(
            context,
            key: const ValueKey('signin_tab_connect'),
            pane: _SignInPane.connect,
            icon: Icons.qr_code_scanner_rounded,
            label: 'Connect',
          ),
          _buildStackedTab(
            context,
            key: const ValueKey('signin_tab_manual'),
            pane: _SignInPane.manual,
            icon: Icons.key_rounded,
            label: 'Manual',
          ),
        ],
      ),
    );
  }

  Widget _buildStackedTab(
    BuildContext context, {
    required Key key,
    required _SignInPane pane,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final selected = _stackedPane == pane;
    final foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (_stackedPane == pane) return;
              setState(() => _stackedPane = pane);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? theme.colorScheme.primaryContainer.withAlpha(190)
                    : Colors.transparent,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: foreground),
                    Gap.horizontal.sm(),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackedSignIn(BuildContext context) {
    return SafeArea(
      child: AppPageGutter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kAppFormMaxWidth,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStackedTabSelector(context),
                        Gap.vertical.xl(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: KeyedSubtree(
                            key: ValueKey(_stackedPane),
                            child: _stackedPane == _SignInPane.connect
                                ? _buildQrPane(context)
                                : _buildManualPane(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandedSignIn(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveView(
      expanded: _buildExpandedSignIn,
      compact: _buildStackedSignIn,
    );
  }
}
