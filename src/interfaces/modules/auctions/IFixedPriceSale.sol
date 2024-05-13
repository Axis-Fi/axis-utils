// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import {IAtomicAuction} from "src/interfaces/IAtomicAuction.sol";

/// @notice Interface for fixed price sale (atomic) auctions
interface IFixedPriceSale is IAtomicAuction {
    /// @notice                     Parameters for a fixed price auction
    ///
    /// @param price                The fixed price of the lot
    /// @param maxPayoutPercent     The maximum payout per purchase, as a percentage of the capacity
    struct FixedPriceParams {
        uint256 price;
        uint24 maxPayoutPercent;
    }
}
