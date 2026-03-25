// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MultiEscrow {
    uint256 public constant FACTOR_SCALE = 1000; // 0.1% precision
    string public constant NAME = "Hostr MultiEscrow";
    string public constant VERSION = "4";

    address public owner;

    error OnlyOwner();
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
    error ERC20TransferFailed();
    error NativeNotExpected();

    struct Trade {
        address buyer;
        address seller;
        address arbiter;
        address token;      // address(0) = native RBTC
        uint256 amount;
        uint256 unlockAt;
        uint256 escrowFee;  // flat fee in token units
    }

    mapping(bytes32 => Trade) public trades;
    bytes32[] private _activeTradeIds;
    mapping(bytes32 => uint256) private _activeTradeIndexPlusOne;

    event TradeCreated(bytes32 indexed tradeId, address indexed token, address seller, address buyer, address indexed arbiter, uint256 amount, uint256 unlockAt, uint256 escrowFee);
    event Arbitrated(bytes32 indexed tradeId, address indexed token, address seller, address buyer, uint256 amount, uint256 fractionForwarded);
    event Claimed(bytes32 indexed tradeId, address indexed token, address seller, address buyer, uint256 amount);
    event ReleasedToCounterparty(bytes32 indexed tradeId, address indexed token, address from, address to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyArbiter(bytes32 tradeId) {
        if (msg.sender != trades[tradeId].arbiter) revert OnlyArbiter();
        _;
    }

    // ── Internal helpers ──────────────────────────────────────────────

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

    /// @dev Transfer native RBTC or ERC20 tokens. Handles non-standard ERC20s
    ///      that do not return a bool from transfer() (e.g. USDT).
    function _transfer(address token, address recipient, uint256 amount) internal {
        if (amount == 0) return;

        if (token == address(0)) {
            (bool success,) = payable(recipient).call{value: amount}("");
            if (!success) revert NativeTransferFailed();
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
            );
            if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
                revert ERC20TransferFailed();
            }
        }
    }

    /// @dev Pull ERC20 tokens via transferFrom. Handles non-standard return values.
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert ERC20TransferFailed();
        }
    }

    function _createTrade(
        bytes32 tradeId,
        address buyer,
        address seller,
        address arbiter,
        address token,
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
            token: token,
            amount: amount,
            unlockAt: unlockAt,
            escrowFee: escrowFee
        });
        _addActiveTrade(tradeId);
        emit TradeCreated(tradeId, token, seller, buyer, arbiter, amount, unlockAt, escrowFee);
    }

    function _settleTrade(
        bytes32 tradeId,
        address firstRecipient,
        uint256 firstAmount,
        address secondRecipient,
        uint256 secondAmount
    ) internal returns (uint256 fee) {
        Trade memory trade = trades[tradeId];
        fee = trade.escrowFee;
        address token = trade.token;

        _removeActiveTrade(tradeId);
        delete trades[tradeId];

        _transfer(token, trade.arbiter, fee);
        _transfer(token, firstRecipient, firstAmount);
        _transfer(token, secondRecipient, secondAmount);
    }

    function _claim(bytes32 tradeId) internal returns (uint256 amountAfterFees) {
        Trade storage trade = trades[tradeId];
        if (block.timestamp <= trade.unlockAt) revert ClaimPeriodNotStarted();
        if (trade.amount == 0) revert NoFundsToClaim();

        address seller = trade.seller;
        address buyer = trade.buyer;
        address token = trade.token;
        amountAfterFees = trade.amount - trade.escrowFee;

        _settleTrade(tradeId, seller, amountAfterFees, address(0), 0);

        emit Claimed(tradeId, token, seller, buyer, amountAfterFees);
    }

    function _releaseToCounterparty(
        bytes32 tradeId,
        address actor
    ) internal returns (address recipient, uint256 amountAfterFees) {
        Trade storage trade = trades[tradeId];
        if (trade.amount == 0) revert NoFundsToRelease();

        address token = trade.token;

        if (actor == trade.seller) {
            recipient = trade.buyer;
        } else if (actor == trade.buyer) {
            recipient = trade.seller;
        } else {
            revert OnlyBuyerOrSeller();
        }

        amountAfterFees = trade.amount - trade.escrowFee;
        _settleTrade(tradeId, recipient, amountAfterFees, address(0), 0);
        emit ReleasedToCounterparty(tradeId, token, actor, recipient, amountAfterFees);
    }

    // ── Admin ─────────────────────────────────────────────────────────

    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ── View helpers ──────────────────────────────────────────────────

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

    function activeTrade(bytes32 tradeId) external view returns (bool isActive, Trade memory trade) {
        trade = trades[tradeId];
        isActive = trade.buyer != address(0) && trade.amount > 0;
    }

    // ── Public entry points ───────────────────────────────────────────

    /// @notice Create a new escrow trade. For native RBTC, pass token=address(0)
    ///         and send msg.value. For ERC20, approve this contract first, then
    ///         pass the token address and amount (msg.value must be 0).
    function createTrade(
        bytes32 tradeId,
        address _buyer,
        address _seller,
        address _arbiter,
        address _token,
        uint256 _amount,
        uint256 _unlockAt,
        uint256 _escrowFee
    ) external payable {
        uint256 funded;
        if (_token == address(0)) {
            funded = msg.value;
        } else {
            if (msg.value != 0) revert NativeNotExpected();
            uint256 before = IERC20(_token).balanceOf(address(this));
            _safeTransferFrom(_token, msg.sender, address(this), _amount);
            funded = IERC20(_token).balanceOf(address(this)) - before;
        }
        _createTrade(tradeId, _buyer, _seller, _arbiter, _token, _unlockAt, _escrowFee, funded);
    }

    // ── Release ───────────────────────────────────────────────────────

    function releaseToCounterparty(bytes32 tradeId) external {
        _releaseToCounterparty(tradeId, msg.sender);
    }

    // ── Arbitrate ─────────────────────────────────────────────────────

    function arbitrate(bytes32 tradeId, uint256 factor) external onlyArbiter(tradeId) {
        Trade storage trade = trades[tradeId];
        if (trade.amount == 0) revert NoFundsToRelease();
        if (factor > FACTOR_SCALE) revert InvalidFactor();

        address seller = trade.seller;
        address buyer = trade.buyer;
        address token = trade.token;

        uint256 amountAfterFee = trade.amount - trade.escrowFee;
        uint256 forwardAmount = (amountAfterFee * factor) / FACTOR_SCALE;
        uint256 remainingAmount = amountAfterFee - forwardAmount;

        _settleTrade(tradeId, seller, forwardAmount, buyer, remainingAmount);

        emit Arbitrated(tradeId, token, seller, buyer, amountAfterFee, factor);
    }

    // ── Claim ─────────────────────────────────────────────────────────

    function claim(bytes32 tradeId) external {
        _claim(tradeId);
    }
}
