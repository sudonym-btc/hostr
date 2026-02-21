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
import 'package:widgetbook_workspace/escrow/trusted_escrow_list_item.dart'
    as _widgetbook_workspace_escrow_trusted_escrow_list_item;
import 'package:widgetbook_workspace/evm/evm.dart'
    as _widgetbook_workspace_evm_evm;
import 'package:widgetbook_workspace/evm/locked_in_contract.dart'
    as _widgetbook_workspace_evm_locked_in_contract;
import 'package:widgetbook_workspace/inbox/inbox_item.dart'
    as _widgetbook_workspace_inbox_inbox_item;
import 'package:widgetbook_workspace/inbox/thread.dart'
    as _widgetbook_workspace_inbox_thread;
import 'package:widgetbook_workspace/inbox/thread_message.dart'
    as _widgetbook_workspace_inbox_thread_message;
import 'package:widgetbook_workspace/inbox/thread_reply.dart'
    as _widgetbook_workspace_inbox_thread_reply;
import 'package:widgetbook_workspace/inbox/thread_view.dart'
    as _widgetbook_workspace_inbox_thread_view;
import 'package:widgetbook_workspace/inbox/trade_header.dart'
    as _widgetbook_workspace_inbox_trade_header;
import 'package:widgetbook_workspace/listing/listing_list_item.dart'
    as _widgetbook_workspace_listing_listing_list_item;
import 'package:widgetbook_workspace/listing/listing_view.dart'
    as _widgetbook_workspace_listing_listing_view;
import 'package:widgetbook_workspace/nwc/nwc.dart'
    as _widgetbook_workspace_nwc_nwc;
import 'package:widgetbook_workspace/payment/amount_input.dart'
    as _widgetbook_workspace_payment_amount_input;
import 'package:widgetbook_workspace/payment/escrow_fund_flow.dart'
    as _widgetbook_workspace_payment_escrow_fund_flow;
import 'package:widgetbook_workspace/payment/modal_payment_requested.dart'
    as _widgetbook_workspace_payment_modal_payment_requested;
import 'package:widgetbook_workspace/payment/payment_flow.dart'
    as _widgetbook_workspace_payment_payment_flow;
import 'package:widgetbook_workspace/payment/swap_flow.dart'
    as _widgetbook_workspace_payment_swap_flow;
import 'package:widgetbook_workspace/profile/profile_chip.dart'
    as _widgetbook_workspace_profile_profile_chip;
import 'package:widgetbook_workspace/profile/profile_header.dart'
    as _widgetbook_workspace_profile_profile_header;
import 'package:widgetbook_workspace/relay/relay_list_item.dart'
    as _widgetbook_workspace_relay_relay_list_item;
import 'package:widgetbook_workspace/reserve.dart'
    as _widgetbook_workspace_reserve;
import 'package:widgetbook_workspace/search/check_in_check_out.dart'
    as _widgetbook_workspace_search_check_in_check_out;
