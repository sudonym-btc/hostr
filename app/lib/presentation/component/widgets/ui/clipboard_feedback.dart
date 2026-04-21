import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/config/constants.dart';

const _copiedLabel = 'Copied';
const _copiedStateDuration = Duration(seconds: 2);

Future<void> copyTextToClipboard(BuildContext context, String text) {
  return Clipboard.setData(ClipboardData(text: text));
}

enum CopyFeedbackButtonVariant { filled, material, outlined, text }

class CopyFeedbackButton extends StatefulWidget {
  final FutureOr<String> Function() value;
  final String label;
  final CopyFeedbackButtonVariant variant;
  final ButtonStyle? style;
  final bool showCopyIcon;
  final bool iconOnly;
  final String? tooltip;

  const CopyFeedbackButton({
    super.key,
    required this.value,
    required this.label,
    this.variant = CopyFeedbackButtonVariant.text,
    this.style,
    this.showCopyIcon = true,
  }) : iconOnly = false,
       tooltip = null;

  const CopyFeedbackButton.icon({super.key, required this.value, this.tooltip})
    : label = '',
      variant = CopyFeedbackButtonVariant.text,
      style = null,
      showCopyIcon = true,
      iconOnly = true;

  @override
  State<CopyFeedbackButton> createState() => _CopyFeedbackButtonState();
}

class _CopyFeedbackButtonState extends State<CopyFeedbackButton> {
  Timer? _resetTimer;
  bool _copied = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final value = await widget.value();
    if (!mounted) return;

    await copyTextToClipboard(context, value);
    if (!mounted) return;

    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(_copiedStateDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.iconOnly) {
      return IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          child: Icon(
            _copied ? Icons.check : Icons.copy,
            key: ValueKey(_copied),
            size: kIconSm,
          ),
        ),
        tooltip: _copied ? _copiedLabel : widget.tooltip,
        onPressed: _copy,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }

    final child = _CopyButtonContent(
      copied: _copied,
      label: widget.label,
      showCopyIcon: widget.showCopyIcon,
    );

    return switch (widget.variant) {
      CopyFeedbackButtonVariant.filled => FilledButton(
        onPressed: _copy,
        style: widget.style,
        child: child,
      ),
      CopyFeedbackButtonVariant.material => MaterialButton(
        onPressed: _copy,
        child: child,
      ),
      CopyFeedbackButtonVariant.outlined => OutlinedButton(
        onPressed: _copy,
        style: widget.style,
        child: child,
      ),
      CopyFeedbackButtonVariant.text => TextButton(
        onPressed: _copy,
        style: widget.style,
        child: child,
      ),
    };
  }
}

class _CopyButtonContent extends StatelessWidget {
  final bool copied;
  final String label;
  final bool showCopyIcon;

  const _CopyButtonContent({
    required this.copied,
    required this.label,
    required this.showCopyIcon,
  });

  @override
  Widget build(BuildContext context) {
    final showIcon = copied || showCopyIcon;

    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: Icon(
                copied ? Icons.check : Icons.copy,
                key: ValueKey(copied),
                size: kIconSm,
              ),
            ),
            const SizedBox(width: kSpace1),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            child: Text(copied ? _copiedLabel : label, key: ValueKey(copied)),
          ),
        ],
      ),
    );
  }
}
