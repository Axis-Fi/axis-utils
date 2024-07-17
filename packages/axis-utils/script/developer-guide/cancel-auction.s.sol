// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {console2} from "@forge-std-1.9.1/console2.sol";
import {Script} from "@forge-std-1.9.1/Script.sol";
import {Constants} from "./constants.s.sol";

// Axis contracts
import {IAuctionHouse} from "@axis-core-0.5.1/interfaces/IAuctionHouse.sol";

contract CancelAuctionScript is Script, Constants {
    function run() public {
        // Define the deployed AuctionHouse
        IAuctionHouse auctionHouse = IAuctionHouse(_batchAuctionHouse);

        // Obtain the lot from the environment variable
        uint256 lotIdRaw = vm.envUint("LOT_ID");
        if (lotIdRaw > type(uint96).max) {
            revert("LOT_ID must be less than uint96 max");
        }
        uint96 lotId = uint96(lotIdRaw);

        // Define callback data (unused)
        bytes memory callbackData = abi.encode("");

        // Cancel the auction
        vm.prank(_SELLER);
        auctionHouse.cancel(lotId, callbackData);
        console2.log("Auction cancelled. Lot ID:", lotId);
    }
}
