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

  // 3 rows × ~32 px chip + 2 × 4 px run spacing
  static const double _runSpacing = 4.0;
  static const double _collapsedMaxHeight = 3 * 32.0 + 2 * _runSpacing;

  @override
  void initState() {
    super.initState();
    // Measure the unconstrained Wrap height after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _wrapKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null &&
          box.hasSize &&
          box.size.height > _collapsedMaxHeight + 2) {
        setState(() {
          _overflows = true;
          _fullHeight = box.size.height;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final amenitiesMap = widget.amenities.toMap();
    final amenityKeys = amenitiesMap.keys
        .where((key) => amenitiesMap[key] == true)
        .toList();

    if (amenityKeys.isEmpty) return const SizedBox.shrink();

    final wrap = Wrap(
      key: _wrapKey,
      spacing: 8.0,
      runSpacing: _runSpacing,
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
                ? _collapsedMaxHeight
                : (_fullHeight ?? _collapsedMaxHeight),
          ),
          child: wrap,
        ),
        if (_overflows)
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(top: 6),
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
