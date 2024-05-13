// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.0;

import {IBatchAuction} from "src/interfaces/IBatchAuction.sol";

interface IEncryptedMarginalPrice is IBatchAuction {
    struct Point {
        uint256 x;
        uint256 y;
    }

    /// @notice         Parameters that are used to set auction-specific data
    ///
    /// @param          minPrice            The minimum price (in quote tokens) that a bid must fulfill
    /// @param          minFillPercent      The minimum percentage of capacity that the lot must fill in order to settle
    /// @param          minBidSize          The minimum size of a bid in quote tokens
    /// @param          publicKey           The public key used to encrypt bids
    struct AuctionDataParams {
        uint256 minPrice;
        uint24 minFillPercent;
        uint256 minBidSize;
        Point publicKey;
    }
}
