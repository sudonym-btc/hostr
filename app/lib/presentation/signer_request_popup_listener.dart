import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

const kSignerApprovalDelay = Duration(seconds: 2);

const kNonBlockingSignerRequestEventKinds = <int>{
  kNostrKindReceivedHeartbeat,
  kNostrKindRelayAuthentication,
};

bool shouldShowFullPageSignerRequest(PendingSignerRequest request) {
  if (request.method != SignerMethod.signEvent) return true;
  final kind = request.event?.kind;
  if (kind == null) return true;
  return !kNonBlockingSignerRequestEventKinds.contains(kind);
}

PendingSignerRequest? visibleFullPageSignerRequest({
  required Iterable<PendingSignerRequest> requests,
  required Set<String> dismissedRequestIds,
  required DateTime now,
  Duration approvalDelay = kSignerApprovalDelay,
}) {
  for (final request in requests) {
    if (dismissedRequestIds.contains(request.id)) continue;
    if (!shouldShowFullPageSignerRequest(request)) continue;
    if (now.difference(request.createdAt) < approvalDelay) continue;
    return request;
  }
  return null;
}

String signerRequestEventKindDescription(int? kind) {
  return switch (kind) {
    kNostrKindProfile => 'profile metadata',
    kNostrKindRelayAuthentication => 'relay authentication',
    kNostrKindListing => 'listing',
    kNostrKindOrder => 'reservation update',
    kNostrKindReview => 'review',
    kNostrKindCommitAuthorization => 'payment commit authorization',
    kNostrKindTradeKeyAuthorization => 'trade key authorization',
    kNostrKindHostrSeed => 'account recovery seed',
    kNostrKindOrderTransition => 'reservation transition',
    kNostrKindEscrowService => 'escrow service advertisement',
    kNostrKindEscrowMethod => 'escrow payment methods',
    kNostrKindEscrowServiceSelected => 'escrow selection',
    kNostrKindLegacyDM => 'legacy direct message',
    kNostrKindDM => 'direct message',
    kNostrKindJsonMessage => 'Hostr message',
    kNostrKindSeenStatus => 'seen status',
    kNostrKindReaction => 'reaction',
    kNostrKindZapRequest => 'zap request',
    kNostrKindZapReceipt => 'zap receipt',
    kNostrKindConnect => 'Nostr Connect request',
    kNostrKindSeal => 'encrypted message seal',
    kNostrKindGiftWrap => 'encrypted message wrapper',
    kNostrKindDmRelays => 'direct message relay list',
    kNostrKindReceivedHeartbeat => 'heartbeat',
    kNostrKindSeenMessages => 'seen message marker',
    kNostrKindNWCInfo => 'Nostr Wallet Connect info',
    kNostrKindNWCRequest => 'Nostr Wallet Connect request',
    kNostrKindNWCResponse => 'Nostr Wallet Connect response',
    kNostrKindNWCNotification => 'Nostr Wallet Connect notification',
    kNostrKindBadgeAward => 'badge award',
    kNostrKindBadgeDefinition => 'badge definition',
    kNostrKindProfileBadges => 'profile badges',
    null => 'signer request',
    _ => 'Nostr event',
  };
}

class SignerRequestPopupListener extends StatefulWidget {
  final Widget child;

  const SignerRequestPopupListener({super.key, required this.child});

  @override
  State<SignerRequestPopupListener> createState() =>
      _SignerRequestPopupListenerState();
}

