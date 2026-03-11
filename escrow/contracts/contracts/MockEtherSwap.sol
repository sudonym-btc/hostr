// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockEtherSwap {
    bytes32 public constant TYPEHASH_CLAIM =
        keccak256(
            "Claim(bytes32 preimage,uint256 amount,address refundAddress,uint256 timelock,address destination)"
        );
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(bytes32 => bool) public swaps;

    error SwapNotFound();
    error NativeTransferFailed();

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("MockEtherSwap")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function lock(
        bytes32 preimageHash,
        uint256 amount,
        address claimAddress,
        address refundAddress,
        uint256 timelock
    ) external payable {
        require(msg.value == amount, "amount mismatch");
        swaps[_swapKey(preimageHash, amount, claimAddress, refundAddress, timelock)] = true;
    }

    function claim(
        bytes32 preimage,
        uint256 amount,
        address refundAddress,
        uint256 timelock,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address claimAddress) {
        claimAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            TYPEHASH_CLAIM,
                            preimage,
                            amount,
                            refundAddress,
                            timelock,
                            msg.sender
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        bytes32 key = _swapKey(
            sha256(abi.encodePacked(preimage)),
            amount,
            claimAddress,
            refundAddress,
            timelock
        );
        if (!swaps[key]) revert SwapNotFound();
        delete swaps[key];

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert NativeTransferFailed();
    }

    function _swapKey(
        bytes32 preimageHash,
        uint256 amount,
        address claimAddress,
        address refundAddress,
        uint256 timelock
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(preimageHash, amount, claimAddress, refundAddress, timelock)
        );
    }
}