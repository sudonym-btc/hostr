// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

enum ActionFieldsAmountSource {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('owner_data')
  ownerData('owner_data'),
  @JsonValue('client_data')
  clientData('client_data');

  final String? value;

  const ActionFieldsAmountSource(this.value);
}

enum ChannelState {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('active')
  active('active'),
  @JsonValue('pending')
  pending('pending'),
  @JsonValue('closed')
  closed('closed'),
  @JsonValue('inactive')
  inactive('inactive');

  final String? value;

  const ChannelState(this.value);
}

enum LnurlResponseTag {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('login')
  login('login'),
  @JsonValue('channelRequest')
  channelrequest('channelRequest'),
  @JsonValue('hostedChannelRequest')
  hostedchannelrequest('hostedChannelRequest'),
  @JsonValue('payRequest')
  payrequest('payRequest'),
  @JsonValue('withdrawRequest')
  withdrawrequest('withdrawRequest');

  final String? value;

  const LnurlResponseTag(this.value);
}

enum LnurlStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('OK')
  ok('OK'),
  @JsonValue('ERROR')
  error('ERROR');

  final String? value;

  const LnurlStatus(this.value);
}

enum WalletPermission {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('view-payments')
  viewPayments('view-payments'),
  @JsonValue('receive-payments')
  receivePayments('receive-payments'),
  @JsonValue('send-payments')
  sendPayments('send-payments');

  final String? value;

  const WalletPermission(this.value);
}

enum WalletShareStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('invite_sent')
  inviteSent('invite_sent'),
  @JsonValue('approved')
  approved('approved');

  final String? value;

  const WalletShareStatus(this.value);
}

enum WalletType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('lightning')
  lightning('lightning'),
  @JsonValue('lightning-shared')
  lightningShared('lightning-shared');

  final String? value;

  const WalletType(this.value);
}

enum NodeApiV1PaymentsGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const NodeApiV1PaymentsGetDirection(this.value);
}

enum NodeApiV1InvoicesGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const NodeApiV1InvoicesGetDirection(this.value);
}

enum ApiV1PaymentsGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1PaymentsGetDirection(this.value);
}

enum ApiV1PaymentsHistoryGetGroup {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('hour')
  hour('hour'),
  @JsonValue('day')
  day('day'),
  @JsonValue('month')
  month('month');

  final String? value;

  const ApiV1PaymentsHistoryGetGroup(this.value);
}

enum ApiV1PaymentsHistoryGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1PaymentsHistoryGetDirection(this.value);
}

enum ApiV1PaymentsStatsCountGetCountBy {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('status')
  status('status'),
  @JsonValue('tag')
  tag('tag'),
  @JsonValue('extension')
  extension('extension'),
  @JsonValue('wallet_id')
  walletId('wallet_id');

  final String? value;

  const ApiV1PaymentsStatsCountGetCountBy(this.value);
}

enum ApiV1PaymentsStatsCountGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1PaymentsStatsCountGetDirection(this.value);
}

enum ApiV1PaymentsStatsWalletsGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1PaymentsStatsWalletsGetDirection(this.value);
}

enum ApiV1PaymentsStatsDailyGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1PaymentsStatsDailyGetDirection(this.value);
}

enum ApiV1PaymentsPaginatedGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1PaymentsPaginatedGetDirection(this.value);
}

enum ApiV1PaymentsAllPaginatedGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1PaymentsAllPaginatedGetDirection(this.value);
}

enum ApiV1WalletPaginatedGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1WalletPaginatedGetDirection(this.value);
}

enum UsersApiV1UserGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const UsersApiV1UserGetDirection(this.value);
}

enum AuditApiV1GetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const AuditApiV1GetDirection(this.value);
}

enum AuditApiV1StatsGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const AuditApiV1StatsGetDirection(this.value);
}

enum ApiV1AssetsPaginatedGetDirection {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('asc')
  asc('asc'),
  @JsonValue('desc')
  desc('desc');

  final String? value;

  const ApiV1AssetsPaginatedGetDirection(this.value);
}