class _SignerRequestPopupListenerState
    extends State<SignerRequestPopupListener> {
  final Set<String> _dismissedRequestIds = {};
  Timer? _ticker;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<List<PendingSignerRequest>>? _pendingSub;
  Object? _attachedAccount;
  List<PendingSignerRequest> _pendingRequests = const [];

  @override
  void initState() {
    super.initState();
    if (!getIt.isRegistered<Hostr>()) return;
    _attachToCurrentAccount();
    _authSub = getIt<Hostr>().auth.authState.listen((_) {
      _attachToCurrentAccount();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _attachToCurrentAccount();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel());
    unawaited(_pendingSub?.cancel());
    _ticker?.cancel();
    super.dispose();
  }

  void _attachToCurrentAccount() {
    if (!mounted || !getIt.isRegistered<Hostr>()) return;
    final hostr = getIt<Hostr>();
    final pubkey = hostr.auth.activePubkey;
    final account = pubkey == null ? null : hostr.ndk.accounts.accounts[pubkey];
    if (identical(account, _attachedAccount)) return;

    _attachedAccount = account;
    unawaited(_pendingSub?.cancel());
    _pendingSub = null;
    _pendingRequests = account?.pendingRequests ?? const [];

    if (account != null) {
      _pendingSub = account.pendingRequestsStream.listen((requests) {
        if (!mounted) return;
        setState(() {
          _pendingRequests = requests;
        });
      });
    }

    if (mounted) setState(() {});
  }

  PendingSignerRequest? get _visibleRequest {
    return visibleFullPageSignerRequest(
      requests: _pendingRequests,
      dismissedRequestIds: _dismissedRequestIds,
      now: DateTime.now(),
    );
  }

  void _keepWaiting(PendingSignerRequest request) {
    setState(() {
      _dismissedRequestIds.add(request.id);
    });
  }

  void _cancel(PendingSignerRequest request) {
    if (!getIt.isRegistered<Hostr>()) return;
    final hostr = getIt<Hostr>();
    final pubkey = hostr.auth.activePubkey;
    final account = pubkey == null ? null : hostr.ndk.accounts.accounts[pubkey];
    account?.cancelRequest(request.id);
    setState(() {
      _dismissedRequestIds.add(request.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = _visibleRequest;
    return Stack(
      children: [
        widget.child,
        if (request != null)
          Positioned.fill(
            child: SignerRequestPopupPage(
              kind: request.event?.kind,
              method: request.method.protocolString,
              createdAt: request.createdAt,
              onKeepWaiting: () => _keepWaiting(request),
              onCancel: () => _cancel(request),
            ),
          ),
      ],
    );
  }
}

class SignerRequestPopupPage extends StatelessWidget {
  final int? kind;
  final String method;
  final DateTime createdAt;
  final VoidCallback onKeepWaiting;
  final VoidCallback onCancel;

  const SignerRequestPopupPage({
    super.key,
    required this.kind,
    required this.method,
    required this.createdAt,
    required this.onKeepWaiting,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final description = signerRequestEventKindDescription(kind);

    return Scaffold(
      key: const ValueKey('signer_request_popup_page'),
      body: AppPane(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: colors.tertiaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.approval_outlined,
                                size: 40,
                                color: colors.onTertiaryContainer,
                              ),
                            ),
                            Gap.vertical.lg(),
                            Text(
                              'Approve in your Nostr app',
                              key: const ValueKey('signer_request_popup_title'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Gap.vertical.sm(),
                            Text(
                              'Hostr is waiting for your remote signer to approve the $description. This usually means your signer app needs attention.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            Gap.vertical.lg(),
                            _SignerRequestDetails(
                              method: method,
                              kind: kind,
                              createdAt: createdAt,
                            ),
                            Gap.vertical.lg(),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                key: const ValueKey(
                                  'signer_request_keep_waiting_button',
                                ),
                                onPressed: onKeepWaiting,
                                child: const Text('Keep waiting'),
                              ),
                            ),
                            Gap.vertical.sm(),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                key: const ValueKey(
                                  'signer_request_cancel_button',
                                ),
                                onPressed: onCancel,
                                child: const Text('Cancel request'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignerRequestDetails extends StatefulWidget {
  final String method;
  final int? kind;
  final DateTime createdAt;

  const _SignerRequestDetails({
    required this.method,
    required this.kind,
    required this.createdAt,
  });

  @override
  State<_SignerRequestDetails> createState() => _SignerRequestDetailsState();
}

class _SignerRequestDetailsState extends State<_SignerRequestDetails> {
  bool _expanded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final elapsed = _elapsedText(widget.createdAt);

    return Align(
      alignment: Alignment.centerLeft,
      child: MessageContainer(
        isSentByMe: false,
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall!.copyWith(color: colors.onSurface),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Request details',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'Waiting: $elapsed',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Gap.horizontal.xs(),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded) ...[
                  Gap.vertical.xs(),
                  Text('Waiting: $elapsed'),
                  Text('Action: ${_methodLabel(widget.method)}'),
                  Text(
                    'Request: ${signerRequestEventKindDescription(widget.kind)}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _elapsedText(DateTime value) {
    final seconds = DateTime.now().difference(value).inSeconds;
    if (seconds <= 0) return 'now';
    return '${seconds}s';
  }

  String _methodLabel(String value) {
    return switch (value) {
      'sign_event' => 'Sign approval',
      'nip04_encrypt' || 'nip44_encrypt' => 'Encrypt message',
      'nip04_decrypt' || 'nip44_decrypt' => 'Decrypt message',
      _ => value.replaceAll('_', ' '),
    };
  }
}
