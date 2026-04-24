import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

const _signerApprovalDelay = Duration(seconds: 5);

const _criticalSignerKinds = <int>{
  kNostrKindCommitAuthorization,
  kNostrKindTradeKeyAuthorization,
  kNostrKindReservation,
  kNostrKindReservationTransition,
  kNostrKindReview,
  kNostrKindEscrowServiceSelected,
  kNostrKindHostrSeed,
};

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
    final now = DateTime.now();
    for (final request in _pendingRequests) {
      if (_dismissedRequestIds.contains(request.id)) continue;
      if (!_isCriticalRequest(request)) continue;
      if (now.difference(request.createdAt) < _signerApprovalDelay) continue;
      return request;
    }
    return null;
  }

  bool _isCriticalRequest(PendingSignerRequest request) {
    if (request.method != SignerMethod.signEvent) return false;
    final kind = request.event?.kind;
    return kind != null && _criticalSignerKinds.contains(kind);
  }

  void _keepWaiting(PendingSignerRequest request) {
    setState(() {
      _dismissedRequestIds.add(request.id);
    });
  }

  void _cancel(PendingSignerRequest request) {
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
            child: _SignerRequestOverlay(
              request: request,
              onKeepWaiting: () => _keepWaiting(request),
              onCancel: () => _cancel(request),
            ),
          ),
      ],
    );
  }
}

class _SignerRequestOverlay extends StatelessWidget {
  final PendingSignerRequest request;
  final VoidCallback onKeepWaiting;
  final VoidCallback onCancel;

  const _SignerRequestOverlay({
    required this.request,
    required this.onKeepWaiting,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final kind = request.event?.kind;
    final title = _titleForKind(kind);

    return Material(
      color: colors.scrim.withValues(alpha: 0.72),
      child: Center(
        child: CustomPadding.horizontal.lg(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppBorderRadii.xl,
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: CustomPadding.lg(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.approval_outlined,
                      size: kIconHero,
                      color: colors.primary,
                    ),
                    Gap.vertical.md(),
                    Text(
                      'Approve in your Nostr app',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Gap.vertical.sm(),
                    Text(
                      'Hostr is waiting for your remote signer to approve $title. This usually means your signer app needs attention.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Gap.vertical.md(),
                    _RequestMetadata(request: request),
                    Gap.vertical.custom(kSpace5),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: kSpace3,
                      runSpacing: kSpace3,
                      children: [
                        FilledButton.icon(
                          onPressed: onKeepWaiting,
                          icon: const Icon(Icons.hourglass_empty),
                          label: const Text('Keep waiting'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel request'),
                        ),
                      ],
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

  String _titleForKind(int? kind) {
    return switch (kind) {
      kNostrKindTradeKeyAuthorization => 'the trade key authorization',
      kNostrKindCommitAuthorization => 'the payment commit authorization',
      kNostrKindReservation => 'the reservation update',
      kNostrKindReservationTransition => 'the reservation transition',
      kNostrKindReview => 'the review',
      kNostrKindEscrowServiceSelected => 'the escrow selection',
      kNostrKindHostrSeed => 'the account recovery seed',
      _ => 'a Hostr event',
    };
  }
}

class _RequestMetadata extends StatelessWidget {
  final PendingSignerRequest request;

  const _RequestMetadata({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final kind = request.event?.kind;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppBorderRadii.md,
      ),
      child: CustomPadding.md(
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall!.copyWith(
            color: colors.onSurfaceVariant,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Method: ${request.method.protocolString}'),
              if (kind != null) Text('Kind: $kind'),
              Text('Waiting since: ${_formatTime(request.createdAt)}'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
