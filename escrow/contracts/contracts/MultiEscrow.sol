// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MultiEscrow {
    uint256 public constant FACTOR_SCALE = 1000; // 0.1% precision

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

    struct Trade {
        address buyer;
        address seller;
        address arbiter;
        uint256 amount;
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
        if (trades[tradeId].buyer != address(0)) revert TradeIdAlreadyExists();
        if (msg.value == 0) revert MustSendFunds();
        trades[tradeId] = Trade({
            buyer: _buyer,
            seller: _seller,
            arbiter: _arbiter,
            amount: msg.value,
            unlockAt: _unlockAt,
            escrowFee: _escrowFee
        });
        _addActiveTrade(tradeId);
        emit TradeCreated(tradeId, _seller, _buyer, _arbiter, _unlockAt, _escrowFee);
    }

    function releaseToCounterparty(bytes32 tradeId) external {
        Trade storage trade = trades[tradeId];
        if (trade.amount == 0) revert NoFundsToRelease();

        address recipient;
        if (msg.sender == trade.seller) {
            recipient = trade.buyer;
        } else if (msg.sender == trade.buyer) {
            recipient = trade.seller;
        } else {
            revert OnlyBuyerOrSeller();
        }

        uint256 amount = trade.amount;
        payable(recipient).transfer(amount);
        emit ReleasedToCounterparty(tradeId, msg.sender, recipient, amount);
        _removeActiveTrade(tradeId);
        delete trades[tradeId];
    }

    function arbitrate(bytes32 tradeId, uint256 factor) external onlyArbiter(tradeId) {
        Trade storage trade = trades[tradeId];
        if (factor == 0 || factor > FACTOR_SCALE) revert InvalidFactor();

        uint256 amount = trade.amount;
        address seller = trade.seller;
        address buyer = trade.buyer;

        uint256 fee = (amount * trade.escrowFee) / 100;
        uint256 amountAfterFee = amount - fee;
        uint256 forwardAmount = (amountAfterFee * factor) / FACTOR_SCALE;
        uint256 remainingAmount = amountAfterFee - forwardAmount;

        if (forwardAmount > 0) {
            payable(seller).transfer(forwardAmount);
        }

        if (remainingAmount > 0) {
            payable(buyer).transfer(remainingAmount);
        }

        emit Arbitrated(tradeId, seller, buyer, amountAfterFee, factor);
        _removeActiveTrade(tradeId);
        delete trades[tradeId];
    }

    function claim(bytes32 tradeId) external {
        Trade storage trade = trades[tradeId];
        if (block.timestamp <= trade.unlockAt) revert ClaimPeriodNotStarted();
        if (trade.amount == 0) revert NoFundsToClaim();

        uint256 amount = trade.amount;
        address seller = trade.seller;
        address buyer = trade.buyer;

        payable(seller).transfer(amount);

        emit Claimed(tradeId, seller, buyer, amount);
        _removeActiveTrade(tradeId);
        delete trades[tradeId];
    }

    function activeTrade(bytes32 tradeId) external view returns (bool isActive, Trade memory trade) {
        trade = trades[tradeId];
        isActive = trade.buyer != address(0) && trade.amount > 0;
    }

}