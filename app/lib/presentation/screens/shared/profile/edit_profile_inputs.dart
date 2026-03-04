import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/profile/verification/main.dart';

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
  final _verification = ProfileVerificationController();
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.text.trim();
    widget.controller.addListener(_onChanged);
    _verification.addListener(_onVerificationChanged);
    // Run initial verification if there's already a value.
    if (_lastValue.isNotEmpty) {
      _verification.verifyNip05Only(nip05: _lastValue, pubkey: widget.pubkey);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _verification
      ..removeListener(_onVerificationChanged)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onVerificationChanged() {
    if (mounted) setState(() {});
  }

  void _onChanged() {
    final value = widget.controller.text.trim();
    if (value == _lastValue) return;
    _lastValue = value;
    _debounce?.cancel();
    if (value.isEmpty) {
      _verification.verifyNip05Only(nip05: '', pubkey: widget.pubkey);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _verification.verifyNip05Only(nip05: value, pubkey: widget.pubkey);
    });
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
        Nip05StatusRow(
          result: _verification.nip05Result,
          loading: _verification.nip05Loading,
        ),
      ],
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
  final _verification = ProfileVerificationController();
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.text.trim();
    widget.controller.addListener(_onChanged);
    _verification.addListener(_onVerificationChanged);
    if (_lastValue.isNotEmpty) {
      _verification.verifyLud16Only(lud16: _lastValue);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _verification
      ..removeListener(_onVerificationChanged)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onVerificationChanged() {
    if (mounted) setState(() {});
  }

  void _onChanged() {
    final value = widget.controller.text.trim();
    if (value == _lastValue) return;
    _lastValue = value;
    _debounce?.cancel();
    if (value.isEmpty) {
      _verification.verifyLud16Only(lud16: '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _verification.verifyLud16Only(lud16: value);
    });
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
        Lud16StatusRow(
          result: _verification.lud16Result,
          loading: _verification.lud16Loading,
        ),
      ],
    );
  }
}
