import hre from "hardhat";
import { MultiEscrow } from "../typechain-types"; // adjust the path if needed

async function main() {
  const ethers = hre.ethers;

  // Get the signer (default account)
  let [escrow, buyer, seller] = await ethers.getSigners();
  seller = seller || {address: '0x164919857a1eaB16c789683f19Df4B218b829416'};
  const contractAddress = "0xE72544c0fa4dE04faecac9EAcC06c0790f168A5a";
  const tradeId = "0x1234"; // Example trade ID

  const MultiEscrowFactory = await ethers.getContractFactory("MultiEscrow");
  const multiEscrow = await MultiEscrowFactory.attach(contractAddress) as MultiEscrow;
  console.log(
    tradeId,
    buyer.address,
    seller.address,
    escrow.address,
    1000,
    100
  );
  multiEscrow.createTrade(
    tradeId,
    buyer.address,
    seller.address,
    escrow.address,
    1000,
    100,
    {value: ethers.parseEther("1.0") } 
  );

  // Fetch logs for the contract
  const filter = {
    address: contractAddress,
    fromBlock: 0,
    toBlock: "latest",
  };

  const logs = await ethers.provider.getLogs(filter);
  for (const log of logs) {
    try {
      const parsedLog = multiEscrow.interface.parseLog(log);
      console.log("Parsed log:", parsedLog);
    } catch (error) {
      console.log("Error parsing log:", error);
    }
  }

  // Define the recipient address and amount to send (in wei)
  const recipient = "0x164919857a1eaB16c789683f19Df4B218b829416"; // Replace with the recipient's address
  const amount = ethers.parseEther("10.0"); // Sending 1 ETH

  // Send the transaction
  const tx = await escrow.sendTransaction({
    to: recipient,
    value: amount,
  });

  // Wait for the transaction to be mined
  await tx.wait();

  console.log(`Sent ${ethers.formatEther(amount)} ETH to ${recipient}`);
  console.log(`Transaction hash: ${tx.hash}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
