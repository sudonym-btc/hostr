// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEtherSwap {
    function claim(
        bytes32 preimage,
        uint256 amount,
        address refundAddress,
        uint256 timelock,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address);
}

contract MultiEscrow {
    uint256 public constant FACTOR_SCALE = 1000; // 0.1% precision
    string public constant NAME = "Hostr MultiEscrow";
    string public constant VERSION = "2";

    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant _RELAY_FEE_QUOTE_TYPEHASH =
        keccak256(
            "RelayFeeQuote(address receiver,uint256 amount,uint256 deadline)"
        );
    bytes32 private constant _CLAIM_AUTHORIZATION_TYPEHASH =
        keccak256(
            "ClaimAuthorization(bytes32 tradeId,RelayFeeQuote relayFeeQuote)RelayFeeQuote(address receiver,uint256 amount,uint256 deadline)"
        );
    bytes32 private constant _RELEASE_AUTHORIZATION_TYPEHASH =
        keccak256(
            "ReleaseAuthorization(bytes32 tradeId,RelayFeeQuote relayFeeQuote)RelayFeeQuote(address receiver,uint256 amount,uint256 deadline)"
        );

    bytes32 public immutable DOMAIN_SEPARATOR;

    error OnlyArbiter();
    error TradeAlreadyActive();
    error TradeNotActive();
    error TradeIdAlreadyExists();
    error MustSendFunds();
    error NoFundsToRelease();
    error OnlyBuyerOrSeller();
    error InvalidFactor();
    error OnlySeller();
    error ClaimPeriodNotStarted();
    error NoFundsToClaim();
    error EscrowFeeTooHigh();
    error NativeTransferFailed();
    error RelayFeeTooHigh();
    error InvalidFeeRecipient();
    error SignatureExpired();
    error InvalidSignature();
    error InvalidSwapContract();
    error ClaimSignerNotBuyer();
    error ClaimedAmountMismatch();

    struct Trade {
        address buyer;
        address seller;
        address arbiter;
        uint256 amount;
        uint256 unlockAt;
        uint256 escrowFee; // flat fee in wei
    }

    struct RelayFeeQuote {
        address receiver;
        uint256 amount;
        uint256 deadline;
    }

    struct ClaimArgs {
        address swapContract;
        bytes32 preimage;
        uint256 amount;
        address refundAddress;
        uint256 timelock;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct FundArgs {
        bytes32 tradeId;
        address buyer;
        address seller;
        address arbiter;
        uint256 unlockAt;
        uint256 escrowFee;
    }

    mapping(bytes32 => Trade) public trades;
    bytes32[] private _activeTradeIds;
    mapping(bytes32 => uint256) private _activeTradeIndexPlusOne;

    event TradeCreated(bytes32 indexed tradeId, address seller, address buyer, address indexed arbiter, uint256 unlockAt, uint256 escrowFee );
    event Arbitrated(bytes32 indexed tradeId, address seller, address buyer, uint256 amount, uint256 fractionForwarded);
    event Claimed(bytes32 indexed tradeId, address seller, address buyer, uint256 amount);
    event ReleasedToCounterparty(bytes32 indexed tradeId, address from, address to, uint256 amount);
    event RelayFeePaid(bytes32 indexed tradeId, address indexed feeReceiver, uint256 amount);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );
    }

    receive() external payable {}

    modifier onlyArbiter(bytes32 tradeId) {
        if (msg.sender != trades[tradeId].arbiter) revert OnlyArbiter();
        _;
    }

    function _addActiveTrade(bytes32 tradeId) internal {
        if (_activeTradeIndexPlusOne[tradeId] != 0) revert TradeAlreadyActive();
        _activeTradeIds.push(tradeId);
        _activeTradeIndexPlusOne[tradeId] = _activeTradeIds.length;
    }

    function _removeActiveTrade(bytes32 tradeId) internal {
        uint256 indexPlusOne = _activeTradeIndexPlusOne[tradeId];
        if (indexPlusOne == 0) revert TradeNotActive();

        uint256 index;
        unchecked {
            index = indexPlusOne - 1;
        }
        uint256 lastIndex = _activeTradeIds.length - 1;

        if (index != lastIndex) {
            bytes32 movedTradeId = _activeTradeIds[lastIndex];
            _activeTradeIds[index] = movedTradeId;
            _activeTradeIndexPlusOne[movedTradeId] = index + 1;
        }

        _activeTradeIds.pop();
        delete _activeTradeIndexPlusOne[tradeId];
    }

    function _sendValue(address recipient, uint256 amount) internal {
        if (amount == 0) return;

        (bool success,) = payable(recipient).call{value: amount}("");
        if (!success) revert NativeTransferFailed();
    }

    function _requireFeeRecipient(RelayFeeQuote memory relayFeeQuote) internal pure {
        if (relayFeeQuote.amount > 0 && relayFeeQuote.receiver == address(0)) {
            revert InvalidFeeRecipient();
        }
    }

    function _remainingAfterFees(
        Trade memory trade,
        RelayFeeQuote memory relayFeeQuote
    ) internal pure returns (uint256 distributableAmount, uint256 relayFeeAmount) {
        distributableAmount = trade.amount - trade.escrowFee;
        relayFeeAmount = relayFeeQuote.amount;
        if (relayFeeAmount > distributableAmount) revert RelayFeeTooHigh();
        distributableAmount -= relayFeeAmount;
    }

    function _hashRelayFeeQuote(
        RelayFeeQuote memory relayFeeQuote
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _RELAY_FEE_QUOTE_TYPEHASH,
                relayFeeQuote.receiver,
                relayFeeQuote.amount,
                relayFeeQuote.deadline
            )
        );
    }

    function _hashTypedData(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    function _recoverSigner(bytes32 digest, bytes calldata signature) internal pure returns (address signer) {
        if (signature.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) revert InvalidSignature();

        signer = ecrecover(digest, v, r, s);
        if (signer == address(0)) revert InvalidSignature();
    }

    function _createTrade(
        bytes32 tradeId,
        address buyer,
        address seller,
        address arbiter,
        uint256 unlockAt,
        uint256 escrowFee,
        uint256 amount
    ) internal {
        if (trades[tradeId].buyer != address(0)) revert TradeIdAlreadyExists();
        if (amount == 0) revert MustSendFunds();
        if (escrowFee > amount) revert EscrowFeeTooHigh();

        trades[tradeId] = Trade({
            buyer: buyer,
            seller: seller,
            arbiter: arbiter,
            amount: amount,
            unlockAt: unlockAt,
            escrowFee: escrowFee
        });
        _addActiveTrade(tradeId);
        emit TradeCreated(tradeId, seller, buyer, arbiter, unlockAt, escrowFee);
    }

    function _settleTrade(
        bytes32 tradeId,
        address firstRecipient,
        uint256 firstAmount,
        address secondRecipient,
        uint256 secondAmount,
        address feeRecipient,
        uint256 feeRecipientAmount
    ) internal returns (uint256 fee) {
        Trade memory trade = trades[tradeId];
        fee = trade.escrowFee;

        _removeActiveTrade(tradeId);
        delete trades[tradeId];

        _sendValue(trade.arbiter, fee);
        _sendValue(firstRecipient, firstAmount);
        _sendValue(secondRecipient, secondAmount);
        _sendValue(feeRecipient, feeRecipientAmount);
        if (feeRecipientAmount > 0) {
            emit RelayFeePaid(tradeId, feeRecipient, feeRecipientAmount);
        }
    }

    function _claim(
        bytes32 tradeId,
        RelayFeeQuote memory relayFeeQuote
    ) internal returns (uint256 amountAfterFees) {
        Trade storage trade = trades[tradeId];
        if (block.timestamp <= trade.unlockAt) revert ClaimPeriodNotStarted();
        if (trade.amount == 0) revert NoFundsToClaim();

        _requireFeeRecipient(relayFeeQuote);

        address seller = trade.seller;
        address buyer = trade.buyer;
        (amountAfterFees,) = _remainingAfterFees(trade, relayFeeQuote);

        _settleTrade(
            tradeId,
            seller,
            amountAfterFees,
            address(0),
            0,
            relayFeeQuote.receiver,
            relayFeeQuote.amount
        );

        emit Claimed(tradeId, seller, buyer, amountAfterFees);
    }

    function _releaseToCounterparty(
        bytes32 tradeId,
        address actor,
        RelayFeeQuote memory relayFeeQuote
    ) internal returns (address recipient, uint256 amountAfterFees) {
        Trade storage trade = trades[tradeId];
        if (trade.amount == 0) revert NoFundsToRelease();

        // TODO(hostr): add a per-trade max relay reimbursement guard for the
        // gasless release path. This matters for `releaseToCounterparty`
        // because the caller/relay could otherwise present a user-signed but
        // overly large `RelayFeeQuote` that diverts too much value away from
        // the counterparty payout. A future version should let the trade
        // creator set a `maxReleaseRelayFee` (or similar) at trade creation
        // time and enforce `relayFeeQuote.amount <= trade.maxReleaseRelayFee`.
        // The same concern is much weaker for `claim`, where the seller is
        // only overpaying relay fees out of their own eventual proceeds.
        _requireFeeRecipient(relayFeeQuote);

        if (actor == trade.seller) {
            recipient = trade.buyer;
        } else if (actor == trade.buyer) {
            recipient = trade.seller;
        } else {
            revert OnlyBuyerOrSeller();
        }

        (amountAfterFees,) = _remainingAfterFees(trade, relayFeeQuote);
        _settleTrade(
            tradeId,
            recipient,
            amountAfterFees,
            address(0),
            0,
            relayFeeQuote.receiver,
            relayFeeQuote.amount
        );
        emit ReleasedToCounterparty(tradeId, actor, recipient, amountAfterFees);
    }

    function activeTradeCount() external view returns (uint256) {
        return _activeTradeIds.length;
    }

    function getActiveTradeIds() external view returns (bytes32[] memory) {
        return _activeTradeIds;
    }

    function getActiveTradeIdsPage(uint256 offset, uint256 limit) external view returns (bytes32[] memory ids) {
        if (offset >= _activeTradeIds.length || limit == 0) {
            return new bytes32[](0);
        }

        uint256 end = offset + limit;
        if (end > _activeTradeIds.length) {
            end = _activeTradeIds.length;
        }

        ids = new bytes32[](end - offset);
        for (uint256 i = offset; i < end;) {
            ids[i - offset] = _activeTradeIds[i];
            unchecked {
                ++i;
            }
        }
    }

    function createTrade(bytes32 tradeId, address _buyer, address _seller, address _arbiter,  uint256 _unlockAt, uint256 _escrowFee) external payable {
        _createTrade(tradeId, _buyer, _seller, _arbiter, _unlockAt, _escrowFee, msg.value);
    }

    function claimSwapAndFund(
        ClaimArgs calldata claimArgs,
        FundArgs calldata fundArgs
    ) external {
        if (claimArgs.swapContract == address(0)) revert InvalidSwapContract();

        uint256 balanceBefore = address(this).balance;
        address claimSigner = IEtherSwap(claimArgs.swapContract).claim(
            claimArgs.preimage,
            claimArgs.amount,
            claimArgs.refundAddress,
            claimArgs.timelock,
            claimArgs.v,
            claimArgs.r,
            claimArgs.s
        );
        if (claimSigner != fundArgs.buyer) revert ClaimSignerNotBuyer();

        uint256 claimedAmount = address(this).balance - balanceBefore;
        if (claimedAmount != claimArgs.amount) revert ClaimedAmountMismatch();

        _createTrade(
            fundArgs.tradeId,
            fundArgs.buyer,
            fundArgs.seller,
            fundArgs.arbiter,
            fundArgs.unlockAt,
            fundArgs.escrowFee,
            claimedAmount
        );
    }

    function hashClaimAuthorization(
        bytes32 tradeId,
        RelayFeeQuote calldata relayFeeQuote
    ) public view returns (bytes32) {
        return _hashTypedData(
            keccak256(
                abi.encode(
                    _CLAIM_AUTHORIZATION_TYPEHASH,
                    tradeId,
                    _hashRelayFeeQuote(relayFeeQuote)
                )
            )
        );
    }

    function hashReleaseAuthorization(
        bytes32 tradeId,
        RelayFeeQuote calldata relayFeeQuote
    ) public view returns (bytes32) {
        return _hashTypedData(
            keccak256(
                abi.encode(
                    _RELEASE_AUTHORIZATION_TYPEHASH,
                    tradeId,
                    _hashRelayFeeQuote(relayFeeQuote)
                )
            )
        );
    }

    function releaseToCounterparty(bytes32 tradeId) external {
        _releaseToCounterparty(
            tradeId,
            msg.sender,
            RelayFeeQuote({receiver: address(0), amount: 0, deadline: 0})
        );
    }

    function releaseToCounterparty(
        bytes32 tradeId,
        RelayFeeQuote calldata relayFeeQuote,
        bytes calldata signature
    ) external {
        if (relayFeeQuote.deadline < block.timestamp) revert SignatureExpired();

        address signer = _recoverSigner(
            hashReleaseAuthorization(tradeId, relayFeeQuote),
            signature
        );

        _releaseToCounterparty(tradeId, signer, relayFeeQuote);
    }

    function arbitrate(bytes32 tradeId, uint256 factor) external onlyArbiter(tradeId) {
        Trade storage trade = trades[tradeId];
        if (trade.amount == 0) revert NoFundsToRelease();
        if (factor > FACTOR_SCALE) revert InvalidFactor();

        address seller = trade.seller;
        address buyer = trade.buyer;

        uint256 amountAfterFee = trade.amount - trade.escrowFee;
        uint256 forwardAmount = (amountAfterFee * factor) / FACTOR_SCALE;
        uint256 remainingAmount = amountAfterFee - forwardAmount;

        _settleTrade(
            tradeId,
            seller,
            forwardAmount,
            buyer,
            remainingAmount,
            address(0),
            0
        );

        emit Arbitrated(tradeId, seller, buyer, amountAfterFee, factor);
    }

    function claim(bytes32 tradeId) external {
        _claim(
            tradeId,
            RelayFeeQuote({receiver: address(0), amount: 0, deadline: 0})
        );
    }

    function claim(
        bytes32 tradeId,
        RelayFeeQuote calldata relayFeeQuote,
        bytes calldata signature
    ) external {
        if (relayFeeQuote.deadline < block.timestamp) revert SignatureExpired();

        Trade storage trade = trades[tradeId];
        address signer = _recoverSigner(
            hashClaimAuthorization(tradeId, relayFeeQuote),
            signature
        );
        if (signer != trade.seller) revert OnlySeller();

        _claim(tradeId, relayFeeQuote);
    }

    function activeTrade(bytes32 tradeId) external view returns (bool isActive, Trade memory trade) {
        trade = trades[tradeId];
        isActive = trade.buyer != address(0) && trade.amount > 0;
    }

}