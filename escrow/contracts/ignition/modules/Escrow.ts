// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const EscrowModule = buildModule("EscrowModule", (m) => {
  const multiEscrow = m.contract("MultiEscrow", [], {});

  return { multiEscrow };
});

export default EscrowModule;
