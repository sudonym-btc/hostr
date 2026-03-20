import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/logic/forms/listing_amenity_field_controller.dart';
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

  static const placeholderAsset = 'assets/images/listing_placeholder.jpg';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ImageUpload(
        controller: controller.imageField.cubit,
        pubkey: pubkey,
        placeholder: _listingPlaceholder(context),
      ),
    );
  }

  Widget _listingPlaceholder(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BlurredImage(
          child: Image.asset(
            placeholderAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        Center(
          child: FilledButton.icon(
            onPressed: () => controller.imageField.cubit.pickMultipleImages(
              allowedFileTypes: ImagePickerCubit.defaultAllowedFileTypes,
            ),
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
      controller: controller.titleField.textController,
      validator: controller.titleField.validate,
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
      controller: controller.priceField.textController,
      validator: controller.priceField.validatePrice,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorFormatter(),
      ],
      decoration: InputDecoration(
        hintText: '10,000',
        prefixText: '${controller.priceField.currency.prefix} ',
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
          subtitle: Text(
            'Allowing barter allows users to submit reservation requests below your listed price, which you can then accept or decline.',
          ),
          value: controller.barterField.value,
          onChanged: controller.barterField.setValue,
        );
      },
    );
  }
}

class ActiveInput extends StatelessWidget {
  final EditListingController controller;

  const ActiveInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active listing'),
          subtitle: const Text(
            'Turn this off to hide the listing from guests.',
          ),
          value: controller.activeField.value,
          onChanged: controller.activeField.setValue,
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
      controller: controller.descriptionField.textController,
      validator: controller.descriptionField.validate,
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
    final options = ListingAmenityFieldController.amenityKeys();
    final selected = widget.controller.amenityField.selectedKeys;
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
                    widget.controller.amenityField.updateSelected(next);
                  });
                },
              );
            }),
            SizedBox(
              width: double.infinity,
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
                  _amenityController.clear();
                  _amenityFocusNode.unfocus();
                  setState(() {
                    final next = Set<String>.from(selected)..add(selection);
                    widget.controller.amenityField.updateSelected(next);
                  });
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
                                      textAlignVertical: TextAlignVertical.top,
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
