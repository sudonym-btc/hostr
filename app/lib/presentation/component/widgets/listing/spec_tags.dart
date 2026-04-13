import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:models/main.dart';

Color getColorForSpec(BuildContext context, String spec) {
  return AppSurface.stepped(context, 2);
}

@Deprecated('Use getColorForSpec instead')
Color getColorForAmenity(BuildContext context, String amenity) =>
    getColorForSpec(context, amenity);

OutlinedBorder getShapeForSpec(BuildContext context, String spec) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(50.0),
    side: BorderSide(color: AppSurface.stepped(context, 4), width: 1.0),
  );
}

@Deprecated('Use getShapeForSpec instead')
OutlinedBorder getShapeForAmenity(BuildContext context, String amenity) =>
    getShapeForSpec(context, amenity);

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
      // Valued specs first — shown as "Label: Value"
      ...valuedEntries.map((entry) {
        return Chip(
          label: Text('${convertToTitleCase(entry.key)}: ${entry.value}'),
          shape: getShapeForSpec(context, entry.key),
          backgroundColor: getColorForSpec(context, entry.key),
        );
      }),
      // Boolean specs
      ...boolKeys.map((spec) {
        return Chip(
          label: Text(convertToTitleCase(spec)),
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
        child: Chip(
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
