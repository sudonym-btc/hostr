import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing.controller.dart';
import 'package:models/main.dart';

import 'image_picker.dart';

class ImagesInput extends StatelessWidget {
  final EditListingController controller;
  final String pubkey;

  const ImagesInput({
    super.key,
    required this.controller,
    required this.pubkey,
  });

  static const _placeholderUrl =
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85'
      '?auto=format&fit=crop&w=600&h=400&q=60';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ImageUpload(
        controller: controller.imageController,
        pubkey: pubkey,
        placeholder: _listingPlaceholder(context),
      ),
    );
  }

  Widget _listingPlaceholder(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
              tileMode: TileMode.mirror,
            ),
            child: Image.network(
              _placeholderUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: () => controller.imageController.pickMultipleImages(),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(AppLocalizations.of(context)!.addImage),
          ),
        ),
      ],
    );
  }
}

class TitleInput extends StatelessWidget {
  final EditListingController controller;

  const TitleInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.titleController,
      validator: controller.validateTitle,
      decoration: const InputDecoration(
        hintText: 'Cozy apartment in the city center',
      ),
    );
  }
}

class PriceInput extends StatelessWidget {
  final EditListingController controller;

  const PriceInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.priceController,
      validator: controller.validatePrice,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _ThousandsSeparatorFormatter(),
      ],
      decoration: InputDecoration(
        hintText: '10,000',
        prefixText: '${controller.priceCurrency.prefix} ',
        suffixText: '/ day',
      ),
    );
  }
}

class BarterInput extends StatelessWidget {
  final EditListingController controller;

  const BarterInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(AppLocalizations.of(context)!.allowBarter),
          value: controller.allowBarter,
          onChanged: controller.setAllowBarter,
        );
      },
    );
  }
}

class DescriptionInput extends StatelessWidget {
  final EditListingController controller;

  const DescriptionInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.descriptionController,
      validator: controller.validateDescription,
      minLines: 2,
      maxLines: 10,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
        hintText:
            'A cozy, rustic cabin nestled in the woods. Perfect for a quiet retreat or a family vacation. Enjoy the serene surroundings and the beautiful nature trails.',
      ),
    );
  }
}

class AmenitiesInput extends StatefulWidget {
  final EditListingController controller;

  const AmenitiesInput({super.key, required this.controller});

  @override
  State<AmenitiesInput> createState() => _AmenitiesInputState();
}

class _AmenitiesInputState extends State<AmenitiesInput> {
  final TextEditingController _amenityController = TextEditingController();
  final FocusNode _amenityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amenityFocusNode.addListener(() {
      if (_amenityFocusNode.hasFocus && _amenityController.text.isEmpty) {
        _amenityController.value = const TextEditingValue(
          text: ' ',
          selection: TextSelection.collapsed(offset: 1),
        );
        Future.microtask(() {
          if (mounted) {
            _amenityController.value = const TextEditingValue(
              text: '',
              selection: TextSelection.collapsed(offset: 0),
            );
          }
        });
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _amenityController.dispose();
    _amenityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = EditListingController.amenityKeys();
    final selected = widget.controller.selectedAmenityKeys;
    final chipPadding = EdgeInsets.symmetric(
      horizontal: kDefaultPadding.toDouble() / 2,
      vertical: kDefaultPadding.toDouble() / 4,
    );
    const chipLabelPadding = EdgeInsets.only(right: 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: kDefaultPadding.toDouble() / 3,
          runSpacing: kDefaultPadding.toDouble() / 3,
          children: [
            ...selected.map((amenity) {
              return InputChip(
                label: Text(convertToTitleCase(amenity)),
                shape: getShapeForAmenity(context, amenity),
                backgroundColor: getColorForAmenity(context, amenity),
                padding: chipPadding,
                labelPadding: chipLabelPadding,
                // visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onDeleted: () {
                  setState(() {
                    final next = Set<String>.from(selected)..remove(amenity);
                    widget.controller.updateSelectedAmenities(next);
                  });
                },
              );
            }),
            SizedBox(
              width: 280,
              child: RawAutocomplete<String>(
                textEditingController: _amenityController,
                focusNode: _amenityFocusNode,
                displayStringForOption: (option) => convertToTitleCase(option),
                optionsBuilder: (TextEditingValue value) {
                  if (!_amenityFocusNode.hasFocus) {
                    return const Iterable<String>.empty();
                  }
                  final query = value.text.trim().toLowerCase();
                  final available = options.where(
                    (option) => !selected.contains(option),
                  );

                  if (query.isEmpty) {
                    return available;
                  }

                  return available.where(
                    (option) => option.toLowerCase().contains(query),
                  );
                },
                onSelected: (selection) {
                  setState(() {
                    final next = Set<String>.from(selected)..add(selection);
                    widget.controller.updateSelectedAmenities(next);
                  });
                  _amenityController.clear();
                  _amenityFocusNode.requestFocus();
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      final chipTheme = Theme.of(context).chipTheme;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: IntrinsicWidth(
                          child: InputChip(
                            shape: getShapeForAmenity(context, 'add_amenity'),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            padding: chipPadding,
                            labelPadding: chipLabelPadding,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onPressed: () => focusNode.requestFocus(),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.fontSize,
                                  color: chipTheme.labelStyle?.color,
                                ),
                                Gap.horizontal.custom(6),
                                IntrinsicWidth(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 0,
                                      maxWidth: 130,
                                    ),
                                    child: TextField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      style: chipTheme.labelStyle,
                                      maxLines: 1,
                                      minLines: 1,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                        isDense: true,
                                        isCollapsed: true,
                                        hintText: 'Add amenity',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 220,
                          minWidth: 280,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(convertToTitleCase(option)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final formatted = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) formatted.write(',');
      formatted.write(digits[i]);
    }

    final result = formatted.toString();

    // Figure out how many raw digits precede the cursor in the new value.
    final rawCursor = newValue.selection.end.clamp(0, newValue.text.length);
    var digitsSeen = 0;
    for (var i = 0; i < rawCursor && i < newValue.text.length; i++) {
      if (newValue.text[i] != ',') digitsSeen++;
    }

    // Walk the formatted string to place the cursor after the same number of digits.
    var formattedCursor = 0;
    var counted = 0;
    for (var i = 0; i < result.length && counted < digitsSeen; i++) {
      formattedCursor = i + 1;
      if (result[i] != ',') counted++;
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: formattedCursor),
    );
  }
}
