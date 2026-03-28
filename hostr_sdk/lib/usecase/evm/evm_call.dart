/// Serialization helpers for named EVM contract calls.
///
/// The application uses `Map<String, Call>` — keys are human-readable method
/// names (for logging / debugging), values are `permissionless.Call`s.
///
/// [Call] is re-exported so downstream files can simply
/// `import 'evm_call.dart'` instead of importing permissionless directly.
library;

import 'package:convert/convert.dart';
import 'package:permissionless/permissionless.dart' show Call;
import 'package:wallet/wallet.dart';

export 'package:permissionless/permissionless.dart' show Call;

/// Serialize a named-calls map to a JSON-compatible list.
///
/// Backward-compatible with the old `CallIntent` format so that
/// persisted recovery data can still be read by [deserializeNamedCalls].
List<Map<String, dynamic>> serializeNamedCalls(Map<String, Call> calls) => calls
    .entries
    .map(
      (e) => {
        'methodName': e.key,
        'to': e.value.to.eip55With0x,
        'data': e.value.data,
        'valueWei': e.value.value.toString(),
      },
    )
    .toList();

/// Deserialize named calls from JSON.
///
/// Handles both the current format and the legacy `CallIntent` format.
Map<String, Call> deserializeNamedCalls(List<dynamic> json) => Map.fromEntries(
  json.map((e) {
    final map = e as Map<String, dynamic>;
    var data = map['data'] as String? ?? '0x';
    // Legacy CallIntent stored raw hex bytes that may lack the 0x prefix.
    if (!data.startsWith('0x')) data = '0x$data';
    return MapEntry(
      map['methodName'] as String? ?? 'unknown',
      Call(
        to: EthereumAddress.fromHex(map['to'] as String),
        value: BigInt.parse(
          (map['valueWei'] ?? map['value'] ?? '0').toString(),
        ),
        data: data,
      ),
    );
  }),
);

/// Build a [Call] from ABI-encoded function output.
///
/// Convenience used by intent builders to avoid duplicating hex-encoding.
Call callFromEncoded({
  required EthereumAddress to,
  required List<int> data,
  BigInt? value,
}) => Call(to: to, value: value ?? BigInt.zero, data: '0x${hex.encode(data)}');
