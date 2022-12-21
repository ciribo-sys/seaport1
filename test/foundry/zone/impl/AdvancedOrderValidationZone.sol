// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { OrderType } from "../../../../contracts/lib/ConsiderationEnums.sol";

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

    event OrderValidated(bytes32 orderHash);

    error OrderNotRestricted(AdvancedOrder order);

    error MismatchedOfferItemLengths(
        uint256 expectedOfferItemLength,
        uint256 actualOfferItemLength
    );

    error InvalidOfferItemAmount(
        OfferItem expectedOfferItem,
        OfferItem actualOfferItem
    );

    AdvancedOrder public storedOrder;

    /**
     * @dev Register a restricted order.
     */
    function registerOrder(AdvancedOrder calldata order) external {
        // Revert if the passed-in order is not restricted.
        if (
            order.parameters.orderType != OrderType.FULL_RESTRICTED ||
            order.parameters.orderType != OrderType.PARTIAL_RESTRICTED ||
            order.parameters.orderType != OrderType.CONTRACT
        ) {
            revert OrderNotRestricted(order);
        }

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
        ZoneParameters calldata zoneParameters
    ) external pure returns (bytes4 validOrderMagicValue) {
        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Declare inner variables.
            OfferItem[] memory offer;
            ConsiderationItem[] memory consideration;

            // // Validate it, update status, and determine fraction to fill.
            // (
            //     bytes32 orderHash,
            //     uint256 numerator,
            //     uint256 denominator
            // ) = _validateOrderAndUpdateStatus(zoneParameters., true);

            // Do not track hash or adjust prices if order is not fulfilled.
            if (numerator == 0) {
                // Mark fill fraction as zero if the order is not fulfilled.
                advancedOrder.numerator = 0;

                // Continue iterating through the remaining orders.
                continue;
            }

            // Otherwise, track the order hash in question.
            assembly {
                mstore(add(orderHashes, i), orderHash)
            }

            // Place the start time for the registered order on the stack.
            uint256 startTime = storedOrder.parameters.startTime;

            // Place the end time for the registered order on the stack.
            uint256 endTime = storedOrder.parameters.endTime;

            // Retrieve array of offer items for the registered order.
            offer = storedOrder.offerItems;

            // Read length of offer array and place on the stack.
            uint256 totalOfferItems = offer.length;

            // Revert if the offer item lengths do not match.
            if (totalOfferItems != storedOrder.parameters.offer.length) {
                revert MismatchedOfferItemLengths(
                    storedOrder.parameters.offer.length,
                    totalOfferItems
                );
            }

            // Iterate over each offer item on the order.
            for (uint256 j = 0; j < totalOfferItems; ++j) {
                // Retrieve the offer item.
                OfferItem memory offerItem = offer[j];

                assembly {
                    // If the offer item is for the native token, set the
                    // first bit of the error buffer to true.
                    invalidNativeOfferItemErrorBuffer := or(
                        invalidNativeOfferItemErrorBuffer,
                        iszero(mload(offerItem))
                    )
                }

                // Apply order fill fraction to offer item end amount.
                uint256 endAmount = _getFraction(
                    numerator,
                    denominator,
                    offerItem.endAmount
                );

                // Reuse same fraction if start and end amounts are equal.
                if (offerItem.startAmount == offerItem.endAmount) {
                    // Apply derived amount to both start and end amount.
                    offerItem.startAmount = endAmount;
                } else {
                    // Apply order fill fraction to offer item start amount.
                    offerItem.startAmount = _getFraction(
                        numerator,
                        denominator,
                        offerItem.startAmount
                    );
                }

                // Adjust offer amount using current time; round down.
                uint256 currentAmount = _locateCurrentAmount(
                    offerItem.startAmount,
                    endAmount,
                    startTime,
                    endTime,
                    false // round down
                );

                // Update amounts in memory to match the current amount.
                // Note that the end amount is used to track spent amounts.
                offerItem.startAmount = currentAmount;
                offerItem.endAmount = currentAmount;

                if (
                    offerItem.startAmount !=
                    storedOrder.parameters.offer[i].startAmount
                ) {
                    revert InvalidOfferItemAmount(
                        storedOrder.parameters.offer[i].startAmount,
                        offerItem.startAmount
                    );
                }
            }
        }

        // Resolve criteria for the passed-in order.
        // Compare the passed-in order to the stored order.
        // Revert if the passed-in order is not valid.
        // Emit an event indicating the order was validated.
        emit OrderValidated(zoneParameters.orderHash);

        // Return the magic value if order is valid.
        return ZoneInterface.validateOrder.selector;
    }
}
