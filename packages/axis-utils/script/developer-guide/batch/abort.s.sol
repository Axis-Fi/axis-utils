// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {Script} from "@forge-std-1.9.1/Script.sol";
import {console2} from "@forge-std-1.9.1/console2.sol";
import {Constants} from "../constants.s.sol";

// Axis contracts
import {IBatchAuctionHouse} from "@axis-core-1.0.0/interfaces/IBatchAuctionHouse.sol";

contract AbortScript is Script, Constants {
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

        // Perform the abort
        // The abort call can be performed by anyone
        auctionHouse.abort(lotId);
        console2.log("Abort completed. Lot ID:", lotId);
    }
}
