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
    const [deployer, buyer] = await hre.ethers.getSigners();
    const seller = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const arbiter = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const relayer = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const caller = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const MultiEscrow = await hre.ethers.getContractFactory("MultiEscrow");
    const MockEtherSwap = await hre.ethers.getContractFactory("MockEtherSwap");
    const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
    const ERC20Swap = await hre.ethers.getContractFactory("ERC20Swap");
    const escrow = await MultiEscrow.connect(deployer).deploy();
    const swap = await MockEtherSwap.deploy();
    const token = await MockERC20.deploy("Mock USDT", "USDT", 6);
    const erc20Swap = await ERC20Swap.deploy();

    // Allow token on escrow
    await escrow.connect(deployer).setTokenAllowed(await token.getAddress(), true);

    for (const wallet of [seller, arbiter, relayer, caller]) {
      await deployer.sendTransaction({
        to: wallet.address,
        value: hre.ethers.parseEther("1"),
      });
    }

    // Mint ERC20 tokens to buyer
    const tokenAmount = 1_000_000n; // 1 USDT (6 decimals)
    await token.mint(buyer.address, tokenAmount * 10n); // 10 USDT

    const amount = hre.ethers.parseEther("1");
    const escrowFee = hre.ethers.parseEther("0.1");
    const relayFee = hre.ethers.parseEther("0.05");
    const erc20Amount = 1_000_000n; // 1 USDT
    const erc20EscrowFee = 100_000n; // 0.1 USDT
    const erc20RelayFee = 50_000n; // 0.05 USDT
    const futureUnlockAt = (await time.latest()) + 3600;
    const pastUnlockAt = (await time.latest()) - 1;

    return {
      deployer,
      escrow,
      swap,
      token,
      erc20Swap,
      buyer,
      seller,
      arbiter,
      relayer,
      caller,
      amount,
      escrowFee,
      relayFee,
      erc20Amount,
      erc20EscrowFee,
      erc20RelayFee,
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

  async function signERC20SwapClaim(
    swap: any,
    signer: any,
    escrowAddress: string,
    preimage: string,
    amount: bigint,
    tokenAddress: string,
    refundAddress: string,
    timelock: number
  ) {
    const { chainId } = await signer.provider.getNetwork();
    const signature = await signer.signTypedData(
      {
        name: "ERC20Swap",
        version: "6",
        chainId,
        verifyingContract: await swap.getAddress(),
      },
      {
        Claim: [
          { name: "preimage", type: "bytes32" },
          { name: "amount", type: "uint256" },
          { name: "tokenAddress", type: "address" },
          { name: "refundAddress", type: "address" },
          { name: "timelock", type: "uint256" },
          { name: "destination", type: "address" },
        ],
      },
      {
        preimage,
        amount,
        tokenAddress,
        refundAddress,
        timelock,
        destination: escrowAddress,
      }
    );

    return hre.ethers.Signature.from(signature);
  }

  async function createNativeTrade({
    escrow,
    buyer,
    seller,
    arbiter,
    amount,
    escrowFee,
    unlockAt,
    label,
  }: {
    escrow: any;
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
      .createTrade(
        tradeId,
        buyer.address,
        seller.address,
        arbiter.address,
        hre.ethers.ZeroAddress,
        0n,
        unlockAt,
        escrowFee,
        { value: amount }
      );
    return tradeId;
  }

  async function createERC20Trade({
    escrow,
    token,
    buyer,
    seller,
    arbiter,
    amount,
    escrowFee,
    unlockAt,
    label,
  }: {
    escrow: any;
    token: any;
    buyer: any;
    seller: any;
    arbiter: any;
    amount: bigint;
    escrowFee: bigint;
    unlockAt: number;
    label: string;
  }) {
    const tradeId = hre.ethers.id(label);
    const tokenAddress = await token.getAddress();
    await token.connect(buyer).approve(await escrow.getAddress(), amount);
    await escrow
      .connect(buyer)
      .createTrade(
        tradeId,
        buyer.address,
        seller.address,
        arbiter.address,
        tokenAddress,
        amount,
        unlockAt,
        escrowFee
      );
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
        version: "3",
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
        version: "3",
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

  // ── Native RBTC tests ──────────────────────────────────────────────

  describe("Native RBTC trades", function () {
    it("keeps direct release working with zero relay fee", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, buyer, seller, arbiter, amount, escrowFee, futureUnlockAt } = fixture;
      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "direct-release",
      });

      await expect(() =>
        escrow.connect(seller)["releaseToCounterparty(bytes32)"](tradeId)
      ).to.changeEtherBalances(
        [buyer, arbiter, escrow],
        [amount - escrowFee, escrowFee, -amount]
      );
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
      const tradeId = await createNativeTrade({
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
      const tradeId = await createNativeTrade({
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
      const tradeId = await createNativeTrade({
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
      const { escrow, buyer, seller, arbiter, relayer, amount, escrowFee, futureUnlockAt } =
        fixture;
      const tradeId = await createNativeTrade({
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
      const { escrow, swap, buyer, seller, arbiter, caller, amount, escrowFee, futureUnlockAt } =
        fixture;
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
            token: hre.ethers.ZeroAddress,
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
      expect(activeTrade.trade.token).to.equal(hre.ethers.ZeroAddress);
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
            token: hre.ethers.ZeroAddress,
            unlockAt: futureUnlockAt,
            escrowFee,
          }
        )
      ).to.be.revertedWithCustomError(escrow, "ClaimSignerNotBuyer");
    });

    it("rejects claimSwapAndFund with non-zero token in FundArgs", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, swap, buyer, seller, arbiter, token, amount, escrowFee, futureUnlockAt } =
        fixture;
      const preimage = hre.ethers.randomBytes(32);
      const preimageHex = hre.ethers.hexlify(preimage);
      const preimageHash = hre.ethers.sha256(preimage);
      const refundAddress = arbiter.address;
      const timelock = futureUnlockAt + 7200;
      const tradeId = hre.ethers.id("swap-token-mismatch");

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
            token: await token.getAddress(),
            unlockAt: futureUnlockAt,
            escrowFee,
          }
        )
      ).to.be.revertedWithCustomError(escrow, "TokenMismatch");
    });
  });

  // ── ERC20 tests ─────────────────────────────────────────────────────

  describe("ERC20 trades", function () {
    it("creates an ERC20 trade via createTrade", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, token, buyer, seller, arbiter, erc20Amount, erc20EscrowFee, futureUnlockAt } =
        fixture;

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-create",
      });

      const activeTrade = await escrow.activeTrade(tradeId);
      expect(activeTrade.isActive).to.equal(true);
      expect(activeTrade.trade.buyer).to.equal(buyer.address);
      expect(activeTrade.trade.seller).to.equal(seller.address);
      expect(activeTrade.trade.token).to.equal(await token.getAddress());
      expect(activeTrade.trade.amount).to.equal(erc20Amount);
      expect(activeTrade.trade.escrowFee).to.equal(erc20EscrowFee);
      expect(await token.balanceOf(await escrow.getAddress())).to.equal(erc20Amount);
    });

    it("direct release pays out ERC20 tokens correctly", async function () {
      const fixture = await loadFixture(deployFixture);
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        erc20Amount,
        erc20EscrowFee,
        futureUnlockAt,
      } = fixture;

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-release",
      });

      const buyerBalBefore = await token.balanceOf(buyer.address);
      const arbiterBalBefore = await token.balanceOf(arbiter.address);

      await escrow.connect(seller)["releaseToCounterparty(bytes32)"](tradeId);

      const buyerBalAfter = await token.balanceOf(buyer.address);
      const arbiterBalAfter = await token.balanceOf(arbiter.address);
      const escrowBal = await token.balanceOf(await escrow.getAddress());

      expect(buyerBalAfter - buyerBalBefore).to.equal(erc20Amount - erc20EscrowFee);
      expect(arbiterBalAfter - arbiterBalBefore).to.equal(erc20EscrowFee);
      expect(escrowBal).to.equal(0n);
    });

    it("gasless release with ERC20 pays relay fee in tokens", async function () {
      const fixture = await loadFixture(deployFixture);
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        relayer,
        caller,
        erc20Amount,
        erc20EscrowFee,
        erc20RelayFee,
        futureUnlockAt,
      } = fixture;

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-gasless-release",
      });

      const deadline = futureUnlockAt + 3600;
      const signature = await signRelease(
        escrow,
        seller,
        tradeId,
        relayer.address,
        erc20RelayFee,
        deadline
      );

      const buyerBalBefore = await token.balanceOf(buyer.address);
      const relayerBalBefore = await token.balanceOf(relayer.address);

      await escrow
        .connect(caller)
        ["releaseToCounterparty(bytes32,(address,uint256,uint256),bytes)"](
          tradeId,
          { receiver: relayer.address, amount: erc20RelayFee, deadline },
          signature
        );

      const buyerBalAfter = await token.balanceOf(buyer.address);
      const relayerBalAfter = await token.balanceOf(relayer.address);
      const arbiterBal = await token.balanceOf(arbiter.address);
      const escrowBal = await token.balanceOf(await escrow.getAddress());

      expect(buyerBalAfter - buyerBalBefore).to.equal(
        erc20Amount - erc20EscrowFee - erc20RelayFee
      );
      expect(relayerBalAfter - relayerBalBefore).to.equal(erc20RelayFee);
      expect(arbiterBal).to.equal(erc20EscrowFee);
      expect(escrowBal).to.equal(0n);
    });

    it("direct claim with ERC20 after unlock", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, token, buyer, seller, arbiter, erc20Amount, erc20EscrowFee, pastUnlockAt } =
        fixture;

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        escrowFee: erc20EscrowFee,
        unlockAt: pastUnlockAt,
        label: "erc20-claim",
      });

      const sellerBalBefore = await token.balanceOf(seller.address);

      await escrow.connect(seller)["claim(bytes32)"](tradeId);

      const sellerBalAfter = await token.balanceOf(seller.address);
      const arbiterBal = await token.balanceOf(arbiter.address);

      expect(sellerBalAfter - sellerBalBefore).to.equal(erc20Amount - erc20EscrowFee);
      expect(arbiterBal).to.equal(erc20EscrowFee);
    });

    it("gasless claim with ERC20 pays relay fee in tokens", async function () {
      const fixture = await loadFixture(deployFixture);
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        relayer,
        caller,
        erc20Amount,
        erc20EscrowFee,
        erc20RelayFee,
        pastUnlockAt,
      } = fixture;

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        escrowFee: erc20EscrowFee,
        unlockAt: pastUnlockAt,
        label: "erc20-gasless-claim",
      });

      const deadline = (await time.latest()) + 3600;
      const signature = await signClaim(
        escrow,
        seller,
        tradeId,
        relayer.address,
        erc20RelayFee,
        deadline
      );

      const sellerBalBefore = await token.balanceOf(seller.address);

      await escrow
        .connect(caller)
        ["claim(bytes32,(address,uint256,uint256),bytes)"](
          tradeId,
          { receiver: relayer.address, amount: erc20RelayFee, deadline },
          signature
        );

      const sellerBalAfter = await token.balanceOf(seller.address);
      const relayerBal = await token.balanceOf(relayer.address);
      const arbiterBal = await token.balanceOf(arbiter.address);

      expect(sellerBalAfter - sellerBalBefore).to.equal(
        erc20Amount - erc20EscrowFee - erc20RelayFee
      );
      expect(relayerBal).to.equal(erc20RelayFee);
      expect(arbiterBal).to.equal(erc20EscrowFee);
    });

    it("arbitrate splits ERC20 tokens correctly", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, token, buyer, seller, arbiter, erc20Amount, erc20EscrowFee, futureUnlockAt } =
        fixture;

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-arbitrate",
      });

      const factor = 500n; // 50% to seller
      const amountAfterFee = erc20Amount - erc20EscrowFee;
      const forwardAmount = (amountAfterFee * factor) / 1000n;
      const remainingAmount = amountAfterFee - forwardAmount;

      const sellerBalBefore = await token.balanceOf(seller.address);
      const buyerBalBefore = await token.balanceOf(buyer.address);

      await escrow.connect(arbiter).arbitrate(tradeId, factor);

      const sellerBalAfter = await token.balanceOf(seller.address);
      const buyerBalAfter = await token.balanceOf(buyer.address);
      const arbiterBal = await token.balanceOf(arbiter.address);

      expect(sellerBalAfter - sellerBalBefore).to.equal(forwardAmount);
      expect(buyerBalAfter - buyerBalBefore).to.equal(remainingAmount);
      expect(arbiterBal).to.equal(erc20EscrowFee);
    });

    it("rejects createTrade for non-allowed token", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, buyer, seller, arbiter, futureUnlockAt } = fixture;
      const FakeToken = await hre.ethers.getContractFactory("MockERC20");
      const fakeToken = await FakeToken.deploy("Fake", "FAKE", 18);
      const amount = 1000n;

      await fakeToken.mint(buyer.address, amount);
      await fakeToken.connect(buyer).approve(await escrow.getAddress(), amount);

      await expect(
        escrow.connect(buyer).createTrade(
          hre.ethers.id("bad-token"),
          buyer.address,
          seller.address,
          arbiter.address,
          await fakeToken.getAddress(),
          amount,
          futureUnlockAt,
          0n
        )
      ).to.be.revertedWithCustomError(escrow, "TokenNotAllowed");
    });

    it("rejects createTrade with ERC20 when msg.value is non-zero", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, token, buyer, seller, arbiter, erc20Amount, futureUnlockAt } = fixture;

      await token.connect(buyer).approve(await escrow.getAddress(), erc20Amount);

      await expect(
        escrow.connect(buyer).createTrade(
          hre.ethers.id("erc20-with-value"),
          buyer.address,
          seller.address,
          arbiter.address,
          await token.getAddress(),
          erc20Amount,
          futureUnlockAt,
          0n,
          { value: 1n }
        )
      ).to.be.revertedWithCustomError(escrow, "NativeNotExpected");
    });

    it("claims an ERC20 swap and funds a trade atomically", async function () {
      const fixture = await loadFixture(deployFixture);
      const {
        escrow,
        erc20Swap,
        token,
        buyer,
        seller,
        arbiter,
        caller,
        erc20Amount,
        erc20EscrowFee,
        futureUnlockAt,
      } = fixture;

      const preimage = hre.ethers.randomBytes(32);
      const preimageHex = hre.ethers.hexlify(preimage);
      const preimageHash = hre.ethers.sha256(preimage);
      const refundAddress = caller.address;
      const timelock = futureUnlockAt + 7200;
      const tradeId = hre.ethers.id("erc20-claim-swap-and-fund");
      const tokenAddress = await token.getAddress();

      // Mint tokens to buyer and lock them in the ERC20 swap
      await token.mint(buyer.address, erc20Amount);
      await token.connect(buyer).approve(await erc20Swap.getAddress(), erc20Amount);
      await erc20Swap
        .connect(buyer)
        ["lock(bytes32,uint256,address,address,address,uint256)"](preimageHash, erc20Amount, tokenAddress, buyer.address, refundAddress, timelock);

      const signature = await signERC20SwapClaim(
        erc20Swap,
        buyer,
        await escrow.getAddress(),
        preimageHex,
        erc20Amount,
        tokenAddress,
        refundAddress,
        timelock
      );

      await expect(
        escrow.connect(caller).claimERC20SwapAndFund(
          {
            swapContract: await erc20Swap.getAddress(),
            preimage: preimageHex,
            amount: erc20Amount,
            tokenAddress,
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
            token: tokenAddress,
            unlockAt: futureUnlockAt,
            escrowFee: erc20EscrowFee,
          }
        )
      ).to.emit(escrow, "TradeCreated");

      const activeTrade = await escrow.activeTrade(tradeId);
      expect(activeTrade.isActive).to.equal(true);
      expect(activeTrade.trade.token).to.equal(tokenAddress);
      expect(activeTrade.trade.amount).to.equal(erc20Amount);
      expect(await token.balanceOf(await escrow.getAddress())).to.equal(erc20Amount);
    });

    it("rejects claimERC20SwapAndFund with token mismatch", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, erc20Swap, token, buyer, seller, arbiter, caller, erc20Amount, erc20EscrowFee, futureUnlockAt } = fixture;

      // Deploy a second token
      const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
      const otherToken = await MockERC20.deploy("Other", "OTH", 6);
      const [deployer] = await hre.ethers.getSigners();
      await escrow.connect(deployer).setTokenAllowed(await otherToken.getAddress(), true);

      const preimage = hre.ethers.randomBytes(32);
      const preimageHex = hre.ethers.hexlify(preimage);
      const preimageHash = hre.ethers.sha256(preimage);
      const refundAddress = caller.address;
      const timelock = futureUnlockAt + 7200;
      const tradeId = hre.ethers.id("erc20-token-mismatch");
      const tokenAddress = await token.getAddress();

      await token.mint(buyer.address, erc20Amount);
      await token.connect(buyer).approve(await erc20Swap.getAddress(), erc20Amount);
      await erc20Swap.connect(buyer)["lock(bytes32,uint256,address,address,address,uint256)"](preimageHash, erc20Amount, tokenAddress, buyer.address, refundAddress, timelock);

      const signature = await signERC20SwapClaim(
        erc20Swap,
        buyer,
        await escrow.getAddress(),
        preimageHex,
        erc20Amount,
        tokenAddress,
        refundAddress,
        timelock
      );

      // FundArgs.token doesn't match claimArgs.tokenAddress
      await expect(
        escrow.connect(caller).claimERC20SwapAndFund(
          {
            swapContract: await erc20Swap.getAddress(),
            preimage: preimageHex,
            amount: erc20Amount,
            tokenAddress,
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
            token: await otherToken.getAddress(),
            unlockAt: futureUnlockAt,
            escrowFee: erc20EscrowFee,
          }
        )
      ).to.be.revertedWithCustomError(escrow, "TokenMismatch");
    });

    it("USDT listing: buyer locks USDT in real ERC20Swap, MultiEscrow atomically claims and funds, then seller releases", async function () {
      const fixture = await loadFixture(deployFixture);
      const {
        escrow,
        erc20Swap,
        token,
        buyer,
        seller,
        arbiter,
        caller,
        erc20Amount,
        erc20EscrowFee,
        futureUnlockAt,
      } = fixture;

      // ── 1. Buyer locks USDT in the real Boltz ERC20Swap ──
      const preimage = hre.ethers.randomBytes(32);
      const preimageHex = hre.ethers.hexlify(preimage);
      const preimageHash = hre.ethers.sha256(preimage);
      const refundAddress = caller.address;
      const timelock = futureUnlockAt + 7200;
      const tradeId = hre.ethers.id("usdt-listing-atomic");
      const tokenAddress = await token.getAddress();

      await token.mint(buyer.address, erc20Amount);
      await token.connect(buyer).approve(await erc20Swap.getAddress(), erc20Amount);
      await erc20Swap
        .connect(buyer)
        ["lock(bytes32,uint256,address,address,address,uint256)"](
          preimageHash,
          erc20Amount,
          tokenAddress,
          buyer.address,
          refundAddress,
          timelock
        );

      // Verify tokens are locked in the swap contract
      expect(await token.balanceOf(await erc20Swap.getAddress())).to.equal(erc20Amount);

      // ── 2. Buyer signs the ERC20Swap claim authorizing the escrow as destination ──
      const signature = await signERC20SwapClaim(
        erc20Swap,
        buyer,
        await escrow.getAddress(),
        preimageHex,
        erc20Amount,
        tokenAddress,
        refundAddress,
        timelock
      );

      // ── 3. Relayer calls claimERC20SwapAndFund — atomic claim + trade creation ──
      await expect(
        escrow.connect(caller).claimERC20SwapAndFund(
          {
            swapContract: await erc20Swap.getAddress(),
            preimage: preimageHex,
            amount: erc20Amount,
            tokenAddress,
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
            token: tokenAddress,
            unlockAt: futureUnlockAt,
            escrowFee: erc20EscrowFee,
          }
        )
      ).to.emit(escrow, "TradeCreated");

      // ── 4. Verify escrow state ──
      const activeTrade = await escrow.activeTrade(tradeId);
      expect(activeTrade.isActive).to.equal(true);
      expect(activeTrade.trade.buyer).to.equal(buyer.address);
      expect(activeTrade.trade.seller).to.equal(seller.address);
      expect(activeTrade.trade.arbiter).to.equal(arbiter.address);
      expect(activeTrade.trade.token).to.equal(tokenAddress);
      expect(activeTrade.trade.amount).to.equal(erc20Amount);
      expect(activeTrade.trade.escrowFee).to.equal(erc20EscrowFee);
      expect(await token.balanceOf(await escrow.getAddress())).to.equal(erc20Amount);
      expect(await token.balanceOf(await erc20Swap.getAddress())).to.equal(0n);

      // ── 5. Seller releases USDT to buyer, completing the trade ──
      const buyerBalBefore = await token.balanceOf(buyer.address);
      const arbiterBalBefore = await token.balanceOf(arbiter.address);

      await escrow.connect(seller)["releaseToCounterparty(bytes32)"](tradeId);

      const buyerBalAfter = await token.balanceOf(buyer.address);
      const arbiterBalAfter = await token.balanceOf(arbiter.address);
      const escrowBalFinal = await token.balanceOf(await escrow.getAddress());

      expect(buyerBalAfter - buyerBalBefore).to.equal(erc20Amount - erc20EscrowFee);
      expect(arbiterBalAfter - arbiterBalBefore).to.equal(erc20EscrowFee);
      expect(escrowBalFinal).to.equal(0n);

      // Trade should no longer be active
      const finalTrade = await escrow.activeTrade(tradeId);
      expect(finalTrade.isActive).to.equal(false);
    });
  });

  // ── Admin tests ─────────────────────────────────────────────────────

  describe("Admin", function () {
    it("allows owner to set token allowlist", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, deployer } = fixture;
      const addr = "0x0000000000000000000000000000000000001234";

      await expect(escrow.connect(deployer).setTokenAllowed(addr, true))
        .to.emit(escrow, "TokenAllowlistUpdated")
        .withArgs(addr, true);

      expect(await escrow.allowedTokens(addr)).to.equal(true);

      await escrow.connect(deployer).setTokenAllowed(addr, false);
      expect(await escrow.allowedTokens(addr)).to.equal(false);
    });

    it("rejects non-owner from setting token allowlist", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, buyer } = fixture;
      const addr = "0x0000000000000000000000000000000000001234";

      await expect(
        escrow.connect(buyer).setTokenAllowed(addr, true)
      ).to.be.revertedWithCustomError(escrow, "OnlyOwner");
    });

    it("allows owner to transfer ownership", async function () {
      const fixture = await loadFixture(deployFixture);
      const { escrow, deployer, buyer } = fixture;

      await escrow.connect(deployer).transferOwnership(buyer.address);
      expect(await escrow.owner()).to.equal(buyer.address);
    });
  });
});
