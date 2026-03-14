import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hostr/presentation/component/widgets/ui/gap.dart';

import 'main.dart';

/// A reusable text input that performs async verification (e.g. NIP-05,
/// LUD-16) with debounced re-checks and a status row beneath the field.
///
/// Subclass or use directly via [VerificationInput.nip05] /
/// [VerificationInput.lnurl] named constructors.
class VerificationInput extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;

  /// Optional notifier set to `true` when the field is blank or verified.
  final ValueNotifier<bool>? validNotifier;

  /// Called to trigger the verification. Receives the trimmed value.
  final Future<void> Function(
    ProfileVerificationController verification,
    String value,
  )
  verify;

  /// Called to clear verification when value is empty/invalid.
  final void Function(ProfileVerificationController verification) clearVerify;

  /// Builds the status row widget beneath the text field.
  final Widget Function(ProfileVerificationController verification)
  statusRowBuilder;

  /// Returns whether the current field value is acceptable for form submit.
  final bool Function(ProfileVerificationController verification, String value)
  isVerified;

  const VerificationInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.verify,
    required this.clearVerify,
    required this.statusRowBuilder,
    required this.isVerified,
    this.validator,
    this.validNotifier,
  });

  /// NIP-05 verification input.
  factory VerificationInput.nip05({
    Key? key,
    required TextEditingController controller,
    required String pubkey,
    String? Function(String?)? validator,
    ValueNotifier<bool>? validNotifier,
  }) {
    return VerificationInput(
      key: key,
      controller: controller,
      hintText: 'user@example.com',
      validator: validator,
      validNotifier: validNotifier,
      verify: (v, value) => v.verifyNip05Only(nip05: value, pubkey: pubkey),
      clearVerify: (v) => v.verifyNip05Only(nip05: '', pubkey: pubkey),
      statusRowBuilder: (v) =>
          Nip05StatusRow(result: v.nip05Result, loading: v.nip05Loading),
      isVerified: (v, value) =>
          !v.nip05Loading && (v.nip05Result?.valid ?? false),
    );
  }

  /// LUD-16 (Lightning Address) verification input.
  factory VerificationInput.lnurl({
    Key? key,
    required TextEditingController controller,
    String? Function(String?)? validator,
    ValueNotifier<bool>? validNotifier,
  }) {
    return VerificationInput(
      key: key,
      controller: controller,
      hintText: 'user@wallet.com',
      validator: validator,
      validNotifier: validNotifier,
      verify: (v, value) => v.verifyLud16Only(lud16: value),
      clearVerify: (v) => v.verifyLud16Only(lud16: ''),
      statusRowBuilder: (v) =>
          Lud16StatusRow(result: v.lud16Result, loading: v.lud16Loading),
      isVerified: (v, value) =>
          !v.lud16Loading && (v.lud16Result?.reachable ?? false),
    );
  }

  @override
  State<VerificationInput> createState() => _VerificationInputState();
}

class _VerificationInputState extends State<VerificationInput> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Timer? _debounce;
  final _verification = ProfileVerificationController();
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.text.trim();
    widget.controller.addListener(_onChanged);
    _verification.addListener(_onVerificationChanged);
    _updateValidNotifier();
    // Run initial verification if there's already a value.
    if (_lastValue.isNotEmpty && _emailRegex.hasMatch(_lastValue)) {
      widget.verify(_verification, _lastValue);
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
    _updateValidNotifier();
    if (mounted) setState(() {});
  }

  void _onChanged() {
    final value = widget.controller.text.trim();
    if (value == _lastValue) return;
    _lastValue = value;
    _updateValidNotifier();
    _debounce?.cancel();
    if (value.isEmpty || !_emailRegex.hasMatch(value)) {
      widget.clearVerify(_verification);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      widget.verify(_verification, value);
    });
  }

  void _updateValidNotifier() {
    final value = widget.controller.text.trim();
    final notifier = widget.validNotifier;
    if (notifier == null) return;

    final nextValue = value.isEmpty || widget.isVerified(_verification, value);
    if (notifier.value == nextValue) return;

    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    final isBuildPhase =
        schedulerPhase == SchedulerPhase.persistentCallbacks ||
        schedulerPhase == SchedulerPhase.midFrameMicrotasks;

    if (isBuildPhase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || notifier.value == nextValue) return;
        notifier.value = nextValue;
      });
      return;
    }

    notifier.value = nextValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(hintText: widget.hintText),
        ),
        Gap.vertical.xs(),
        widget.statusRowBuilder(_verification),
      ],
    );
  }
}
