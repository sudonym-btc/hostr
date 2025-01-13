import 'package:hostr/data/models/nostr_kind/nwc/nwc_info.dart';

class NwcMethodParams {
  toJson() {}
}

class NwcMethodResponse {}

/// PAY INVOICE
class NwcMethodPayInvoiceParams extends NwcMethodParams {
  final String invoice;
  final int? amount;
  NwcMethodPayInvoiceParams({required this.invoice, this.amount});

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodPayInvoiceParams(
        invoice: json['invoice'], amount: json['amount']);
  }

  toJson() {
    return {'invoice': invoice, 'amount': amount};
  }
}

class NwcMethodPayInvoiceResponse extends NwcMethodResponse {
  final String preimage;
  final int? fees_paid;
  NwcMethodPayInvoiceResponse({required this.preimage, this.fees_paid});

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodPayInvoiceResponse(
        preimage: json['preimage'], fees_paid: json['fees_paid']);
  }

  toJson() {
    return {'preimage': preimage, 'fees_paid': fees_paid};
  }
}

/// MAKE INVOICE
class NwcMethodMakeInvoiceParams extends NwcMethodParams {
  final int amount;
  final String? description;
  final String? description_hash;
  final int? expiry;

  NwcMethodMakeInvoiceParams(
      {required this.amount,
      this.description,
      this.description_hash,
      this.expiry});

  toJson() {
    return {
      'amount': amount,
      'description': description,
      'description_hash': description_hash,
      'expiry': expiry
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodMakeInvoiceParams(
        amount: json['amount'],
        description: json['description'],
        description_hash: json['description_hash'],
        expiry: json['expiry']);
  }
}

class NwcMethodMakeInvoiceResponse extends NwcMethodResponse {
  /// incoming or outgoing for payments
  final String type;
  final String? invoice;
  final String? description;
  final String? description_hash;
  final String? preimage;
  final String payment_hash;
  final int? created_at;
  final int? expires_at;
  final int? amount;
  final int? fees_paid;

  final dynamic metadata;
  NwcMethodMakeInvoiceResponse(
      {required this.type,
      this.invoice,
      this.description,
      this.description_hash,
      this.preimage,
      required this.payment_hash,
      this.created_at,
      this.expires_at,
      this.amount,
      this.fees_paid,
      this.metadata});

  toJson() {
    return {
      'type': type,
      'invoice': invoice,
      'description': description,
      'description_hash': description_hash,
      'preimage': preimage,
      'payment_hash': payment_hash,
      'created_at': created_at,
      'expires_at': expires_at,
      'amount': amount,
      'fees_paid': fees_paid,
      'metadata': metadata
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodMakeInvoiceResponse(
        type: json['type'],
        invoice: json['invoice'],
        description: json['description'],
        description_hash: json['description_hash'],
        preimage: json['preimage'],
        payment_hash: json['payment_hash'],
        created_at: json['created_at'],
        expires_at: json['expires_at'],
        amount: json['amount'],
        fees_paid: json['fees_paid'],
        metadata: json['metadata']);
  }
}

/// LOOKUP INVOICE
class NwcMethodLookupInvoiceParams extends NwcMethodParams {
  ///  one of payment_hash or invoice is required
  final String? payment_hash;
  final String? invoice;
  NwcMethodLookupInvoiceParams({this.payment_hash, this.invoice})
      : assert(payment_hash != null || invoice != null);

  toJson() {
    return {'payment_hash': payment_hash, 'invoice': invoice};
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodLookupInvoiceParams(
        payment_hash: json['payment_hash'], invoice: json['invoice']);
  }
}

class NwcMethodLookupInvoiceResponse extends NwcMethodResponse {
  final String type;
  final String payment_hash;
  final String? invoice;
  final String? description;
  final String? description_hash;
  final String? preimage;
  final int? created_at;
  final int? expires_at;
  final int? settled_at;
  final int? amount;
  final int? fees_paid;
  final dynamic metadata;
  NwcMethodLookupInvoiceResponse(
      {required this.type,
      required this.payment_hash,
      this.invoice,
      this.description,
      this.description_hash,
      this.preimage,
      this.created_at,
      this.expires_at,
      this.settled_at,
      this.amount,
      this.fees_paid,
      this.metadata});

