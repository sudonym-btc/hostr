import 'package:models/main.dart';

import 'keypairs.dart';

List<EscrowService> MOCK_ESCROWS(
        {String? contractAddress, String? byteCodeHash}) =>
    [
      EscrowService(
          pubKey: MockKeys.escrow.publicKey,
          content: EscrowServiceContent(
              chainId: ChainIds.RootstockRegtest.value,
              pubkey: MockKeys.escrow.publicKey,
//               Verifiable build metadata: the exact Solidity compiler version, optimizer flag + runs, and metadata settings used to compile. These determine the runtime bytecode.
// Runtime bytecode hash: take eth_getCode for the deployed address, hash with keccak256. This uniquely identifies the deployed logic (state ignored).
// Sourcify/Etherscan verification: third‑party verification that the published source + compiler settings reproduce the deployed bytecode. Clients can trust the verified record and compare the hash themselves.
// So the escrow publisher should include: contract address, chainId, runtime bytecode hash, compiler version, optimizer settings, and optionally a Sourcify/Etherscan link. Clients then compare on‑chain runtime hash to the advertised hash.
              evmAddress: getEvmCredentials(MockKeys.escrow.privateKey!)
                  .address
                  .eip55With0x,
              contractAddress: contractAddress ??
                  "0x1460fd6f56f2e62104a794C69Cc06BE7DC975Bed",
              contractBytecodeHash: byteCodeHash ?? "0xMockBytecodeHash",
              maxDuration: Duration(days: 365),
              type: EscrowType.EVM),
          createdAt: DateTime(2025).millisecondsSinceEpoch ~/ 1000,
          tags: []).signAs(MockKeys.escrow, EscrowService.fromNostrEvent),
    ].toList();
