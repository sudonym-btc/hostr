import 'package:dart_nostr/dart_nostr.dart';

class BudgetPeriod {
  static String daily = 'daily';
  static String weekly = 'weekly';
  static String monthly = 'monthly';
  static String yearly = 'yearly';
}

class NostrWalletAuth {
  generateUri(
      {required NostrKeyPairs keyPair,
      required int budget,
      required String budgetPeriod,
      required String relay,
      required String secret,
      String? appPubKey}) {
    return Uri(
        scheme: 'nostr+walletauth',
        host: keyPair.public,
        queryParameters: {
          'relay': relay,
          'secret': secret,
          'required_commands': 'pay_invoice make_invoice lookup_invoice',
          'optional_commands': 'list_transactions',
          'budget': '$budget/$budgetPeriod',
          // 'identifier': appPubKey
        });
  }
}
