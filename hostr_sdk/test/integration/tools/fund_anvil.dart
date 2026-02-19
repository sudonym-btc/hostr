import 'dart:convert';
import 'dart:io';

Future<void> fundAnvilAddress(
  String addressHex, {
  BigInt? balanceWei,
  String rpcUrl = 'http://localhost:8545',
}) async {
  final resolvedBalanceWei = balanceWei ?? BigInt.parse('500000000000000000');
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(rpcUrl));
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.add(
      utf8.encode(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'anvil_setBalance',
          'params': [addressHex, '0x${resolvedBalanceWei.toRadixString(16)}'],
        }),
      ),
    );

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    final payload = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode != HttpStatus.ok) {
      throw StateError(
        'Failed to fund Anvil address: HTTP ${response.statusCode} - $body',
      );
    }
    if (payload['error'] != null) {
      throw StateError('Failed to fund Anvil address: ${payload['error']}');
    }
    if (payload['result'] == false) {
      throw StateError('Failed to fund Anvil address: result=false');
    }
  } finally {
    client.close(force: true);
  }
}
