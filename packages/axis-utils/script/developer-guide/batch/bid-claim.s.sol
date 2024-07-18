// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {Script} from "@forge-std-1.9.1/Script.sol";
import {console2} from "@forge-std-1.9.1/console2.sol";
import {Constants} from "../constants.s.sol";

// Axis contracts
import {IBatchAuctionHouse} from "@axis-core-1.0.0/interfaces/IBatchAuctionHouse.sol";

contract BidClaimScript is Script, Constants {
    function run() public {
        // Define the deployed BatchAuctionHouse
        IBatchAuctionHouse auctionHouse = IBatchAuctionHouse(_batchAuctionHouse);

        // Obtain the lot from the environment variable
        uint96 lotId;
        {
            uint256 lotIdRaw = vm.envUint("LOT_ID");
            if (lotIdRaw > type(uint96).max) {
                revert("LOT_ID must be less than uint96 max");
            }
            lotId = uint96(lotIdRaw);
        }

        // Obtain the bid from the environment variable
        uint64 bidId;
        {
            uint256 bidIdRaw = vm.envUint("BID_ID");
            if (bidIdRaw > type(uint64).max) {
                revert("BID_ID must be less than uint64 max");
            }
            bidId = uint64(bidIdRaw);
        }

        // Prepare the bid ids array
        uint64[] memory bidIds = new uint64[](1);
        bidIds[0] = bidId;

        // Perform the claim
        // Anyone can claim bids on behalf of the bidder
        // The proceeds/payout will go to the bidder
        auctionHouse.claimBids(lotId, bidIds);
        console2.log("Bid claim completed. Lot ID: %d, Bid ID: %d", lotId, bidId);
    }
}
