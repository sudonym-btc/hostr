import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

// ─── NIP-05 Input ──────────────────────────────────────────────

class Nip05Input extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  /// The pubkey to verify the NIP-05 against.
  final String pubkey;

  const Nip05Input({
    super.key,
    required this.controller,
    required this.pubkey,
    this.validator,
  });

  @override
  State<Nip05Input> createState() => _Nip05InputState();
}

class _Nip05InputState extends State<Nip05Input> {
  Timer? _debounce;
  Nip05VerificationResult? _result;
  bool _loading = false;
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.text.trim();
    widget.controller.addListener(_onChanged);
    // Run initial verification if there's already a value.
    if (_lastValue.isNotEmpty) {
      _verify(_lastValue);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    final value = widget.controller.text.trim();
    if (value == _lastValue) return;
    _lastValue = value;
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() {
        _result = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _verify(value);
    });
  }

  Future<void> _verify(String nip05) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final result = await getIt<Hostr>().verification.verifyNip05(
        nip05: nip05,
        pubkey: widget.pubkey,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _result = Nip05VerificationResult.invalid(error: e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          decoration: const InputDecoration(
            hintText: 'user@example.com',
            isDense: true,
          ),
        ),
        _Nip05Status(result: _result, loading: _loading),
      ],
    );
  }
}

class _Nip05Status extends StatelessWidget {
  final Nip05VerificationResult? result;
  final bool loading;

  const _Nip05Status({this.result, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _statusRow(
        context,
        icon: Icons.badge_outlined,
        iconColor: Theme.of(context).colorScheme.outline,
        text: 'Verifying…',
        trailing: const AppLoadingIndicator.small(),
      );
    }

    if (result == null) return const SizedBox.shrink();

    final valid = result!.valid;
    return _statusRow(
      context,
      icon: valid ? Icons.verified : Icons.error_outline,
      iconColor: valid ? Colors.blue : Theme.of(context).colorScheme.error,
      text: valid ? 'Verified' : (result!.error ?? 'Verification failed'),
      textColor: valid ? Colors.blue : Theme.of(context).colorScheme.error,
    );
  }
}

// ─── Lightning Address (LUD-16) Input ──────────────────────────

class LnurlInput extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const LnurlInput({super.key, required this.controller, this.validator});

  @override
  State<LnurlInput> createState() => _LnurlInputState();
}

class _LnurlInputState extends State<LnurlInput> {
  Timer? _debounce;
  Lud16VerificationResult? _result;
  bool _loading = false;
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.text.trim();
    widget.controller.addListener(_onChanged);
    if (_lastValue.isNotEmpty) {
      _verify(_lastValue);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    final value = widget.controller.text.trim();
    if (value == _lastValue) return;
    _lastValue = value;
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() {
        _result = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _verify(value);
    });
  }

  Future<void> _verify(String lud16) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final result = await getIt<Hostr>().verification.verifyLud16(
        lud16: lud16,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _result = Lud16VerificationResult.unreachable(
            error: e.toString(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          decoration: const InputDecoration(
            hintText: 'user@wallet.com',
            isDense: true,
          ),
        ),
        _Lud16Status(result: _result, loading: _loading),
      ],
    );
  }
}

class _Lud16Status extends StatelessWidget {
  final Lud16VerificationResult? result;
  final bool loading;

  const _Lud16Status({this.result, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _statusRow(
        context,
        icon: Icons.bolt_outlined,
        iconColor: Theme.of(context).colorScheme.outline,
        text: 'Verifying…',
        trailing: const AppLoadingIndicator.small(),
      );
    }

    if (result == null) return const SizedBox.shrink();

    final reachable = result!.reachable;
    final allowsNostr = result!.allowsNostr;

    if (!reachable) {
      return _statusRow(
        context,
        icon: Icons.bolt_outlined,
        iconColor: Theme.of(context).colorScheme.error,
        text: result!.error ?? 'Unreachable',
        textColor: Theme.of(context).colorScheme.error,
      );
    }

    // Reachable — show with optional zap chip
    return Row(
      children: [
        Icon(Icons.bolt, color: Colors.amber, size: kIconSm),
        Gap.horizontal.custom(6),
        Text(
          'Reachable',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.green),
        ),
        if (allowsNostr) ...[
          Gap.horizontal.sm(),
          _chip(context, label: 'Zaps enabled', color: Colors.blue),
        ],
      ],
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────

Widget _statusRow(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String text,
  Color? textColor,
  Widget? trailing,
}) {
  return Row(
    children: [
      Icon(icon, color: iconColor, size: kIconSm),
      Gap.horizontal.custom(6),
      Expanded(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor ?? Theme.of(context).colorScheme.outline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (trailing != null) trailing,
    ],
  );
}

Widget _chip(
  BuildContext context, {
  required String label,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