  toJson() {
    return {
      'type': type,
      'payment_hash': payment_hash,
      'invoice': invoice,
      'description': description,
      'description_hash': description_hash,
      'preimage': preimage,
      'created_at': created_at,
      'expires_at': expires_at,
      'settled_at': settled_at,
      'amount': amount,
      'fees_paid': fees_paid,
      'metadata': metadata
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodLookupInvoiceResponse(
        type: json['type'],
        payment_hash: json['payment_hash'],
        invoice: json['invoice'],
        description: json['description'],
        description_hash: json['description_hash'],
        preimage: json['preimage'],
        created_at: json['created_at'],
        expires_at: json['expires_at'],
        settled_at: json['settled_at'],
        amount: json['amount'],
        fees_paid: json['fees_paid'],
        metadata: json['metadata']);
  }
}

enum NwcLookupInvoiceErrors { NOT_FOUND }

/// GET BALANCE
class NwcMethodGetBalanceParams extends NwcMethodParams {
  toJson() {
    return {};
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodGetBalanceParams();
  }
}

class NwcMethodGetBalanceResponse extends NwcMethodResponse {
  /// Balance msats
  final int balance;

  NwcMethodGetBalanceResponse({required this.balance});

  toJson() {
    return {'balance': balance};
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodGetBalanceResponse(balance: json['balance']);
  }
}

/// GET INFO
class NwcMethodGetInfoParams extends NwcMethodParams {
  toJson() {
    return {};
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodGetInfoParams();
  }
}

class NwcMethodGetInfoResponse extends NwcMethodResponse {
  final String alias;
  final String color;
  final String pubkey;
  final String network;
  final int block_height;
  final int block_hash;
  final List<NwcMethods> methods;
  final List<NwcNotifications> notifications;

  NwcMethodGetInfoResponse(
      {required this.alias,
      required this.color,
      required this.pubkey,
      required this.network,
      required this.block_height,
      required this.block_hash,
      required this.methods,
      required this.notifications});

  toJson() {
    return {
      'alias': alias,
      'color': color,
      'pubkey': pubkey,
      'network': network,
      'block_height': block_height,
      'block_hash': block_hash,
      'methods': methods,
      'notifications': notifications
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return NwcMethodGetInfoResponse(
        alias: json['alias'],
        color: json['color'],
        pubkey: json['pubkey'],
        network: json['network'],
        block_height: json['block_height'],
        block_hash: json['block_hash'],
        methods: json['methods'],
        notifications: json['notifications']);
  }
}

/// Combine method params with their response types
abstract class NwcMethod {
  final NwcMethods method = NwcMethods.get_info;
  final NwcMethodParams params;
  final NwcMethodResponse? response;

  NwcMethod({required this.params, this.response});
}

class NwcMethodPayInvoice extends NwcMethod {
  @override
  final method = NwcMethods.pay_invoice;
  @override
  final NwcMethodPayInvoiceParams params;
  @override
  final NwcMethodPayInvoiceResponse? response;
  NwcMethodPayInvoice({required this.params, this.response})
      : super(params: params, response: response);
}

class NwcMethodMakeInvoice extends NwcMethod {
  @override
  final method = NwcMethods.make_invoice;
  @override
  final NwcMethodMakeInvoiceParams params;
  @override
  final NwcMethodMakeInvoiceResponse? response;
  NwcMethodMakeInvoice({required this.params, this.response})
      : super(params: params, response: response);
}

class NwcMethodLookupInvoice extends NwcMethod {
  @override
  final method = NwcMethods.lookup_invoice;
  @override
  final NwcMethodLookupInvoiceParams params;
  @override
  final NwcMethodLookupInvoiceResponse? response;
  NwcMethodLookupInvoice({required this.params, this.response})
      : super(params: params, response: response);
}

class NwcMethodGetInfo extends NwcMethod {
  @override
  final method = NwcMethods.get_info;
  @override
  final NwcMethodGetInfoParams params = NwcMethodGetInfoParams();
  @override
  final NwcMethodGetInfoResponse? response;
  NwcMethodGetInfo({this.response})
      : super(params: NwcMethodGetInfoParams(), response: response);
}

class NwcMethodGetBalance extends NwcMethod {
  @override
  final method = NwcMethods.get_balance;
  @override
  final NwcMethodGetBalanceParams params = NwcMethodGetBalanceParams();
  @override
  final NwcMethodGetBalanceResponse? response;
  NwcMethodGetBalance({this.response})
      : super(params: NwcMethodGetBalanceParams(), response: response);
}
