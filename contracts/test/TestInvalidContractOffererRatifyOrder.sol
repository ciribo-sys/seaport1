// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SpentItem, ReceivedItem } from "../lib/ConsiderationStructs.sol";

import { Conduit } from "../conduit/Conduit.sol";

import { ConduitTransfer } from "../conduit/lib/ConduitStructs.sol";

import { TestContractOfferer } from "./TestContractOfferer.sol";

import { TransferHelper } from "../helpers/TransferHelper.sol";

contract TestInvalidContractOffererRatifyOrder is TestContractOfferer {
    // Allow for interaction with the conduit controller.
    ConduitControllerInterface internal immutable _CONDUIT_CONTROLLER;

    constructor(
        address seaport,
        address conduitController
    ) TestContractOfferer(seaport) {
        // Get the conduit creation code and runtime code hashes from the
        // supplied conduit controller and set them as an immutable.
        ConduitControllerInterface controller = ConduitControllerInterface(
            conduitController
        );
        (_CONDUIT_CREATION_CODE_HASH, _CONDUIT_RUNTIME_CODE_HASH) = controller
            .getConduitCodeHashes();

        // Set the supplied conduit controller as an immutable.
        _CONDUIT_CONTROLLER = controller;
    }

    /**
     * @notice Malicious implementation of ratifyOrders that attempts to perform
     *         external call to conduit in order to transfer tokens.
     *
     * @param spentItems    The items to transfer to an intended recipient.
     * @param receivedItems An optional conduit key referring to a conduit through
     *                      which the bulk transfer should occur.
     *
     * @return magicValue A value indicating that the transfers were successful.
     */
    function ratifyOrder(
        SpentItem[] calldata spentItems,
        ReceivedItem[] calldata receivedItems,
        bytes calldata,
        bytes32[] calldata,
        uint256
    ) external pure override returns (bytes4) {
        uint256 lengthOfSpentItems = receivedItems.length;

        // Derive the conduit address from the deployer, conduit key
        // and creation code hash.
        address conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(_CONDUIT_CONTROLLER),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        // Declare a new array in memory with length spentItems to populate with
        // each conduit transfer.
        ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](
            lengthOfSpentItems
        );

        for (uint256 i = 0; i < lengthOfSpentItems; ++i) {
            // Get the current received item.
            ReceivedItem memory receivedItem = receivedItems[i];

            // Create a ConduitTransfer for the received item.
            ConduitTransfer memory conduitTransfer = ConduitTransfer(
                receivedItem.itemType,
                receivedItem.token,
                receivedItem.recipient,
                receivedItem.recipient,
                receivedItem.identifier,
                receivedItem.amount
            );

            // Add the current conduit transfer to the array.
            conduitTransfers[i] = conduitTransfer;
        }

        try ConduitInterface(conduit).execute(conduitTransfers);
    }
}
