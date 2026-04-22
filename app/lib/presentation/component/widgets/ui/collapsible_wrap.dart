import 'package:flutter/material.dart';

import 'app_chip.dart';
import 'chip_wrap.dart';

/// A [Wrap] that shows at most [maxChildren] items when collapsed.
///
/// When the total number of children exceeds [maxChildren], the last
/// visible slot is replaced with a "+N more" chip. Tapping it expands
/// to show all children plus a "Show less" chip.
///
/// Provide [toggleChipBuilder] to customise the toggle chip appearance.
/// It receives the label text ("+ N more" / "Show less") and the tap
/// callback. When omitted a plain [InputChip] is used.
class CollapsibleWrap extends StatefulWidget {
  /// Maximum number of children to show when collapsed.
  /// If `null`, all children are always visible.
  final int? maxChildren;

  /// Spacing between children on the main axis.
  final double spacing;

  /// Spacing between runs (rows).
  final double runSpacing;

  /// The full list of child widgets.
  final List<Widget> children;

  /// Optional builder for the toggle chip.
  final Widget Function(String label, VoidCallback onTap)? toggleChipBuilder;

  const CollapsibleWrap({
    super.key,
    this.maxChildren,
    this.spacing = 8.0,
    this.runSpacing = 6.0,
    this.toggleChipBuilder,
    required this.children,
  });

  @override
  State<CollapsibleWrap> createState() => _CollapsibleWrapState();
}

class _CollapsibleWrapState extends State<CollapsibleWrap> {
  bool _expanded = false;

  Widget _buildToggle(String label, VoidCallback onTap) {
    if (widget.toggleChipBuilder != null) {
      return widget.toggleChipBuilder!(label, onTap);
    }
    return InputChip(
      label: Text(label),
      labelStyle: AppChipStyles.labelStyle(context),
      shape: AppChipStyles.shape,
      side: AppChipStyles.neutralSide(context),
      color: AppChipStyles.selectableColor(context),
      padding: AppChipStyles.padding,
      labelPadding: AppChipStyles.labelPadding,
      visualDensity: AppChipStyles.visualDensity,
      materialTapTargetSize: AppChipStyles.materialTapTargetSize,
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.children;
    final max = widget.maxChildren;
    final overflows = max != null && all.length > max;

    List<Widget> visible;
    if (!overflows || _expanded) {
      visible = [
        ...all,
        if (overflows)
          _buildToggle('Show less', () => setState(() => _expanded = false)),
      ];
    } else {
      final hidden = all.length - max;
      visible = [
        ...all.take(max),
        _buildToggle('+$hidden more', () => setState(() => _expanded = true)),
      ];
    }

    return ChipWrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: visible,
    );
  }
}
