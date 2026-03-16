import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:models/main.dart';

Color getColorForAmenity(BuildContext context, String amenity) {
  return Theme.of(context).colorScheme.primary.withAlpha(40);
  // final random = Random(amenity.hashCode);
  // return Color.fromARGB(
  //   25,
  //   random.nextInt(256),
  //   random.nextInt(256),
  //   random.nextInt(256),
  // );
}

OutlinedBorder getShapeForAmenity(BuildContext context, String amenity) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(50.0), // Makes the chip perfectly round
    side: BorderSide(
      color: getColorForAmenity(context, amenity), // Sets the border color
      width: 1.0,
    ),
  );
}

class AmenityTagsWidget extends StatefulWidget {
  final Amenities amenities;

  const AmenityTagsWidget({super.key, required this.amenities});

  @override
  State<AmenityTagsWidget> createState() => _AmenityTagsWidgetState();
}

class _AmenityTagsWidgetState extends State<AmenityTagsWidget> {
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
  void didUpdateWidget(covariant AmenityTagsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amenities != widget.amenities) {
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
    final amenitiesMap = widget.amenities.toMap();
    final amenityKeys = amenitiesMap.keys
        .where((key) => amenitiesMap[key] == true)
        .toList();

    if (amenityKeys.isEmpty) return const SizedBox.shrink();

    final wrap = Wrap(
      key: _wrapKey,
      spacing: spacing.chipSpacing,
      runSpacing: spacing.chipRunSpacing,
      children: amenityKeys.map((amenity) {
        return Chip(
          label: Text(convertToTitleCase(amenity)),
          shape: getShapeForAmenity(context, amenity),
          backgroundColor: getColorForAmenity(context, amenity),
        );
      }).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          clipBehavior: Clip.hardEdge,
          // BoxDecoration required for clipBehavior to work on AnimatedContainer
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
