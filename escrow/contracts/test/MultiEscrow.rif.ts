import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("MultiEscrow RIF compatibility", function () {
  const noRelayFeeQuote = {
    receiver: hre.ethers.ZeroAddress,
    amount: 0n,
    deadline: 0,
  };

  async function deployFixture() {
    const [buyer] = await hre.ethers.getSigners();
    const seller = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const arbiter = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const relayer = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const caller = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const MultiEscrow = await hre.ethers.getContractFactory("MultiEscrow");
    const MockEtherSwap = await hre.ethers.getContractFactory("MockEtherSwap");
    const escrow = await MultiEscrow.deploy();
    const swap = await MockEtherSwap.deploy();

    for (const wallet of [seller, arbiter, relayer, caller]) {
      await buyer.sendTransaction({
        to: wallet.address,
        value: hre.ethers.parseEther("1"),
      });
    }

    const amount = hre.ethers.parseEther("1");
    const escrowFee = hre.ethers.parseEther("0.1");
    const relayFee = hre.ethers.parseEther("0.05");
    const futureUnlockAt = (await time.latest()) + 3600;
    const pastUnlockAt = (await time.latest()) - 1;

    return {
      escrow,
      swap,
      buyer,
      seller,
      arbiter,
      relayer,
      caller,
      amount,
      escrowFee,
      relayFee,
      futureUnlockAt,
      pastUnlockAt,
    };
  }

  async function signSwapClaim(
    swap: any,
    signer: any,
    escrowAddress: string,
    preimage: string,
    amount: bigint,
    refundAddress: string,
    timelock: number
  ) {
    const { chainId } = await signer.provider.getNetwork();
    const signature = await signer.signTypedData(
      {
        name: "MockEtherSwap",
        version: "1",
        chainId,
        verifyingContract: await swap.getAddress(),
      },
      {
        Claim: [
          { name: "preimage", type: "bytes32" },
          { name: "amount", type: "uint256" },
          { name: "refundAddress", type: "address" },
          { name: "timelock", type: "uint256" },
          { name: "destination", type: "address" },
        ],
      },
      {
        preimage,
        amount,
        refundAddress,
        timelock,
        destination: escrowAddress,
      }
    );

    return hre.ethers.Signature.from(signature);
  }

  async function createTrade({
    escrow,
    buyer,
    seller,
    arbiter,
    amount,
    escrowFee,
    unlockAt,
    label,
  }: {
    escrow: Awaited<ReturnType<typeof hre.ethers.getContractFactory>> extends never ? never : any;
    buyer: any;
    seller: any;
    arbiter: any;
    amount: bigint;
    escrowFee: bigint;
    unlockAt: number;
    label: string;
  }) {
    const tradeId = hre.ethers.id(label);
    await escrow
      .connect(buyer)
      .createTrade(tradeId, buyer.address, seller.address, arbiter.address, unlockAt, escrowFee, {
        value: amount,
      });
    return tradeId;
  }

  async function signRelease(
    escrow: any,
    signer: any,
    tradeId: string,
    feeReceiver: string,
    feeAmount: bigint,
    deadline: number
  ) {
    const { chainId } = await signer.provider.getNetwork();
    return signer.signTypedData(
      {
        name: "Hostr MultiEscrow",
        version: "2",
        chainId,
        verifyingContract: await escrow.getAddress(),
      },
      {
        RelayFeeQuote: [
          { name: "receiver", type: "address" },
          { name: "amount", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
        ReleaseAuthorization: [
          { name: "tradeId", type: "bytes32" },
          { name: "relayFeeQuote", type: "RelayFeeQuote" },
        ],
      },
      {
        tradeId,
        relayFeeQuote: {
          receiver: feeReceiver,
          amount: feeAmount,
          deadline,
        },
      }
    );
  }

  async function signClaim(
    escrow: any,
    signer: any,
    tradeId: string,
    feeReceiver: string,
    feeAmount: bigint,
    deadline: number
  ) {
    const { chainId } = await signer.provider.getNetwork();
    return signer.signTypedData(
      {
        name: "Hostr MultiEscrow",
        version: "2",
        chainId,
        verifyingContract: await escrow.getAddress(),
      },
      {
        RelayFeeQuote: [
          { name: "receiver", type: "address" },
          { name: "amount", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
        ClaimAuthorization: [
          { name: "tradeId", type: "bytes32" },
          { name: "relayFeeQuote", type: "RelayFeeQuote" },
        ],
      },
      {
        tradeId,
        relayFeeQuote: {
          receiver: feeReceiver,
          amount: feeAmount,
          deadline,
        },
      }
    );
  }

  it("keeps direct release working with zero relay fee", async function () {
    const fixture = await loadFixture(deployFixture);
    const { escrow, buyer, seller, arbiter, amount, escrowFee, futureUnlockAt } = fixture;
    const tradeId = await createTrade({
      escrow,
      buyer,
      seller,
      arbiter,
      amount,
      escrowFee,
      unlockAt: futureUnlockAt,
      label: "direct-release",
    });

    await expect(() => escrow.connect(seller)["releaseToCounterparty(bytes32)"](tradeId)).to.changeEtherBalances(
      [buyer, arbiter, escrow],
      [amount - escrowFee, escrowFee, -amount]
    );

    expect(noRelayFeeQuote.amount).to.equal(0n);
  });

  it("allows seller-signed gasless release and pays the relay receiver", async function () {
    const fixture = await loadFixture(deployFixture);
    const {
      escrow,
      buyer,
      seller,
      arbiter,
      relayer,
      caller,
      amount,
      escrowFee,
      relayFee,
      futureUnlockAt,
    } = fixture;
    const tradeId = await createTrade({
      escrow,
      buyer,
      seller,
      arbiter,
      amount,
      escrowFee,
      unlockAt: futureUnlockAt,
      label: "gasless-release",
    });

    const deadline = futureUnlockAt + 3600;
    const signature = await signRelease(
      escrow,
      seller,
      tradeId,
      relayer.address,
      relayFee,
      deadline
    );
    const relayFeeQuote = {
      receiver: relayer.address,
      amount: relayFee,
      deadline,
    };

    await expect(() =>
      escrow
        .connect(caller)
        ["releaseToCounterparty(bytes32,(address,uint256,uint256),bytes)"](
          tradeId,
          relayFeeQuote,
          signature
        )
    ).to.changeEtherBalances(
      [buyer, arbiter, relayer, escrow],
      [amount - escrowFee - relayFee, escrowFee, relayFee, -amount]
    );
  });

  it("allows seller-signed gasless claim after unlock and pays the relay receiver", async function () {
    const fixture = await loadFixture(deployFixture);
    const {
      escrow,
      buyer,
      seller,
      arbiter,
      relayer,
      caller,
      amount,
      escrowFee,
      relayFee,
      pastUnlockAt,
    } = fixture;
    const tradeId = await createTrade({
      escrow,
      buyer,
      seller,
      arbiter,
      amount,
      escrowFee,
      unlockAt: pastUnlockAt,
      label: "gasless-claim",
    });

    const deadline = (await time.latest()) + 3600;
    const signature = await signClaim(
      escrow,
      seller,
      tradeId,
      relayer.address,
      relayFee,
      deadline
    );
    const relayFeeQuote = {
      receiver: relayer.address,
      amount: relayFee,
      deadline,
    };

    await expect(() =>
      escrow
        .connect(caller)
        ["claim(bytes32,(address,uint256,uint256),bytes)"](
          tradeId,
          relayFeeQuote,
          signature
        )
    ).to.changeEtherBalances(
      [seller, arbiter, relayer, escrow],
      [amount - escrowFee - relayFee, escrowFee, relayFee, -amount]
    );
  });

  it("rejects gasless claim signatures not made by the seller", async function () {
    const fixture = await loadFixture(deployFixture);
    const { escrow, buyer, seller, arbiter, relayer, amount, escrowFee, pastUnlockAt } = fixture;
    const tradeId = await createTrade({
      escrow,
      buyer,
      seller,
      arbiter,
      amount,
      escrowFee,
      unlockAt: pastUnlockAt,
      label: "bad-claim-signer",
    });

    const deadline = (await time.latest()) + 3600;
    const signature = await signClaim(
      escrow,
      buyer,
      tradeId,
      relayer.address,
      1n,
      deadline
    );

    await expect(
      escrow["claim(bytes32,(address,uint256,uint256),bytes)"](
        tradeId,
        {
          receiver: relayer.address,
          amount: 1n,
          deadline,
        },
        signature
      )
    ).to.be.revertedWithCustomError(escrow, "OnlySeller");
  });

  it("rejects expired gasless release authorizations", async function () {
    const fixture = await loadFixture(deployFixture);
    const { escrow, buyer, seller, arbiter, relayer, amount, escrowFee, futureUnlockAt } = fixture;
    const tradeId = await createTrade({
      escrow,
      buyer,
      seller,
      arbiter,
      amount,
      escrowFee,
      unlockAt: futureUnlockAt,
      label: "expired-release",
    });

    const deadline = (await time.latest()) - 1;
    const signature = await signRelease(
      escrow,
      seller,
      tradeId,
      relayer.address,
      1n,
      deadline
    );

    await expect(
      escrow["releaseToCounterparty(bytes32,(address,uint256,uint256),bytes)"](
        tradeId,
        {
          receiver: relayer.address,
          amount: 1n,
          deadline,
        },
        signature
      )
    ).to.be.revertedWithCustomError(escrow, "SignatureExpired");
  });

  it("claims a swap and funds a trade atomically", async function () {
    const fixture = await loadFixture(deployFixture);
    const { escrow, swap, buyer, seller, arbiter, caller, amount, escrowFee, futureUnlockAt } = fixture;
    const preimage = hre.ethers.randomBytes(32);
    const preimageHex = hre.ethers.hexlify(preimage);
    const preimageHash = hre.ethers.sha256(preimage);
    const refundAddress = caller.address;
    const timelock = futureUnlockAt + 7200;
    const tradeId = hre.ethers.id("claim-swap-and-fund");

    await swap.lock(preimageHash, amount, buyer.address, refundAddress, timelock, {
      value: amount,
    });

    const signature = await signSwapClaim(
      swap,
      buyer,
      await escrow.getAddress(),
      preimageHex,
      amount,
      refundAddress,
      timelock
    );

    await expect(
      escrow.connect(caller).claimSwapAndFund(
        {
          swapContract: await swap.getAddress(),
          preimage: preimageHex,
          amount,
          refundAddress,
          timelock,
          v: signature.v,
          r: signature.r,
          s: signature.s,
        },
        {
          tradeId,
          buyer: buyer.address,
          seller: seller.address,
          arbiter: arbiter.address,
          unlockAt: futureUnlockAt,
          escrowFee,
        }
      )
    ).to.emit(escrow, "TradeCreated");

    const activeTrade = await escrow.activeTrade(tradeId);
    expect(activeTrade.isActive).to.equal(true);
    expect(activeTrade.trade.buyer).to.equal(buyer.address);
    expect(activeTrade.trade.seller).to.equal(seller.address);
    expect(activeTrade.trade.arbiter).to.equal(arbiter.address);
    expect(activeTrade.trade.amount).to.equal(amount);
    expect(activeTrade.trade.unlockAt).to.equal(futureUnlockAt);
    expect(activeTrade.trade.escrowFee).to.equal(escrowFee);
    expect(await hre.ethers.provider.getBalance(await escrow.getAddress())).to.equal(amount);
  });

  it("rejects claimSwapAndFund when the swap signer is not the funded buyer", async function () {
    const fixture = await loadFixture(deployFixture);
    const { escrow, swap, buyer, seller, arbiter, amount, escrowFee, futureUnlockAt } = fixture;
    const preimage = hre.ethers.randomBytes(32);
    const preimageHex = hre.ethers.hexlify(preimage);
    const preimageHash = hre.ethers.sha256(preimage);
    const refundAddress = arbiter.address;
    const timelock = futureUnlockAt + 7200;
    const tradeId = hre.ethers.id("claim-signer-not-buyer");

    await swap.lock(preimageHash, amount, seller.address, refundAddress, timelock, {
      value: amount,
    });

    const signature = await signSwapClaim(
      swap,
      seller,
      await escrow.getAddress(),
      preimageHex,
      amount,
      refundAddress,
      timelock
    );

    await expect(
      escrow.claimSwapAndFund(
        {
          swapContract: await swap.getAddress(),
          preimage: preimageHex,
          amount,
          refundAddress,
          timelock,
          v: signature.v,
          r: signature.r,
          s: signature.s,
        },
        {
          tradeId,
          buyer: buyer.address,
          seller: seller.address,
          arbiter: arbiter.address,
          unlockAt: futureUnlockAt,
          escrowFee,
        }
      )
    ).to.be.revertedWithCustomError(escrow, "ClaimSignerNotBuyer");
  });
});
