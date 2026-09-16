import fs from 'node:fs';
import path from 'node:path';

/** Deploy exactly the artifact consumed by NMDK's TypeScript and Dart drivers. */
export function readCanonicalEscrowArtifact() {
  const artifactPath = process.env.NMDK_ESCROW_ARTIFACT ?? path.resolve(
    import.meta.dirname,
    '../../../dependencies/nmdk/dependencies/marketplace-evm-contracts/artifacts/MultiEscrow.json',
  );
  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  if (artifact.contractName !== 'MultiEscrow' || !Array.isArray(artifact.abi) ||
      !/^0x[0-9a-f]+$/i.test(artifact.bytecode) ||
      !/^0x[0-9a-f]+$/i.test(artifact.deployedBytecode)) {
    throw new Error(`Invalid canonical MultiEscrow artifact: ${artifactPath}`);
  }
  return artifact;
}
