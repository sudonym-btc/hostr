import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:models/main.dart';

Color getColorForSpec(BuildContext context, String spec) {
  return AppSurface.stepped(context, 2);
}

OutlinedBorder getShapeForSpec(BuildContext context, String spec) {
  return AppShapes.pillWithSide(color: AppSurface.stepped(context, 4));
}

class SpecificationsWidget extends StatelessWidget {
  final Specifications specifications;

  const SpecificationsWidget({super.key, required this.specifications});

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final layout = AppLayoutSpec.of(context);
    final maxChildren = layout.isExpanded ? 10 : 5;
    final specsMap = specifications.toMap();

    // Separate valued specs (int > 0) and boolean specs (true)
    final valuedEntries = specsMap.entries
        .where((e) => e.value is int && (e.value as int) > 0)
        .toList();
    final boolKeys = specsMap.keys
        .where((key) => specsMap[key] == true)
        .toList();

    if (valuedEntries.isEmpty && boolKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[
      // Valued specs first — shown with localized plural/count labels.
      ...valuedEntries.map((entry) {
        return AppChip(
          label: Text(
            localizedSpecification(context, entry.key, count: entry.value),
          ),
          shape: getShapeForSpec(context, entry.key),
          backgroundColor: getColorForSpec(context, entry.key),
        );
      }),
      // Boolean specs
      ...boolKeys.map((spec) {
        return AppChip(
          label: Text(localizedSpecification(context, spec)),
          shape: getShapeForSpec(context, spec),
          backgroundColor: getColorForSpec(context, spec),
        );
      }),
    ];

    return CollapsibleWrap(
      maxChildren: maxChildren,
      spacing: spacing.chipSpacing,
      runSpacing: spacing.chipRunSpacing,
      toggleChipBuilder: (label, onTap) => GestureDetector(
        onTap: onTap,
        child: AppChip(
          label: Text(label),
          shape: getShapeForSpec(context, ''),
          backgroundColor: getColorForSpec(context, ''),
        ),
      ),
      children: chips,
    );
  }
}

/// Backwards-compatible alias.
@Deprecated('Use SpecificationsWidget instead')
typedef AmenityTagsWidget = SpecificationsWidget;
