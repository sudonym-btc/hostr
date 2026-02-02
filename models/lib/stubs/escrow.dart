import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

List<Escrow> MOCK_ESCROWS({String? contractAddress}) => [
      Escrow.fromNostrEvent(Nip01Utils.signWithPrivateKey(
          privateKey: MockKeys.escrow.privateKey!,
          event: Nip01Event(
              pubKey: MockKeys.escrow.publicKey,
              content: json.encode(EscrowContent(
                      chainId: ChainIds.RootstockRegtest.value,
                      pubkey: MockKeys.escrow.publicKey,
                      evmAddress: getEvmCredentials(MockKeys.escrow.privateKey!)
                          .address
                          .eip55With0x,
                      contractAddress: contractAddress ??
                          "0x1460fd6f56f2e62104a794C69Cc06BE7DC975Bed",
                      maxDuration: Duration(days: 365),
                      type: EscrowType.EVM)
                  .toJson()),
              createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
              kind: NOSTR_KIND_ESCROW,
              tags: []))),
    ].toList();
