// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _i1;
import 'package:widgetbook_workspace/component/filled_button.dart' as _i3;
import 'package:widgetbook_workspace/component/floating_action_button.dart'
    as _i6;
import 'package:widgetbook_workspace/evm/evm.dart' as _i4;
import 'package:widgetbook_workspace/evm/locked_in_contract.dart' as _i5;
import 'package:widgetbook_workspace/inbox/inbox.dart' as _i13;
import 'package:widgetbook_workspace/inbox/inbox_item.dart' as _i8;
import 'package:widgetbook_workspace/inbox/thread.dart' as _i14;
import 'package:widgetbook_workspace/listing/edit.dart' as _i16;
import 'package:widgetbook_workspace/listing/listing.dart' as _i15;
import 'package:widgetbook_workspace/listing/listing_list_item.dart' as _i9;
import 'package:widgetbook_workspace/nwc/nwc.dart' as _i10;
import 'package:widgetbook_workspace/payment/amount_input.dart' as _i7;
import 'package:widgetbook_workspace/payment/modal_payment_requested.dart'
    as _i2;
import 'package:widgetbook_workspace/profile/profile.dart' as _i18;
import 'package:widgetbook_workspace/profile/profile_chip.dart' as _i11;
import 'package:widgetbook_workspace/reserve.dart' as _i17;
import 'package:widgetbook_workspace/search/check_in_check_out.dart' as _i12;

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookFolder(
    name: 'material',
    children: [
      _i1.WidgetbookComponent(
        name: 'FilledButton',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Bolt11',
            builder: _i2.bolt11,
          ),
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i3.primaryButton,
          ),
          _i1.WidgetbookUseCase(
            name: 'EVM balance',
            builder: _i4.evmBalance,
          ),
          _i1.WidgetbookUseCase(
            name: 'Icon',
            builder: _i3.primaryButtonIcon,
          ),
          _i1.WidgetbookUseCase(
            name: 'Lightning Address',
            builder: _i2.lightningAddress,
          ),
          _i1.WidgetbookUseCase(
            name: 'Lightning Address Amount Fixed',
            builder: _i2.amountFixed,
          ),
          _i1.WidgetbookUseCase(
            name: 'Zap',
            builder: _i2.zap,
          ),
          _i1.WidgetbookUseCase(
            name: 'defaultUseCase',
            builder: _i5.lockedInContract,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'FloatingActionButton',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i6.floatingActionButton,
          ),
          _i1.WidgetbookUseCase(
            name: 'Icon',
            builder: _i6.floatingActionButtonIcon,
          ),
        ],
      ),
    ],
  ),
  _i1.WidgetbookFolder(
    name: 'presentation',
    children: [
      _i1.WidgetbookFolder(
        name: 'component',
        children: [
          _i1.WidgetbookFolder(
            name: 'widgets',
            children: [
              _i1.WidgetbookFolder(
                name: 'amount',
                children: [
                  _i1.WidgetbookComponent(
                    name: 'AmountInputWidget',
                    useCases: [
                      _i1.WidgetbookUseCase(
                        name: 'Currency chooser',
                        builder: _i7.currencyChooserAmountUseCase,
                      ),
                      _i1.WidgetbookUseCase(
                        name: 'Default',
                        builder: _i7.defaultUseCase,
                      ),
                      _i1.WidgetbookUseCase(
                        name: 'Fixed Currency',
                        builder: _i7.fixedAmountUseCase,
                      ),
                    ],
                  )
                ],
              ),
              _i1.WidgetbookFolder(
                name: 'inbox',
                children: [
                  _i1.WidgetbookLeafComponent(
                    name: 'InboxItemWidget',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i8.inboxItem,
                    ),
                  )
                ],
              ),
              _i1.WidgetbookFolder(
                name: 'listing',
                children: [
                  _i1.WidgetbookLeafComponent(
                    name: 'ListingListItemWidget',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i9.listing,
                    ),
                  )
                ],
              ),
              _i1.WidgetbookFolder(
                name: 'nostr_wallet_connect',
                children: [
                  _i1.WidgetbookLeafComponent(
                    name: 'NostrWalletConnectWidget',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i10.nwc,
                    ),
                  )
                ],
              ),
              _i1.WidgetbookFolder(
                name: 'profile',
                children: [
                  _i1.WidgetbookLeafComponent(
                    name: 'ProfileChipWidget',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i11.listing,
                    ),
                  )
                ],
              ),
            ],
          )
        ],
      ),
      _i1.WidgetbookFolder(
        name: 'forms',
        children: [
          _i1.WidgetbookFolder(
            name: 'search',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'DateRangeButtons',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Default',
                  builder: _i12.defaultUseCase,
                ),
              )
            ],
          )
        ],
      ),
      _i1.WidgetbookFolder(
        name: 'screens',
        children: [
          _i1.WidgetbookFolder(
            name: 'shared',
            children: [
              _i1.WidgetbookFolder(
                name: 'inbox',
                children: [
                  _i1.WidgetbookLeafComponent(
                    name: 'InboxScreen',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Empty',
                      builder: _i13.inboxEmpty,
                    ),
                  ),
                  _i1.WidgetbookFolder(
                    name: 'thread',
                    children: [
                      _i1.WidgetbookLeafComponent(
                        name: 'ThreadScreen',
                        useCase: _i1.WidgetbookUseCase(
                          name: 'Default',
                          builder: _i14.thread,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              _i1.WidgetbookFolder(
                name: 'listing',
                children: [
                  _i1.WidgetbookComponent(
                    name: 'ListingScreen',
                    useCases: [
                      _i1.WidgetbookUseCase(
                        name: 'Default',
                        builder: _i15.listing,
                      ),
                      _i1.WidgetbookUseCase(
                        name: 'Edit',
                        builder: _i16.edit,
                      ),
                    ],
                  ),
                  _i1.WidgetbookLeafComponent(
                    name: 'Reserve',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i17.reserve,
                    ),
                  ),
                ],
              ),
              _i1.WidgetbookFolder(
                name: 'profile',
                children: [
                  _i1.WidgetbookLeafComponent(
                    name: 'ProfileScreen',
                    useCase: _i1.WidgetbookUseCase(
                      name: 'Default',
                      builder: _i18.defaultUseCase,
                    ),
                  )
                ],
              ),
            ],
          )
        ],
      ),
    ],
  ),
];
