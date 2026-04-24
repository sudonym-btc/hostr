import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:injectable/injectable.dart';
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
    IdentityClaims? latest;
    await for (final claim in requests.query<IdentityClaims>(
      filter: Filter(
        kinds: const [kNostrKindIdentityClaims],
        authors: [pubkey],
        limit: 1,
      ),
      relays: relays,
      name: 'IdentityClaims-load',
    )) {
      if (latest == null || latest.createdAt < claim.createdAt) {
        latest = claim;
      }
    }
    return latest;
  }

  Future<String?> loadEvmAddress(String pubkey) async {
    return (await loadClaims(pubkey))?.evmAddress;
  }

  Future<IdentityClaims?> ensureEvmAddress() =>
      logger.span('ensureEvmAddress', () async {
        final keyPair = _auth.activeKeyPair;
        if (keyPair == null) return null;

        final evmKey = await _auth.hd.getActiveEvmKey();
        final address = evmKey.address.eip55With0x;
        final existing = await loadClaims(keyPair.publicKey);
        if (_sameAddress(existing?.evmAddress, address)) return existing;

        final proof = _signEvmIdentityClaim(
          evmKey: evmKey,
          nostrPubkey: keyPair.publicKey,
          evmAddress: address,
        );
        final unsigned =
            (existing ??
                    IdentityClaims.build(
                      pubKey: keyPair.publicKey,
                      evmAddress: address,
                    ))
                .withEvmAddress(address, eip191Proof: proof);

        final signed = unsigned.signAs(keyPair, IdentityClaims.fromNostrEvent);
        await requests.broadcast(event: signed, relays: _hostrRelays);
        notifyUpdate(signed);
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
