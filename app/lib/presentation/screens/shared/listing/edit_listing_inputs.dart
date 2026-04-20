import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/logic/forms/listing_spec_field_controller.dart';
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
            style: AppButtonStyles.secondary(context),
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

  /// Available denominations the user can switch between.
  /// When empty, no selector is shown.
  final List<String> possibleDenominations;

  const PriceInput({
    super.key,
    required this.controller,
    this.possibleDenominations = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.priceField,
      builder: (context, _) {
        final denom = controller.priceField.denomination;
        final displayAmount = controller.priceField.displayAmount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── tap target ──────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openEditor(context, denom),
              child: InputDecorator(
                decoration: InputDecoration(
                  suffixText: '/ day',
                  hintText: 'Tap to set price',
                ),
                child: Text(
                  formatAmount(displayAmount),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context, String denom) async {
    final current =
        controller.priceField.amount ??
        DenominatedAmount.zero(
          controller.priceField.denomination,
          controller.priceField.decimals,
        );

    final result = await AmountEditorBottomSheet.show(
      context,
      initialAmount: current,
      possibleDenominations: possibleDenominations,
      onDenominationChanged: (d) {
        controller.priceField.setDenomination(d);
      },
    );

    if (result != null) {
      controller.priceField.setAmount(result);
    }
  }
}

class NegotiableInput extends StatelessWidget {
  final EditListingController controller;

  const NegotiableInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(AppLocalizations.of(context)!.negotiable),
          subtitle: Text(
            'Allows reservation requests below the listed price, which can then be accepted or declined.',
          ),
          value: controller.negotiableField.value,
          onChanged: controller.negotiableField.setValue,
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
        return SwitchListTile(
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

class SpecificationsInput extends StatefulWidget {
  final EditListingController controller;

  const SpecificationsInput({super.key, required this.controller});

  @override
  State<SpecificationsInput> createState() => _SpecificationsInputState();
}

class _SpecificationsInputState extends State<SpecificationsInput> {
  final TextEditingController _specController = TextEditingController();
  final FocusNode _specFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _specFocusNode.addListener(() {
      if (_specFocusNode.hasFocus && _specController.text.isEmpty) {
        _specController.value = const TextEditingValue(
          text: ' ',
          selection: TextSelection.collapsed(offset: 1),
        );
        Future.microtask(() {
          if (mounted) {
            _specController.value = const TextEditingValue(
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
    _specController.dispose();
    _specFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boolOptions = ListingSpecFieldController.booleanSpecKeys();
    final selected = widget.controller.specField.selectedBoolKeys;
    final valuedSpecKeys = ListingSpecFieldController.valuedSpecKeys();
    final valuedSpecs = widget.controller.specField.valuedSpecs;
    final chipPadding = EdgeInsets.symmetric(
      horizontal: kDefaultPadding.toDouble() / 2,
      vertical: kDefaultPadding.toDouble() / 4,
    );
    const chipLabelPadding = EdgeInsets.only(right: 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Valued specs (number inputs) ──────────────────────────────
        ...valuedSpecKeys.map((key) {
          final value = valuedSpecs[key] ?? 0;
          return Padding(
            padding: EdgeInsets.only(bottom: kDefaultPadding.toDouble() / 2),
            child: IntFieldSelector(
              label: localizedSpecification(context, key),
              value: value,
              onChanged: (v) {
                setState(() {
                  widget.controller.specField.updateValuedSpec(key, v ?? 0);
                });
              },
              min: 0,
            ),
          );
        }),
        if (valuedSpecKeys.isNotEmpty) Gap.vertical.sm(),

        // ── Boolean specs (chip picker) ───────────────────────────────
        Wrap(
          spacing: kDefaultPadding.toDouble() / 3,
          runSpacing: kDefaultPadding.toDouble() / 3,
          children: [
            ...selected.map((spec) {
              return InputChip(
                label: Text(localizedSpecification(context, spec)),
                shape: getShapeForSpec(context, spec),
                backgroundColor: getColorForSpec(context, spec),
                padding: chipPadding,
                labelPadding: chipLabelPadding,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onDeleted: () {
                  setState(() {
                    final next = Set<String>.from(selected)..remove(spec);
                    widget.controller.specField.updateSelectedBool(next);
                  });
                },
              );
            }),
            SizedBox(
              width: double.infinity,
              child: RawAutocomplete<String>(
                textEditingController: _specController,
                focusNode: _specFocusNode,
                displayStringForOption: (option) =>
                    localizedSpecification(context, option),
                optionsBuilder: (TextEditingValue value) {
                  if (!_specFocusNode.hasFocus) {
                    return const Iterable<String>.empty();
                  }
                  final query = value.text.trim().toLowerCase();
                  final available = boolOptions.where(
                    (option) => !selected.contains(option),
                  );

                  if (query.isEmpty) {
                    return available;
                  }

                  return available.where((option) {
                    final label = localizedSpecification(
                      context,
                      option,
                    ).toLowerCase();
                    return option.toLowerCase().contains(query) ||
                        label.contains(query);
                  });
                },
                onSelected: (selection) {
                  _specController.clear();
                  _specFocusNode.unfocus();
                  setState(() {
                    final next = Set<String>.from(selected)..add(selection);
                    widget.controller.specField.updateSelectedBool(next);
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
                            shape: getShapeForSpec(context, 'add_spec'),
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
                                        hintText: 'Add feature',
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
                              title: Text(
                                localizedSpecification(context, option),
                              ),
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

// ── Amount inputs ─────────────────────────────────────────────────────

class _AmountTapInput extends StatelessWidget {
  final AmountFieldController controller;
  final String hintText;
  final List<String> possibleDenominations;

  const _AmountTapInput({
    required this.controller,
    required this.hintText,
    this.possibleDenominations = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final displayAmount =
            controller.amount ??
            DenominatedAmount.zero(
              controller.denomination,
              controller.decimals,
            );

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openEditor(context),
          child: InputDecorator(
            decoration: InputDecoration(hintText: hintText),
            child: Text(
              formatAmount(displayAmount),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final current =
        controller.amount ??
        DenominatedAmount.zero(controller.denomination, controller.decimals);

    final result = await AmountEditorBottomSheet.show(
      context,
      initialAmount: current,
      possibleDenominations: possibleDenominations,
      onDenominationChanged: controller.setDenomination,
    );

    if (result != null) {
      controller.setValue(result);
    }
  }
}

class SecurityDepositInput extends StatelessWidget {
  final EditListingController controller;
  final List<String> possibleDenominations;

  const SecurityDepositInput({
    super.key,
    required this.controller,
    this.possibleDenominations = const [],
  });

  @override
  Widget build(BuildContext context) {
    return _AmountTapInput(
      controller: controller.securityDepositField,
      hintText: 'Tap to set deposit',
      possibleDenominations: possibleDenominations,
    );
  }
}

class MinPaymentInput extends StatelessWidget {
  final EditListingController controller;
  final List<String> possibleDenominations;

  const MinPaymentInput({
    super.key,
    required this.controller,
    this.possibleDenominations = const [],
  });

  @override
  Widget build(BuildContext context) {
    return _AmountTapInput(
      controller: controller.minPaymentField,
      hintText: 'Tap to set minimum',
      possibleDenominations: possibleDenominations,
    );
  }
}

/// Collapsible section for advanced listing settings.
class AdvancedSettingsSection extends StatefulWidget {
  final EditListingController controller;
  final List<String> possibleDenominations;

  const AdvancedSettingsSection({
    super.key,
    required this.controller,
    this.possibleDenominations = const [],
  });

  @override
  State<AdvancedSettingsSection> createState() =>
      _AdvancedSettingsSectionState();
}

class _AdvancedSettingsSectionState extends State<AdvancedSettingsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Advanced',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildContent(context),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security deposit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SecurityDepositInput(
            controller: widget.controller,
            possibleDenominations: widget.possibleDenominations,
          ),
          const SizedBox(height: 4),
          Text(
            'Amount held in escrow as a damage deposit, returned after checkout.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Minimum payment',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          MinPaymentInput(
            controller: widget.controller,
            possibleDenominations: widget.possibleDenominations,
          ),
          const SizedBox(height: 4),
          Text(
            'Lowest payment amount you will accept for a reservation.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