import 'package:widgetbook_workspace/search/search_box.dart'
    as _widgetbook_workspace_search_search_box;

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
                name: 'escrow',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'TrustedEscrowListItemWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Missing profile',
                        builder:
                            _widgetbook_workspace_escrow_trusted_escrow_list_item
                                .trustedEscrowMissingProfile,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'With profile',
                        builder:
                            _widgetbook_workspace_escrow_trusted_escrow_list_item
                                .trustedEscrowWithProfile,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'flow',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'ModalBottomSheet',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Escrow Fund - Confirm',
                        builder: _widgetbook_workspace_payment_escrow_fund_flow
                            .escrowFundConfirm,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Escrow Fund - Success',
                        builder: _widgetbook_workspace_payment_escrow_fund_flow
                            .escrowFundSuccess,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Payment - Confirm',
                        builder: _widgetbook_workspace_payment_payment_flow
                            .paymentConfirm,
                      ),
                    ],
                  ),
                  _widgetbook.WidgetbookFolder(
                    name: 'payment',
                    children: [
                      _widgetbook.WidgetbookComponent(
                        name: 'PaymentFailureWidget',
                        useCases: [
                          _widgetbook.WidgetbookUseCase(
                            name: 'Error',
                            builder: _widgetbook_workspace_payment_payment_flow
                                .paymentError,
                          ),
                        ],
                      ),
                      _widgetbook.WidgetbookComponent(
                        name: 'PaymentProgressWidget',
                        useCases: [
                          _widgetbook.WidgetbookUseCase(
                            name: 'Loading',
                            builder: _widgetbook_workspace_payment_payment_flow
                                .paymentLoading,
                          ),
                        ],
                      ),
                      _widgetbook.WidgetbookComponent(
                        name: 'PaymentSuccessWidget',
                        useCases: [
                          _widgetbook.WidgetbookUseCase(
                            name: 'Success',
                            builder: _widgetbook_workspace_payment_payment_flow
                                .paymentSuccess,
                          ),
                        ],
                      ),
                      _widgetbook.WidgetbookFolder(
                        name: 'escrow',
                        children: [
                          _widgetbook.WidgetbookFolder(
                            name: 'fund',
                            children: [
                              _widgetbook.WidgetbookComponent(
                                name: 'EscrowFundFailureWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Error',
                                    builder:
                                        _widgetbook_workspace_payment_escrow_fund_flow
                                            .escrowFundError,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'EscrowFundProgressWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'On-chain in progress',
                                    builder:
                                        _widgetbook_workspace_payment_escrow_fund_flow
                                            .escrowFundOnChainProgress,
                                  ),
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap in progress',
                                    builder:
                                        _widgetbook_workspace_payment_escrow_fund_flow
                                            .escrowFundSwapProgress,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'EscrowFundTradeProgressWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Trade in progress',
                                    builder:
                                        _widgetbook_workspace_payment_escrow_fund_flow
                                            .escrowFundTradeProgress,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      _widgetbook.WidgetbookFolder(
                        name: 'swap',
                        children: [
                          _widgetbook.WidgetbookFolder(
                            name: 'in',
                            children: [
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapInConfirmWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap In - Confirm',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapInConfirm,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapInFailureWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap In - Error',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapInError,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapInPaymentProgressWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap In - Payment in progress',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapInPaymentProgress,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapInProgressWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap In - Loading',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapInLoading,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapInSuccessWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap In - Success',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapInSuccess,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _widgetbook.WidgetbookFolder(
                            name: 'out',
                            children: [
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapOutConfirmWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap Out - Confirm',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapOutConfirm,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapOutFailureWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap Out - Error',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapOutError,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapOutPaymentProgressWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap Out - Payment in progress',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapOutPaymentProgress,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapOutProgressWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap Out - Loading',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapOutLoading,
                                  ),
                                ],
                              ),
                              _widgetbook.WidgetbookComponent(
                                name: 'SwapOutSuccessWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Swap Out - Success',
                                    builder:
                                        _widgetbook_workspace_payment_swap_flow
                                            .swapOutSuccess,
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
              _widgetbook.WidgetbookFolder(
                name: 'inbox',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'InboxItemView',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Missing counterparty profile',
                        builder: _widgetbook_workspace_inbox_inbox_item
                            .inboxItemMissingCounterparty,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Received - normal message',
                        builder: _widgetbook_workspace_inbox_inbox_item
                            .inboxItemReceivedNormal,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Received - reservation request',
                        builder: _widgetbook_workspace_inbox_inbox_item
                            .inboxItemReceivedReservationRequest,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Sent - normal message',
                        builder: _widgetbook_workspace_inbox_inbox_item
                            .inboxItemSentNormal,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Sent - reservation request',
                        builder: _widgetbook_workspace_inbox_inbox_item
                            .inboxItemSentReservationRequest,
                      ),
                    ],
                  ),
                  _widgetbook.WidgetbookFolder(
                    name: 'thread',
                    children: [
                      _widgetbook.WidgetbookComponent(
                        name: 'ThreadReplyView',
                        useCases: [
                          _widgetbook.WidgetbookUseCase(
                            name: 'Error',
                            builder: _widgetbook_workspace_inbox_thread_reply
                                .threadReplyError,
                          ),
                          _widgetbook.WidgetbookUseCase(
                            name: 'Initial',
                            builder: _widgetbook_workspace_inbox_thread_reply
                                .threadReplyInitial,
                          ),
                          _widgetbook.WidgetbookUseCase(
                            name: 'Loading',
                            builder: _widgetbook_workspace_inbox_thread_reply
                                .threadReplyLoading,
                          ),
                        ],
                      ),
                      _widgetbook.WidgetbookComponent(
                        name: 'ThreadView',
                        useCases: [
                          _widgetbook.WidgetbookUseCase(
                            name: 'Scenario',
                            builder: _widgetbook_workspace_inbox_thread_view
                                .threadViewScenario,
                          ),
                        ],
                      ),
                      _widgetbook.WidgetbookFolder(
                        name: 'message',
                        children: [
                          _widgetbook.WidgetbookComponent(
                            name: 'ThreadMessageWidget',
                            useCases: [
                              _widgetbook.WidgetbookUseCase(
                                name: 'Thread message - received',
                                builder:
                                    _widgetbook_workspace_inbox_thread_message
                                        .threadMessageReceived,
                              ),
                              _widgetbook.WidgetbookUseCase(
                                name: 'Thread message - sent',
                                builder:
                                    _widgetbook_workspace_inbox_thread_message
                                        .threadMessageSent,
                              ),
                            ],
                          ),
                          _widgetbook.WidgetbookFolder(
                            name: 'reservation_request',
                            children: [
                              _widgetbook.WidgetbookComponent(
                                name: 'ThreadReservationRequestWidget',
                                useCases: [
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Reservation request - received',
                                    builder:
                                        _widgetbook_workspace_inbox_thread_message
                                            .reservationRequestReceived,
                                  ),
                                  _widgetbook.WidgetbookUseCase(
                                    name: 'Reservation request - sent',
                                    builder:
                                        _widgetbook_workspace_inbox_thread_message
                                            .reservationRequestSent,
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
              _widgetbook.WidgetbookFolder(
                name: 'listing',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'ListingListItemView',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Pure - date selected',
                        builder: _widgetbook_workspace_listing_listing_list_item
                            .listingPureDateSelected,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Pure - no date selected',
                        builder: _widgetbook_workspace_listing_listing_list_item
                            .listingPureNoDateSelected,
                      ),
                    ],
                  ),
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
                      _widgetbook.WidgetbookUseCase(
                        name: 'No active connection',
                        builder:
                            _widgetbook_workspace_nwc_nwc.nwcNoActiveConnection,
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
                  _widgetbook.WidgetbookComponent(
                    name: 'ProfileHeaderWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_profile_profile_header
                            .profileHeaderDefault,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Loading',
                        builder: _widgetbook_workspace_profile_profile_header
                            .profileHeaderLoading,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Missing image',
                        builder: _widgetbook_workspace_profile_profile_header
                            .profileHeaderMissingImage,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'relay',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'RelayListItemView',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Bootstrap (not removable)',
                        builder: _widgetbook_workspace_relay_relay_list_item
                            .relayBootstrap,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Connected',
                        builder: _widgetbook_workspace_relay_relay_list_item
                            .relayConnected,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Disconnected',
                        builder: _widgetbook_workspace_relay_relay_list_item
                            .relayDisconnected,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'reservation',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'TradeHeaderView',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Trade header (knobs)',
                        builder: _widgetbook_workspace_inbox_trade_header
                            .tradeHeaderKnobs,
                      ),
                    ],
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'search',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'SearchBoxWidget',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Default',
                        builder: _widgetbook_workspace_search_search_box
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
                    name: 'ListingViewBody',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'Body - date selected',
                        builder: _widgetbook_workspace_listing_listing_view
                            .listingViewBodyDateSelected,
                      ),
                      _widgetbook.WidgetbookUseCase(
                        name: 'Body - no date selected',
                        builder: _widgetbook_workspace_listing_listing_view
                            .listingViewBodyNoDateSelected,
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
            ],
          ),
        ],
      ),
    ],
  ),
];
