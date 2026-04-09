// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MultiEscrow is EIP712, ReentrancyGuard {
    uint256 public constant FACTOR_SCALE = 1000; // 0.1% precision

    address public owner;

    // ── Errors ────────────────────────────────────────────────────────

    error OnlyOwner();
    error InvalidSignature();
    error NotAContract();
    error TradeAlreadyActive();
    error TradeNotActive();
    error TradeIdAlreadyExists();
    error MustSendFunds();
    error NoFundsToRelease();
    error OnlyBuyerOrSeller();
    error InvalidFactor();
    error ClaimPeriodNotStarted();
    error NoFundsToClaim();
    error EscrowFeeTooHigh();
    error NativeTransferFailed();
    error ERC20TransferFailed();
    error NativeNotExpected();
    error InsufficientExcess();
    error NothingToWithdraw();

    // ── Types ─────────────────────────────────────────────────────────

    struct Trade {
        address buyer;
        address seller;
        address arbiter;
        address token;      // address(0) = native RBTC
        uint256 amount;
        uint256 unlockAt;
        uint256 escrowFee;  // flat fee in token units
    }

    // ── EIP-712 type hashes ───────────────────────────────────────────

    bytes32 private constant RELEASE_TYPEHASH =
        keccak256("Release(bytes32 tradeId,address actor)");

    bytes32 private constant CLAIM_TYPEHASH =
        keccak256("Claim(bytes32 tradeId)");

    bytes32 private constant ARBITRATE_TYPEHASH =
        keccak256("Arbitrate(bytes32 tradeId,uint256 factor)");

    bytes32 private constant WITHDRAW_TYPEHASH =
        keccak256("Withdraw(address token,address destination)");

    // ── State ─────────────────────────────────────────────────────────

    mapping(bytes32 => Trade) public trades;
    bytes32[] private _activeTradeIds;
    mapping(bytes32 => uint256) private _activeTradeIndexPlusOne;

    /// @dev user => token => withdrawable balance.
    ///      token address(0) represents native RBTC.
    mapping(address => mapping(address => uint256)) public balances;

    /// @dev user => list of token addresses with non-zero balances (for enumeration).
    mapping(address => address[]) private _userTokens;

    /// @dev user => token => true if the token is already tracked in _userTokens.
    mapping(address => mapping(address => bool)) private _userTokenKnown;

    /// @dev token => total pending withdrawal amount across all settled trades
    mapping(address => uint256) public totalPending;

    // ── Events ────────────────────────────────────────────────────────

    event TradeCreated(bytes32 indexed tradeId, address indexed token, address seller, address buyer, address indexed arbiter, uint256 amount, uint256 unlockAt, uint256 escrowFee);
    event Arbitrated(bytes32 indexed tradeId, address indexed token, address seller, address buyer, uint256 amount, uint256 fractionForwarded);
    event Claimed(bytes32 indexed tradeId, address indexed token, address seller, address buyer, uint256 amount);
    event ReleasedToCounterparty(bytes32 indexed tradeId, address indexed token, address from, address to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Withdrawn(address indexed beneficiary, address indexed token, address destination, uint256 amount);

    // ── Constructor ───────────────────────────────────────────────────

    constructor() EIP712("Hostr MultiEscrow", "6") {
        owner = msg.sender;
    }

    receive() external payable {}

    // ── Modifiers ─────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    // ── Internal helpers ──────────────────────────────────────────────

    /// @dev Verify an EIP-712 typed-data signature. Works for both EOA
    ///      (ecrecover) and smart-contract wallets (ERC-1271).
    function _verifySigner(address signer, bytes32 structHash, bytes calldata signature) internal view {
        bytes32 digest = _hashTypedDataV4(structHash);
        if (!SignatureChecker.isValidSignatureNow(signer, digest, signature)) {
            revert InvalidSignature();
        }
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

    /// @dev Transfer native RBTC or ERC20 tokens. Handles non-standard ERC20s
    ///      that do not return a bool from transfer() (e.g. USDT).
    function _transfer(address token, address recipient, uint256 amount) internal {
        if (amount == 0) return;

        if (token == address(0)) {
            (bool success,) = payable(recipient).call{value: amount}("");
            if (!success) revert NativeTransferFailed();
        } else {
            if (token.code.length == 0) revert NotAContract();
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
        if (token.code.length == 0) revert NotAContract();
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

    function _creditBalance(address recipient, address token, uint256 amount) internal {
        if (amount == 0 || recipient == address(0)) return;
        balances[recipient][token] += amount;
        if (!_userTokenKnown[recipient][token]) {
            _userTokenKnown[recipient][token] = true;
            _userTokens[recipient].push(token);
        }
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

        // Credit balances keyed by (user, token)
        uint256 pendingTotal;
        if (fee > 0) {
            _creditBalance(trade.arbiter, token, fee);
            pendingTotal += fee;
        }
        if (firstAmount > 0) {
            _creditBalance(firstRecipient, token, firstAmount);
            pendingTotal += firstAmount;
        }
        if (secondAmount > 0) {
            _creditBalance(secondRecipient, token, secondAmount);
            pendingTotal += secondAmount;
        }
        totalPending[token] += pendingTotal;
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
    ) external payable nonReentrant {
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

    /// @notice Release funds to the counterparty. `actor` must be the buyer or
    ///         seller stored in the trade. `signature` is an EIP-712 signature
    ///         from `actor` (EOA ecrecover or ERC-1271 smart account).
    ///         Anyone can broadcast the transaction.
    function releaseToCounterparty(
        bytes32 tradeId,
        address actor,
        bytes calldata signature
    ) external nonReentrant {
        _verifySigner(
            actor,
            keccak256(abi.encode(RELEASE_TYPEHASH, tradeId, actor)),
            signature
        );
        _releaseToCounterparty(tradeId, actor);
    }

    // ── Arbitrate ─────────────────────────────────────────────────────

    /// @notice Arbitrate a trade, splitting funds between buyer and seller.
    ///         `signature` must be from the trade's arbiter.
    ///         Anyone can broadcast the transaction.
    function arbitrate(
        bytes32 tradeId,
        uint256 factor,
        bytes calldata signature
    ) external nonReentrant {
        _verifySigner(
            trades[tradeId].arbiter,
            keccak256(abi.encode(ARBITRATE_TYPEHASH, tradeId, factor)),
            signature
        );

        Trade memory trade = trades[tradeId];
        if (trade.amount == 0) revert NoFundsToRelease();
        if (factor > FACTOR_SCALE) revert InvalidFactor();

        uint256 amountAfterFee = trade.amount - trade.escrowFee;
        uint256 forwardAmount = (amountAfterFee * factor) / FACTOR_SCALE;

        _settleTrade(tradeId, trade.seller, forwardAmount, trade.buyer, amountAfterFee - forwardAmount);

        emit Arbitrated(tradeId, trade.token, trade.seller, trade.buyer, amountAfterFee, factor);
    }

    // ── Claim ─────────────────────────────────────────────────────────

    /// @notice Claim funds after the unlock period. `signature` must be from
    ///         the trade's seller. Anyone can broadcast the transaction.
    function claim(
        bytes32 tradeId,
        bytes calldata signature
    ) external nonReentrant {
        address seller = trades[tradeId].seller;
        _verifySigner(
            seller,
            keccak256(abi.encode(CLAIM_TYPEHASH, tradeId)),
            signature
        );
        _claim(tradeId);
    }

    // ── Withdraw ──────────────────────────────────────────────────────

    /// @notice Withdraw the full balance of a specific token.
    ///         `beneficiary` is the address that was awarded funds during
    ///         settlement. `signature` must be from `beneficiary`.
    ///         Anyone can broadcast the transaction (gas-sponsored relay).
    function withdraw(
        address token,
        address beneficiary,
        address destination,
        bytes calldata signature
    ) external nonReentrant {
        _verifySigner(
            beneficiary,
            keccak256(abi.encode(WITHDRAW_TYPEHASH, token, destination)),
            signature
        );

        uint256 amount = balances[beneficiary][token];
        if (amount == 0) revert NothingToWithdraw();

        // Clear before transfer (CEI)
        balances[beneficiary][token] = 0;
        totalPending[token] -= amount;

        _transfer(token, destination, amount);

        emit Withdrawn(beneficiary, token, destination, amount);
    }

    // ── Balance queries ───────────────────────────────────────────────

    /// @notice Returns all tokens and corresponding balances for a user.
    function balanceOf(address user) external view returns (address[] memory tokens, uint256[] memory amounts) {
        address[] storage userTokenList = _userTokens[user];
        uint256 len = userTokenList.length;

        // Count non-zero entries first to size the return arrays
        uint256 count;
        for (uint256 i; i < len;) {
            if (balances[user][userTokenList[i]] > 0) {
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }

        tokens = new address[](count);
        amounts = new uint256[](count);
        uint256 j;
        for (uint256 i; i < len;) {
            uint256 bal = balances[user][userTokenList[i]];
            if (bal > 0) {
                tokens[j] = userTokenList[i];
                amounts[j] = bal;
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    // ── Rescue ────────────────────────────────────────────────────────

    /// @notice Recover ERC-20 tokens sent directly to the contract that are
    ///         not backing any active trade. Only callable by the owner.
    function rescueERC20(address token, address to, uint256 amount) external onlyOwner {
        if (token == address(0)) revert NativeNotExpected();
        if (token.code.length == 0) revert NotAContract();

        uint256 committed;
        uint256 len = _activeTradeIds.length;
        for (uint256 i; i < len;) {
            Trade storage t = trades[_activeTradeIds[i]];
            if (t.token == token) {
                committed += t.amount;
            }
            unchecked { ++i; }
        }
        // Include settled-but-unwithdrawn balances
        committed += totalPending[token];

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 excess = balance - committed;
        if (amount > excess) revert InsufficientExcess();

        _transfer(token, to, amount);
    }
}
