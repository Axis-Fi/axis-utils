// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {Constants} from "script/guides/constants.s.sol";

// Axis contracts
import {IAuction} from "src/interfaces/modules/IAuction.sol";
import {IAuctionHouse} from "src/interfaces/IAuctionHouse.sol";
import {Keycode, toKeycode} from "src/modules/Keycode.sol";

contract ModuleManagementScript is Script, Constants {
    function installModule() public {
        // Define the AuctionHouse
        IAuctionHouse auctionHouse = IAuctionHouse(_atomicAuctionHouse);

        // Get the module address from the environment variable
        address moduleAddress = vm.envAddress("MODULE_ADDRESS");

        // Install the module
        // Must be performed as the owner of the AuctionHouse
        // vm.prank(_OWNER);
        // auctionHouse.installModule(Module(moduleAddress));
    }

    function sunsetModule() public {
        // Define the AuctionHouse
        IAuctionHouse auctionHouse = IAuctionHouse(_atomicAuctionHouse);

        // Get the module keycode from the environment variable
        bytes memory keycodeRaw = vm.envBytes("MODULE_KEYCODE");
        Keycode keycode = toKeycode(bytes5(keycodeRaw));

        // Sunset the module
        // Must be performed as the owner of the AuctionHouse
        // vm.prank(_OWNER);
        // auctionHouse.sunsetModule(keycode);
    }

    function execOnModule() public {
        // Define the AuctionHouse
        IAuctionHouse auctionHouse = IAuctionHouse(_atomicAuctionHouse);

        // Get the module keycode from the environment variable
        bytes memory keycodeRaw = vm.envBytes("MODULE_KEYCODE");
        Keycode keycode = toKeycode(bytes5(keycodeRaw));

        // Prepare the module call
        bytes memory callData = abi.encodeWithSelector(
            IAuction.isLive.selector,
            1 // lotId
        );

        // Execute the call on the module
        // Must be performed as the owner of the AuctionHouse
        // vm.prank(_OWNER);
        // auctionHouse.execOnModule(keycode, callData);
    }
}
