// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_workspace/component/filled_button.dart'
    as _widgetbook_workspace_component_filled_button;
import 'package:widgetbook_workspace/component/floating_action_button.dart'
    as _widgetbook_workspace_component_floating_action_button;
import 'package:widgetbook_workspace/evm/evm.dart'
    as _widgetbook_workspace_evm_evm;
import 'package:widgetbook_workspace/evm/locked_in_contract.dart'
    as _widgetbook_workspace_evm_locked_in_contract;
import 'package:widgetbook_workspace/inbox/inbox.dart'
    as _widgetbook_workspace_inbox_inbox;
import 'package:widgetbook_workspace/inbox/inbox_item.dart'
    as _widgetbook_workspace_inbox_inbox_item;
import 'package:widgetbook_workspace/inbox/thread.dart'
    as _widgetbook_workspace_inbox_thread;
import 'package:widgetbook_workspace/listing/edit.dart'
    as _widgetbook_workspace_listing_edit;
import 'package:widgetbook_workspace/listing/listing.dart'
    as _widgetbook_workspace_listing_listing;
import 'package:widgetbook_workspace/listing/listing_list_item.dart'
    as _widgetbook_workspace_listing_listing_list_item;
import 'package:widgetbook_workspace/nwc/nwc.dart'
    as _widgetbook_workspace_nwc_nwc;
import 'package:widgetbook_workspace/payment/amount_input.dart'
    as _widgetbook_workspace_payment_amount_input;
import 'package:widgetbook_workspace/payment/modal_payment_requested.dart'
    as _widgetbook_workspace_payment_modal_payment_requested;
import 'package:widgetbook_workspace/profile/profile.dart'
    as _widgetbook_workspace_profile_profile;
import 'package:widgetbook_workspace/profile/profile_chip.dart'
    as _widgetbook_workspace_profile_profile_chip;
import 'package:widgetbook_workspace/reserve.dart'
    as _widgetbook_workspace_reserve;
import 'package:widgetbook_workspace/search/check_in_check_out.dart'
    as _widgetbook_workspace_search_check_in_check_out;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'material',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'FilledButton',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Bolt11',
            builder:
                _widgetbook_workspace_payment_modal_payment_requested.bolt11,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder:
                _widgetbook_workspace_component_filled_button.primaryButton,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'EVM balance',
            builder: _widgetbook_workspace_evm_evm.evmBalance,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Icon',
            builder:
                _widgetbook_workspace_component_filled_button.primaryButtonIcon,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Lightning Address',
            builder: _widgetbook_workspace_payment_modal_payment_requested
                .lightningAddress,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Lightning Address Amount Fixed',
            builder: _widgetbook_workspace_payment_modal_payment_requested
                .amountFixed,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Zap',
            builder: _widgetbook_workspace_payment_modal_payment_requested.zap,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'defaultUseCase',
            builder:
                _widgetbook_workspace_evm_locked_in_contract.lockedInContract,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'FloatingActionButton',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_component_floating_action_button
                .floatingActionButton,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Icon',
            builder: _widgetbook_workspace_component_floating_action_button
                .floatingActionButtonIcon,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'presentation',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'component',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'widgets',
            children: [
              _widgetbook.WidgetbookFolder(
                name: 'amount',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'AmountInputWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Currency chooser',
                        builder: _widgetbook_workspace_payment_amount_input
                            .currencyChooserAmountUseCase,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_payment_amount_input
                            .defaultUseCase,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Fixed Currency',
                        builder: _widgetbook_workspace_payment_amount_input
                            .fixedAmountUseCase,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'inbox',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'InboxItemWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder:
                            _widgetbook_workspace_inbox_inbox_item.inboxItem,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'listing',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'ListingListItemWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_listing_listing_list_item
                            .listing,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'nostr_wallet_connect',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'NostrWalletConnectWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_nwc_nwc.nwc,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'profile',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'ProfileChipWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder:
                            _widgetbook_workspace_profile_profile_chip.listing,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'forms',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'search',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'DateRangeButtons',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Default',
                    builder: _widgetbook_workspace_search_check_in_check_out
                        .defaultUseCase,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'screens',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'shared',
            children: [
              _widgetbook.WidgetbookFolder(
                name: 'inbox',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'InboxScreen',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Empty',
                        builder: _widgetbook_workspace_inbox_inbox.inboxEmpty,
                      ),
                    ],
                  ),
                  _widgetbook.WidgetbookFolder(
                    name: 'thread',
                    children: [
                      _widgetbook.WidgetbookComponent(
                        name: 'ThreadScreen',
                        useCases: [
                          _widgetbook.WidgetbookUseCase(
                            name: 'Default',
                            builder: _widgetbook_workspace_inbox_thread.thread,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'listing',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'ListingScreen',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_listing_listing.listing,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Edit',
                        builder: _widgetbook_workspace_listing_edit.edit,
                      ),
                    ],
                  ),
                  _widgetbook.WidgetbookComponent(
                    name: 'Reserve',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_reserve.reserve,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'profile',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'ProfileScreen',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_profile_profile
                            .defaultUseCase,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
