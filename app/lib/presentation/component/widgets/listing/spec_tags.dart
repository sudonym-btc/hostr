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
    side: BorderSide(
      color: AppSurface.stepped(context, 4),
      width: 1.0,
    ),
  );
}

@Deprecated('Use getShapeForSpec instead')
OutlinedBorder getShapeForAmenity(BuildContext context, String amenity) =>
    getShapeForSpec(context, amenity);

class SpecificationsWidget extends StatefulWidget {
  final Specifications specifications;

  const SpecificationsWidget({super.key, required this.specifications});

  @override
  State<SpecificationsWidget> createState() => _SpecificationsWidgetState();
}

class _SpecificationsWidgetState extends State<SpecificationsWidget> {
  bool _expanded = false;
  bool _overflows = false;
  double? _fullHeight;
  final GlobalKey _wrapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scheduleOverflowMeasurement();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleOverflowMeasurement();
  }

  @override
  void didUpdateWidget(covariant SpecificationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.specifications != widget.specifications) {
      _scheduleOverflowMeasurement();
    }
  }

  void _scheduleOverflowMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureOverflow();
    });
  }

  double _collapsedMaxHeight(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return 3 * spacing.chipRowHeight + 2 * spacing.chipRunSpacing;
  }

  void _measureOverflow() {
    final box = _wrapKey.currentContext?.findRenderObject() as RenderBox?;
    final collapsedMaxHeight = _collapsedMaxHeight(context);
    final nextFullHeight = box?.hasSize == true ? box!.size.height : null;
    final nextOverflows =
        nextFullHeight != null && nextFullHeight > collapsedMaxHeight + 2;

    if (_overflows == nextOverflows && _fullHeight == nextFullHeight) {
      return;
    }

    setState(() {
      _overflows = nextOverflows;
      _fullHeight = nextFullHeight;
      if (!nextOverflows) {
        _expanded = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final collapsedMaxHeight = _collapsedMaxHeight(context);
    final specsMap = widget.specifications.toMap();

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

    final wrap = Wrap(
      key: _wrapKey,
      spacing: spacing.chipSpacing,
      runSpacing: spacing.chipRunSpacing,
      children: chips,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          constraints: BoxConstraints(
            maxHeight: (_overflows && !_expanded)
                ? collapsedMaxHeight
                : (_fullHeight ?? collapsedMaxHeight),
          ),
          child: wrap,
        ),
        if (_overflows)
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.only(top: spacing.xs * 0.75),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Show more'),
          ),
      ],
    );
  }
}

/// Backwards-compatible alias.
@Deprecated('Use SpecificationsWidget instead')
typedef AmenityTagsWidget = SpecificationsWidget;
