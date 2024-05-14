// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {Script} from "forge-std/Script.sol";
import {Constants} from "script/guides/constants.s.sol";
import {console2} from "forge-std/console2.sol";

// Axis contracts
import {IBatchAuctionHouse} from "src/interfaces/IBatchAuctionHouse.sol";
import {IBatchAuction} from "src/interfaces/IBatchAuction.sol";

contract BidCancelScript is Script, Constants {
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

        // Get the auction module
        IBatchAuction empModule = IBatchAuction(address(auctionHouse.getModuleForId(lotId)));

        // Determine the index of the bid
        uint256 bidCount = empModule.getNumBids(lotId);
        uint256 bidIndex;
        bool bidIndexFound;
        for (uint256 i = 0; i < bidCount; i++) {
            if (empModule.getBidIdAtIndex(lotId, i) == bidId) {
                bidIndex = i;
                bidIndexFound = true;
                break;
            }
        }
        if (bidIndexFound == false) {
            revert("Bid not found");
        }

        // Conduct the cancellation as the bidder
        address bidder = address(0x10);

        vm.prank(bidder);
        auctionHouse.refundBid(lotId, bidId, bidIndex);
        console2.log("Purchase completed. Lot ID: %d, Bid ID: %d", lotId, bidId);
    }
}
