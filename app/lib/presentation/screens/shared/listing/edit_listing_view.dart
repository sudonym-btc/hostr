import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing.controller.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'image_picker.dart';

class EditListingView extends StatefulWidget {
  final String? a;

  const EditListingView({super.key, this.a});

  @override
  State<StatefulWidget> createState() => EditListingViewState();
}

class EditListingViewState extends State<EditListingView> {
  bool loading = false;
  final EditListingController controller = EditListingController();
  final TextEditingController _amenityController = TextEditingController();
  final FocusNode _amenityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amenityFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amenityController.dispose();
    _amenityFocusNode.dispose();
    super.dispose();
  }

  Scaffold buildListing(BuildContext context, Listing l) {
    if (controller.l == null || (l.id != null && controller.l?.id != l.id)) {
      controller.setState(l);
    }

    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: CustomPadding(
          top: 0,
          bottom: 0,
          child: FilledButton(
            onPressed: loading == false
                ? () async {
                    setState(() {
                      loading = true;
                    });
                    await controller.save();
                    setState(() {
                      loading = false;
                    });
                  }
                : null,
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96.0),
            child: Form(
              child: Column(
                children: [
                  CustomPadding(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ImageUpload(
                        controller: controller.imageController,
                        pubkey: l.pubKey,
                      ),
                    ),
                  ),
                  CustomPadding(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: controller.titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Title',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: controller.priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Price per night',
                            hintText: '10000',
                            prefixText: '${controller.priceCurrency.prefix} ',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        _buildAmenitiesInput(context),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controller.descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Description',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.a == null
        ? buildListing(
            context,
            Listing.fromNostrEvent(
              Nip01Event(
                pubKey: '',
                kind: Listing.kinds.first,
                tags: [],
                content: ListingContent(
                  title: '',
                  description: '',
                  price: [
                    Price(
                      amount: Amount(
                        currency: Currency.BTC,
                        value: BigInt.from(100000),
                      ),
                      frequency: Frequency.daily,
                    ),
                  ],
                  minStay: Duration(days: 1),
                  checkIn: TimeOfDay(hour: 11, minute: 0),
                  checkOut: TimeOfDay(hour: 11, minute: 0),
                  location: '',
                  quantity: 1,
                  type: ListingType.room,
                  images: [],
                  amenities: Amenities(),
                  requiresEscrow: false,
                ).toString(),
              ),
            ),
          )
        : ListingProvider(
            a: widget.a,
            onDone: (l) {
              if (controller.l == null || controller.l?.id != l.id) {
                controller.setState(l);
              }
            },
            builder: (context, state) {
              if (state.data == null) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return buildListing(context, state.data!);
            },
          );
  }

  Widget _buildAmenitiesInput(BuildContext context) {
    final options = EditListingController.amenityKeys();
    final selected = controller.selectedAmenityKeys;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: selected.map((amenity) {
            return InputChip(
              label: Text(convertToTitleCase(amenity)),
              onDeleted: () {
                setState(() {
                  final next = Set<String>.from(selected)..remove(amenity);
                  controller.updateSelectedAmenities(next);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8.0),
        RawAutocomplete<String>(
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
              controller.updateSelectedAmenities(next);
            });
            _amenityController.clear();
            _amenityFocusNode.requestFocus();
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Amenities',
                    hintText: 'Add amenity',
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
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
      ],
    );
  }
}
