import { expect } from 'chai';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import hre from 'hardhat';
import { readCanonicalEscrowArtifact } from '../task/artifact.js';
import { deployEscrow } from '../task/deploy.js';

describe('Hostr deployment', () => {
  it('replaces the selected deployment with canonical bytecode and preserves other networks', async () => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'hostr-escrow-deploy-'));
    const addressFile = path.join(directory, 'addresses.json');
    const previousPath = process.env.ADDRESS_FILE;
    const retained = { MultiEscrow: '0x1111111111111111111111111111111111111111' };
    fs.writeFileSync(addressFile, JSON.stringify({ 'mainnet.42161': retained, 'hardhat.31337': retained }));
    process.env.ADDRESS_FILE = addressFile;
    const connection = await hre.network.create('hardhat');
    try {
      await deployEscrow(connection);
      const addresses = JSON.parse(fs.readFileSync(addressFile, 'utf8'));
      expect(addresses['mainnet.42161']).to.deep.equal(retained);
      expect(addresses['hardhat.31337'].MultiEscrow).not.to.equal(retained.MultiEscrow);
      const deployed: any = await connection.ethers.getContractAt(
        readCanonicalEscrowArtifact().abi,
        addresses['hardhat.31337'].MultiEscrow,
      );
      const domain = await deployed.eip712Domain();
      expect(domain.name).to.equal('Nostr MultiEscrow');
      expect(domain.version).to.equal('7');
    } finally {
      await connection.close();
      if (previousPath === undefined) delete process.env.ADDRESS_FILE;
      else process.env.ADDRESS_FILE = previousPath;
      fs.rmSync(directory, { recursive: true, force: true });
    }
  });
});
