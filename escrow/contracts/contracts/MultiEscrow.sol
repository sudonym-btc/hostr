pragma solidity ^0.8.0;

contract MultiEscrow {
    struct Trade {
        address buyer;
        address seller;
        address arbiter;
        uint256 amount;
        uint256 timelock;
        uint256 escrowFee;
    }

    mapping(bytes32 => Trade) public trades;

    event TradeCreated(bytes32 indexed tradeId, address buyer, address seller, address arbiter, uint256 timelock, uint256 escrowFee );
    event Arbitrated(bytes32 indexed tradeId, address seller, address buyer, uint256 amount, uint256 fractionForwarded);
    event Claimed(bytes32 indexed tradeId, address seller, address buyer, uint256 amount);

    modifier onlyBuyer(bytes32 tradeId) {
        require(msg.sender == trades[tradeId].buyer, "Only buyer can call this function");
        _;
    }

    modifier onlyArbiter(bytes32 tradeId) {
        require(msg.sender == trades[tradeId].arbiter, "Only arbiter can call this function");
        _;
    }
    event DebugLog(string message);
    function createTrade(bytes32 tradeId, address _buyer, address _seller, address _arbiter,  uint256 _timelock, uint256 _escrowFee) external payable {
        emit DebugLog("TradeCreated event emitted");

        require(trades[tradeId].buyer == address(0), "Trade ID already exists");
        require(msg.value > 0, "Must send funds to create an escrow contract");
        require(_timelock > 0, "Timelock must be greater than 0");

        trades[tradeId] = Trade({
            buyer: _buyer,
            seller: _seller,
            arbiter: _arbiter,
            amount: 0,
            timelock: block.timestamp + _timelock,
            escrowFee: _escrowFee
        });
        emit TradeCreated(tradeId, _buyer, _seller, _arbiter, _timelock, _escrowFee);
    }

    function arbitrate(bytes32 tradeId, uint256 factor) external onlyArbiter(tradeId) {
        Trade storage trade = trades[tradeId];
        require(factor > 0 && factor < 1, "Factor must be between 0 and 1");

        uint256 fee = (trade.amount * trade.escrowFee) / 100;
        uint256 amountAfterFee = trade.amount - fee;
        uint256 forwardAmount = (amountAfterFee * factor) / 1;

        if (forwardAmount > 0) {
            payable(trade.seller).transfer(forwardAmount);
        }
        trade.amount -= forwardAmount + fee;

        uint256 remainingAmount = trade.amount;
        if (remainingAmount > 0) {
            payable(trade.buyer).transfer(remainingAmount);
        }
        trade.amount = 0;

        emit Arbitrated(tradeId, trade.seller, trade.buyer, amountAfterFee, factor);
        delete trades[tradeId];
    }

    function claim(bytes32 tradeId) external {
        Trade storage trade = trades[tradeId];
        require(msg.sender == trade.seller, "Only the seller can claim the funds");
        require(block.timestamp > trade.timelock + 2 weeks, "Claim period has not started yet");
        require(trade.amount > 0, "No funds to claim");

        payable(trade.seller).transfer(trade.amount);
        trade.amount = 0;

        emit Claimed(tradeId, trade.seller, trade.buyer, trade.amount);
        delete trades[tradeId];
    }

}