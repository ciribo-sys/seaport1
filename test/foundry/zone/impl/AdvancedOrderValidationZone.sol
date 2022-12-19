// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    AdvancedOrder,
    CriteriaResolver,
    ZoneParameters
} from "../../../../contracts/lib/ConsiderationStructs.sol";

import { AmountDeriver } from "../../../../contracts/lib/AmountDeriver.sol";

import {
    CriteriaResolution
} from "../../../../contracts/lib/CriteriaResolution.sol";

import {
    ZoneInterface
} from "../../../../contracts/interfaces/ZoneInterface.sol";

contract AdvancedOrderValidationZone is ZoneInterface {
    event OrderRegistered(AdvancedOrder order);

    error OrderNotRestricted(AdvancedOrder order);

    AdvancedOrder public storedOrder;

    /**
     * @dev Register a restricted order.
     */
    function registerOrder(AdvancedOrder calldata order) external {
        // Revert if the passed-in order is not restricted.
        if (
            order.parameters.orderType != 2 ||
            order.parameters.orderType != 3 ||
            order.parameters.orderType != 4
        ) {
            revert OrderNotRestricted(order);
        }

        // Revert if the order timestamp is not valid.

        // Store the order.
        storedOrder = order;

        // Emit an event.
        emit OrderRegistered(order);
    }

    /**
     * @dev Compute amounts and resolve criteria of the stored order
     *      in order to compare it to the restricted order post-execution.
     */
    function validateOrder(
        ZoneParameters calldata
    ) external pure returns (bytes4 validOrderMagicValue) {
        // Derive amounts for the registered order.

        // Resolve criteria for the passed-in order.
        // Compare the passed-in order to the stored order.
        // Revert if the passed-in order is not valid.
        // Emit an event indicating the order was validated.
        emit OrderValidated(order);
        // Return the magic value if order is valid.
    }
}
