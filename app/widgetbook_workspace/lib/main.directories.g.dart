// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _i1;
import 'package:widgetbook_workspace/listing.dart' as _i2;
import 'package:widgetbook_workspace/listings.dart' as _i3;
import 'package:widgetbook_workspace/reserve.dart' as _i4;

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookFolder(
    name: 'presentation',
    children: [
      _i1.WidgetbookFolder(
        name: 'screens',
        children: [
          _i1.WidgetbookFolder(
            name: 'shared',
            children: [
              _i1.WidgetbookFolder(
                name: 'listing',
                children: [
                  _i1.WidgetbookLeafComponent(
                    name: 'ListingListItem',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i2.listing,
                    ),
                  ),
                  _i1.WidgetbookLeafComponent(
                    name: 'Listings',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i3.listings,
                    ),
                  ),
                  _i1.WidgetbookLeafComponent(
                    name: 'Reserve',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i4.reserve,
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      )
    ],
  )
];
