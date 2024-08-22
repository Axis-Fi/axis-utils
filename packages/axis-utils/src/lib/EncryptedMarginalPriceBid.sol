// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ECIES, Point} from "@axis-core-1.0.0/lib/ECIES.sol";

/// @title  EncryptedMarginalPriceBid
/// @notice Library for encrypting the amount out for a bid in an encrypted marginal price auction
library EncryptedMarginalPriceBid {
    function formatBid(uint96 amountOut_, uint128 bidSeed) internal pure returns (uint256) {
        uint256 formattedAmountOut;
        {
            uint128 subtracted;
            unchecked {
                subtracted = uint128(amountOut_) - bidSeed;
            }
            formattedAmountOut = uint256(bytes32(abi.encodePacked(bidSeed, subtracted)));
        }

        return formattedAmountOut;
    }

    /// @notice Encrypts the amount out for a bid
    ///
    /// @param  lotId_              The ID of the auction lot
    /// @param  bidder_             The address of the bidder that will receive refunds and payouts
    /// @param  amountIn_           The amount of the bid in quote tokens
    /// @param  amountOut_          The amount of the bid out in quote tokens
    /// @param  auctionPublicKey_   The public key of the auction
    /// @param  bidSeed_            The seed for the bid
    /// @param  bidPrivateKey_      The private key for the bid
    /// @return encryptedAmountOut  The encrypted amount out
    function encryptAmountOut(
        uint96 lotId_,
        address bidder_,
        uint96 amountIn_,
        uint96 amountOut_,
        Point memory auctionPublicKey_,
        uint128 bidSeed_,
        uint256 bidPrivateKey_
    ) public view returns (uint256 encryptedAmountOut) {
        // Format the amount out
        uint256 formattedAmountOut = formatBid(amountOut_, bidSeed_);
        uint256 salt = uint256(keccak256(abi.encodePacked(lotId_, bidder_, uint96(amountIn_))));

        (encryptedAmountOut,) =
            ECIES.encrypt(formattedAmountOut, auctionPublicKey_, bidPrivateKey_, salt);

        return encryptedAmountOut;
    }
}
