import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

const RELEASE_TYPES = {
  Release: [
    { name: "tradeId", type: "bytes32" },
    { name: "actor", type: "address" },
  ],
};

const CLAIM_TYPES = {
  Claim: [{ name: "tradeId", type: "bytes32" }],
};

const ARBITRATE_TYPES = {
  Arbitrate: [
    { name: "tradeId", type: "bytes32" },
    { name: "paymentFactor", type: "uint256" },
    { name: "bondFactor", type: "uint256" },
  ],
};

const WITHDRAW_TYPES = {
  Withdraw: [
    { name: "token", type: "address" },
    { name: "destination", type: "address" },
  ],
};

describe("MultiEscrow", function () {
  async function deployFixture() {
    const [deployer, buyer] = await hre.ethers.getSigners();
    const seller = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const arbiter = hre.ethers.Wallet.createRandom().connect(hre.ethers.provider);
    const MultiEscrow = await hre.ethers.getContractFactory("MultiEscrow");
    const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
    const escrow = await MultiEscrow.connect(deployer).deploy();
    const token = await MockERC20.deploy("Mock USDT", "USDT", 6);

    for (const wallet of [seller, arbiter]) {
      await deployer.sendTransaction({
        to: wallet.address,
        value: hre.ethers.parseEther("1"),
      });
    }

    // Mint ERC20 tokens to buyer
    const tokenAmount = 1_000_000n; // 1 USDT (6 decimals)
    await token.mint(buyer.address, tokenAmount * 10n); // 10 USDT

    const amount = hre.ethers.parseEther("1");
    const bondAmount = hre.ethers.parseEther("0.5");
    const escrowFee = hre.ethers.parseEther("0.1");
    const erc20Amount = 1_000_000n; // 1 USDT
    const erc20BondAmount = 500_000n; // 0.5 USDT
    const erc20EscrowFee = 100_000n; // 0.1 USDT
    const futureUnlockAt = (await time.latest()) + 3600;
    const pastUnlockAt = (await time.latest()) - 1;

    // Pull domain from deployed contract via EIP-5267 eip712Domain()
    const [, name, version, chainId, verifyingContract] =
      await escrow.eip712Domain();
    const domain = { name, version, chainId, verifyingContract };

    return {
      deployer,
      escrow,
      token,
      buyer,
      seller,
      arbiter,
      amount,
      bondAmount,
      escrowFee,
      erc20Amount,
      erc20BondAmount,
      erc20EscrowFee,
      futureUnlockAt,
      pastUnlockAt,
      domain,
    };
  }

  // ── Helpers ──────────────────────────────────────────────────────

  async function createNativeTrade({
    escrow,
    buyer,
    seller,
    arbiter,
    amount,
    bondAmount,
    escrowFee,
    unlockAt,
    label,
  }: {
    escrow: any;
    buyer: any;
    seller: any;
    arbiter: any;
    amount: bigint;
    bondAmount: bigint;
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
        amount,
        bondAmount,
        unlockAt,
        escrowFee,
        { value: amount + bondAmount }
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
    bondAmount,
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
    bondAmount: bigint;
    escrowFee: bigint;
    unlockAt: number;
    label: string;
  }) {
    const tradeId = hre.ethers.id(label);
    const tokenAddress = await token.getAddress();
    await token.connect(buyer).approve(await escrow.getAddress(), amount + bondAmount);
    await escrow
      .connect(buyer)
      .createTrade(
        tradeId,
        buyer.address,
        seller.address,
        arbiter.address,
        tokenAddress,
        amount,
        bondAmount,
        unlockAt,
        escrowFee
      );
    return tradeId;
  }

  async function signRelease(
    signer: any,
    domain: any,
    tradeId: string,
    actor: string
  ) {
    return signer.signTypedData(domain, RELEASE_TYPES, { tradeId, actor });
  }

  async function signClaim(signer: any, domain: any, tradeId: string) {
    return signer.signTypedData(domain, CLAIM_TYPES, { tradeId });
  }

  async function signArbitrate(
    signer: any,
    domain: any,
    tradeId: string,
    paymentFactor: bigint,
    bondFactor: bigint
  ) {
    return signer.signTypedData(domain, ARBITRATE_TYPES, { tradeId, paymentFactor, bondFactor });
  }

  async function signWithdraw(
    signer: any,
    domain: any,
    token: string,
    destination: string
  ) {
    return signer.signTypedData(domain, WITHDRAW_TYPES, { token, destination });
  }

  // ── Native RBTC tests ──────────────────────────────────────────────

  describe("Native RBTC trades", function () {
    it("release credits buyer balance", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "native-release",
      });

      const sig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, sig);

      // Buyer should have balance credited (seller released → buyer receives)
      const buyerBal = await escrow.balances(buyer.address, hre.ethers.ZeroAddress);
      const arbiterBal = await escrow.balances(arbiter.address, hre.ethers.ZeroAddress);
      expect(buyerBal).to.equal(amount + bondAmount - escrowFee);
      expect(arbiterBal).to.equal(escrowFee);
    });

    it("claim credits seller balance after unlock", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, pastUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: pastUnlockAt,
        label: "native-claim",
      });

      const sig = await signClaim(seller, domain, tradeId);
      await escrow.claim(tradeId, sig);

      // claim: payment-fee → seller, bond → buyer
      const sellerBal = await escrow.balances(seller.address, hre.ethers.ZeroAddress);
      const buyerBal = await escrow.balances(buyer.address, hre.ethers.ZeroAddress);
      const arbiterBal = await escrow.balances(arbiter.address, hre.ethers.ZeroAddress);
      expect(sellerBal).to.equal(amount - escrowFee);
      expect(buyerBal).to.equal(bondAmount);
      expect(arbiterBal).to.equal(escrowFee);
    });

    it("arbitrate splits native balances correctly", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "native-arbitrate",
      });

      const paymentFactor = 700n; // 70% of payment to seller
      const bondFactor = 0n;      // 0% of bond to seller (full refund to buyer)
      const paymentAfterFee = amount - escrowFee;
      const sellerPayment = (paymentAfterFee * paymentFactor) / 1000n;
      const buyerPayment  = paymentAfterFee - sellerPayment;
      const sellerBond = (bondAmount * bondFactor) / 1000n;
      const buyerBond  = bondAmount - sellerBond;

      const sig = await signArbitrate(arbiter, domain, tradeId, paymentFactor, bondFactor);
      await escrow.arbitrate(tradeId, paymentFactor, bondFactor, sig);

      expect(await escrow.balances(seller.address, hre.ethers.ZeroAddress)).to.equal(sellerPayment + sellerBond);
      expect(await escrow.balances(buyer.address, hre.ethers.ZeroAddress)).to.equal(buyerPayment + buyerBond);
      expect(await escrow.balances(arbiter.address, hre.ethers.ZeroAddress)).to.equal(escrowFee);
    });

    it("withdraw sends native RBTC to destination", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "native-withdraw",
      });

      // Release → credits buyer
      const releaseSig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, releaseSig);

      const expectedBuyerBal = amount + bondAmount - escrowFee;
      expect(await escrow.balances(buyer.address, hre.ethers.ZeroAddress)).to.equal(expectedBuyerBal);

      // Withdraw buyer balance to buyer's own address
      const withdrawSig = await signWithdraw(
        buyer,
        domain,
        hre.ethers.ZeroAddress,
        buyer.address
      );

      await expect(
        escrow.withdraw(hre.ethers.ZeroAddress, buyer.address, buyer.address, withdrawSig)
      )
        .to.emit(escrow, "Withdrawn")
        .withArgs(buyer.address, hre.ethers.ZeroAddress, buyer.address, expectedBuyerBal);

      expect(await escrow.balances(buyer.address, hre.ethers.ZeroAddress)).to.equal(0n);
    });

    it("withdraw reverts when balance is zero", async function () {
      const { escrow, buyer, domain } = await loadFixture(deployFixture);

      const sig = await signWithdraw(buyer, domain, hre.ethers.ZeroAddress, buyer.address);

      await expect(
        escrow.withdraw(hre.ethers.ZeroAddress, buyer.address, buyer.address, sig)
      ).to.be.revertedWithCustomError(escrow, "NothingToWithdraw");
    });

    it("withdraw rejects invalid signature", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "native-bad-sig",
      });

      const releaseSig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, releaseSig);

      // Seller tries to sign withdraw for buyer's balance
      const badSig = await signWithdraw(seller, domain, hre.ethers.ZeroAddress, seller.address);

      await expect(
        escrow.withdraw(hre.ethers.ZeroAddress, buyer.address, seller.address, badSig)
      ).to.be.revertedWithCustomError(escrow, "InvalidSignature");
    });
  });

  // ── balanceOf view ─────────────────────────────────────────────────

  describe("balanceOf", function () {
    it("returns empty arrays when user has no balances", async function () {
      const { escrow, buyer } = await loadFixture(deployFixture);
      const result = await escrow.balanceOf(buyer.address);
      expect(result.tokens).to.deep.equal([]);
      expect(result.amounts).to.deep.equal([]);
    });

    it("returns native balance after settlement", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "balanceof-native",
      });

      const sig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, sig);

      const result = await escrow.balanceOf(buyer.address);
      expect(result.tokens).to.deep.equal([hre.ethers.ZeroAddress]);
      expect(result.amounts).to.deep.equal([amount + bondAmount - escrowFee]);
    });

    it("returns multiple tokens after mixed settlements", async function () {
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        erc20Amount,
        erc20BondAmount,
        erc20EscrowFee,
        futureUnlockAt,
        domain,
      } = await loadFixture(deployFixture);

      // Native trade → release
      const nativeTradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "multi-native",
      });
      const relSig1 = await signRelease(seller, domain, nativeTradeId, seller.address);
      await escrow.releaseToCounterparty(nativeTradeId, seller.address, relSig1);

      // ERC20 trade → release
      const erc20TradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: erc20BondAmount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "multi-erc20",
      });
      const relSig2 = await signRelease(seller, domain, erc20TradeId, seller.address);
      await escrow.releaseToCounterparty(erc20TradeId, seller.address, relSig2);

      // Buyer has both native + erc20 balances
      const result = await escrow.balanceOf(buyer.address);
      expect(result.tokens.length).to.equal(2);

      const tokenAddress = await token.getAddress();
      const nativeIdx = result.tokens.indexOf(hre.ethers.ZeroAddress);
      const erc20Idx = result.tokens.indexOf(tokenAddress);
      expect(nativeIdx).to.be.gte(0);
      expect(erc20Idx).to.be.gte(0);
      expect(result.amounts[nativeIdx]).to.equal(amount + bondAmount - escrowFee);
      expect(result.amounts[erc20Idx]).to.equal(erc20Amount + erc20BondAmount - erc20EscrowFee);
    });

    it("balance disappears after withdraw", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "balanceof-withdraw",
      });

      const relSig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, relSig);

      const wSig = await signWithdraw(buyer, domain, hre.ethers.ZeroAddress, buyer.address);
      await escrow.withdraw(hre.ethers.ZeroAddress, buyer.address, buyer.address, wSig);

      const result = await escrow.balanceOf(buyer.address);
      expect(result.tokens).to.deep.equal([]);
      expect(result.amounts).to.deep.equal([]);
    });
  });

  // ── ERC20 tests ─────────────────────────────────────────────────────

  describe("ERC20 trades", function () {
    it("creates an ERC20 trade via createTrade", async function () {
      const { escrow, token, buyer, seller, arbiter, erc20Amount, erc20BondAmount, erc20EscrowFee, futureUnlockAt } =
        await loadFixture(deployFixture);

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: erc20BondAmount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-create",
      });

      const activeTrade = await escrow.activeTrade(tradeId);
      expect(activeTrade.isActive).to.equal(true);
      expect(activeTrade.trade.buyer).to.equal(buyer.address);
      expect(activeTrade.trade.seller).to.equal(seller.address);
      expect(activeTrade.trade.token).to.equal(await token.getAddress());
      expect(activeTrade.trade.paymentAmount).to.equal(erc20Amount);
      expect(activeTrade.trade.bondAmount).to.equal(erc20BondAmount);
      expect(activeTrade.trade.escrowFee).to.equal(erc20EscrowFee);
      expect(await token.balanceOf(await escrow.getAddress())).to.equal(erc20Amount + erc20BondAmount);
    });

    it("release credits buyer ERC20 balance", async function () {
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        erc20Amount,
        erc20BondAmount,
        erc20EscrowFee,
        futureUnlockAt,
        domain,
      } = await loadFixture(deployFixture);

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: erc20BondAmount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-release",
      });

      const sig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, sig);

      const tokenAddress = await token.getAddress();
      const buyerBal = await escrow.balances(buyer.address, tokenAddress);
      const arbiterBal = await escrow.balances(arbiter.address, tokenAddress);
      expect(buyerBal).to.equal(erc20Amount + erc20BondAmount - erc20EscrowFee);
      expect(arbiterBal).to.equal(erc20EscrowFee);
    });

    it("withdraw sends ERC20 tokens to destination", async function () {
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        erc20Amount,
        erc20BondAmount,
        erc20EscrowFee,
        futureUnlockAt,
        domain,
      } = await loadFixture(deployFixture);

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: erc20BondAmount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-withdraw",
      });

      const relSig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, relSig);

      const tokenAddress = await token.getAddress();
      const expectedBuyerBal = erc20Amount + erc20BondAmount - erc20EscrowFee;

      const buyerTokenBefore = await token.balanceOf(buyer.address);

      const wSig = await signWithdraw(buyer, domain, tokenAddress, buyer.address);
      await escrow.withdraw(tokenAddress, buyer.address, buyer.address, wSig);

      const buyerTokenAfter = await token.balanceOf(buyer.address);
      expect(buyerTokenAfter - buyerTokenBefore).to.equal(expectedBuyerBal);
      expect(await escrow.balances(buyer.address, tokenAddress)).to.equal(0n);
    });

    it("claim credits seller with ERC20 after unlock", async function () {
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        erc20Amount,
        erc20BondAmount,
        erc20EscrowFee,
        pastUnlockAt,
        domain,
      } = await loadFixture(deployFixture);

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: erc20BondAmount,
        escrowFee: erc20EscrowFee,
        unlockAt: pastUnlockAt,
        label: "erc20-claim",
      });

      const sig = await signClaim(seller, domain, tradeId);
      await escrow.claim(tradeId, sig);

      const tokenAddress = await token.getAddress();
      const sellerBal = await escrow.balances(seller.address, tokenAddress);
      const buyerBal = await escrow.balances(buyer.address, tokenAddress);
      const arbiterBal = await escrow.balances(arbiter.address, tokenAddress);
      expect(sellerBal).to.equal(erc20Amount - erc20EscrowFee);
      expect(buyerBal).to.equal(erc20BondAmount);
      expect(arbiterBal).to.equal(erc20EscrowFee);
    });

    it("arbitrate splits ERC20 balances correctly", async function () {
      const {
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        erc20Amount,
        erc20BondAmount,
        erc20EscrowFee,
        futureUnlockAt,
        domain,
      } = await loadFixture(deployFixture);

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: erc20BondAmount,
        escrowFee: erc20EscrowFee,
        unlockAt: futureUnlockAt,
        label: "erc20-arbitrate",
      });

      const paymentFactor = 500n; // 50% of payment to seller
      const bondFactor = 200n;    // 20% of bond to seller
      const paymentAfterFee = erc20Amount - erc20EscrowFee;
      const sellerPayment = (paymentAfterFee * paymentFactor) / 1000n;
      const buyerPayment  = paymentAfterFee - sellerPayment;
      const sellerBond = (erc20BondAmount * bondFactor) / 1000n;
      const buyerBond  = erc20BondAmount - sellerBond;

      const sig = await signArbitrate(arbiter, domain, tradeId, paymentFactor, bondFactor);
      await escrow.arbitrate(tradeId, paymentFactor, bondFactor, sig);

      const tokenAddress = await token.getAddress();
      expect(await escrow.balances(seller.address, tokenAddress)).to.equal(sellerPayment + sellerBond);
      expect(await escrow.balances(buyer.address, tokenAddress)).to.equal(buyerPayment + buyerBond);
      expect(await escrow.balances(arbiter.address, tokenAddress)).to.equal(erc20EscrowFee);
    });

    it("rejects createTrade with ERC20 when msg.value is non-zero", async function () {
      const { escrow, token, buyer, seller, arbiter, erc20Amount, futureUnlockAt } =
        await loadFixture(deployFixture);

      await token.connect(buyer).approve(await escrow.getAddress(), erc20Amount);

      await expect(
        escrow.connect(buyer).createTrade(
          hre.ethers.id("erc20-with-value"),
          buyer.address,
          seller.address,
          arbiter.address,
          await token.getAddress(),
          erc20Amount,
          0n,
          futureUnlockAt,
          0n,
          { value: 1n }
        )
      ).to.be.revertedWithCustomError(escrow, "NativeNotExpected");
    });
  });

  // ── Security deposit (bond) tests ────────────────────────────────────

  describe("Security deposit (bond)", function () {
    it("creates a trade with zero bond", async function () {
      const { escrow, buyer, seller, arbiter, amount, escrowFee, futureUnlockAt } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount: 0n,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "zero-bond-create",
      });

      const activeTrade = await escrow.activeTrade(tradeId);
      expect(activeTrade.isActive).to.equal(true);
      expect(activeTrade.trade.paymentAmount).to.equal(amount);
      expect(activeTrade.trade.bondAmount).to.equal(0n);
    });

    it("release with zero bond credits only payment to buyer", async function () {
      const { escrow, buyer, seller, arbiter, amount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount: 0n,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "zero-bond-release",
      });

      const sig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, sig);

      const buyerBal = await escrow.balances(buyer.address, hre.ethers.ZeroAddress);
      const arbiterBal = await escrow.balances(arbiter.address, hre.ethers.ZeroAddress);
      expect(buyerBal).to.equal(amount - escrowFee);
      expect(arbiterBal).to.equal(escrowFee);
    });

    it("claim with zero bond sends all payment to seller", async function () {
      const { escrow, buyer, seller, arbiter, amount, escrowFee, pastUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount: 0n,
        escrowFee,
        unlockAt: pastUnlockAt,
        label: "zero-bond-claim",
      });

      const sig = await signClaim(seller, domain, tradeId);
      await escrow.claim(tradeId, sig);

      const sellerBal = await escrow.balances(seller.address, hre.ethers.ZeroAddress);
      const buyerBal = await escrow.balances(buyer.address, hre.ethers.ZeroAddress);
      const arbiterBal = await escrow.balances(arbiter.address, hre.ethers.ZeroAddress);
      expect(sellerBal).to.equal(amount - escrowFee);
      expect(buyerBal).to.equal(0n); // no bond → nothing returned to buyer
      expect(arbiterBal).to.equal(escrowFee);
    });

    it("arbitrate with zero bond only splits payment", async function () {
      const { escrow, buyer, seller, arbiter, amount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount: 0n,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "zero-bond-arbitrate",
      });

      const paymentFactor = 600n;
      const bondFactor = 500n; // irrelevant when bond is 0
      const paymentAfterFee = amount - escrowFee;
      const sellerPayment = (paymentAfterFee * paymentFactor) / 1000n;
      const buyerPayment  = paymentAfterFee - sellerPayment;

      const sig = await signArbitrate(arbiter, domain, tradeId, paymentFactor, bondFactor);
      await escrow.arbitrate(tradeId, paymentFactor, bondFactor, sig);

      expect(await escrow.balances(seller.address, hre.ethers.ZeroAddress)).to.equal(sellerPayment);
      expect(await escrow.balances(buyer.address, hre.ethers.ZeroAddress)).to.equal(buyerPayment);
      expect(await escrow.balances(arbiter.address, hre.ethers.ZeroAddress)).to.equal(escrowFee);
    });

    it("claim returns bond to buyer while payment goes to seller", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, pastUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: pastUnlockAt,
        label: "bond-claim-split",
      });

      const sig = await signClaim(seller, domain, tradeId);
      await escrow.claim(tradeId, sig);

      // payment - fee → seller, bond → buyer
      expect(await escrow.balances(seller.address, hre.ethers.ZeroAddress)).to.equal(amount - escrowFee);
      expect(await escrow.balances(buyer.address, hre.ethers.ZeroAddress)).to.equal(bondAmount);
      expect(await escrow.balances(arbiter.address, hre.ethers.ZeroAddress)).to.equal(escrowFee);
    });

    it("arbitrate splits payment and bond independently", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "bond-arbitrate-split",
      });

      // 80% of payment to seller, 30% of bond to seller
      const paymentFactor = 800n;
      const bondFactor = 300n;
      const paymentAfterFee = amount - escrowFee;
      const sellerPayment = (paymentAfterFee * paymentFactor) / 1000n;
      const buyerPayment  = paymentAfterFee - sellerPayment;
      const sellerBond = (bondAmount * bondFactor) / 1000n;
      const buyerBond  = bondAmount - sellerBond;

      const sig = await signArbitrate(arbiter, domain, tradeId, paymentFactor, bondFactor);
      await escrow.arbitrate(tradeId, paymentFactor, bondFactor, sig);

      expect(await escrow.balances(seller.address, hre.ethers.ZeroAddress)).to.equal(sellerPayment + sellerBond);
      expect(await escrow.balances(buyer.address, hre.ethers.ZeroAddress)).to.equal(buyerPayment + buyerBond);
      expect(await escrow.balances(arbiter.address, hre.ethers.ZeroAddress)).to.equal(escrowFee);
    });

    it("release sends payment + bond to buyer", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "bond-release-all",
      });

      const sig = await signRelease(seller, domain, tradeId, seller.address);
      await escrow.releaseToCounterparty(tradeId, seller.address, sig);

      // Release returns everything (minus fee) to buyer
      expect(await escrow.balances(buyer.address, hre.ethers.ZeroAddress)).to.equal(amount + bondAmount - escrowFee);
      expect(await escrow.balances(arbiter.address, hre.ethers.ZeroAddress)).to.equal(escrowFee);
    });

    it("ERC20 trade with bond: claim returns bond to buyer", async function () {
      const { escrow, token, buyer, seller, arbiter, erc20Amount, erc20BondAmount, erc20EscrowFee, pastUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: erc20BondAmount,
        escrowFee: erc20EscrowFee,
        unlockAt: pastUnlockAt,
        label: "erc20-bond-claim",
      });

      const sig = await signClaim(seller, domain, tradeId);
      await escrow.claim(tradeId, sig);

      const tokenAddress = await token.getAddress();
      expect(await escrow.balances(seller.address, tokenAddress)).to.equal(erc20Amount - erc20EscrowFee);
      expect(await escrow.balances(buyer.address, tokenAddress)).to.equal(erc20BondAmount);
      expect(await escrow.balances(arbiter.address, tokenAddress)).to.equal(erc20EscrowFee);
    });

    it("ERC20 trade with zero bond: claim gives nothing to buyer", async function () {
      const { escrow, token, buyer, seller, arbiter, erc20Amount, erc20EscrowFee, pastUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createERC20Trade({
        escrow,
        token,
        buyer,
        seller,
        arbiter,
        amount: erc20Amount,
        bondAmount: 0n,
        escrowFee: erc20EscrowFee,
        unlockAt: pastUnlockAt,
        label: "erc20-zero-bond-claim",
      });

      const sig = await signClaim(seller, domain, tradeId);
      await escrow.claim(tradeId, sig);

      const tokenAddress = await token.getAddress();
      expect(await escrow.balances(seller.address, tokenAddress)).to.equal(erc20Amount - erc20EscrowFee);
      expect(await escrow.balances(buyer.address, tokenAddress)).to.equal(0n);
      expect(await escrow.balances(arbiter.address, tokenAddress)).to.equal(erc20EscrowFee);
    });
  });

  // ── Admin tests ─────────────────────────────────────────────────────

  describe("Admin", function () {
    it("allows owner to transfer ownership", async function () {
      const { escrow, deployer, buyer } = await loadFixture(deployFixture);
      await escrow.connect(deployer).transferOwnership(buyer.address);
      expect(await escrow.owner()).to.equal(buyer.address);
    });
  });

  // ── EIP-712 signature edge cases ────────────────────────────────────

  describe("Signature validation", function () {
    it("rejects release with wrong signer", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "bad-release-signer",
      });

      // Arbiter signs release pretending to be seller
      const sig = await signRelease(arbiter, domain, tradeId, seller.address);
      await expect(
        escrow.releaseToCounterparty(tradeId, seller.address, sig)
      ).to.be.revertedWithCustomError(escrow, "InvalidSignature");
    });

    it("rejects claim with wrong signer", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, pastUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: pastUnlockAt,
        label: "bad-claim-signer",
      });

      // Buyer tries to sign claim (only seller can)
      const sig = await signClaim(buyer, domain, tradeId);
      await expect(escrow.claim(tradeId, sig)).to.be.revertedWithCustomError(
        escrow,
        "InvalidSignature"
      );
    });

    it("rejects arbitrate with wrong signer", async function () {
      const { escrow, buyer, seller, arbiter, amount, bondAmount, escrowFee, futureUnlockAt, domain } =
        await loadFixture(deployFixture);

      const tradeId = await createNativeTrade({
        escrow,
        buyer,
        seller,
        arbiter,
        amount,
        bondAmount,
        escrowFee,
        unlockAt: futureUnlockAt,
        label: "bad-arb-signer",
      });

      // Seller signs arbitrate (only arbiter can)
      const sig = await signArbitrate(seller, domain, tradeId, 500n, 500n);
      await expect(
        escrow.arbitrate(tradeId, 500n, 500n, sig)
      ).to.be.revertedWithCustomError(escrow, "InvalidSignature");
    });
  });
});
