// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GiwaTap
/// @notice Minimal, gas-cheap on-chain tipping / micro-payment contract for GIWA (Ethereum L2).
///         Anyone can send ETH to any recipient with an optional message. Every tip is logged
///         on-chain so recipients (creators, cafes, street vendors, event organizers, ...) get
///         a permanent, shareable, verifiable payment history — no account, no signup, no custody.
/// @dev    100% non-custodial: funds are forwarded to the recipient in the same transaction.
///         The contract never holds a balance between calls.
contract GiwaTap {
    struct Tip {
        address sender;
        address recipient;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    /// @notice Running total (in wei) ever received by a given address through GiwaTap.
    mapping(address => uint256) public totalReceived;

    /// @notice Number of tips a given address has received.
    mapping(address => uint256) public tipCount;

    /// @notice Full tip history, append-only.
    Tip[] public tips;

    event Tipped(
        uint256 indexed tipId,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        string message,
        uint256 timestamp
    );

    error ZeroAmount();
    error ZeroAddressRecipient();
    error MessageTooLong();
    error TransferFailed();

    uint256 public constant MAX_MESSAGE_LENGTH = 280;

    /// @notice Send a tip / payment to `recipient`, forwarded instantly, with an optional note.
    /// @param recipient The address receiving the ETH.
    /// @param message Optional short note (e.g. "Great coffee!", "Table 4", "Thanks for the demo").
    function tap(address payable recipient, string calldata message) external payable {
        if (msg.value == 0) revert ZeroAmount();
        if (recipient == address(0)) revert ZeroAddressRecipient();
        if (bytes(message).length > MAX_MESSAGE_LENGTH) revert MessageTooLong();

        totalReceived[recipient] += msg.value;
        tipCount[recipient] += 1;

        tips.push(Tip({
            sender: msg.sender,
            recipient: recipient,
            amount: msg.value,
            message: message,
            timestamp: block.timestamp
        }));

        emit Tipped(tips.length - 1, msg.sender, recipient, msg.value, message, block.timestamp);

        (bool success, ) = recipient.call{value: msg.value}("");
        if (!success) revert TransferFailed();
    }

    /// @notice Total number of tips ever sent through this contract.
    function totalTips() external view returns (uint256) {
        return tips.length;
    }

    /// @notice Returns the `count` most recent tips (newest first). Useful for a live feed UI.
    /// @param count How many recent tips to return (capped to available history).
    function recentTips(uint256 count) external view returns (Tip[] memory result) {
        uint256 len = tips.length;
        if (count > len) count = len;
        result = new Tip[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tips[len - 1 - i];
        }
    }

    /// @notice Returns the `count` most recent tips received by `recipient` (newest first).
    /// @dev O(n) scan — fine for a demo/MVP with a bounded tip history; for production scale,
    ///      index tips off-chain via events instead.
    function recentTipsFor(address recipient, uint256 count) external view returns (Tip[] memory result) {
        uint256 len = tips.length;
        uint256 found = 0;
        // First pass: count matches up to `count`.
        uint256[] memory idxs = new uint256[](count);
        for (uint256 i = len; i > 0 && found < count; i--) {
            if (tips[i - 1].recipient == recipient) {
                idxs[found] = i - 1;
                found++;
            }
        }
        result = new Tip[](found);
        for (uint256 j = 0; j < found; j++) {
            result[j] = tips[idxs[j]];
        }
    }
}
