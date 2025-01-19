import hre from "hardhat";
async function main() {
  const ethers = hre.ethers;

  // Get the signer (default account)
  const [sender] = await ethers.getSigners();

  const contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const tradeId = "0x1234"; // Example trade ID

  const MultiEscrow = await ethers.getContractFactory("MultiEscrow");
  const multiEscrow = await MultiEscrow.attach(contractAddress);
  console.log(multiEscrow);

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
  const tx = await sender.sendTransaction({
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
