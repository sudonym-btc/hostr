import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  SearchFormController get _c => widget.controller;

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
          AreaLocationInput(controller: widget.controller.locationController),
          Gap.vertical.lg(),

          // ── Date range ──────────────────────────────────────────
          FormLabel(label: 'When?'),
          Gap.vertical.md(),
          SizedBox(
            width: double.infinity,
            child: DateRangeButtons(
              controller: widget.controller.dateRangeController,
            ),
          ),
          Gap.vertical.lg(),

          // ── Listing type ────────────────────────────────────────
          FormLabel(label: 'Property type'),
          Gap.vertical.md(),
          _ListingTypeChips(
            selected: _c.listingType,
            onChanged: _c.updateListingType,
          ),
          Gap.vertical.lg(),

          // ── Guests ──────────────────────────────────────────────
          FormLabel(label: 'Guests'),
          Gap.vertical.md(),
          _GuestCounter(value: _c.guests, onChanged: _c.updateGuests),
          Gap.vertical.lg(),

          // ── Beachfront toggle ───────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Beachfront'),
            subtitle: const Text('Only show beachfront properties'),
            value: _c.beachfront,
            onChanged: _c.updateBeachfront,
          ),
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
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final entry in _labels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (on) => onChanged(on ? entry.key : null),
          ),
      ],
    );
  }
}

// ── Guest counter ───────────────────────────────────────────────────────────

class _GuestCounter extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _GuestCounter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton.outlined(
          onPressed: value != null && value! > 1
              ? () => onChanged(value! - 1)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            value?.toString() ?? 'Any',
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton.outlined(
          onPressed: () => onChanged((value ?? 0) + 1),
          icon: const Icon(Icons.add),
        ),
        if (value != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => onChanged(null),
            child: const Text('Any'),
          ),
        ],
      ],
    );
  }
}
