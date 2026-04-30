import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:models/main.dart';

import 'date_range_buttons.dart';
import 'location_input.dart';
import 'search_form_controller.dart';

class SearchForm extends StatefulWidget {
  final SearchFormController controller;

  const SearchForm({super.key, required this.controller});

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    // If restoring state that already has advanced filters set, expand.
    _showAdvanced = _hasAdvancedFilters;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  SearchFormController get _c => widget.controller;

  bool get _hasAdvancedFilters =>
      _c.listingTypeField.value != null ||
      _c.beachfrontField.value ||
      _c.kitchenField.value ||
      _c.allowsPetsField.value ||
      _c.negotiableField.value ||
      _c.bedroomsField.value != null ||
      _c.bedsField.value != null ||
      _c.bathroomsField.value != null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Location ────────────────────────────────────────────
          FormLabel(label: 'Where are you going?'),
          Gap.vertical.md(),
          AreaLocationInput(
            controller: _c.locationField,
            textFieldKey: const ValueKey('search_filters_location_input'),
          ),
          Gap.vertical.lg(),

          // ── Date range ──────────────────────────────────────────
          FormLabel(label: 'When?'),
          Gap.vertical.md(),
          SizedBox(
            width: double.infinity,
            child: DateRangeButtons(controller: _c.dateRangeField),
          ),
          Gap.vertical.lg(),

          // ── Guests ──────────────────────────────────────────────
          FormLabel(label: 'Guests'),
          Gap.vertical.md(),
          IntFieldSelector(
            value: _c.guestsField.value,
            onChanged: _c.guestsField.setValue,
          ),
          Gap.vertical.lg(),

          // ── Advanced section ────────────────────────────────────
          _AdvancedHeader(
            key: const ValueKey('search_filters_advanced_toggle'),
            expanded: _showAdvanced,
            onToggle: () => setState(() => _showAdvanced = !_showAdvanced),
          ),
          if (_showAdvanced) ...[
            Gap.vertical.md(),
            FormLabel(label: 'Property type'),
            Gap.vertical.md(),
            _ListingTypeChips(
              selected: _c.listingTypeField.value,
              onChanged: _c.listingTypeField.setValue,
            ),
            Gap.vertical.lg(),
            SwitchListTile(
              key: const ValueKey('search_filters_beachfront_switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Beachfront'),
              value: _c.beachfrontField.value,
              onChanged: _c.beachfrontField.setValue,
            ),
            SwitchListTile(
              key: const ValueKey('search_filters_kitchen_switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Kitchen'),
              value: _c.kitchenField.value,
              onChanged: _c.kitchenField.setValue,
            ),
            SwitchListTile(
              key: const ValueKey('search_filters_allows_pets_switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Allows pets'),
              value: _c.allowsPetsField.value,
              onChanged: _c.allowsPetsField.setValue,
            ),
            SwitchListTile(
              key: const ValueKey('search_filters_negotiable_switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Negotiable'),
              value: _c.negotiableField.value,
              onChanged: _c.negotiableField.setValue,
            ),
            Gap.vertical.md(),
            IntFieldSelector(
              label: 'Bedrooms',
              value: _c.bedroomsField.value,
              onChanged: _c.bedroomsField.setValue,
            ),
            Gap.vertical.md(),
            IntFieldSelector(
              label: 'Beds',
              value: _c.bedsField.value,
              onChanged: _c.bedsField.setValue,
            ),
            Gap.vertical.md(),
            IntFieldSelector(
              label: 'Bathrooms',
              value: _c.bathroomsField.value,
              onChanged: _c.bathroomsField.setValue,
            ),
          ],
        ],
      ),
    );
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }
}

// ── Listing type choice chips ───────────────────────────────────────────────

class _ListingTypeChips extends StatelessWidget {
  final ListingType? selected;
  final ValueChanged<ListingType?> onChanged;

  const _ListingTypeChips({required this.selected, required this.onChanged});

  static const _labels = {
    ListingType.room: 'Room',
    ListingType.apartment: 'Apartment',
    ListingType.house: 'House',
    ListingType.villa: 'Villa',
    ListingType.hotel: 'Hotel',
    ListingType.hostel: 'Hostel',
    ListingType.resort: 'Resort',
  };

  @override
  Widget build(BuildContext context) {
    return ChipWrap(
      children: [
        for (final entry in _labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (on) => onChanged(on ? entry.key : null),
            labelStyle: AppChipStyles.statefulLabelStyle(context),
            shape: AppChipStyles.shape,
            side: AppChipStyles.selectableSide(context),
            color: AppChipStyles.selectableColor(context),
            padding: AppChipStyles.padding,
            labelPadding: AppChipStyles.labelPadding,
            visualDensity: AppChipStyles.visualDensity,
            materialTapTargetSize: AppChipStyles.materialTapTargetSize,
          ),
      ],
    );
  }
}

// ── Advanced section header ─────────────────────────────────────────────────

class _AdvancedHeader extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _AdvancedHeader({
    super.key,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: AppBorderRadii.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              'Advanced',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }
}
