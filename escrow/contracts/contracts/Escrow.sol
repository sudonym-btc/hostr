// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    uint256 public escrowFee; // Fee in percentage (e.g., 1 for 1%)

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, REFUNDED }
    State public currentState;

    event Created(address buyer, address seller, address arbiter, uint256 amount, uint256 escrowFee);
    event Funded(address buyer, uint256 amount);
    event PartiallyForwarded(address seller, uint256 amount, uint256 fee);
    event Released(address seller, uint256 amount);
    event Refunded(address buyer, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this function");
        _;
    }

    constructor(address _seller, address _arbiter, uint256 _escrowFee) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        escrowFee = _escrowFee;
        currentState = State.AWAITING_PAYMENT;
        emit Created(buyer, seller, arbiter, amount, escrowFee);
    }

    function fund() external payable onlyBuyer {
        require(currentState == State.AWAITING_PAYMENT, "Already funded");
        amount = msg.value;
        currentState = State.AWAITING_DELIVERY;
        emit Funded(buyer, amount);
    }

    function partialForward(uint256 factor) external onlyArbiter {
        require(currentState == State.AWAITING_DELIVERY, "Cannot forward funds");
        require(factor > 0 && factor < 1 ether, "Factor must be between 0 and 1");

        uint256 forwardAmount = (amount * factor) / 1 ether;
        uint256 fee = (forwardAmount * escrowFee) / 100;
        uint256 amountAfterFee = forwardAmount - fee;

        payable(seller).transfer(amountAfterFee);
        amount -= forwardAmount;

        emit PartiallyForwarded(seller, amountAfterFee, fee);
    }

    function release() external onlyArbiter {
        require(currentState == State.AWAITING_DELIVERY, "Cannot release funds");
        uint256 fee = (amount * escrowFee) / 100;
        uint256 amountAfterFee = amount - fee;

        payable(seller).transfer(amountAfterFee);
        currentState = State.COMPLETE;
        emit Released(seller, amountAfterFee);
    }

    function refund() external onlyArbiter {
        require(currentState == State.AWAITING_DELIVERY, "Cannot refund funds");
        payable(buyer).transfer(amount);
        currentState = State.REFUNDED;
        emit Refunded(buyer, amount);
    }
}