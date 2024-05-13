// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {IAuctionHouse} from "src/interfaces/IAuctionHouse.sol";

import {Constants} from "script/guides/constants.s.sol";

contract CreateAuctionScript is Script, Constants {
    function run() external {
        // Define the deployed AuctionHouse
        IAuctionHouse auctionHouse = IAuctionHouse(_auctionHouse);

        // Define the tokens used in the auction

        // Define the auction routing parameters

        // Define the auction module parameters

        // Define the auction parameters

        // Create the auction
    }
}
