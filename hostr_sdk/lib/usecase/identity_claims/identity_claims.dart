import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:web3dart/web3dart.dart';

import '../../config.dart';
import '../auth/auth.dart';
import '../crud.usecase.dart';

@Singleton()
class IdentityClaimsUseCase extends CrudUseCase<IdentityClaims> {
  final Auth _auth;
  final HostrConfig _config;

  IdentityClaimsUseCase({
    required Auth auth,
    required HostrConfig config,
    required super.requests,
    required super.logger,
  }) : _auth = auth,
       _config = config,
       super(kind: kNostrKindIdentityClaims);

  Future<IdentityClaims?> loadClaims(String pubkey) async {
    final relays = _hostrRelays;
    await for (final claim in requests.query<IdentityClaims>(
      filter: Filter(
        kinds: const [kNostrKindIdentityClaims],
        authors: [pubkey],
        limit: 1,
      ),
      relays: relays,
      name: 'IdentityClaims-load',
    )) {
      return claim;
    }
    return null;
  }

  Future<String?> loadEvmAddress(String pubkey) async {
    return (await loadClaims(pubkey))?.evmAddress;
  }

  Future<IdentityClaims?>
  ensureEvmAddress() => logger.span('ensureEvmAddress', () async {
    final keyPair = _auth.activeKeyPair;
    if (keyPair == null) return null;

    final evmKey = await _auth.hd.getActiveEvmKey();
    final address = evmKey.address.eip55With0x;
    final existing = await loadClaims(keyPair.publicKey);
    logger.d(
      'ensureEvmAddress state: '
      'pubkey=${_shortHex(keyPair.publicKey)} '
      'evmAddress=$address '
      'existing=${_identityClaimSummary(existing)}',
    );
    if (_sameAddress(existing?.evmAddress, address)) return existing;

    final proof = _signEvmIdentityClaim(
      evmKey: evmKey,
      nostrPubkey: keyPair.publicKey,
      evmAddress: address,
    );
    logger.d(
      'ensureEvmAddress proof generated: '
      'address=$address proof=${_shortHex(proof)}',
    );
    final unsigned =
        (existing ??
                IdentityClaims.build(
                  pubKey: keyPair.publicKey,
                  evmAddress: address,
                ))
            .withEvmAddress(address, eip191Proof: proof);
    logger.d(
      'ensureEvmAddress unsigned claim: ${_identityClaimSummary(unsigned)}',
    );
    logger.d(
      'ensureEvmAddress unsigned claim JSON: ${_nostrEventDebugJson(unsigned)}',
    );

    final result = await upsert(unsigned);
    final signed = result.event;
    logger.d('ensureEvmAddress signed claim: ${_identityClaimSummary(signed)}');
    logger.d(
      'ensureEvmAddress signed claim JSON: ${_nostrEventDebugJson(signed)}',
    );
    final calculatedId = Nip01Utils.calculateId(signed);
    if (signed.id != calculatedId) {
      logger.w(
        'ensureEvmAddress signed claim has invalid id before broadcast: '
        'id=${_shortHex(signed.id)} calculated=${_shortHex(calculatedId)}',
      );
    }
    return signed;
  });

  List<String>? get _hostrRelays =>
      _config.hostrRelay.isEmpty ? null : [_config.hostrRelay];

  bool _sameAddress(String? a, String b) => a?.toLowerCase() == b.toLowerCase();
}

String evmIdentityClaimMessage({
  required String nostrPubkey,
  required String evmAddress,
}) {
  return [
    'Hostr EVM identity claim',
    'nostr:$nostrPubkey',
    'evm:address:$evmAddress',
  ].join('\n');
}

String _signEvmIdentityClaim({
  required EthPrivateKey evmKey,
  required String nostrPubkey,
  required String evmAddress,
}) {
  final message = evmIdentityClaimMessage(
    nostrPubkey: nostrPubkey,
    evmAddress: evmAddress,
  );
  return '0x${hex.encode(evmKey.signPersonalMessageToUint8List(utf8.encode(message)))}';
}

String _shortHex(String? value) {
  if (value == null) return 'null';
  if (value.length <= 16) return value;
  return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
}

String _nostrEventDebugJson(Nip01Event event) {
  return jsonEncode(Nip01EventModel.fromEntity(event).toJson());
}

String _identityClaimSummary(IdentityClaims? claim) {
  if (claim == null) return 'none';
  final calculatedId = Nip01Utils.calculateId(claim);
  return [
    'kind=${claim.kind}',
    'pubkey=${_shortHex(claim.pubKey)}',
    'createdAt=${claim.createdAt}',
    'tags=${claim.tags.length}',
    'evmAddress=${claim.evmAddress}',
    'proof=${_shortHex(claim.evmAddressProof)}',
    'id=${_shortHex(claim.id)}',
    'calculated=${_shortHex(calculatedId)}',
    'idValid=${claim.id == calculatedId}',
    'sigPresent=${claim.sig != null}',
    if (claim.sig != null) 'sig=${_shortHex(claim.sig)}',
  ].join(' ');
}
