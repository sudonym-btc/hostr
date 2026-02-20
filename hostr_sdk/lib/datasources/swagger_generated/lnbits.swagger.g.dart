// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lnbits.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessControlList _$AccessControlListFromJson(Map<String, dynamic> json) =>
    AccessControlList(
      id: json['id'] as String,
      name: json['name'] as String,
      endpoints:
          (json['endpoints'] as List<dynamic>?)
              ?.map((e) => EndpointAccess.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tokenIdList:
          (json['token_id_list'] as List<dynamic>?)
              ?.map((e) => SimpleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AccessControlListToJson(AccessControlList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'endpoints': ?instance.endpoints?.map((e) => e.toJson()).toList(),
      'token_id_list': ?instance.tokenIdList?.map((e) => e.toJson()).toList(),
    };

ActionFields _$ActionFieldsFromJson(Map<String, dynamic> json) => ActionFields(
  generateAction: json['generate_action'] as bool? ?? false,
  generatePaymentLogic: json['generate_payment_logic'] as bool? ?? false,
  walletId: json['wallet_id'] as String?,
  currency: json['currency'] as String?,
  amount: json['amount'] as String?,
  amountSource: actionFieldsAmountSourceNullableFromJson(json['amount_source']),
  paidFlag: json['paid_flag'] as String?,
);

Map<String, dynamic> _$ActionFieldsToJson(ActionFields instance) =>
    <String, dynamic>{
      'generate_action': ?instance.generateAction,
      'generate_payment_logic': ?instance.generatePaymentLogic,
      'wallet_id': ?instance.walletId,
      'currency': ?instance.currency,
      'amount': ?instance.amount,
      'amount_source': ?actionFieldsAmountSourceNullableToJson(
        instance.amountSource,
      ),
      'paid_flag': ?instance.paidFlag,
    };

AdminSettings _$AdminSettingsFromJson(
  Map<String, dynamic> json,
) => AdminSettings(
  keycloakDiscoveryUrl: json['keycloak_discovery_url'] as String?,
  keycloakClientId: json['keycloak_client_id'] as String?,
  keycloakClientSecret: json['keycloak_client_secret'] as String?,
  keycloakClientCustomOrg: json['keycloak_client_custom_org'] as String?,
  keycloakClientCustomIcon: json['keycloak_client_custom_icon'] as String?,
  githubClientId: json['github_client_id'] as String?,
  githubClientSecret: json['github_client_secret'] as String?,
  googleClientId: json['google_client_id'] as String?,
  googleClientSecret: json['google_client_secret'] as String?,
  nostrAbsoluteRequestUrls:
      (json['nostr_absolute_request_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  authTokenExpireMinutes: (json['auth_token_expire_minutes'] as num?)?.toInt(),
  authAllMethods:
      (json['auth_all_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  authAllowedMethods:
      (json['auth_allowed_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  authCredetialsUpdateThreshold:
      (json['auth_credetials_update_threshold'] as num?)?.toInt(),
  authAuthenticationCacheMinutes:
      (json['auth_authentication_cache_minutes'] as num?)?.toInt(),
  lnbitsAuditEnabled: json['lnbits_audit_enabled'] as bool? ?? true,
  lnbitsAuditRetentionDays: (json['lnbits_audit_retention_days'] as num?)
      ?.toInt(),
  lnbitsAuditLogIpAddress:
      json['lnbits_audit_log_ip_address'] as bool? ?? false,
  lnbitsAuditLogPathParams:
      json['lnbits_audit_log_path_params'] as bool? ?? true,
  lnbitsAuditLogQueryParams:
      json['lnbits_audit_log_query_params'] as bool? ?? true,
  lnbitsAuditLogRequestBody:
      json['lnbits_audit_log_request_body'] as bool? ?? false,
  lnbitsAuditIncludePaths:
      (json['lnbits_audit_include_paths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAuditExcludePaths:
      (json['lnbits_audit_exclude_paths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAuditHttpMethods:
      (json['lnbits_audit_http_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAuditHttpResponseCodes:
      (json['lnbits_audit_http_response_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsNodeUi: json['lnbits_node_ui'] as bool? ?? false,
  lnbitsPublicNodeUi: json['lnbits_public_node_ui'] as bool? ?? false,
  lnbitsNodeUiTransactions:
      json['lnbits_node_ui_transactions'] as bool? ?? false,
  lnbitsWebpushPubkey: json['lnbits_webpush_pubkey'] as String?,
  lnbitsWebpushPrivkey: json['lnbits_webpush_privkey'] as String?,
  lightningInvoiceExpiry: (json['lightning_invoice_expiry'] as num?)?.toInt(),
  paypalEnabled: json['paypal_enabled'] as bool? ?? false,
  paypalApiEndpoint: json['paypal_api_endpoint'] as String?,
  paypalClientId: json['paypal_client_id'] as String?,
  paypalClientSecret: json['paypal_client_secret'] as String?,
  paypalPaymentSuccessUrl: json['paypal_payment_success_url'] as String?,
  paypalPaymentWebhookUrl: json['paypal_payment_webhook_url'] as String?,
  paypalWebhookId: json['paypal_webhook_id'] as String?,
  paypalLimits: json['paypal_limits'] == null
      ? null
      : FiatProviderLimits.fromJson(
          json['paypal_limits'] as Map<String, dynamic>,
        ),
  stripeEnabled: json['stripe_enabled'] as bool? ?? false,
  stripeApiEndpoint: json['stripe_api_endpoint'] as String?,
  stripeApiSecretKey: json['stripe_api_secret_key'] as String?,
  stripePaymentSuccessUrl: json['stripe_payment_success_url'] as String?,
  stripePaymentWebhookUrl: json['stripe_payment_webhook_url'] as String?,
  stripeWebhookSigningSecret: json['stripe_webhook_signing_secret'] as String?,
  stripeLimits: json['stripe_limits'] == null
      ? null
      : FiatProviderLimits.fromJson(
          json['stripe_limits'] as Map<String, dynamic>,
        ),
  breezLiquidApiKey: json['breez_liquid_api_key'] as String?,
  breezLiquidSeed: json['breez_liquid_seed'] as String?,
  breezLiquidFeeOffsetSat: (json['breez_liquid_fee_offset_sat'] as num?)
      ?.toInt(),
  strikeApiEndpoint: json['strike_api_endpoint'] as String?,
  strikeApiKey: json['strike_api_key'] as String?,
  breezApiKey: json['breez_api_key'] as String?,
  breezGreenlightSeed: json['breez_greenlight_seed'] as String?,
  breezGreenlightInviteCode: json['breez_greenlight_invite_code'] as String?,
  breezGreenlightDeviceKey: json['breez_greenlight_device_key'] as String?,
  breezGreenlightDeviceCert: json['breez_greenlight_device_cert'] as String?,
  breezUseTrampoline: json['breez_use_trampoline'] as bool? ?? true,
  nwcPairingUrl: json['nwc_pairing_url'] as String?,
  lntipsApiEndpoint: json['lntips_api_endpoint'] as String?,
  lntipsApiKey: json['lntips_api_key'] as String?,
  lntipsAdminKey: json['lntips_admin_key'] as String?,
  lntipsInvoiceKey: json['lntips_invoice_key'] as String?,
  sparkUrl: json['spark_url'] as String?,
  sparkToken: json['spark_token'] as String?,
  opennodeApiEndpoint: json['opennode_api_endpoint'] as String?,
  opennodeKey: json['opennode_key'] as String?,
  opennodeAdminKey: json['opennode_admin_key'] as String?,
  opennodeInvoiceKey: json['opennode_invoice_key'] as String?,
  phoenixdApiEndpoint: json['phoenixd_api_endpoint'] as String?,
  phoenixdApiPassword: json['phoenixd_api_password'] as String?,
  zbdApiEndpoint: json['zbd_api_endpoint'] as String?,
  zbdApiKey: json['zbd_api_key'] as String?,
  boltzClientEndpoint: json['boltz_client_endpoint'] as String?,
  boltzClientMacaroon: json['boltz_client_macaroon'] as String?,
  boltzClientPassword: json['boltz_client_password'] as String?,
  boltzClientCert: json['boltz_client_cert'] as String?,
  boltzMnemonic: json['boltz_mnemonic'] as String?,
  albyApiEndpoint: json['alby_api_endpoint'] as String?,
  albyAccessToken: json['alby_access_token'] as String?,
  blinkApiEndpoint: json['blink_api_endpoint'] as String?,
  blinkWsEndpoint: json['blink_ws_endpoint'] as String?,
  blinkToken: json['blink_token'] as String?,
  lnpayApiEndpoint: json['lnpay_api_endpoint'] as String?,
  lnpayApiKey: json['lnpay_api_key'] as String?,
  lnpayWalletKey: json['lnpay_wallet_key'] as String?,
  lnpayAdminKey: json['lnpay_admin_key'] as String?,
  lndGrpcEndpoint: json['lnd_grpc_endpoint'] as String?,
  lndGrpcCert: json['lnd_grpc_cert'] as String?,
  lndGrpcPort: (json['lnd_grpc_port'] as num?)?.toInt(),
  lndGrpcAdminMacaroon: json['lnd_grpc_admin_macaroon'] as String?,
  lndGrpcInvoiceMacaroon: json['lnd_grpc_invoice_macaroon'] as String?,
  lndGrpcMacaroon: json['lnd_grpc_macaroon'] as String?,
  lndGrpcMacaroonEncrypted: json['lnd_grpc_macaroon_encrypted'] as String?,
  lndRestEndpoint: json['lnd_rest_endpoint'] as String?,
  lndRestCert: json['lnd_rest_cert'] as String?,
  lndRestMacaroon: json['lnd_rest_macaroon'] as String?,
  lndRestMacaroonEncrypted: json['lnd_rest_macaroon_encrypted'] as String?,
  lndRestRouteHints: json['lnd_rest_route_hints'] as bool? ?? true,
  lndRestAllowSelfPayment:
      json['lnd_rest_allow_self_payment'] as bool? ?? false,
  lndCert: json['lnd_cert'] as String?,
  lndAdminMacaroon: json['lnd_admin_macaroon'] as String?,
  lndInvoiceMacaroon: json['lnd_invoice_macaroon'] as String?,
  lndRestAdminMacaroon: json['lnd_rest_admin_macaroon'] as String?,
  lndRestInvoiceMacaroon: json['lnd_rest_invoice_macaroon'] as String?,
  eclairUrl: json['eclair_url'] as String?,
  eclairPass: json['eclair_pass'] as String?,
  corelightningRestUrl: json['corelightning_rest_url'] as String?,
  corelightningRestMacaroon: json['corelightning_rest_macaroon'] as String?,
  corelightningRestCert: json['corelightning_rest_cert'] as String?,
  corelightningRpc: json['corelightning_rpc'] as String?,
  corelightningPayCommand: json['corelightning_pay_command'] as String?,
  clightningRpc: json['clightning_rpc'] as String?,
  clnrestUrl: json['clnrest_url'] as String?,
  clnrestCa: json['clnrest_ca'] as String?,
  clnrestCert: json['clnrest_cert'] as String?,
  clnrestReadonlyRune: json['clnrest_readonly_rune'] as String?,
  clnrestInvoiceRune: json['clnrest_invoice_rune'] as String?,
  clnrestPayRune: json['clnrest_pay_rune'] as String?,
  clnrestRenepayRune: json['clnrest_renepay_rune'] as String?,
  clnrestLastPayIndex: json['clnrest_last_pay_index'] as String?,
  clnrestNodeid: json['clnrest_nodeid'] as String?,
  clicheEndpoint: json['cliche_endpoint'] as String?,
  lnbitsEndpoint: json['lnbits_endpoint'] as String?,
  lnbitsKey: json['lnbits_key'] as String?,
  lnbitsAdminKey: json['lnbits_admin_key'] as String?,
  lnbitsInvoiceKey: json['lnbits_invoice_key'] as String?,
  fakeWalletSecret: json['fake_wallet_secret'] as String?,
  lnbitsDenomination: json['lnbits_denomination'] as String?,
  lnbitsBackendWalletClass: json['lnbits_backend_wallet_class'] as String?,
  lnbitsFundingSourcePayInvoiceWaitSeconds:
      (json['lnbits_funding_source_pay_invoice_wait_seconds'] as num?)?.toInt(),
  fundingSourceMaxRetries: (json['funding_source_max_retries'] as num?)
      ?.toInt(),
  lnbitsNostrNotificationsEnabled:
      json['lnbits_nostr_notifications_enabled'] as bool? ?? false,
  lnbitsNostrNotificationsPrivateKey:
      json['lnbits_nostr_notifications_private_key'] as String?,
  lnbitsNostrNotificationsIdentifiers:
      (json['lnbits_nostr_notifications_identifiers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsTelegramNotificationsEnabled:
      json['lnbits_telegram_notifications_enabled'] as bool? ?? false,
  lnbitsTelegramNotificationsAccessToken:
      json['lnbits_telegram_notifications_access_token'] as String?,
  lnbitsTelegramNotificationsChatId:
      json['lnbits_telegram_notifications_chat_id'] as String?,
  lnbitsEmailNotificationsEnabled:
      json['lnbits_email_notifications_enabled'] as bool? ?? false,
  lnbitsEmailNotificationsEmail:
      json['lnbits_email_notifications_email'] as String?,
  lnbitsEmailNotificationsUsername:
      json['lnbits_email_notifications_username'] as String?,
  lnbitsEmailNotificationsPassword:
      json['lnbits_email_notifications_password'] as String?,
  lnbitsEmailNotificationsServer:
      json['lnbits_email_notifications_server'] as String?,
  lnbitsEmailNotificationsPort:
      (json['lnbits_email_notifications_port'] as num?)?.toInt(),
  lnbitsEmailNotificationsToEmails:
      (json['lnbits_email_notifications_to_emails'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsNotificationSettingsUpdate:
      json['lnbits_notification_settings_update'] as bool? ?? true,
  lnbitsNotificationCreditDebit:
      json['lnbits_notification_credit_debit'] as bool? ?? true,
  notificationBalanceDeltaThresholdSats:
      (json['notification_balance_delta_threshold_sats'] as num?)?.toInt(),
  lnbitsNotificationServerStartStop:
      json['lnbits_notification_server_start_stop'] as bool? ?? true,
  lnbitsNotificationWatchdog:
      json['lnbits_notification_watchdog'] as bool? ?? false,
  lnbitsNotificationServerStatusHours:
      (json['lnbits_notification_server_status_hours'] as num?)?.toInt(),
  lnbitsNotificationIncomingPaymentAmountSats:
      (json['lnbits_notification_incoming_payment_amount_sats'] as num?)
          ?.toInt(),
  lnbitsNotificationOutgoingPaymentAmountSats:
      (json['lnbits_notification_outgoing_payment_amount_sats'] as num?)
          ?.toInt(),
  lnbitsRateLimitNo: (json['lnbits_rate_limit_no'] as num?)?.toInt(),
  lnbitsRateLimitUnit: json['lnbits_rate_limit_unit'] as String?,
  lnbitsAllowedIps:
      (json['lnbits_allowed_ips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsBlockedIps:
      (json['lnbits_blocked_ips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsCallbackUrlRules:
      (json['lnbits_callback_url_rules'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsWalletLimitMaxBalance: (json['lnbits_wallet_limit_max_balance'] as num?)
      ?.toInt(),
  lnbitsWalletLimitDailyMaxWithdraw:
      (json['lnbits_wallet_limit_daily_max_withdraw'] as num?)?.toInt(),
  lnbitsWalletLimitSecsBetweenTrans:
      (json['lnbits_wallet_limit_secs_between_trans'] as num?)?.toInt(),
  lnbitsOnlyAllowIncomingPayments:
      json['lnbits_only_allow_incoming_payments'] as bool? ?? false,
  lnbitsWatchdogSwitchToVoidwallet:
      json['lnbits_watchdog_switch_to_voidwallet'] as bool? ?? false,
  lnbitsWatchdogIntervalMinutes:
      (json['lnbits_watchdog_interval_minutes'] as num?)?.toInt(),
  lnbitsWatchdogDelta: (json['lnbits_watchdog_delta'] as num?)?.toInt(),
  lnbitsMaxOutgoingPaymentAmountSats:
      (json['lnbits_max_outgoing_payment_amount_sats'] as num?)?.toInt(),
  lnbitsMaxIncomingPaymentAmountSats:
      (json['lnbits_max_incoming_payment_amount_sats'] as num?)?.toInt(),
  lnbitsExchangeRateCacheSeconds:
      (json['lnbits_exchange_rate_cache_seconds'] as num?)?.toInt(),
  lnbitsExchangeHistorySize: (json['lnbits_exchange_history_size'] as num?)
      ?.toInt(),
  lnbitsExchangeHistoryRefreshIntervalSeconds:
      (json['lnbits_exchange_history_refresh_interval_seconds'] as num?)
          ?.toInt(),
  lnbitsExchangeRateProviders:
      (json['lnbits_exchange_rate_providers'] as List<dynamic>?)
          ?.map((e) => ExchangeRateProvider.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  lnbitsReserveFeeMin: (json['lnbits_reserve_fee_min'] as num?)?.toInt(),
  lnbitsReserveFeePercent: (json['lnbits_reserve_fee_percent'] as num?)
      ?.toDouble(),
  lnbitsServiceFee: (json['lnbits_service_fee'] as num?)?.toDouble(),
  lnbitsServiceFeeIgnoreInternal:
      json['lnbits_service_fee_ignore_internal'] as bool? ?? true,
  lnbitsServiceFeeMax: (json['lnbits_service_fee_max'] as num?)?.toInt(),
  lnbitsServiceFeeWallet: json['lnbits_service_fee_wallet'] as String?,
  lnbitsMaxAssetSizeMb: (json['lnbits_max_asset_size_mb'] as num?)?.toDouble(),
  lnbitsAssetsAllowedMimeTypes:
      (json['lnbits_assets_allowed_mime_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAssetThumbnailWidth: (json['lnbits_asset_thumbnail_width'] as num?)
      ?.toInt(),
  lnbitsAssetThumbnailHeight: (json['lnbits_asset_thumbnail_height'] as num?)
      ?.toInt(),
  lnbitsAssetThumbnailFormat: json['lnbits_asset_thumbnail_format'] as String?,
  lnbitsMaxAssetsPerUser: (json['lnbits_max_assets_per_user'] as num?)?.toInt(),
  lnbitsAssetsNoLimitUsers:
      (json['lnbits_assets_no_limit_users'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsBaseurl: json['lnbits_baseurl'] as String?,
  lnbitsHideApi: json['lnbits_hide_api'] as bool? ?? false,
  lnbitsSiteTitle: json['lnbits_site_title'] as String?,
  lnbitsSiteTagline: json['lnbits_site_tagline'] as String?,
  lnbitsSiteDescription: json['lnbits_site_description'] as String?,
  lnbitsShowHomePageElements:
      json['lnbits_show_home_page_elements'] as bool? ?? true,
  lnbitsDefaultWalletName: json['lnbits_default_wallet_name'] as String?,
  lnbitsCustomBadge: json['lnbits_custom_badge'] as String?,
  lnbitsCustomBadgeColor: json['lnbits_custom_badge_color'] as String?,
  lnbitsThemeOptions:
      (json['lnbits_theme_options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsCustomLogo: json['lnbits_custom_logo'] as String?,
  lnbitsCustomImage: json['lnbits_custom_image'] as String?,
  lnbitsAdSpaceTitle: json['lnbits_ad_space_title'] as String?,
  lnbitsAdSpace: json['lnbits_ad_space'] as String?,
  lnbitsAdSpaceEnabled: json['lnbits_ad_space_enabled'] as bool? ?? false,
  lnbitsAllowedCurrencies:
      (json['lnbits_allowed_currencies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsDefaultAccountingCurrency:
      json['lnbits_default_accounting_currency'] as String?,
  lnbitsQrLogo: json['lnbits_qr_logo'] as String?,
  lnbitsAppleTouchIcon: json['lnbits_apple_touch_icon'] as String?,
  lnbitsDefaultReaction: json['lnbits_default_reaction'] as String?,
  lnbitsDefaultTheme: json['lnbits_default_theme'] as String?,
  lnbitsDefaultBorder: json['lnbits_default_border'] as String?,
  lnbitsDefaultGradient: json['lnbits_default_gradient'] as bool? ?? true,
  lnbitsDefaultBgimage: json['lnbits_default_bgimage'] as String?,
  lnbitsAdminExtensions:
      (json['lnbits_admin_extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsUserDefaultExtensions:
      (json['lnbits_user_default_extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsExtensionsDeactivateAll:
      json['lnbits_extensions_deactivate_all'] as bool? ?? false,
  lnbitsExtensionsBuilderActivateNonAdmins:
      json['lnbits_extensions_builder_activate_non_admins'] as bool? ?? false,
  lnbitsExtensionsReviewsUrl: json['lnbits_extensions_reviews_url'] as String?,
  lnbitsExtensionsManifests:
      (json['lnbits_extensions_manifests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsExtensionsBuilderManifestUrl:
      json['lnbits_extensions_builder_manifest_url'] as String?,
  lnbitsAdminUsers:
      (json['lnbits_admin_users'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAllowedUsers:
      (json['lnbits_allowed_users'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAllowNewAccounts: json['lnbits_allow_new_accounts'] as bool? ?? true,
  isSuperUser: json['is_super_user'] as bool,
  lnbitsAllowedFundingSources:
      (json['lnbits_allowed_funding_sources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$AdminSettingsToJson(
  AdminSettings instance,
) => <String, dynamic>{
  'keycloak_discovery_url': ?instance.keycloakDiscoveryUrl,
  'keycloak_client_id': ?instance.keycloakClientId,
  'keycloak_client_secret': ?instance.keycloakClientSecret,
  'keycloak_client_custom_org': ?instance.keycloakClientCustomOrg,
  'keycloak_client_custom_icon': ?instance.keycloakClientCustomIcon,
  'github_client_id': ?instance.githubClientId,
  'github_client_secret': ?instance.githubClientSecret,
  'google_client_id': ?instance.googleClientId,
  'google_client_secret': ?instance.googleClientSecret,
  'nostr_absolute_request_urls': ?instance.nostrAbsoluteRequestUrls,
  'auth_token_expire_minutes': ?instance.authTokenExpireMinutes,
  'auth_all_methods': ?instance.authAllMethods,
  'auth_allowed_methods': ?instance.authAllowedMethods,
  'auth_credetials_update_threshold': ?instance.authCredetialsUpdateThreshold,
  'auth_authentication_cache_minutes': ?instance.authAuthenticationCacheMinutes,
  'lnbits_audit_enabled': ?instance.lnbitsAuditEnabled,
  'lnbits_audit_retention_days': ?instance.lnbitsAuditRetentionDays,
  'lnbits_audit_log_ip_address': ?instance.lnbitsAuditLogIpAddress,
  'lnbits_audit_log_path_params': ?instance.lnbitsAuditLogPathParams,
  'lnbits_audit_log_query_params': ?instance.lnbitsAuditLogQueryParams,
  'lnbits_audit_log_request_body': ?instance.lnbitsAuditLogRequestBody,
  'lnbits_audit_include_paths': ?instance.lnbitsAuditIncludePaths,
  'lnbits_audit_exclude_paths': ?instance.lnbitsAuditExcludePaths,
  'lnbits_audit_http_methods': ?instance.lnbitsAuditHttpMethods,
  'lnbits_audit_http_response_codes': ?instance.lnbitsAuditHttpResponseCodes,
  'lnbits_node_ui': ?instance.lnbitsNodeUi,
  'lnbits_public_node_ui': ?instance.lnbitsPublicNodeUi,
  'lnbits_node_ui_transactions': ?instance.lnbitsNodeUiTransactions,
  'lnbits_webpush_pubkey': ?instance.lnbitsWebpushPubkey,
  'lnbits_webpush_privkey': ?instance.lnbitsWebpushPrivkey,
  'lightning_invoice_expiry': ?instance.lightningInvoiceExpiry,
  'paypal_enabled': ?instance.paypalEnabled,
  'paypal_api_endpoint': ?instance.paypalApiEndpoint,
  'paypal_client_id': ?instance.paypalClientId,
  'paypal_client_secret': ?instance.paypalClientSecret,
  'paypal_payment_success_url': ?instance.paypalPaymentSuccessUrl,
  'paypal_payment_webhook_url': ?instance.paypalPaymentWebhookUrl,
  'paypal_webhook_id': ?instance.paypalWebhookId,
  'paypal_limits': ?instance.paypalLimits?.toJson(),
  'stripe_enabled': ?instance.stripeEnabled,
  'stripe_api_endpoint': ?instance.stripeApiEndpoint,
  'stripe_api_secret_key': ?instance.stripeApiSecretKey,
  'stripe_payment_success_url': ?instance.stripePaymentSuccessUrl,
  'stripe_payment_webhook_url': ?instance.stripePaymentWebhookUrl,
  'stripe_webhook_signing_secret': ?instance.stripeWebhookSigningSecret,
  'stripe_limits': ?instance.stripeLimits?.toJson(),
  'breez_liquid_api_key': ?instance.breezLiquidApiKey,
  'breez_liquid_seed': ?instance.breezLiquidSeed,
  'breez_liquid_fee_offset_sat': ?instance.breezLiquidFeeOffsetSat,
  'strike_api_endpoint': ?instance.strikeApiEndpoint,
  'strike_api_key': ?instance.strikeApiKey,
  'breez_api_key': ?instance.breezApiKey,
  'breez_greenlight_seed': ?instance.breezGreenlightSeed,
  'breez_greenlight_invite_code': ?instance.breezGreenlightInviteCode,
  'breez_greenlight_device_key': ?instance.breezGreenlightDeviceKey,
  'breez_greenlight_device_cert': ?instance.breezGreenlightDeviceCert,
  'breez_use_trampoline': ?instance.breezUseTrampoline,
  'nwc_pairing_url': ?instance.nwcPairingUrl,
  'lntips_api_endpoint': ?instance.lntipsApiEndpoint,
  'lntips_api_key': ?instance.lntipsApiKey,
  'lntips_admin_key': ?instance.lntipsAdminKey,
  'lntips_invoice_key': ?instance.lntipsInvoiceKey,
  'spark_url': ?instance.sparkUrl,
  'spark_token': ?instance.sparkToken,
  'opennode_api_endpoint': ?instance.opennodeApiEndpoint,
  'opennode_key': ?instance.opennodeKey,
  'opennode_admin_key': ?instance.opennodeAdminKey,
  'opennode_invoice_key': ?instance.opennodeInvoiceKey,
  'phoenixd_api_endpoint': ?instance.phoenixdApiEndpoint,
  'phoenixd_api_password': ?instance.phoenixdApiPassword,
  'zbd_api_endpoint': ?instance.zbdApiEndpoint,
  'zbd_api_key': ?instance.zbdApiKey,
  'boltz_client_endpoint': ?instance.boltzClientEndpoint,
  'boltz_client_macaroon': ?instance.boltzClientMacaroon,
  'boltz_client_password': ?instance.boltzClientPassword,
  'boltz_client_cert': ?instance.boltzClientCert,
  'boltz_mnemonic': ?instance.boltzMnemonic,
  'alby_api_endpoint': ?instance.albyApiEndpoint,
  'alby_access_token': ?instance.albyAccessToken,
  'blink_api_endpoint': ?instance.blinkApiEndpoint,
  'blink_ws_endpoint': ?instance.blinkWsEndpoint,
  'blink_token': ?instance.blinkToken,
  'lnpay_api_endpoint': ?instance.lnpayApiEndpoint,
  'lnpay_api_key': ?instance.lnpayApiKey,
  'lnpay_wallet_key': ?instance.lnpayWalletKey,
  'lnpay_admin_key': ?instance.lnpayAdminKey,
  'lnd_grpc_endpoint': ?instance.lndGrpcEndpoint,
  'lnd_grpc_cert': ?instance.lndGrpcCert,
  'lnd_grpc_port': ?instance.lndGrpcPort,
  'lnd_grpc_admin_macaroon': ?instance.lndGrpcAdminMacaroon,
  'lnd_grpc_invoice_macaroon': ?instance.lndGrpcInvoiceMacaroon,
  'lnd_grpc_macaroon': ?instance.lndGrpcMacaroon,
  'lnd_grpc_macaroon_encrypted': ?instance.lndGrpcMacaroonEncrypted,
  'lnd_rest_endpoint': ?instance.lndRestEndpoint,
  'lnd_rest_cert': ?instance.lndRestCert,
  'lnd_rest_macaroon': ?instance.lndRestMacaroon,
  'lnd_rest_macaroon_encrypted': ?instance.lndRestMacaroonEncrypted,
  'lnd_rest_route_hints': ?instance.lndRestRouteHints,
  'lnd_rest_allow_self_payment': ?instance.lndRestAllowSelfPayment,
  'lnd_cert': ?instance.lndCert,
  'lnd_admin_macaroon': ?instance.lndAdminMacaroon,
  'lnd_invoice_macaroon': ?instance.lndInvoiceMacaroon,
  'lnd_rest_admin_macaroon': ?instance.lndRestAdminMacaroon,
  'lnd_rest_invoice_macaroon': ?instance.lndRestInvoiceMacaroon,
  'eclair_url': ?instance.eclairUrl,
  'eclair_pass': ?instance.eclairPass,
  'corelightning_rest_url': ?instance.corelightningRestUrl,
  'corelightning_rest_macaroon': ?instance.corelightningRestMacaroon,
  'corelightning_rest_cert': ?instance.corelightningRestCert,
  'corelightning_rpc': ?instance.corelightningRpc,
  'corelightning_pay_command': ?instance.corelightningPayCommand,
  'clightning_rpc': ?instance.clightningRpc,
  'clnrest_url': ?instance.clnrestUrl,
  'clnrest_ca': ?instance.clnrestCa,
  'clnrest_cert': ?instance.clnrestCert,
  'clnrest_readonly_rune': ?instance.clnrestReadonlyRune,
  'clnrest_invoice_rune': ?instance.clnrestInvoiceRune,
  'clnrest_pay_rune': ?instance.clnrestPayRune,
  'clnrest_renepay_rune': ?instance.clnrestRenepayRune,
  'clnrest_last_pay_index': ?instance.clnrestLastPayIndex,
  'clnrest_nodeid': ?instance.clnrestNodeid,
  'cliche_endpoint': ?instance.clicheEndpoint,
  'lnbits_endpoint': ?instance.lnbitsEndpoint,
  'lnbits_key': ?instance.lnbitsKey,
  'lnbits_admin_key': ?instance.lnbitsAdminKey,
  'lnbits_invoice_key': ?instance.lnbitsInvoiceKey,
  'fake_wallet_secret': ?instance.fakeWalletSecret,
  'lnbits_denomination': ?instance.lnbitsDenomination,
  'lnbits_backend_wallet_class': ?instance.lnbitsBackendWalletClass,
  'lnbits_funding_source_pay_invoice_wait_seconds':
      ?instance.lnbitsFundingSourcePayInvoiceWaitSeconds,
  'funding_source_max_retries': ?instance.fundingSourceMaxRetries,
  'lnbits_nostr_notifications_enabled':
      ?instance.lnbitsNostrNotificationsEnabled,
  'lnbits_nostr_notifications_private_key':
      ?instance.lnbitsNostrNotificationsPrivateKey,
  'lnbits_nostr_notifications_identifiers':
      ?instance.lnbitsNostrNotificationsIdentifiers,
  'lnbits_telegram_notifications_enabled':
      ?instance.lnbitsTelegramNotificationsEnabled,
  'lnbits_telegram_notifications_access_token':
      ?instance.lnbitsTelegramNotificationsAccessToken,
  'lnbits_telegram_notifications_chat_id':
      ?instance.lnbitsTelegramNotificationsChatId,
  'lnbits_email_notifications_enabled':
      ?instance.lnbitsEmailNotificationsEnabled,
  'lnbits_email_notifications_email': ?instance.lnbitsEmailNotificationsEmail,
  'lnbits_email_notifications_username':
      ?instance.lnbitsEmailNotificationsUsername,
  'lnbits_email_notifications_password':
      ?instance.lnbitsEmailNotificationsPassword,
  'lnbits_email_notifications_server': ?instance.lnbitsEmailNotificationsServer,
  'lnbits_email_notifications_port': ?instance.lnbitsEmailNotificationsPort,
  'lnbits_email_notifications_to_emails':
      ?instance.lnbitsEmailNotificationsToEmails,
  'lnbits_notification_settings_update':
      ?instance.lnbitsNotificationSettingsUpdate,
  'lnbits_notification_credit_debit': ?instance.lnbitsNotificationCreditDebit,
  'notification_balance_delta_threshold_sats':
      ?instance.notificationBalanceDeltaThresholdSats,
  'lnbits_notification_server_start_stop':
      ?instance.lnbitsNotificationServerStartStop,
  'lnbits_notification_watchdog': ?instance.lnbitsNotificationWatchdog,
  'lnbits_notification_server_status_hours':
      ?instance.lnbitsNotificationServerStatusHours,
  'lnbits_notification_incoming_payment_amount_sats':
      ?instance.lnbitsNotificationIncomingPaymentAmountSats,
  'lnbits_notification_outgoing_payment_amount_sats':
      ?instance.lnbitsNotificationOutgoingPaymentAmountSats,
  'lnbits_rate_limit_no': ?instance.lnbitsRateLimitNo,
  'lnbits_rate_limit_unit': ?instance.lnbitsRateLimitUnit,
  'lnbits_allowed_ips': ?instance.lnbitsAllowedIps,
  'lnbits_blocked_ips': ?instance.lnbitsBlockedIps,
  'lnbits_callback_url_rules': ?instance.lnbitsCallbackUrlRules,
  'lnbits_wallet_limit_max_balance': ?instance.lnbitsWalletLimitMaxBalance,
  'lnbits_wallet_limit_daily_max_withdraw':
      ?instance.lnbitsWalletLimitDailyMaxWithdraw,
  'lnbits_wallet_limit_secs_between_trans':
      ?instance.lnbitsWalletLimitSecsBetweenTrans,
  'lnbits_only_allow_incoming_payments':
      ?instance.lnbitsOnlyAllowIncomingPayments,
  'lnbits_watchdog_switch_to_voidwallet':
      ?instance.lnbitsWatchdogSwitchToVoidwallet,
  'lnbits_watchdog_interval_minutes': ?instance.lnbitsWatchdogIntervalMinutes,
  'lnbits_watchdog_delta': ?instance.lnbitsWatchdogDelta,
  'lnbits_max_outgoing_payment_amount_sats':
      ?instance.lnbitsMaxOutgoingPaymentAmountSats,
  'lnbits_max_incoming_payment_amount_sats':
      ?instance.lnbitsMaxIncomingPaymentAmountSats,
  'lnbits_exchange_rate_cache_seconds':
      ?instance.lnbitsExchangeRateCacheSeconds,
  'lnbits_exchange_history_size': ?instance.lnbitsExchangeHistorySize,
  'lnbits_exchange_history_refresh_interval_seconds':
      ?instance.lnbitsExchangeHistoryRefreshIntervalSeconds,
  'lnbits_exchange_rate_providers': ?instance.lnbitsExchangeRateProviders
      ?.map((e) => e.toJson())
      .toList(),
  'lnbits_reserve_fee_min': ?instance.lnbitsReserveFeeMin,
  'lnbits_reserve_fee_percent': ?instance.lnbitsReserveFeePercent,
  'lnbits_service_fee': ?instance.lnbitsServiceFee,
  'lnbits_service_fee_ignore_internal':
      ?instance.lnbitsServiceFeeIgnoreInternal,
  'lnbits_service_fee_max': ?instance.lnbitsServiceFeeMax,
  'lnbits_service_fee_wallet': ?instance.lnbitsServiceFeeWallet,
  'lnbits_max_asset_size_mb': ?instance.lnbitsMaxAssetSizeMb,
  'lnbits_assets_allowed_mime_types': ?instance.lnbitsAssetsAllowedMimeTypes,
  'lnbits_asset_thumbnail_width': ?instance.lnbitsAssetThumbnailWidth,
  'lnbits_asset_thumbnail_height': ?instance.lnbitsAssetThumbnailHeight,
  'lnbits_asset_thumbnail_format': ?instance.lnbitsAssetThumbnailFormat,
  'lnbits_max_assets_per_user': ?instance.lnbitsMaxAssetsPerUser,
  'lnbits_assets_no_limit_users': ?instance.lnbitsAssetsNoLimitUsers,
  'lnbits_baseurl': ?instance.lnbitsBaseurl,
  'lnbits_hide_api': ?instance.lnbitsHideApi,
  'lnbits_site_title': ?instance.lnbitsSiteTitle,
  'lnbits_site_tagline': ?instance.lnbitsSiteTagline,
  'lnbits_site_description': ?instance.lnbitsSiteDescription,
  'lnbits_show_home_page_elements': ?instance.lnbitsShowHomePageElements,
  'lnbits_default_wallet_name': ?instance.lnbitsDefaultWalletName,
  'lnbits_custom_badge': ?instance.lnbitsCustomBadge,
  'lnbits_custom_badge_color': ?instance.lnbitsCustomBadgeColor,
  'lnbits_theme_options': ?instance.lnbitsThemeOptions,
  'lnbits_custom_logo': ?instance.lnbitsCustomLogo,
  'lnbits_custom_image': ?instance.lnbitsCustomImage,
  'lnbits_ad_space_title': ?instance.lnbitsAdSpaceTitle,
  'lnbits_ad_space': ?instance.lnbitsAdSpace,
  'lnbits_ad_space_enabled': ?instance.lnbitsAdSpaceEnabled,
  'lnbits_allowed_currencies': ?instance.lnbitsAllowedCurrencies,
  'lnbits_default_accounting_currency':
      ?instance.lnbitsDefaultAccountingCurrency,
  'lnbits_qr_logo': ?instance.lnbitsQrLogo,
  'lnbits_apple_touch_icon': ?instance.lnbitsAppleTouchIcon,
  'lnbits_default_reaction': ?instance.lnbitsDefaultReaction,
  'lnbits_default_theme': ?instance.lnbitsDefaultTheme,
  'lnbits_default_border': ?instance.lnbitsDefaultBorder,
  'lnbits_default_gradient': ?instance.lnbitsDefaultGradient,
  'lnbits_default_bgimage': ?instance.lnbitsDefaultBgimage,
  'lnbits_admin_extensions': ?instance.lnbitsAdminExtensions,
  'lnbits_user_default_extensions': ?instance.lnbitsUserDefaultExtensions,
  'lnbits_extensions_deactivate_all': ?instance.lnbitsExtensionsDeactivateAll,
  'lnbits_extensions_builder_activate_non_admins':
      ?instance.lnbitsExtensionsBuilderActivateNonAdmins,
  'lnbits_extensions_reviews_url': ?instance.lnbitsExtensionsReviewsUrl,
  'lnbits_extensions_manifests': ?instance.lnbitsExtensionsManifests,
  'lnbits_extensions_builder_manifest_url':
      ?instance.lnbitsExtensionsBuilderManifestUrl,
  'lnbits_admin_users': ?instance.lnbitsAdminUsers,
  'lnbits_allowed_users': ?instance.lnbitsAllowedUsers,
  'lnbits_allow_new_accounts': ?instance.lnbitsAllowNewAccounts,
  'is_super_user': instance.isSuperUser,
  'lnbits_allowed_funding_sources': ?instance.lnbitsAllowedFundingSources,
};

ApiTokenRequest _$ApiTokenRequestFromJson(Map<String, dynamic> json) =>
    ApiTokenRequest(
      aclId: json['acl_id'] as String,
      tokenName: json['token_name'] as String,
      password: json['password'] as String,
      expirationTimeMinutes: (json['expiration_time_minutes'] as num).toInt(),
    );

Map<String, dynamic> _$ApiTokenRequestToJson(ApiTokenRequest instance) =>
    <String, dynamic>{
      'acl_id': instance.aclId,
      'token_name': instance.tokenName,
      'password': instance.password,
      'expiration_time_minutes': instance.expirationTimeMinutes,
    };

ApiTokenResponse _$ApiTokenResponseFromJson(Map<String, dynamic> json) =>
    ApiTokenResponse(
      id: json['id'] as String,
      apiToken: json['api_token'] as String,
    );

Map<String, dynamic> _$ApiTokenResponseToJson(ApiTokenResponse instance) =>
    <String, dynamic>{'id': instance.id, 'api_token': instance.apiToken};

AssetInfo _$AssetInfoFromJson(Map<String, dynamic> json) => AssetInfo(
  id: json['id'] as String,
  mimeType: json['mime_type'] as String,
  name: json['name'] as String,
  isPublic: json['is_public'] as bool? ?? false,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  thumbnailBase64: json['thumbnail_base64'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AssetInfoToJson(AssetInfo instance) => <String, dynamic>{
  'id': instance.id,
  'mime_type': instance.mimeType,
  'name': instance.name,
  'is_public': ?instance.isPublic,
  'size_bytes': instance.sizeBytes,
  'thumbnail_base64': ?instance.thumbnailBase64,
  'created_at': ?instance.createdAt?.toIso8601String(),
};

AssetUpdate _$AssetUpdateFromJson(Map<String, dynamic> json) => AssetUpdate(
  name: json['name'] as String?,
  isPublic: json['is_public'] as bool?,
);

Map<String, dynamic> _$AssetUpdateToJson(AssetUpdate instance) =>
    <String, dynamic>{'name': ?instance.name, 'is_public': ?instance.isPublic};

AuditCountStat _$AuditCountStatFromJson(Map<String, dynamic> json) =>
    AuditCountStat(
      field: json['field'] as String?,
      total: (json['total'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AuditCountStatToJson(AuditCountStat instance) =>
    <String, dynamic>{'field': ?instance.field, 'total': ?instance.total};

AuditStats _$AuditStatsFromJson(Map<String, dynamic> json) => AuditStats(
  requestMethod:
      (json['request_method'] as List<dynamic>?)
          ?.map((e) => AuditCountStat.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  responseCode:
      (json['response_code'] as List<dynamic>?)
          ?.map((e) => AuditCountStat.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  component:
      (json['component'] as List<dynamic>?)
          ?.map((e) => AuditCountStat.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  longDuration:
      (json['long_duration'] as List<dynamic>?)
          ?.map((e) => AuditCountStat.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$AuditStatsToJson(
  AuditStats instance,
) => <String, dynamic>{
  'request_method': ?instance.requestMethod?.map((e) => e.toJson()).toList(),
  'response_code': ?instance.responseCode?.map((e) => e.toJson()).toList(),
  'component': ?instance.component?.map((e) => e.toJson()).toList(),
  'long_duration': ?instance.longDuration?.map((e) => e.toJson()).toList(),
};

BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost
_$BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPostFromJson(
  Map<String, dynamic> json,
) => BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost(
  name: json['name'] as String?,
  currency: json['currency'] as String?,
);

Map<String, dynamic>
_$BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPostToJson(
  BodyCreateANewWalletForUserUsersApiV1UserUserIdWalletPost instance,
) => <String, dynamic>{'name': ?instance.name, 'currency': ?instance.currency};

BodyUploadApiV1AssetsPost _$BodyUploadApiV1AssetsPostFromJson(
  Map<String, dynamic> json,
) => BodyUploadApiV1AssetsPost(file: json['file'] as String);

Map<String, dynamic> _$BodyUploadApiV1AssetsPostToJson(
  BodyUploadApiV1AssetsPost instance,
) => <String, dynamic>{'file': instance.file};

BodyApiConnectPeerNodeApiV1PeersPost
_$BodyApiConnectPeerNodeApiV1PeersPostFromJson(Map<String, dynamic> json) =>
    BodyApiConnectPeerNodeApiV1PeersPost(uri: json['uri'] as String);

Map<String, dynamic> _$BodyApiConnectPeerNodeApiV1PeersPostToJson(
  BodyApiConnectPeerNodeApiV1PeersPost instance,
) => <String, dynamic>{'uri': instance.uri};

BodyApiCreateChannelNodeApiV1ChannelsPost
_$BodyApiCreateChannelNodeApiV1ChannelsPostFromJson(
  Map<String, dynamic> json,
) => BodyApiCreateChannelNodeApiV1ChannelsPost(
  peerId: json['peer_id'] as String,
  fundingAmount: (json['funding_amount'] as num).toInt(),
  pushAmount: (json['push_amount'] as num?)?.toInt(),
  feeRate: (json['fee_rate'] as num?)?.toInt(),
);

Map<String, dynamic> _$BodyApiCreateChannelNodeApiV1ChannelsPostToJson(
  BodyApiCreateChannelNodeApiV1ChannelsPost instance,
) => <String, dynamic>{
  'peer_id': instance.peerId,
  'funding_amount': instance.fundingAmount,
  'push_amount': ?instance.pushAmount,
  'fee_rate': ?instance.feeRate,
};

BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut
_$BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPutFromJson(
  Map<String, dynamic> json,
) => BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut(
  feePpm: (json['fee_ppm'] as num?)?.toInt(),
  feeBaseMsat: (json['fee_base_msat'] as num?)?.toInt(),
);

Map<String, dynamic> _$BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPutToJson(
  BodyApiSetChannelFeesNodeApiV1ChannelsChannelIdPut instance,
) => <String, dynamic>{
  'fee_ppm': ?instance.feePpm,
  'fee_base_msat': ?instance.feeBaseMsat,
};

BodyApiUpdateWalletApiV1WalletPatch
_$BodyApiUpdateWalletApiV1WalletPatchFromJson(Map<String, dynamic> json) =>
    BodyApiUpdateWalletApiV1WalletPatch(
      name: json['name'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      currency: json['currency'] as String?,
      pinned: json['pinned'] as bool?,
    );

Map<String, dynamic> _$BodyApiUpdateWalletApiV1WalletPatchToJson(
  BodyApiUpdateWalletApiV1WalletPatch instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'icon': ?instance.icon,
  'color': ?instance.color,
  'currency': ?instance.currency,
  'pinned': ?instance.pinned,
};

CancelInvoice _$CancelInvoiceFromJson(Map<String, dynamic> json) =>
    CancelInvoice(paymentHash: json['payment_hash'] as String);

Map<String, dynamic> _$CancelInvoiceToJson(CancelInvoice instance) =>
    <String, dynamic>{'payment_hash': instance.paymentHash};

ChannelBalance _$ChannelBalanceFromJson(Map<String, dynamic> json) =>
    ChannelBalance(
      localMsat: (json['local_msat'] as num).toInt(),
      remoteMsat: (json['remote_msat'] as num).toInt(),
      totalMsat: (json['total_msat'] as num).toInt(),
    );

Map<String, dynamic> _$ChannelBalanceToJson(ChannelBalance instance) =>
    <String, dynamic>{
      'local_msat': instance.localMsat,
      'remote_msat': instance.remoteMsat,
      'total_msat': instance.totalMsat,
    };

ChannelPoint _$ChannelPointFromJson(Map<String, dynamic> json) => ChannelPoint(
  fundingTxid: json['funding_txid'] as String,
  outputIndex: (json['output_index'] as num).toInt(),
);

Map<String, dynamic> _$ChannelPointToJson(ChannelPoint instance) =>
    <String, dynamic>{
      'funding_txid': instance.fundingTxid,
      'output_index': instance.outputIndex,
    };

ChannelStats _$ChannelStatsFromJson(Map<String, dynamic> json) => ChannelStats(
  counts: json['counts'] as Map<String, dynamic>,
  avgSize: (json['avg_size'] as num).toInt(),
  biggestSize: (json['biggest_size'] as num?)?.toInt(),
  smallestSize: (json['smallest_size'] as num?)?.toInt(),
  totalCapacity: (json['total_capacity'] as num).toInt(),
);

Map<String, dynamic> _$ChannelStatsToJson(ChannelStats instance) =>
    <String, dynamic>{
      'counts': instance.counts,
      'avg_size': instance.avgSize,
      'biggest_size': ?instance.biggestSize,
      'smallest_size': ?instance.smallestSize,
      'total_capacity': instance.totalCapacity,
    };

ClientDataFields _$ClientDataFieldsFromJson(Map<String, dynamic> json) =>
    ClientDataFields(
      publicInputs:
          (json['public_inputs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ClientDataFieldsToJson(ClientDataFields instance) =>
    <String, dynamic>{'public_inputs': ?instance.publicInputs};

ConversionData _$ConversionDataFromJson(Map<String, dynamic> json) =>
    ConversionData(
      from: json['from_'] as String?,
      amount: (json['amount'] as num).toDouble(),
      to: json['to'] as String?,
    );

Map<String, dynamic> _$ConversionDataToJson(ConversionData instance) =>
    <String, dynamic>{
      'from_': ?instance.from,
      'amount': instance.amount,
      'to': ?instance.to,
    };

CreateExtension _$CreateExtensionFromJson(Map<String, dynamic> json) =>
    CreateExtension(
      extId: json['ext_id'] as String,
      archive: json['archive'] as String,
      sourceRepo: json['source_repo'] as String,
      version: json['version'] as String,
      costSats: (json['cost_sats'] as num?)?.toInt(),
      paymentHash: json['payment_hash'] as String?,
    );

Map<String, dynamic> _$CreateExtensionToJson(CreateExtension instance) =>
    <String, dynamic>{
      'ext_id': instance.extId,
      'archive': instance.archive,
      'source_repo': instance.sourceRepo,
      'version': instance.version,
      'cost_sats': ?instance.costSats,
      'payment_hash': ?instance.paymentHash,
    };

CreateExtensionReview _$CreateExtensionReviewFromJson(
  Map<String, dynamic> json,
) => CreateExtensionReview(
  tag: json['tag'] as String,
  name: json['name'] as String?,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$CreateExtensionReviewToJson(
  CreateExtensionReview instance,
) => <String, dynamic>{
  'tag': instance.tag,
  'name': ?instance.name,
  'rating': instance.rating,
  'comment': ?instance.comment,
};

CreateFiatSubscription _$CreateFiatSubscriptionFromJson(
  Map<String, dynamic> json,
) => CreateFiatSubscription(
  subscriptionId: json['subscription_id'] as String,
  quantity: (json['quantity'] as num).toInt(),
  paymentOptions: FiatSubscriptionPaymentOptions.fromJson(
    json['payment_options'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CreateFiatSubscriptionToJson(
  CreateFiatSubscription instance,
) => <String, dynamic>{
  'subscription_id': instance.subscriptionId,
  'quantity': instance.quantity,
  'payment_options': instance.paymentOptions.toJson(),
};

CreateInvoice _$CreateInvoiceFromJson(Map<String, dynamic> json) =>
    CreateInvoice(
      unit: json['unit'] as String?,
      internal: json['internal'] as bool? ?? false,
      out: json['out'] as bool? ?? true,
      amount: (json['amount'] as num?)?.toDouble(),
      memo: json['memo'] as String?,
      descriptionHash: json['description_hash'] as String?,
      unhashedDescription: json['unhashed_description'] as String?,
      paymentHash: json['payment_hash'] as String?,
      expiry: (json['expiry'] as num?)?.toInt(),
      extra: json['extra'],
      webhook: json['webhook'] as String?,
      bolt11: json['bolt11'] as String?,
      lnurlWithdraw: json['lnurl_withdraw'] == null
          ? null
          : LnurlWithdrawResponse.fromJson(
              json['lnurl_withdraw'] as Map<String, dynamic>,
            ),
      fiatProvider: json['fiat_provider'] as String?,
      labels:
          (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$CreateInvoiceToJson(CreateInvoice instance) =>
    <String, dynamic>{
      'unit': ?instance.unit,
      'internal': ?instance.internal,
      'out': ?instance.out,
      'amount': ?instance.amount,
      'memo': ?instance.memo,
      'description_hash': ?instance.descriptionHash,
      'unhashed_description': ?instance.unhashedDescription,
      'payment_hash': ?instance.paymentHash,
      'expiry': ?instance.expiry,
      'extra': ?instance.extra,
      'webhook': ?instance.webhook,
      'bolt11': ?instance.bolt11,
      'lnurl_withdraw': ?instance.lnurlWithdraw?.toJson(),
      'fiat_provider': ?instance.fiatProvider,
      'labels': ?instance.labels,
    };

CreateLnurlPayment _$CreateLnurlPaymentFromJson(Map<String, dynamic> json) =>
    CreateLnurlPayment(
      res: json['res'] == null
          ? null
          : LnurlPayResponse.fromJson(json['res'] as Map<String, dynamic>),
      lnurl: json['lnurl'],
      amount: (json['amount'] as num).toInt(),
      comment: json['comment'] as String?,
      unit: json['unit'] as String?,
      internalMemo: json['internal_memo'] as String?,
    );

Map<String, dynamic> _$CreateLnurlPaymentToJson(CreateLnurlPayment instance) =>
    <String, dynamic>{
      'res': ?instance.res?.toJson(),
      'lnurl': ?instance.lnurl,
      'amount': instance.amount,
      'comment': ?instance.comment,
      'unit': ?instance.unit,
      'internal_memo': ?instance.internalMemo,
    };

CreateLnurlWithdraw _$CreateLnurlWithdrawFromJson(Map<String, dynamic> json) =>
    CreateLnurlWithdraw(lnurlW: json['lnurl_w'] as String);

Map<String, dynamic> _$CreateLnurlWithdrawToJson(
  CreateLnurlWithdraw instance,
) => <String, dynamic>{'lnurl_w': instance.lnurlW};

CreateUser _$CreateUserFromJson(Map<String, dynamic> json) => CreateUser(
  id: json['id'] as String?,
  email: json['email'] as String?,
  username: json['username'] as String?,
  password: json['password'] as String?,
  passwordRepeat: json['password_repeat'] as String?,
  pubkey: json['pubkey'] as String?,
  externalId: json['external_id'] as String?,
  extensions:
      (json['extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  extra: json['extra'] == null
      ? null
      : UserExtra.fromJson(json['extra'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateUserToJson(CreateUser instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'email': ?instance.email,
      'username': ?instance.username,
      'password': ?instance.password,
      'password_repeat': ?instance.passwordRepeat,
      'pubkey': ?instance.pubkey,
      'external_id': ?instance.externalId,
      'extensions': ?instance.extensions,
      'extra': ?instance.extra?.toJson(),
    };

CreateWallet _$CreateWalletFromJson(Map<String, dynamic> json) => CreateWallet(
  name: json['name'] as String?,
  walletType: CreateWallet.walletTypeWalletTypeNullableFromJson(
    json['wallet_type'],
  ),
  sharedWalletId: json['shared_wallet_id'] as String?,
);

Map<String, dynamic> _$CreateWalletToJson(CreateWallet instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'wallet_type': ?walletTypeNullableToJson(instance.walletType),
      'shared_wallet_id': ?instance.sharedWalletId,
    };

CreateWebPushSubscription _$CreateWebPushSubscriptionFromJson(
  Map<String, dynamic> json,
) => CreateWebPushSubscription(subscription: json['subscription'] as String);

Map<String, dynamic> _$CreateWebPushSubscriptionToJson(
  CreateWebPushSubscription instance,
) => <String, dynamic>{'subscription': instance.subscription};

DataField _$DataFieldFromJson(Map<String, dynamic> json) => DataField(
  name: json['name'] as String,
  type: json['type'] as String,
  label: json['label'] as String?,
  hint: json['hint'] as String?,
  optional: json['optional'] as bool? ?? false,
  editable: json['editable'] as bool? ?? false,
  searchable: json['searchable'] as bool? ?? false,
  sortable: json['sortable'] as bool? ?? false,
  fields:
      (json['fields'] as List<dynamic>?)
          ?.map((e) => DataField.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$DataFieldToJson(DataField instance) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'label': ?instance.label,
  'hint': ?instance.hint,
  'optional': ?instance.optional,
  'editable': ?instance.editable,
  'searchable': ?instance.searchable,
  'sortable': ?instance.sortable,
  'fields': ?instance.fields?.map((e) => e.toJson()).toList(),
};

DataFields _$DataFieldsFromJson(Map<String, dynamic> json) => DataFields(
  name: json['name'] as String,
  editable: json['editable'] as bool? ?? true,
  fields:
      (json['fields'] as List<dynamic>?)
          ?.map((e) => DataField.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$DataFieldsToJson(DataFields instance) =>
    <String, dynamic>{
      'name': instance.name,
      'editable': ?instance.editable,
      'fields': ?instance.fields?.map((e) => e.toJson()).toList(),
    };

DecodePayment _$DecodePaymentFromJson(Map<String, dynamic> json) =>
    DecodePayment(
      data: json['data'] as String,
      filterFields:
          (json['filter_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$DecodePaymentToJson(DecodePayment instance) =>
    <String, dynamic>{
      'data': instance.data,
      'filter_fields': ?instance.filterFields,
    };

DeleteAccessControlList _$DeleteAccessControlListFromJson(
  Map<String, dynamic> json,
) => DeleteAccessControlList(
  id: json['id'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$DeleteAccessControlListToJson(
  DeleteAccessControlList instance,
) => <String, dynamic>{'id': instance.id, 'password': instance.password};

DeleteTokenRequest _$DeleteTokenRequestFromJson(Map<String, dynamic> json) =>
    DeleteTokenRequest(
      id: json['id'] as String,
      aclId: json['acl_id'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$DeleteTokenRequestToJson(DeleteTokenRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'acl_id': instance.aclId,
      'password': instance.password,
    };

EndpointAccess _$EndpointAccessFromJson(Map<String, dynamic> json) =>
    EndpointAccess(
      path: json['path'] as String,
      name: json['name'] as String,
      read: json['read'] as bool? ?? false,
      write: json['write'] as bool? ?? false,
    );

Map<String, dynamic> _$EndpointAccessToJson(EndpointAccess instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'read': ?instance.read,
      'write': ?instance.write,
    };

ExchangeRateProvider _$ExchangeRateProviderFromJson(
  Map<String, dynamic> json,
) => ExchangeRateProvider(
  name: json['name'] as String,
  apiUrl: json['api_url'] as String,
  path: json['path'] as String,
  excludeTo:
      (json['exclude_to'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  tickerConversion:
      (json['ticker_conversion'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$ExchangeRateProviderToJson(
  ExchangeRateProvider instance,
) => <String, dynamic>{
  'name': instance.name,
  'api_url': instance.apiUrl,
  'path': instance.path,
  'exclude_to': ?instance.excludeTo,
  'ticker_conversion': ?instance.tickerConversion,
};

Extension _$ExtensionFromJson(Map<String, dynamic> json) => Extension(
  code: json['code'] as String,
  isValid: json['is_valid'] as bool,
  name: json['name'] as String?,
  shortDescription: json['short_description'] as String?,
  tile: json['tile'] as String?,
  upgradeHash: json['upgrade_hash'] as String?,
);

Map<String, dynamic> _$ExtensionToJson(Extension instance) => <String, dynamic>{
  'code': instance.code,
  'is_valid': instance.isValid,
  'name': ?instance.name,
  'short_description': ?instance.shortDescription,
  'tile': ?instance.tile,
  'upgrade_hash': ?instance.upgradeHash,
};

ExtensionData _$ExtensionDataFromJson(
  Map<String, dynamic> json,
) => ExtensionData(
  id: json['id'] as String,
  name: json['name'] as String,
  stubVersion: json['stub_version'] as String?,
  shortDescription: json['short_description'] as String?,
  description: json['description'] as String?,
  ownerData: DataFields.fromJson(json['owner_data'] as Map<String, dynamic>),
  clientData: DataFields.fromJson(json['client_data'] as Map<String, dynamic>),
  settingsData: SettingsFields.fromJson(
    json['settings_data'] as Map<String, dynamic>,
  ),
  publicPage: PublicPageFields.fromJson(
    json['public_page'] as Map<String, dynamic>,
  ),
  previewAction: json['preview_action'] == null
      ? null
      : PreviewAction.fromJson(json['preview_action'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ExtensionDataToJson(ExtensionData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'stub_version': ?instance.stubVersion,
      'short_description': ?instance.shortDescription,
      'description': ?instance.description,
      'owner_data': instance.ownerData.toJson(),
      'client_data': instance.clientData.toJson(),
      'settings_data': instance.settingsData.toJson(),
      'public_page': instance.publicPage.toJson(),
      'preview_action': ?instance.previewAction?.toJson(),
    };

ExtensionRelease _$ExtensionReleaseFromJson(Map<String, dynamic> json) =>
    ExtensionRelease(
      name: json['name'] as String,
      version: json['version'] as String,
      archive: json['archive'] as String,
      sourceRepo: json['source_repo'] as String,
      isGithubRelease: json['is_github_release'] as bool? ?? false,
      hash: json['hash'] as String?,
      minLnbitsVersion: json['min_lnbits_version'] as String?,
      maxLnbitsVersion: json['max_lnbits_version'] as String?,
      isVersionCompatible: json['is_version_compatible'] as bool? ?? true,
      htmlUrl: json['html_url'] as String?,
      description: json['description'] as String?,
      warning: json['warning'] as String?,
      repo: json['repo'] as String?,
      icon: json['icon'] as String?,
      detailsLink: json['details_link'] as String?,
      paidFeatures: json['paid_features'] as String?,
      payLink: json['pay_link'] as String?,
      costSats: (json['cost_sats'] as num?)?.toInt(),
      paidSats: (json['paid_sats'] as num?)?.toInt(),
      paymentHash: json['payment_hash'] as String?,
    );

Map<String, dynamic> _$ExtensionReleaseToJson(ExtensionRelease instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'archive': instance.archive,
      'source_repo': instance.sourceRepo,
      'is_github_release': ?instance.isGithubRelease,
      'hash': ?instance.hash,
      'min_lnbits_version': ?instance.minLnbitsVersion,
      'max_lnbits_version': ?instance.maxLnbitsVersion,
      'is_version_compatible': ?instance.isVersionCompatible,
      'html_url': ?instance.htmlUrl,
      'description': ?instance.description,
      'warning': ?instance.warning,
      'repo': ?instance.repo,
      'icon': ?instance.icon,
      'details_link': ?instance.detailsLink,
      'paid_features': ?instance.paidFeatures,
      'pay_link': ?instance.payLink,
      'cost_sats': ?instance.costSats,
      'paid_sats': ?instance.paidSats,
      'payment_hash': ?instance.paymentHash,
    };

ExtensionReviewPaymentRequest _$ExtensionReviewPaymentRequestFromJson(
  Map<String, dynamic> json,
) => ExtensionReviewPaymentRequest(
  paymentHash: json['payment_hash'] as String,
  paymentRequest: json['payment_request'] as String,
);

Map<String, dynamic> _$ExtensionReviewPaymentRequestToJson(
  ExtensionReviewPaymentRequest instance,
) => <String, dynamic>{
  'payment_hash': instance.paymentHash,
  'payment_request': instance.paymentRequest,
};

ExtensionReviewsStatus _$ExtensionReviewsStatusFromJson(
  Map<String, dynamic> json,
) => ExtensionReviewsStatus(
  tag: json['tag'] as String,
  avgRating: (json['avg_rating'] as num).toDouble(),
  reviewCount: (json['review_count'] as num).toInt(),
);

Map<String, dynamic> _$ExtensionReviewsStatusToJson(
  ExtensionReviewsStatus instance,
) => <String, dynamic>{
  'tag': instance.tag,
  'avg_rating': instance.avgRating,
  'review_count': instance.reviewCount,
};

FiatProviderLimits _$FiatProviderLimitsFromJson(Map<String, dynamic> json) =>
    FiatProviderLimits(
      allowedUsers:
          (json['allowed_users'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      serviceMaxFeeSats: (json['service_max_fee_sats'] as num?)?.toInt(),
      serviceFeePercent: (json['service_fee_percent'] as num?)?.toDouble(),
      serviceFeeWalletId: json['service_fee_wallet_id'] as String?,
      serviceMinAmountSats: (json['service_min_amount_sats'] as num?)?.toInt(),
      serviceMaxAmountSats: (json['service_max_amount_sats'] as num?)?.toInt(),
      serviceFaucetWalletId: json['service_faucet_wallet_id'] as String?,
    );

Map<String, dynamic> _$FiatProviderLimitsToJson(FiatProviderLimits instance) =>
    <String, dynamic>{
      'allowed_users': ?instance.allowedUsers,
      'service_max_fee_sats': ?instance.serviceMaxFeeSats,
      'service_fee_percent': ?instance.serviceFeePercent,
      'service_fee_wallet_id': ?instance.serviceFeeWalletId,
      'service_min_amount_sats': ?instance.serviceMinAmountSats,
      'service_max_amount_sats': ?instance.serviceMaxAmountSats,
      'service_faucet_wallet_id': ?instance.serviceFaucetWalletId,
    };

FiatSubscriptionPaymentOptions _$FiatSubscriptionPaymentOptionsFromJson(
  Map<String, dynamic> json,
) => FiatSubscriptionPaymentOptions(
  memo: json['memo'] as String?,
  walletId: json['wallet_id'] as String?,
  subscriptionRequestId: json['subscription_request_id'] as String?,
  tag: json['tag'] as String?,
  extra: json['extra'],
  successUrl: json['success_url'] as String?,
);

Map<String, dynamic> _$FiatSubscriptionPaymentOptionsToJson(
  FiatSubscriptionPaymentOptions instance,
) => <String, dynamic>{
  'memo': ?instance.memo,
  'wallet_id': ?instance.walletId,
  'subscription_request_id': ?instance.subscriptionRequestId,
  'tag': ?instance.tag,
  'extra': ?instance.extra,
  'success_url': ?instance.successUrl,
};

FiatSubscriptionResponse _$FiatSubscriptionResponseFromJson(
  Map<String, dynamic> json,
) => FiatSubscriptionResponse(
  ok: json['ok'] as bool? ?? true,
  subscriptionRequestId: json['subscription_request_id'] as String?,
  checkoutSessionUrl: json['checkout_session_url'] as String?,
  errorMessage: json['error_message'] as String?,
);

Map<String, dynamic> _$FiatSubscriptionResponseToJson(
  FiatSubscriptionResponse instance,
) => <String, dynamic>{
  'ok': ?instance.ok,
  'subscription_request_id': ?instance.subscriptionRequestId,
  'checkout_session_url': ?instance.checkoutSessionUrl,
  'error_message': ?instance.errorMessage,
};

HTTPValidationError _$HTTPValidationErrorFromJson(Map<String, dynamic> json) =>
    HTTPValidationError(
      detail:
          (json['detail'] as List<dynamic>?)
              ?.map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$HTTPValidationErrorToJson(
  HTTPValidationError instance,
) => <String, dynamic>{
  'detail': ?instance.detail?.map((e) => e.toJson()).toList(),
};

InvoiceResponse _$InvoiceResponseFromJson(Map<String, dynamic> json) =>
    InvoiceResponse(
      ok: json['ok'] as bool,
      checkingId: json['checking_id'] as String,
      paymentRequest: json['payment_request'] as String,
      errorMessage: json['error_message'] as String,
      preimage: json['preimage'] as String,
      feeMsat: (json['fee_msat'] as num).toInt(),
    );

Map<String, dynamic> _$InvoiceResponseToJson(InvoiceResponse instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'checking_id': instance.checkingId,
      'payment_request': instance.paymentRequest,
      'error_message': instance.errorMessage,
      'preimage': instance.preimage,
      'fee_msat': instance.feeMsat,
    };

LnurlAuthResponse _$LnurlAuthResponseFromJson(Map<String, dynamic> json) =>
    LnurlAuthResponse(
      tag: LnurlAuthResponse.lnurlResponseTagTagNullableFromJson(json['tag']),
      callback: json['callback'] as String,
      k1: json['k1'] as String,
    );

Map<String, dynamic> _$LnurlAuthResponseToJson(LnurlAuthResponse instance) =>
    <String, dynamic>{
      'tag': ?lnurlResponseTagNullableToJson(instance.tag),
      'callback': instance.callback,
      'k1': instance.k1,
    };

LnurlErrorResponse _$LnurlErrorResponseFromJson(Map<String, dynamic> json) =>
    LnurlErrorResponse(
      status: LnurlErrorResponse.lnurlStatusStatusNullableFromJson(
        json['status'],
      ),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$LnurlErrorResponseToJson(LnurlErrorResponse instance) =>
    <String, dynamic>{
      'status': ?lnurlStatusNullableToJson(instance.status),
      'reason': instance.reason,
    };

LnurlPayResponse _$LnurlPayResponseFromJson(Map<String, dynamic> json) =>
    LnurlPayResponse(
      tag: LnurlPayResponse.lnurlResponseTagTagNullableFromJson(json['tag']),
      callback: json['callback'] as String,
      minSendable: (json['minSendable'] as num).toInt(),
      maxSendable: (json['maxSendable'] as num).toInt(),
      metadata: json['metadata'] as String,
      payerData: json['payerData'] == null
          ? null
          : LnurlPayResponsePayerData.fromJson(
              json['payerData'] as Map<String, dynamic>,
            ),
      commentAllowed: (json['commentAllowed'] as num?)?.toInt(),
      allowsNostr: json['allowsNostr'] as bool?,
      nostrPubkey: json['nostrPubkey'] as String?,
    );

Map<String, dynamic> _$LnurlPayResponseToJson(LnurlPayResponse instance) =>
    <String, dynamic>{
      'tag': ?lnurlResponseTagNullableToJson(instance.tag),
      'callback': instance.callback,
      'minSendable': instance.minSendable,
      'maxSendable': instance.maxSendable,
      'metadata': instance.metadata,
      'payerData': ?instance.payerData?.toJson(),
      'commentAllowed': ?instance.commentAllowed,
      'allowsNostr': ?instance.allowsNostr,
      'nostrPubkey': ?instance.nostrPubkey,
    };

LnurlPayResponsePayerData _$LnurlPayResponsePayerDataFromJson(
  Map<String, dynamic> json,
) => LnurlPayResponsePayerData(
  name: json['name'] == null
      ? null
      : LnurlPayResponsePayerDataOption.fromJson(
          json['name'] as Map<String, dynamic>,
        ),
  pubkey: json['pubkey'] == null
      ? null
      : LnurlPayResponsePayerDataOption.fromJson(
          json['pubkey'] as Map<String, dynamic>,
        ),
  identifier: json['identifier'] == null
      ? null
      : LnurlPayResponsePayerDataOption.fromJson(
          json['identifier'] as Map<String, dynamic>,
        ),
  email: json['email'] == null
      ? null
      : LnurlPayResponsePayerDataOption.fromJson(
          json['email'] as Map<String, dynamic>,
        ),
  auth: json['auth'] == null
      ? null
      : LnurlPayResponsePayerDataOptionAuth.fromJson(
          json['auth'] as Map<String, dynamic>,
        ),
  extras:
      (json['extras'] as List<dynamic>?)
          ?.map(
            (e) => LnurlPayResponsePayerDataExtra.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$LnurlPayResponsePayerDataToJson(
  LnurlPayResponsePayerData instance,
) => <String, dynamic>{
  'name': ?instance.name?.toJson(),
  'pubkey': ?instance.pubkey?.toJson(),
  'identifier': ?instance.identifier?.toJson(),
  'email': ?instance.email?.toJson(),
  'auth': ?instance.auth?.toJson(),
  'extras': ?instance.extras?.map((e) => e.toJson()).toList(),
};

LnurlPayResponsePayerDataExtra _$LnurlPayResponsePayerDataExtraFromJson(
  Map<String, dynamic> json,
) => LnurlPayResponsePayerDataExtra(
  name: json['name'] as String,
  field: LnurlPayResponsePayerDataOption.fromJson(
    json['field'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$LnurlPayResponsePayerDataExtraToJson(
  LnurlPayResponsePayerDataExtra instance,
) => <String, dynamic>{'name': instance.name, 'field': instance.field.toJson()};

LnurlPayResponsePayerDataOption _$LnurlPayResponsePayerDataOptionFromJson(
  Map<String, dynamic> json,
) => LnurlPayResponsePayerDataOption(mandatory: json['mandatory'] as bool);

Map<String, dynamic> _$LnurlPayResponsePayerDataOptionToJson(
  LnurlPayResponsePayerDataOption instance,
) => <String, dynamic>{'mandatory': instance.mandatory};

LnurlPayResponsePayerDataOptionAuth
_$LnurlPayResponsePayerDataOptionAuthFromJson(Map<String, dynamic> json) =>
    LnurlPayResponsePayerDataOptionAuth(
      mandatory: json['mandatory'] as bool,
      k1: json['k1'] as String,
    );

Map<String, dynamic> _$LnurlPayResponsePayerDataOptionAuthToJson(
  LnurlPayResponsePayerDataOptionAuth instance,
) => <String, dynamic>{'mandatory': instance.mandatory, 'k1': instance.k1};

LnurlResponseModel _$LnurlResponseModelFromJson(Map<String, dynamic> json) =>
    LnurlResponseModel();

Map<String, dynamic> _$LnurlResponseModelToJson(LnurlResponseModel instance) =>
    <String, dynamic>{};

LnurlScan _$LnurlScanFromJson(Map<String, dynamic> json) =>
    LnurlScan(lnurl: json['lnurl']);

Map<String, dynamic> _$LnurlScanToJson(LnurlScan instance) => <String, dynamic>{
  'lnurl': ?instance.lnurl,
};

LnurlWithdrawResponse _$LnurlWithdrawResponseFromJson(
  Map<String, dynamic> json,
) => LnurlWithdrawResponse(
  tag: LnurlWithdrawResponse.lnurlResponseTagTagNullableFromJson(json['tag']),
  callback: json['callback'] as String,
  k1: json['k1'] as String,
  minWithdrawable: (json['minWithdrawable'] as num).toInt(),
  maxWithdrawable: (json['maxWithdrawable'] as num).toInt(),
  defaultDescription: json['defaultDescription'] as String?,
  balanceCheck: json['balanceCheck'] as String?,
  currentBalance: (json['currentBalance'] as num?)?.toInt(),
  payLink: json['payLink'] as String?,
);

Map<String, dynamic> _$LnurlWithdrawResponseToJson(
  LnurlWithdrawResponse instance,
) => <String, dynamic>{
  'tag': ?lnurlResponseTagNullableToJson(instance.tag),
  'callback': instance.callback,
  'k1': instance.k1,
  'minWithdrawable': instance.minWithdrawable,
  'maxWithdrawable': instance.maxWithdrawable,
  'defaultDescription': ?instance.defaultDescription,
  'balanceCheck': ?instance.balanceCheck,
  'currentBalance': ?instance.currentBalance,
  'payLink': ?instance.payLink,
};

LoginUsernamePassword _$LoginUsernamePasswordFromJson(
  Map<String, dynamic> json,
) => LoginUsernamePassword(
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginUsernamePasswordToJson(
  LoginUsernamePassword instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
};

LoginUsr _$LoginUsrFromJson(Map<String, dynamic> json) =>
    LoginUsr(usr: json['usr'] as String);

Map<String, dynamic> _$LoginUsrToJson(LoginUsr instance) => <String, dynamic>{
  'usr': instance.usr,
};

NodeChannel _$NodeChannelFromJson(Map<String, dynamic> json) => NodeChannel(
  peerId: json['peer_id'] as String,
  balance: ChannelBalance.fromJson(json['balance'] as Map<String, dynamic>),
  state: channelStateFromJson(json['state']),
  id: json['id'] as String?,
  shortId: json['short_id'] as String?,
  point: json['point'] == null
      ? null
      : ChannelPoint.fromJson(json['point'] as Map<String, dynamic>),
  name: json['name'] as String?,
  color: json['color'] as String?,
  feePpm: (json['fee_ppm'] as num?)?.toInt(),
  feeBaseMsat: (json['fee_base_msat'] as num?)?.toInt(),
);

Map<String, dynamic> _$NodeChannelToJson(NodeChannel instance) =>
    <String, dynamic>{
      'peer_id': instance.peerId,
      'balance': instance.balance.toJson(),
      'state': ?channelStateToJson(instance.state),
      'id': ?instance.id,
      'short_id': ?instance.shortId,
      'point': ?instance.point?.toJson(),
      'name': ?instance.name,
      'color': ?instance.color,
      'fee_ppm': ?instance.feePpm,
      'fee_base_msat': ?instance.feeBaseMsat,
    };

NodeFees _$NodeFeesFromJson(Map<String, dynamic> json) => NodeFees(
  totalMsat: (json['total_msat'] as num).toInt(),
  dailyMsat: (json['daily_msat'] as num?)?.toInt(),
  weeklyMsat: (json['weekly_msat'] as num?)?.toInt(),
  monthlyMsat: (json['monthly_msat'] as num?)?.toInt(),
);

Map<String, dynamic> _$NodeFeesToJson(NodeFees instance) => <String, dynamic>{
  'total_msat': instance.totalMsat,
  'daily_msat': ?instance.dailyMsat,
  'weekly_msat': ?instance.weeklyMsat,
  'monthly_msat': ?instance.monthlyMsat,
};

NodeInfoResponse _$NodeInfoResponseFromJson(Map<String, dynamic> json) =>
    NodeInfoResponse(
      id: json['id'] as String,
      backendName: json['backend_name'] as String,
      alias: json['alias'] as String,
      color: json['color'] as String,
      numPeers: (json['num_peers'] as num).toInt(),
      blockheight: (json['blockheight'] as num).toInt(),
      channelStats: ChannelStats.fromJson(
        json['channel_stats'] as Map<String, dynamic>,
      ),
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      onchainBalanceSat: (json['onchain_balance_sat'] as num).toInt(),
      onchainConfirmedSat: (json['onchain_confirmed_sat'] as num).toInt(),
      fees: NodeFees.fromJson(json['fees'] as Map<String, dynamic>),
      balanceMsat: (json['balance_msat'] as num).toInt(),
    );

Map<String, dynamic> _$NodeInfoResponseToJson(NodeInfoResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'backend_name': instance.backendName,
      'alias': instance.alias,
      'color': instance.color,
      'num_peers': instance.numPeers,
      'blockheight': instance.blockheight,
      'channel_stats': instance.channelStats.toJson(),
      'addresses': instance.addresses,
      'onchain_balance_sat': instance.onchainBalanceSat,
      'onchain_confirmed_sat': instance.onchainConfirmedSat,
      'fees': instance.fees.toJson(),
      'balance_msat': instance.balanceMsat,
    };

NodePeerInfo _$NodePeerInfoFromJson(Map<String, dynamic> json) => NodePeerInfo(
  id: json['id'] as String,
  alias: json['alias'] as String?,
  color: json['color'] as String?,
  lastTimestamp: (json['last_timestamp'] as num?)?.toInt(),
  addresses:
      (json['addresses'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$NodePeerInfoToJson(NodePeerInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'alias': ?instance.alias,
      'color': ?instance.color,
      'last_timestamp': ?instance.lastTimestamp,
      'addresses': ?instance.addresses,
    };

NodeRank _$NodeRankFromJson(Map<String, dynamic> json) => NodeRank(
  capacity: (json['capacity'] as num?)?.toInt(),
  channelcount: (json['channelcount'] as num?)?.toInt(),
  age: (json['age'] as num?)?.toInt(),
  growth: (json['growth'] as num?)?.toInt(),
  availability: (json['availability'] as num?)?.toInt(),
);

Map<String, dynamic> _$NodeRankToJson(NodeRank instance) => <String, dynamic>{
  'capacity': ?instance.capacity,
  'channelcount': ?instance.channelcount,
  'age': ?instance.age,
  'growth': ?instance.growth,
  'availability': ?instance.availability,
};

OwnerDataFields _$OwnerDataFieldsFromJson(Map<String, dynamic> json) =>
    OwnerDataFields(
      name: json['name'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$OwnerDataFieldsToJson(OwnerDataFields instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'description': ?instance.description,
    };

Page _$PageFromJson(Map<String, dynamic> json) => Page(
  data:
      (json['data'] as List<dynamic>?)?.map((e) => e as Object).toList() ?? [],
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$PageToJson(Page instance) => <String, dynamic>{
  'data': instance.data,
  'total': instance.total,
};

PayToEnableInfo _$PayToEnableInfoFromJson(Map<String, dynamic> json) =>
    PayToEnableInfo(
      amount: (json['amount'] as num?)?.toInt(),
      required: json['required'] as bool? ?? false,
      wallet: json['wallet'] as String?,
    );

Map<String, dynamic> _$PayToEnableInfoToJson(PayToEnableInfo instance) =>
    <String, dynamic>{
      'amount': ?instance.amount,
      'required': ?instance.required,
      'wallet': ?instance.wallet,
    };

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  checkingId: json['checking_id'] as String,
  paymentHash: json['payment_hash'] as String,
  walletId: json['wallet_id'] as String,
  amount: (json['amount'] as num).toInt(),
  fee: (json['fee'] as num).toInt(),
  bolt11: json['bolt11'] as String,
  paymentRequest: json['payment_request'] as String?,
  fiatProvider: json['fiat_provider'] as String?,
  status: json['status'] as String?,
  memo: json['memo'] as String?,
  expiry: json['expiry'] == null
      ? null
      : DateTime.parse(json['expiry'] as String),
  webhook: json['webhook'] as String?,
  webhookStatus: json['webhook_status'] as String?,
  preimage: json['preimage'] as String?,
  tag: json['tag'] as String?,
  extension: json['extension'] as String?,
  time: json['time'] == null ? null : DateTime.parse(json['time'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  labels:
      (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  extra: json['extra'],
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'checking_id': instance.checkingId,
  'payment_hash': instance.paymentHash,
  'wallet_id': instance.walletId,
  'amount': instance.amount,
  'fee': instance.fee,
  'bolt11': instance.bolt11,
  'payment_request': ?instance.paymentRequest,
  'fiat_provider': ?instance.fiatProvider,
  'status': ?instance.status,
  'memo': ?instance.memo,
  'expiry': ?instance.expiry?.toIso8601String(),
  'webhook': ?instance.webhook,
  'webhook_status': ?instance.webhookStatus,
  'preimage': ?instance.preimage,
  'tag': ?instance.tag,
  'extension': ?instance.extension,
  'time': ?instance.time?.toIso8601String(),
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
  'labels': ?instance.labels,
  'extra': ?instance.extra,
};

PaymentCountStat _$PaymentCountStatFromJson(Map<String, dynamic> json) =>
    PaymentCountStat(
      field: json['field'] as String?,
      total: (json['total'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PaymentCountStatToJson(PaymentCountStat instance) =>
    <String, dynamic>{'field': ?instance.field, 'total': ?instance.total};

PaymentDailyStats _$PaymentDailyStatsFromJson(Map<String, dynamic> json) =>
    PaymentDailyStats(
      date: DateTime.parse(json['date'] as String),
      balance: (json['balance'] as num?)?.toDouble(),
      balanceIn: (json['balance_in'] as num?)?.toDouble(),
      balanceOut: (json['balance_out'] as num?)?.toDouble(),
      paymentsCount: (json['payments_count'] as num?)?.toInt(),
      countIn: (json['count_in'] as num?)?.toInt(),
      countOut: (json['count_out'] as num?)?.toInt(),
      fee: (json['fee'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PaymentDailyStatsToJson(PaymentDailyStats instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'balance': ?instance.balance,
      'balance_in': ?instance.balanceIn,
      'balance_out': ?instance.balanceOut,
      'payments_count': ?instance.paymentsCount,
      'count_in': ?instance.countIn,
      'count_out': ?instance.countOut,
      'fee': ?instance.fee,
    };

PaymentHistoryPoint _$PaymentHistoryPointFromJson(Map<String, dynamic> json) =>
    PaymentHistoryPoint(
      date: DateTime.parse(json['date'] as String),
      income: (json['income'] as num).toInt(),
      spending: (json['spending'] as num).toInt(),
      balance: (json['balance'] as num).toInt(),
    );

Map<String, dynamic> _$PaymentHistoryPointToJson(
  PaymentHistoryPoint instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'income': instance.income,
  'spending': instance.spending,
  'balance': instance.balance,
};

PaymentWalletStats _$PaymentWalletStatsFromJson(Map<String, dynamic> json) =>
    PaymentWalletStats(
      walletId: json['wallet_id'] as String?,
      walletName: json['wallet_name'] as String?,
      userId: json['user_id'] as String?,
      paymentsCount: (json['payments_count'] as num).toInt(),
      balance: (json['balance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PaymentWalletStatsToJson(PaymentWalletStats instance) =>
    <String, dynamic>{
      'wallet_id': ?instance.walletId,
      'wallet_name': ?instance.walletName,
      'user_id': ?instance.userId,
      'payments_count': instance.paymentsCount,
      'balance': ?instance.balance,
    };

PreviewAction _$PreviewActionFromJson(Map<String, dynamic> json) =>
    PreviewAction(
      isPreviewMode: json['is_preview_mode'] as bool? ?? false,
      isSettingsPreview: json['is_settings_preview'] as bool? ?? false,
      isOwnerDataPreview: json['is_owner_data_preview'] as bool? ?? false,
      isClientDataPreview: json['is_client_data_preview'] as bool? ?? false,
      isPublicPagePreview: json['is_public_page_preview'] as bool? ?? false,
    );

Map<String, dynamic> _$PreviewActionToJson(PreviewAction instance) =>
    <String, dynamic>{
      'is_preview_mode': ?instance.isPreviewMode,
      'is_settings_preview': ?instance.isSettingsPreview,
      'is_owner_data_preview': ?instance.isOwnerDataPreview,
      'is_client_data_preview': ?instance.isClientDataPreview,
      'is_public_page_preview': ?instance.isPublicPagePreview,
    };

PublicNodeInfo _$PublicNodeInfoFromJson(Map<String, dynamic> json) =>
    PublicNodeInfo(
      id: json['id'] as String,
      backendName: json['backend_name'] as String,
      alias: json['alias'] as String,
      color: json['color'] as String,
      numPeers: (json['num_peers'] as num).toInt(),
      blockheight: (json['blockheight'] as num).toInt(),
      channelStats: ChannelStats.fromJson(
        json['channel_stats'] as Map<String, dynamic>,
      ),
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$PublicNodeInfoToJson(PublicNodeInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'backend_name': instance.backendName,
      'alias': instance.alias,
      'color': instance.color,
      'num_peers': instance.numPeers,
      'blockheight': instance.blockheight,
      'channel_stats': instance.channelStats.toJson(),
      'addresses': instance.addresses,
    };

PublicPageFields _$PublicPageFieldsFromJson(Map<String, dynamic> json) =>
    PublicPageFields(
      hasPublicPage: json['has_public_page'] as bool? ?? false,
      ownerDataFields: OwnerDataFields.fromJson(
        json['owner_data_fields'] as Map<String, dynamic>,
      ),
      clientDataFields: ClientDataFields.fromJson(
        json['client_data_fields'] as Map<String, dynamic>,
      ),
      actionFields: ActionFields.fromJson(
        json['action_fields'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PublicPageFieldsToJson(PublicPageFields instance) =>
    <String, dynamic>{
      'has_public_page': ?instance.hasPublicPage,
      'owner_data_fields': instance.ownerDataFields.toJson(),
      'client_data_fields': instance.clientDataFields.toJson(),
      'action_fields': instance.actionFields.toJson(),
    };

RegisterUser _$RegisterUserFromJson(Map<String, dynamic> json) => RegisterUser(
  email: json['email'] as String?,
  username: json['username'] as String,
  password: json['password'] as String,
  passwordRepeat: json['password_repeat'] as String,
);

Map<String, dynamic> _$RegisterUserToJson(RegisterUser instance) =>
    <String, dynamic>{
      'email': ?instance.email,
      'username': instance.username,
      'password': instance.password,
      'password_repeat': instance.passwordRepeat,
    };

ReleasePaymentInfo _$ReleasePaymentInfoFromJson(Map<String, dynamic> json) =>
    ReleasePaymentInfo(
      amount: (json['amount'] as num?)?.toInt(),
      payLink: json['pay_link'] as String?,
      paymentHash: json['payment_hash'] as String?,
      paymentRequest: json['payment_request'] as String?,
    );

Map<String, dynamic> _$ReleasePaymentInfoToJson(ReleasePaymentInfo instance) =>
    <String, dynamic>{
      'amount': ?instance.amount,
      'pay_link': ?instance.payLink,
      'payment_hash': ?instance.paymentHash,
      'payment_request': ?instance.paymentRequest,
    };

ResetUserPassword _$ResetUserPasswordFromJson(Map<String, dynamic> json) =>
    ResetUserPassword(
      resetKey: json['reset_key'] as String,
      password: json['password'] as String,
      passwordRepeat: json['password_repeat'] as String,
    );

Map<String, dynamic> _$ResetUserPasswordToJson(ResetUserPassword instance) =>
    <String, dynamic>{
      'reset_key': instance.resetKey,
      'password': instance.password,
      'password_repeat': instance.passwordRepeat,
    };

SettingsFields _$SettingsFieldsFromJson(Map<String, dynamic> json) =>
    SettingsFields(
      name: json['name'] as String,
      editable: json['editable'] as bool? ?? true,
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => DataField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      enabled: json['enabled'] as bool? ?? false,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$SettingsFieldsToJson(SettingsFields instance) =>
    <String, dynamic>{
      'name': instance.name,
      'editable': ?instance.editable,
      'fields': ?instance.fields?.map((e) => e.toJson()).toList(),
      'enabled': ?instance.enabled,
      'type': ?instance.type,
    };

SettleInvoice _$SettleInvoiceFromJson(Map<String, dynamic> json) =>
    SettleInvoice(preimage: json['preimage'] as String);

Map<String, dynamic> _$SettleInvoiceToJson(SettleInvoice instance) =>
    <String, dynamic>{'preimage': instance.preimage};

SimpleItem _$SimpleItemFromJson(Map<String, dynamic> json) =>
    SimpleItem(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$SimpleItemToJson(SimpleItem instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

SimpleStatus _$SimpleStatusFromJson(Map<String, dynamic> json) => SimpleStatus(
  success: json['success'] as bool,
  message: json['message'] as String,
);

Map<String, dynamic> _$SimpleStatusToJson(SimpleStatus instance) =>
    <String, dynamic>{'success': instance.success, 'message': instance.message};

StoredPayLink _$StoredPayLinkFromJson(Map<String, dynamic> json) =>
    StoredPayLink(
      lnurl: json['lnurl'] as String,
      label: json['label'] as String,
      lastUsed: (json['last_used'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StoredPayLinkToJson(StoredPayLink instance) =>
    <String, dynamic>{
      'lnurl': instance.lnurl,
      'label': instance.label,
      'last_used': ?instance.lastUsed,
    };

StoredPayLinks _$StoredPayLinksFromJson(Map<String, dynamic> json) =>
    StoredPayLinks(
      links:
          (json['links'] as List<dynamic>?)
              ?.map((e) => StoredPayLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$StoredPayLinksToJson(StoredPayLinks instance) =>
    <String, dynamic>{
      'links': ?instance.links?.map((e) => e.toJson()).toList(),
    };

UpdateAccessControlList _$UpdateAccessControlListFromJson(
  Map<String, dynamic> json,
) => UpdateAccessControlList(
  id: json['id'] as String,
  name: json['name'] as String,
  endpoints:
      (json['endpoints'] as List<dynamic>?)
          ?.map((e) => EndpointAccess.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  tokenIdList:
      (json['token_id_list'] as List<dynamic>?)
          ?.map((e) => SimpleItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  password: json['password'] as String,
);

Map<String, dynamic> _$UpdateAccessControlListToJson(
  UpdateAccessControlList instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'endpoints': ?instance.endpoints?.map((e) => e.toJson()).toList(),
  'token_id_list': ?instance.tokenIdList?.map((e) => e.toJson()).toList(),
  'password': instance.password,
};

UpdateBalance _$UpdateBalanceFromJson(Map<String, dynamic> json) =>
    UpdateBalance(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$UpdateBalanceToJson(UpdateBalance instance) =>
    <String, dynamic>{'id': instance.id, 'amount': instance.amount};

UpdatePaymentLabels _$UpdatePaymentLabelsFromJson(Map<String, dynamic> json) =>
    UpdatePaymentLabels(
      labels:
          (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$UpdatePaymentLabelsToJson(
  UpdatePaymentLabels instance,
) => <String, dynamic>{'labels': ?instance.labels};

UpdateSettings _$UpdateSettingsFromJson(
  Map<String, dynamic> json,
) => UpdateSettings(
  keycloakDiscoveryUrl: json['keycloak_discovery_url'] as String?,
  keycloakClientId: json['keycloak_client_id'] as String?,
  keycloakClientSecret: json['keycloak_client_secret'] as String?,
  keycloakClientCustomOrg: json['keycloak_client_custom_org'] as String?,
  keycloakClientCustomIcon: json['keycloak_client_custom_icon'] as String?,
  githubClientId: json['github_client_id'] as String?,
  githubClientSecret: json['github_client_secret'] as String?,
  googleClientId: json['google_client_id'] as String?,
  googleClientSecret: json['google_client_secret'] as String?,
  nostrAbsoluteRequestUrls:
      (json['nostr_absolute_request_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  authTokenExpireMinutes: (json['auth_token_expire_minutes'] as num?)?.toInt(),
  authAllMethods:
      (json['auth_all_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  authAllowedMethods:
      (json['auth_allowed_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  authCredetialsUpdateThreshold:
      (json['auth_credetials_update_threshold'] as num?)?.toInt(),
  authAuthenticationCacheMinutes:
      (json['auth_authentication_cache_minutes'] as num?)?.toInt(),
  lnbitsAuditEnabled: json['lnbits_audit_enabled'] as bool? ?? true,
  lnbitsAuditRetentionDays: (json['lnbits_audit_retention_days'] as num?)
      ?.toInt(),
  lnbitsAuditLogIpAddress:
      json['lnbits_audit_log_ip_address'] as bool? ?? false,
  lnbitsAuditLogPathParams:
      json['lnbits_audit_log_path_params'] as bool? ?? true,
  lnbitsAuditLogQueryParams:
      json['lnbits_audit_log_query_params'] as bool? ?? true,
  lnbitsAuditLogRequestBody:
      json['lnbits_audit_log_request_body'] as bool? ?? false,
  lnbitsAuditIncludePaths:
      (json['lnbits_audit_include_paths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAuditExcludePaths:
      (json['lnbits_audit_exclude_paths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAuditHttpMethods:
      (json['lnbits_audit_http_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAuditHttpResponseCodes:
      (json['lnbits_audit_http_response_codes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsNodeUi: json['lnbits_node_ui'] as bool? ?? false,
  lnbitsPublicNodeUi: json['lnbits_public_node_ui'] as bool? ?? false,
  lnbitsNodeUiTransactions:
      json['lnbits_node_ui_transactions'] as bool? ?? false,
  lnbitsWebpushPubkey: json['lnbits_webpush_pubkey'] as String?,
  lnbitsWebpushPrivkey: json['lnbits_webpush_privkey'] as String?,
  lightningInvoiceExpiry: (json['lightning_invoice_expiry'] as num?)?.toInt(),
  paypalEnabled: json['paypal_enabled'] as bool? ?? false,
  paypalApiEndpoint: json['paypal_api_endpoint'] as String?,
  paypalClientId: json['paypal_client_id'] as String?,
  paypalClientSecret: json['paypal_client_secret'] as String?,
  paypalPaymentSuccessUrl: json['paypal_payment_success_url'] as String?,
  paypalPaymentWebhookUrl: json['paypal_payment_webhook_url'] as String?,
  paypalWebhookId: json['paypal_webhook_id'] as String?,
  paypalLimits: json['paypal_limits'] == null
      ? null
      : FiatProviderLimits.fromJson(
          json['paypal_limits'] as Map<String, dynamic>,
        ),
  stripeEnabled: json['stripe_enabled'] as bool? ?? false,
  stripeApiEndpoint: json['stripe_api_endpoint'] as String?,
  stripeApiSecretKey: json['stripe_api_secret_key'] as String?,
  stripePaymentSuccessUrl: json['stripe_payment_success_url'] as String?,
  stripePaymentWebhookUrl: json['stripe_payment_webhook_url'] as String?,
  stripeWebhookSigningSecret: json['stripe_webhook_signing_secret'] as String?,
  stripeLimits: json['stripe_limits'] == null
      ? null
      : FiatProviderLimits.fromJson(
          json['stripe_limits'] as Map<String, dynamic>,
        ),
  breezLiquidApiKey: json['breez_liquid_api_key'] as String?,
  breezLiquidSeed: json['breez_liquid_seed'] as String?,
  breezLiquidFeeOffsetSat: (json['breez_liquid_fee_offset_sat'] as num?)
      ?.toInt(),
  strikeApiEndpoint: json['strike_api_endpoint'] as String?,
  strikeApiKey: json['strike_api_key'] as String?,
  breezApiKey: json['breez_api_key'] as String?,
  breezGreenlightSeed: json['breez_greenlight_seed'] as String?,
  breezGreenlightInviteCode: json['breez_greenlight_invite_code'] as String?,
  breezGreenlightDeviceKey: json['breez_greenlight_device_key'] as String?,
  breezGreenlightDeviceCert: json['breez_greenlight_device_cert'] as String?,
  breezUseTrampoline: json['breez_use_trampoline'] as bool? ?? true,
  nwcPairingUrl: json['nwc_pairing_url'] as String?,
  lntipsApiEndpoint: json['lntips_api_endpoint'] as String?,
  lntipsApiKey: json['lntips_api_key'] as String?,
  lntipsAdminKey: json['lntips_admin_key'] as String?,
  lntipsInvoiceKey: json['lntips_invoice_key'] as String?,
  sparkUrl: json['spark_url'] as String?,
  sparkToken: json['spark_token'] as String?,
  opennodeApiEndpoint: json['opennode_api_endpoint'] as String?,
  opennodeKey: json['opennode_key'] as String?,
  opennodeAdminKey: json['opennode_admin_key'] as String?,
  opennodeInvoiceKey: json['opennode_invoice_key'] as String?,
  phoenixdApiEndpoint: json['phoenixd_api_endpoint'] as String?,
  phoenixdApiPassword: json['phoenixd_api_password'] as String?,
  zbdApiEndpoint: json['zbd_api_endpoint'] as String?,
  zbdApiKey: json['zbd_api_key'] as String?,
  boltzClientEndpoint: json['boltz_client_endpoint'] as String?,
  boltzClientMacaroon: json['boltz_client_macaroon'] as String?,
  boltzClientPassword: json['boltz_client_password'] as String?,
  boltzClientCert: json['boltz_client_cert'] as String?,
  boltzMnemonic: json['boltz_mnemonic'] as String?,
  albyApiEndpoint: json['alby_api_endpoint'] as String?,
  albyAccessToken: json['alby_access_token'] as String?,
  blinkApiEndpoint: json['blink_api_endpoint'] as String?,
  blinkWsEndpoint: json['blink_ws_endpoint'] as String?,
  blinkToken: json['blink_token'] as String?,
  lnpayApiEndpoint: json['lnpay_api_endpoint'] as String?,
  lnpayApiKey: json['lnpay_api_key'] as String?,
  lnpayWalletKey: json['lnpay_wallet_key'] as String?,
  lnpayAdminKey: json['lnpay_admin_key'] as String?,
  lndGrpcEndpoint: json['lnd_grpc_endpoint'] as String?,
  lndGrpcCert: json['lnd_grpc_cert'] as String?,
  lndGrpcPort: (json['lnd_grpc_port'] as num?)?.toInt(),
  lndGrpcAdminMacaroon: json['lnd_grpc_admin_macaroon'] as String?,
  lndGrpcInvoiceMacaroon: json['lnd_grpc_invoice_macaroon'] as String?,
  lndGrpcMacaroon: json['lnd_grpc_macaroon'] as String?,
  lndGrpcMacaroonEncrypted: json['lnd_grpc_macaroon_encrypted'] as String?,
  lndRestEndpoint: json['lnd_rest_endpoint'] as String?,
  lndRestCert: json['lnd_rest_cert'] as String?,
  lndRestMacaroon: json['lnd_rest_macaroon'] as String?,
  lndRestMacaroonEncrypted: json['lnd_rest_macaroon_encrypted'] as String?,
  lndRestRouteHints: json['lnd_rest_route_hints'] as bool? ?? true,
  lndRestAllowSelfPayment:
      json['lnd_rest_allow_self_payment'] as bool? ?? false,
  lndCert: json['lnd_cert'] as String?,
  lndAdminMacaroon: json['lnd_admin_macaroon'] as String?,
  lndInvoiceMacaroon: json['lnd_invoice_macaroon'] as String?,
  lndRestAdminMacaroon: json['lnd_rest_admin_macaroon'] as String?,
  lndRestInvoiceMacaroon: json['lnd_rest_invoice_macaroon'] as String?,
  eclairUrl: json['eclair_url'] as String?,
  eclairPass: json['eclair_pass'] as String?,
  corelightningRestUrl: json['corelightning_rest_url'] as String?,
  corelightningRestMacaroon: json['corelightning_rest_macaroon'] as String?,
  corelightningRestCert: json['corelightning_rest_cert'] as String?,
  corelightningRpc: json['corelightning_rpc'] as String?,
  corelightningPayCommand: json['corelightning_pay_command'] as String?,
  clightningRpc: json['clightning_rpc'] as String?,
  clnrestUrl: json['clnrest_url'] as String?,
  clnrestCa: json['clnrest_ca'] as String?,
  clnrestCert: json['clnrest_cert'] as String?,
  clnrestReadonlyRune: json['clnrest_readonly_rune'] as String?,
  clnrestInvoiceRune: json['clnrest_invoice_rune'] as String?,
  clnrestPayRune: json['clnrest_pay_rune'] as String?,
  clnrestRenepayRune: json['clnrest_renepay_rune'] as String?,
  clnrestLastPayIndex: json['clnrest_last_pay_index'] as String?,
  clnrestNodeid: json['clnrest_nodeid'] as String?,
  clicheEndpoint: json['cliche_endpoint'] as String?,
  lnbitsEndpoint: json['lnbits_endpoint'] as String?,
  lnbitsKey: json['lnbits_key'] as String?,
  lnbitsAdminKey: json['lnbits_admin_key'] as String?,
  lnbitsInvoiceKey: json['lnbits_invoice_key'] as String?,
  fakeWalletSecret: json['fake_wallet_secret'] as String?,
  lnbitsDenomination: json['lnbits_denomination'] as String?,
  lnbitsBackendWalletClass: json['lnbits_backend_wallet_class'] as String?,
  lnbitsFundingSourcePayInvoiceWaitSeconds:
      (json['lnbits_funding_source_pay_invoice_wait_seconds'] as num?)?.toInt(),
  fundingSourceMaxRetries: (json['funding_source_max_retries'] as num?)
      ?.toInt(),
  lnbitsNostrNotificationsEnabled:
      json['lnbits_nostr_notifications_enabled'] as bool? ?? false,
  lnbitsNostrNotificationsPrivateKey:
      json['lnbits_nostr_notifications_private_key'] as String?,
  lnbitsNostrNotificationsIdentifiers:
      (json['lnbits_nostr_notifications_identifiers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsTelegramNotificationsEnabled:
      json['lnbits_telegram_notifications_enabled'] as bool? ?? false,
  lnbitsTelegramNotificationsAccessToken:
      json['lnbits_telegram_notifications_access_token'] as String?,
  lnbitsTelegramNotificationsChatId:
      json['lnbits_telegram_notifications_chat_id'] as String?,
  lnbitsEmailNotificationsEnabled:
      json['lnbits_email_notifications_enabled'] as bool? ?? false,
  lnbitsEmailNotificationsEmail:
      json['lnbits_email_notifications_email'] as String?,
  lnbitsEmailNotificationsUsername:
      json['lnbits_email_notifications_username'] as String?,
  lnbitsEmailNotificationsPassword:
      json['lnbits_email_notifications_password'] as String?,
  lnbitsEmailNotificationsServer:
      json['lnbits_email_notifications_server'] as String?,
  lnbitsEmailNotificationsPort:
      (json['lnbits_email_notifications_port'] as num?)?.toInt(),
  lnbitsEmailNotificationsToEmails:
      (json['lnbits_email_notifications_to_emails'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsNotificationSettingsUpdate:
      json['lnbits_notification_settings_update'] as bool? ?? true,
  lnbitsNotificationCreditDebit:
      json['lnbits_notification_credit_debit'] as bool? ?? true,
  notificationBalanceDeltaThresholdSats:
      (json['notification_balance_delta_threshold_sats'] as num?)?.toInt(),
  lnbitsNotificationServerStartStop:
      json['lnbits_notification_server_start_stop'] as bool? ?? true,
  lnbitsNotificationWatchdog:
      json['lnbits_notification_watchdog'] as bool? ?? false,
  lnbitsNotificationServerStatusHours:
      (json['lnbits_notification_server_status_hours'] as num?)?.toInt(),
  lnbitsNotificationIncomingPaymentAmountSats:
      (json['lnbits_notification_incoming_payment_amount_sats'] as num?)
          ?.toInt(),
  lnbitsNotificationOutgoingPaymentAmountSats:
      (json['lnbits_notification_outgoing_payment_amount_sats'] as num?)
          ?.toInt(),
  lnbitsRateLimitNo: (json['lnbits_rate_limit_no'] as num?)?.toInt(),
  lnbitsRateLimitUnit: json['lnbits_rate_limit_unit'] as String?,
  lnbitsAllowedIps:
      (json['lnbits_allowed_ips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsBlockedIps:
      (json['lnbits_blocked_ips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsCallbackUrlRules:
      (json['lnbits_callback_url_rules'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsWalletLimitMaxBalance: (json['lnbits_wallet_limit_max_balance'] as num?)
      ?.toInt(),
  lnbitsWalletLimitDailyMaxWithdraw:
      (json['lnbits_wallet_limit_daily_max_withdraw'] as num?)?.toInt(),
  lnbitsWalletLimitSecsBetweenTrans:
      (json['lnbits_wallet_limit_secs_between_trans'] as num?)?.toInt(),
  lnbitsOnlyAllowIncomingPayments:
      json['lnbits_only_allow_incoming_payments'] as bool? ?? false,
  lnbitsWatchdogSwitchToVoidwallet:
      json['lnbits_watchdog_switch_to_voidwallet'] as bool? ?? false,
  lnbitsWatchdogIntervalMinutes:
      (json['lnbits_watchdog_interval_minutes'] as num?)?.toInt(),
  lnbitsWatchdogDelta: (json['lnbits_watchdog_delta'] as num?)?.toInt(),
  lnbitsMaxOutgoingPaymentAmountSats:
      (json['lnbits_max_outgoing_payment_amount_sats'] as num?)?.toInt(),
  lnbitsMaxIncomingPaymentAmountSats:
      (json['lnbits_max_incoming_payment_amount_sats'] as num?)?.toInt(),
  lnbitsExchangeRateCacheSeconds:
      (json['lnbits_exchange_rate_cache_seconds'] as num?)?.toInt(),
  lnbitsExchangeHistorySize: (json['lnbits_exchange_history_size'] as num?)
      ?.toInt(),
  lnbitsExchangeHistoryRefreshIntervalSeconds:
      (json['lnbits_exchange_history_refresh_interval_seconds'] as num?)
          ?.toInt(),
  lnbitsExchangeRateProviders:
      (json['lnbits_exchange_rate_providers'] as List<dynamic>?)
          ?.map((e) => ExchangeRateProvider.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  lnbitsReserveFeeMin: (json['lnbits_reserve_fee_min'] as num?)?.toInt(),
  lnbitsReserveFeePercent: (json['lnbits_reserve_fee_percent'] as num?)
      ?.toDouble(),
  lnbitsServiceFee: (json['lnbits_service_fee'] as num?)?.toDouble(),
  lnbitsServiceFeeIgnoreInternal:
      json['lnbits_service_fee_ignore_internal'] as bool? ?? true,
  lnbitsServiceFeeMax: (json['lnbits_service_fee_max'] as num?)?.toInt(),
  lnbitsServiceFeeWallet: json['lnbits_service_fee_wallet'] as String?,
  lnbitsMaxAssetSizeMb: (json['lnbits_max_asset_size_mb'] as num?)?.toDouble(),
  lnbitsAssetsAllowedMimeTypes:
      (json['lnbits_assets_allowed_mime_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAssetThumbnailWidth: (json['lnbits_asset_thumbnail_width'] as num?)
      ?.toInt(),
  lnbitsAssetThumbnailHeight: (json['lnbits_asset_thumbnail_height'] as num?)
      ?.toInt(),
  lnbitsAssetThumbnailFormat: json['lnbits_asset_thumbnail_format'] as String?,
  lnbitsMaxAssetsPerUser: (json['lnbits_max_assets_per_user'] as num?)?.toInt(),
  lnbitsAssetsNoLimitUsers:
      (json['lnbits_assets_no_limit_users'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsBaseurl: json['lnbits_baseurl'] as String?,
  lnbitsHideApi: json['lnbits_hide_api'] as bool? ?? false,
  lnbitsSiteTitle: json['lnbits_site_title'] as String?,
  lnbitsSiteTagline: json['lnbits_site_tagline'] as String?,
  lnbitsSiteDescription: json['lnbits_site_description'] as String?,
  lnbitsShowHomePageElements:
      json['lnbits_show_home_page_elements'] as bool? ?? true,
  lnbitsDefaultWalletName: json['lnbits_default_wallet_name'] as String?,
  lnbitsCustomBadge: json['lnbits_custom_badge'] as String?,
  lnbitsCustomBadgeColor: json['lnbits_custom_badge_color'] as String?,
  lnbitsThemeOptions:
      (json['lnbits_theme_options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsCustomLogo: json['lnbits_custom_logo'] as String?,
  lnbitsCustomImage: json['lnbits_custom_image'] as String?,
  lnbitsAdSpaceTitle: json['lnbits_ad_space_title'] as String?,
  lnbitsAdSpace: json['lnbits_ad_space'] as String?,
  lnbitsAdSpaceEnabled: json['lnbits_ad_space_enabled'] as bool? ?? false,
  lnbitsAllowedCurrencies:
      (json['lnbits_allowed_currencies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsDefaultAccountingCurrency:
      json['lnbits_default_accounting_currency'] as String?,
  lnbitsQrLogo: json['lnbits_qr_logo'] as String?,
  lnbitsAppleTouchIcon: json['lnbits_apple_touch_icon'] as String?,
  lnbitsDefaultReaction: json['lnbits_default_reaction'] as String?,
  lnbitsDefaultTheme: json['lnbits_default_theme'] as String?,
  lnbitsDefaultBorder: json['lnbits_default_border'] as String?,
  lnbitsDefaultGradient: json['lnbits_default_gradient'] as bool? ?? true,
  lnbitsDefaultBgimage: json['lnbits_default_bgimage'] as String?,
  lnbitsAdminExtensions:
      (json['lnbits_admin_extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsUserDefaultExtensions:
      (json['lnbits_user_default_extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsExtensionsDeactivateAll:
      json['lnbits_extensions_deactivate_all'] as bool? ?? false,
  lnbitsExtensionsBuilderActivateNonAdmins:
      json['lnbits_extensions_builder_activate_non_admins'] as bool? ?? false,
  lnbitsExtensionsReviewsUrl: json['lnbits_extensions_reviews_url'] as String?,
  lnbitsExtensionsManifests:
      (json['lnbits_extensions_manifests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsExtensionsBuilderManifestUrl:
      json['lnbits_extensions_builder_manifest_url'] as String?,
  lnbitsAdminUsers:
      (json['lnbits_admin_users'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAllowedUsers:
      (json['lnbits_allowed_users'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  lnbitsAllowNewAccounts: json['lnbits_allow_new_accounts'] as bool? ?? true,
);

Map<String, dynamic> _$UpdateSettingsToJson(
  UpdateSettings instance,
) => <String, dynamic>{
  'keycloak_discovery_url': ?instance.keycloakDiscoveryUrl,
  'keycloak_client_id': ?instance.keycloakClientId,
  'keycloak_client_secret': ?instance.keycloakClientSecret,
  'keycloak_client_custom_org': ?instance.keycloakClientCustomOrg,
  'keycloak_client_custom_icon': ?instance.keycloakClientCustomIcon,
  'github_client_id': ?instance.githubClientId,
  'github_client_secret': ?instance.githubClientSecret,
  'google_client_id': ?instance.googleClientId,
  'google_client_secret': ?instance.googleClientSecret,
  'nostr_absolute_request_urls': ?instance.nostrAbsoluteRequestUrls,
  'auth_token_expire_minutes': ?instance.authTokenExpireMinutes,
  'auth_all_methods': ?instance.authAllMethods,
  'auth_allowed_methods': ?instance.authAllowedMethods,
  'auth_credetials_update_threshold': ?instance.authCredetialsUpdateThreshold,
  'auth_authentication_cache_minutes': ?instance.authAuthenticationCacheMinutes,
  'lnbits_audit_enabled': ?instance.lnbitsAuditEnabled,
  'lnbits_audit_retention_days': ?instance.lnbitsAuditRetentionDays,
  'lnbits_audit_log_ip_address': ?instance.lnbitsAuditLogIpAddress,
  'lnbits_audit_log_path_params': ?instance.lnbitsAuditLogPathParams,
  'lnbits_audit_log_query_params': ?instance.lnbitsAuditLogQueryParams,
  'lnbits_audit_log_request_body': ?instance.lnbitsAuditLogRequestBody,
  'lnbits_audit_include_paths': ?instance.lnbitsAuditIncludePaths,
  'lnbits_audit_exclude_paths': ?instance.lnbitsAuditExcludePaths,
  'lnbits_audit_http_methods': ?instance.lnbitsAuditHttpMethods,
  'lnbits_audit_http_response_codes': ?instance.lnbitsAuditHttpResponseCodes,
  'lnbits_node_ui': ?instance.lnbitsNodeUi,
  'lnbits_public_node_ui': ?instance.lnbitsPublicNodeUi,
  'lnbits_node_ui_transactions': ?instance.lnbitsNodeUiTransactions,
  'lnbits_webpush_pubkey': ?instance.lnbitsWebpushPubkey,
  'lnbits_webpush_privkey': ?instance.lnbitsWebpushPrivkey,
  'lightning_invoice_expiry': ?instance.lightningInvoiceExpiry,
  'paypal_enabled': ?instance.paypalEnabled,
  'paypal_api_endpoint': ?instance.paypalApiEndpoint,
  'paypal_client_id': ?instance.paypalClientId,
  'paypal_client_secret': ?instance.paypalClientSecret,
  'paypal_payment_success_url': ?instance.paypalPaymentSuccessUrl,
  'paypal_payment_webhook_url': ?instance.paypalPaymentWebhookUrl,
  'paypal_webhook_id': ?instance.paypalWebhookId,
  'paypal_limits': ?instance.paypalLimits?.toJson(),
  'stripe_enabled': ?instance.stripeEnabled,
  'stripe_api_endpoint': ?instance.stripeApiEndpoint,
  'stripe_api_secret_key': ?instance.stripeApiSecretKey,
  'stripe_payment_success_url': ?instance.stripePaymentSuccessUrl,
  'stripe_payment_webhook_url': ?instance.stripePaymentWebhookUrl,
  'stripe_webhook_signing_secret': ?instance.stripeWebhookSigningSecret,
  'stripe_limits': ?instance.stripeLimits?.toJson(),
  'breez_liquid_api_key': ?instance.breezLiquidApiKey,
  'breez_liquid_seed': ?instance.breezLiquidSeed,
  'breez_liquid_fee_offset_sat': ?instance.breezLiquidFeeOffsetSat,
  'strike_api_endpoint': ?instance.strikeApiEndpoint,
  'strike_api_key': ?instance.strikeApiKey,
  'breez_api_key': ?instance.breezApiKey,
  'breez_greenlight_seed': ?instance.breezGreenlightSeed,
  'breez_greenlight_invite_code': ?instance.breezGreenlightInviteCode,
  'breez_greenlight_device_key': ?instance.breezGreenlightDeviceKey,
  'breez_greenlight_device_cert': ?instance.breezGreenlightDeviceCert,
  'breez_use_trampoline': ?instance.breezUseTrampoline,
  'nwc_pairing_url': ?instance.nwcPairingUrl,
  'lntips_api_endpoint': ?instance.lntipsApiEndpoint,
  'lntips_api_key': ?instance.lntipsApiKey,
  'lntips_admin_key': ?instance.lntipsAdminKey,
  'lntips_invoice_key': ?instance.lntipsInvoiceKey,
  'spark_url': ?instance.sparkUrl,
  'spark_token': ?instance.sparkToken,
  'opennode_api_endpoint': ?instance.opennodeApiEndpoint,
  'opennode_key': ?instance.opennodeKey,
  'opennode_admin_key': ?instance.opennodeAdminKey,
  'opennode_invoice_key': ?instance.opennodeInvoiceKey,
  'phoenixd_api_endpoint': ?instance.phoenixdApiEndpoint,
  'phoenixd_api_password': ?instance.phoenixdApiPassword,
  'zbd_api_endpoint': ?instance.zbdApiEndpoint,
  'zbd_api_key': ?instance.zbdApiKey,
  'boltz_client_endpoint': ?instance.boltzClientEndpoint,
  'boltz_client_macaroon': ?instance.boltzClientMacaroon,
  'boltz_client_password': ?instance.boltzClientPassword,
  'boltz_client_cert': ?instance.boltzClientCert,
  'boltz_mnemonic': ?instance.boltzMnemonic,
  'alby_api_endpoint': ?instance.albyApiEndpoint,
  'alby_access_token': ?instance.albyAccessToken,
  'blink_api_endpoint': ?instance.blinkApiEndpoint,
  'blink_ws_endpoint': ?instance.blinkWsEndpoint,
  'blink_token': ?instance.blinkToken,
  'lnpay_api_endpoint': ?instance.lnpayApiEndpoint,
  'lnpay_api_key': ?instance.lnpayApiKey,
  'lnpay_wallet_key': ?instance.lnpayWalletKey,
  'lnpay_admin_key': ?instance.lnpayAdminKey,
  'lnd_grpc_endpoint': ?instance.lndGrpcEndpoint,
  'lnd_grpc_cert': ?instance.lndGrpcCert,
  'lnd_grpc_port': ?instance.lndGrpcPort,
  'lnd_grpc_admin_macaroon': ?instance.lndGrpcAdminMacaroon,
  'lnd_grpc_invoice_macaroon': ?instance.lndGrpcInvoiceMacaroon,
  'lnd_grpc_macaroon': ?instance.lndGrpcMacaroon,
  'lnd_grpc_macaroon_encrypted': ?instance.lndGrpcMacaroonEncrypted,
  'lnd_rest_endpoint': ?instance.lndRestEndpoint,
  'lnd_rest_cert': ?instance.lndRestCert,
  'lnd_rest_macaroon': ?instance.lndRestMacaroon,
  'lnd_rest_macaroon_encrypted': ?instance.lndRestMacaroonEncrypted,
  'lnd_rest_route_hints': ?instance.lndRestRouteHints,
  'lnd_rest_allow_self_payment': ?instance.lndRestAllowSelfPayment,
  'lnd_cert': ?instance.lndCert,
  'lnd_admin_macaroon': ?instance.lndAdminMacaroon,
  'lnd_invoice_macaroon': ?instance.lndInvoiceMacaroon,
  'lnd_rest_admin_macaroon': ?instance.lndRestAdminMacaroon,
  'lnd_rest_invoice_macaroon': ?instance.lndRestInvoiceMacaroon,
  'eclair_url': ?instance.eclairUrl,
  'eclair_pass': ?instance.eclairPass,
  'corelightning_rest_url': ?instance.corelightningRestUrl,
  'corelightning_rest_macaroon': ?instance.corelightningRestMacaroon,
  'corelightning_rest_cert': ?instance.corelightningRestCert,
  'corelightning_rpc': ?instance.corelightningRpc,
  'corelightning_pay_command': ?instance.corelightningPayCommand,
  'clightning_rpc': ?instance.clightningRpc,
  'clnrest_url': ?instance.clnrestUrl,
  'clnrest_ca': ?instance.clnrestCa,
  'clnrest_cert': ?instance.clnrestCert,
  'clnrest_readonly_rune': ?instance.clnrestReadonlyRune,
  'clnrest_invoice_rune': ?instance.clnrestInvoiceRune,
  'clnrest_pay_rune': ?instance.clnrestPayRune,
  'clnrest_renepay_rune': ?instance.clnrestRenepayRune,
  'clnrest_last_pay_index': ?instance.clnrestLastPayIndex,
  'clnrest_nodeid': ?instance.clnrestNodeid,
  'cliche_endpoint': ?instance.clicheEndpoint,
  'lnbits_endpoint': ?instance.lnbitsEndpoint,
  'lnbits_key': ?instance.lnbitsKey,
  'lnbits_admin_key': ?instance.lnbitsAdminKey,
  'lnbits_invoice_key': ?instance.lnbitsInvoiceKey,
  'fake_wallet_secret': ?instance.fakeWalletSecret,
  'lnbits_denomination': ?instance.lnbitsDenomination,
  'lnbits_backend_wallet_class': ?instance.lnbitsBackendWalletClass,
  'lnbits_funding_source_pay_invoice_wait_seconds':
      ?instance.lnbitsFundingSourcePayInvoiceWaitSeconds,
  'funding_source_max_retries': ?instance.fundingSourceMaxRetries,
  'lnbits_nostr_notifications_enabled':
      ?instance.lnbitsNostrNotificationsEnabled,
  'lnbits_nostr_notifications_private_key':
      ?instance.lnbitsNostrNotificationsPrivateKey,
  'lnbits_nostr_notifications_identifiers':
      ?instance.lnbitsNostrNotificationsIdentifiers,
  'lnbits_telegram_notifications_enabled':
      ?instance.lnbitsTelegramNotificationsEnabled,
  'lnbits_telegram_notifications_access_token':
      ?instance.lnbitsTelegramNotificationsAccessToken,
  'lnbits_telegram_notifications_chat_id':
      ?instance.lnbitsTelegramNotificationsChatId,
  'lnbits_email_notifications_enabled':
      ?instance.lnbitsEmailNotificationsEnabled,
  'lnbits_email_notifications_email': ?instance.lnbitsEmailNotificationsEmail,
  'lnbits_email_notifications_username':
      ?instance.lnbitsEmailNotificationsUsername,
  'lnbits_email_notifications_password':
      ?instance.lnbitsEmailNotificationsPassword,
  'lnbits_email_notifications_server': ?instance.lnbitsEmailNotificationsServer,
  'lnbits_email_notifications_port': ?instance.lnbitsEmailNotificationsPort,
  'lnbits_email_notifications_to_emails':
      ?instance.lnbitsEmailNotificationsToEmails,
  'lnbits_notification_settings_update':
      ?instance.lnbitsNotificationSettingsUpdate,
  'lnbits_notification_credit_debit': ?instance.lnbitsNotificationCreditDebit,
  'notification_balance_delta_threshold_sats':
      ?instance.notificationBalanceDeltaThresholdSats,
  'lnbits_notification_server_start_stop':
      ?instance.lnbitsNotificationServerStartStop,
  'lnbits_notification_watchdog': ?instance.lnbitsNotificationWatchdog,
  'lnbits_notification_server_status_hours':
      ?instance.lnbitsNotificationServerStatusHours,
  'lnbits_notification_incoming_payment_amount_sats':
      ?instance.lnbitsNotificationIncomingPaymentAmountSats,
  'lnbits_notification_outgoing_payment_amount_sats':
      ?instance.lnbitsNotificationOutgoingPaymentAmountSats,
  'lnbits_rate_limit_no': ?instance.lnbitsRateLimitNo,
  'lnbits_rate_limit_unit': ?instance.lnbitsRateLimitUnit,
  'lnbits_allowed_ips': ?instance.lnbitsAllowedIps,
  'lnbits_blocked_ips': ?instance.lnbitsBlockedIps,
  'lnbits_callback_url_rules': ?instance.lnbitsCallbackUrlRules,
  'lnbits_wallet_limit_max_balance': ?instance.lnbitsWalletLimitMaxBalance,
  'lnbits_wallet_limit_daily_max_withdraw':
      ?instance.lnbitsWalletLimitDailyMaxWithdraw,
  'lnbits_wallet_limit_secs_between_trans':
      ?instance.lnbitsWalletLimitSecsBetweenTrans,
  'lnbits_only_allow_incoming_payments':
      ?instance.lnbitsOnlyAllowIncomingPayments,
  'lnbits_watchdog_switch_to_voidwallet':
      ?instance.lnbitsWatchdogSwitchToVoidwallet,
  'lnbits_watchdog_interval_minutes': ?instance.lnbitsWatchdogIntervalMinutes,
  'lnbits_watchdog_delta': ?instance.lnbitsWatchdogDelta,
  'lnbits_max_outgoing_payment_amount_sats':
      ?instance.lnbitsMaxOutgoingPaymentAmountSats,
  'lnbits_max_incoming_payment_amount_sats':
      ?instance.lnbitsMaxIncomingPaymentAmountSats,
  'lnbits_exchange_rate_cache_seconds':
      ?instance.lnbitsExchangeRateCacheSeconds,
  'lnbits_exchange_history_size': ?instance.lnbitsExchangeHistorySize,
  'lnbits_exchange_history_refresh_interval_seconds':
      ?instance.lnbitsExchangeHistoryRefreshIntervalSeconds,
  'lnbits_exchange_rate_providers': ?instance.lnbitsExchangeRateProviders
      ?.map((e) => e.toJson())
      .toList(),
  'lnbits_reserve_fee_min': ?instance.lnbitsReserveFeeMin,
  'lnbits_reserve_fee_percent': ?instance.lnbitsReserveFeePercent,
  'lnbits_service_fee': ?instance.lnbitsServiceFee,
  'lnbits_service_fee_ignore_internal':
      ?instance.lnbitsServiceFeeIgnoreInternal,
  'lnbits_service_fee_max': ?instance.lnbitsServiceFeeMax,
  'lnbits_service_fee_wallet': ?instance.lnbitsServiceFeeWallet,
  'lnbits_max_asset_size_mb': ?instance.lnbitsMaxAssetSizeMb,
  'lnbits_assets_allowed_mime_types': ?instance.lnbitsAssetsAllowedMimeTypes,
  'lnbits_asset_thumbnail_width': ?instance.lnbitsAssetThumbnailWidth,
  'lnbits_asset_thumbnail_height': ?instance.lnbitsAssetThumbnailHeight,
  'lnbits_asset_thumbnail_format': ?instance.lnbitsAssetThumbnailFormat,
  'lnbits_max_assets_per_user': ?instance.lnbitsMaxAssetsPerUser,
  'lnbits_assets_no_limit_users': ?instance.lnbitsAssetsNoLimitUsers,
  'lnbits_baseurl': ?instance.lnbitsBaseurl,
  'lnbits_hide_api': ?instance.lnbitsHideApi,
  'lnbits_site_title': ?instance.lnbitsSiteTitle,
  'lnbits_site_tagline': ?instance.lnbitsSiteTagline,
  'lnbits_site_description': ?instance.lnbitsSiteDescription,
  'lnbits_show_home_page_elements': ?instance.lnbitsShowHomePageElements,
  'lnbits_default_wallet_name': ?instance.lnbitsDefaultWalletName,
  'lnbits_custom_badge': ?instance.lnbitsCustomBadge,
  'lnbits_custom_badge_color': ?instance.lnbitsCustomBadgeColor,
  'lnbits_theme_options': ?instance.lnbitsThemeOptions,
  'lnbits_custom_logo': ?instance.lnbitsCustomLogo,
  'lnbits_custom_image': ?instance.lnbitsCustomImage,
  'lnbits_ad_space_title': ?instance.lnbitsAdSpaceTitle,
  'lnbits_ad_space': ?instance.lnbitsAdSpace,
  'lnbits_ad_space_enabled': ?instance.lnbitsAdSpaceEnabled,
  'lnbits_allowed_currencies': ?instance.lnbitsAllowedCurrencies,
  'lnbits_default_accounting_currency':
      ?instance.lnbitsDefaultAccountingCurrency,
  'lnbits_qr_logo': ?instance.lnbitsQrLogo,
  'lnbits_apple_touch_icon': ?instance.lnbitsAppleTouchIcon,
  'lnbits_default_reaction': ?instance.lnbitsDefaultReaction,
  'lnbits_default_theme': ?instance.lnbitsDefaultTheme,
  'lnbits_default_border': ?instance.lnbitsDefaultBorder,
  'lnbits_default_gradient': ?instance.lnbitsDefaultGradient,
  'lnbits_default_bgimage': ?instance.lnbitsDefaultBgimage,
  'lnbits_admin_extensions': ?instance.lnbitsAdminExtensions,
  'lnbits_user_default_extensions': ?instance.lnbitsUserDefaultExtensions,
  'lnbits_extensions_deactivate_all': ?instance.lnbitsExtensionsDeactivateAll,
  'lnbits_extensions_builder_activate_non_admins':
      ?instance.lnbitsExtensionsBuilderActivateNonAdmins,
  'lnbits_extensions_reviews_url': ?instance.lnbitsExtensionsReviewsUrl,
  'lnbits_extensions_manifests': ?instance.lnbitsExtensionsManifests,
  'lnbits_extensions_builder_manifest_url':
      ?instance.lnbitsExtensionsBuilderManifestUrl,
  'lnbits_admin_users': ?instance.lnbitsAdminUsers,
  'lnbits_allowed_users': ?instance.lnbitsAllowedUsers,
  'lnbits_allow_new_accounts': ?instance.lnbitsAllowNewAccounts,
};

UpdateSuperuserPassword _$UpdateSuperuserPasswordFromJson(
  Map<String, dynamic> json,
) => UpdateSuperuserPassword(
  username: json['username'] as String,
  password: json['password'] as String,
  passwordRepeat: json['password_repeat'] as String,
);

Map<String, dynamic> _$UpdateSuperuserPasswordToJson(
  UpdateSuperuserPassword instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'password_repeat': instance.passwordRepeat,
};

UpdateUser _$UpdateUserFromJson(Map<String, dynamic> json) => UpdateUser(
  userId: json['user_id'] as String,
  username: json['username'] as String,
  extra: json['extra'] == null
      ? null
      : UserExtra.fromJson(json['extra'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UpdateUserToJson(UpdateUser instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
      'extra': ?instance.extra?.toJson(),
    };

UpdateUserPassword _$UpdateUserPasswordFromJson(Map<String, dynamic> json) =>
    UpdateUserPassword(
      userId: json['user_id'] as String,
      passwordOld: json['password_old'] as String?,
      password: json['password'] as String,
      passwordRepeat: json['password_repeat'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$UpdateUserPasswordToJson(UpdateUserPassword instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'password_old': ?instance.passwordOld,
      'password': instance.password,
      'password_repeat': instance.passwordRepeat,
      'username': instance.username,
    };

UpdateUserPubkey _$UpdateUserPubkeyFromJson(Map<String, dynamic> json) =>
    UpdateUserPubkey(
      userId: json['user_id'] as String,
      pubkey: json['pubkey'] as String,
    );

Map<String, dynamic> _$UpdateUserPubkeyToJson(UpdateUserPubkey instance) =>
    <String, dynamic>{'user_id': instance.userId, 'pubkey': instance.pubkey};

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  email: json['email'] as String?,
  username: json['username'] as String?,
  pubkey: json['pubkey'] as String?,
  externalId: json['external_id'] as String?,
  extensions:
      (json['extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  wallets:
      (json['wallets'] as List<dynamic>?)
          ?.map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  admin: json['admin'] as bool? ?? false,
  superUser: json['super_user'] as bool? ?? false,
  fiatProviders:
      (json['fiat_providers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  hasPassword: json['has_password'] as bool? ?? false,
  extra: json['extra'] == null
      ? null
      : UserExtra.fromJson(json['extra'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'email': ?instance.email,
  'username': ?instance.username,
  'pubkey': ?instance.pubkey,
  'external_id': ?instance.externalId,
  'extensions': ?instance.extensions,
  'wallets': ?instance.wallets?.map((e) => e.toJson()).toList(),
  'admin': ?instance.admin,
  'super_user': ?instance.superUser,
  'fiat_providers': ?instance.fiatProviders,
  'has_password': ?instance.hasPassword,
  'extra': ?instance.extra?.toJson(),
};

UserAcls _$UserAclsFromJson(Map<String, dynamic> json) => UserAcls(
  id: json['id'] as String,
  accessControlList:
      (json['access_control_list'] as List<dynamic>?)
          ?.map((e) => AccessControlList.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserAclsToJson(UserAcls instance) => <String, dynamic>{
  'id': instance.id,
  'access_control_list': ?instance.accessControlList
      ?.map((e) => e.toJson())
      .toList(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
};

UserExtra _$UserExtraFromJson(Map<String, dynamic> json) => UserExtra(
  emailVerified: json['email_verified'] as bool? ?? false,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  displayName: json['display_name'] as String?,
  picture: json['picture'] as String?,
  provider: json['provider'] as String?,
  visibleWalletCount: (json['visible_wallet_count'] as num?)?.toInt(),
  notifications: json['notifications'] == null
      ? null
      : UserNotifications.fromJson(
          json['notifications'] as Map<String, dynamic>,
        ),
  walletInviteRequests:
      (json['wallet_invite_requests'] as List<dynamic>?)
          ?.map((e) => WalletInviteRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  labels:
      (json['labels'] as List<dynamic>?)
          ?.map((e) => UserLabel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$UserExtraToJson(UserExtra instance) => <String, dynamic>{
  'email_verified': ?instance.emailVerified,
  'first_name': ?instance.firstName,
  'last_name': ?instance.lastName,
  'display_name': ?instance.displayName,
  'picture': ?instance.picture,
  'provider': ?instance.provider,
  'visible_wallet_count': ?instance.visibleWalletCount,
  'notifications': ?instance.notifications?.toJson(),
  'wallet_invite_requests': ?instance.walletInviteRequests
      ?.map((e) => e.toJson())
      .toList(),
  'labels': ?instance.labels?.map((e) => e.toJson()).toList(),
};

UserLabel _$UserLabelFromJson(Map<String, dynamic> json) => UserLabel(
  name: json['name'] as String,
  description: json['description'] as String?,
  color: json['color'] as String?,
);

Map<String, dynamic> _$UserLabelToJson(UserLabel instance) => <String, dynamic>{
  'name': instance.name,
  'description': ?instance.description,
  'color': ?instance.color,
};

UserNotifications _$UserNotificationsFromJson(Map<String, dynamic> json) =>
    UserNotifications(
      nostrIdentifier: json['nostr_identifier'] as String?,
      telegramChatId: json['telegram_chat_id'] as String?,
      emailAddress: json['email_address'] as String?,
      excludedWallets:
          (json['excluded_wallets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      outgoingPaymentsSats: (json['outgoing_payments_sats'] as num?)?.toInt(),
      incomingPaymentsSats: (json['incoming_payments_sats'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserNotificationsToJson(UserNotifications instance) =>
    <String, dynamic>{
      'nostr_identifier': ?instance.nostrIdentifier,
      'telegram_chat_id': ?instance.telegramChatId,
      'email_address': ?instance.emailAddress,
      'excluded_wallets': ?instance.excludedWallets,
      'outgoing_payments_sats': ?instance.outgoingPaymentsSats,
      'incoming_payments_sats': ?instance.incomingPaymentsSats,
    };

ValidationError _$ValidationErrorFromJson(
  Map<String, dynamic> json,
) => ValidationError(
  loc: (json['loc'] as List<dynamic>?)?.map((e) => e as Object).toList() ?? [],
  msg: json['msg'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$ValidationErrorToJson(ValidationError instance) =>
    <String, dynamic>{
      'loc': instance.loc,
      'msg': instance.msg,
      'type': instance.type,
    };

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
  id: json['id'] as String,
  user: json['user'] as String,
  walletType: json['wallet_type'] as String?,
  adminkey: json['adminkey'] as String,
  inkey: json['inkey'] as String,
  name: json['name'] as String,
  sharedWalletId: json['shared_wallet_id'] as String?,
  deleted: json['deleted'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  currency: json['currency'] as String?,
  balanceMsat: (json['balance_msat'] as num?)?.toInt(),
  extra: json['extra'] == null
      ? null
      : WalletExtra.fromJson(json['extra'] as Map<String, dynamic>),
  storedPaylinks: json['stored_paylinks'] == null
      ? null
      : StoredPayLinks.fromJson(
          json['stored_paylinks'] as Map<String, dynamic>,
        ),
  sharePermissions: Wallet.walletPermissionSharePermissionsListFromJson(
    json['share_permissions'] as List?,
  ),
);

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
  'id': instance.id,
  'user': instance.user,
  'wallet_type': ?instance.walletType,
  'adminkey': instance.adminkey,
  'inkey': instance.inkey,
  'name': instance.name,
  'shared_wallet_id': ?instance.sharedWalletId,
  'deleted': ?instance.deleted,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': ?instance.updatedAt?.toIso8601String(),
  'currency': ?instance.currency,
  'balance_msat': ?instance.balanceMsat,
  'extra': ?instance.extra?.toJson(),
  'stored_paylinks': ?instance.storedPaylinks?.toJson(),
  'share_permissions': walletPermissionListToJson(instance.sharePermissions),
};

WalletExtra _$WalletExtraFromJson(Map<String, dynamic> json) => WalletExtra(
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  pinned: json['pinned'] as bool? ?? false,
  sharedWith:
      (json['shared_with'] as List<dynamic>?)
          ?.map(
            (e) => WalletSharePermission.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$WalletExtraToJson(WalletExtra instance) =>
    <String, dynamic>{
      'icon': ?instance.icon,
      'color': ?instance.color,
      'pinned': ?instance.pinned,
      'shared_with': ?instance.sharedWith?.map((e) => e.toJson()).toList(),
    };

WalletInviteRequest _$WalletInviteRequestFromJson(Map<String, dynamic> json) =>
    WalletInviteRequest(
      requestId: json['request_id'] as String,
      fromUserName: json['from_user_name'] as String?,
      toWalletId: json['to_wallet_id'] as String,
      toWalletName: json['to_wallet_name'] as String,
    );

Map<String, dynamic> _$WalletInviteRequestToJson(
  WalletInviteRequest instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'from_user_name': ?instance.fromUserName,
  'to_wallet_id': instance.toWalletId,
  'to_wallet_name': instance.toWalletName,
};

WalletSharePermission _$WalletSharePermissionFromJson(
  Map<String, dynamic> json,
) => WalletSharePermission(
  requestId: json['request_id'] as String?,
  username: json['username'] as String,
  sharedWithWalletId: json['shared_with_wallet_id'] as String?,
  permissions: WalletSharePermission.walletPermissionPermissionsListFromJson(
    json['permissions'] as List?,
  ),
  status: walletShareStatusFromJson(json['status']),
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$WalletSharePermissionToJson(
  WalletSharePermission instance,
) => <String, dynamic>{
  'request_id': ?instance.requestId,
  'username': instance.username,
  'shared_with_wallet_id': ?instance.sharedWithWalletId,
  'permissions': walletPermissionListToJson(instance.permissions),
  'status': ?walletShareStatusToJson(instance.status),
  'comment': ?instance.comment,
};

WebPushSubscription _$WebPushSubscriptionFromJson(Map<String, dynamic> json) =>
    WebPushSubscription(
      endpoint: json['endpoint'] as String,
      user: json['user'] as String,
      data: json['data'] as String,
      host: json['host'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$WebPushSubscriptionToJson(
  WebPushSubscription instance,
) => <String, dynamic>{
  'endpoint': instance.endpoint,
  'user': instance.user,
  'data': instance.data,
  'host': instance.host,
  'timestamp': instance.timestamp.toIso8601String(),
};
