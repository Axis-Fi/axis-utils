// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Scripting libraries
import {Script, console2} from "@forge-std-1.9.1/Script.sol";

// Generic contracts
import {MockERC20} from "../../../test/mocks/MockERC20.sol";

contract DeployTokens is Script {
    function deployTestTokens(address seller, address buyer) public {
        vm.startBroadcast();

        // Deploy mock tokens
        MockERC20 quoteToken = new MockERC20();
        quoteToken.initialize("Test Token 1", "TT1", 18);
        console2.log("Quote token deployed at address: ", address(quoteToken));
        MockERC20 baseToken = new MockERC20();
        baseToken.initialize("Test Token 2", "TT2", 18);
        console2.log("Base token deployed at address: ", address(baseToken));

        // Mint quote tokens to buyer
        quoteToken.mint(buyer, 1e25);
        console2.log("Minted 1e25 quote tokens to buyer");

        // Mint base tokens to seller
        baseToken.mint(seller, 1e25);
        console2.log("Minted 1e25 base tokens to seller");

        vm.stopBroadcast();
    }

    function mintTestTokens(address token, address receiver) public {
        // Mint tokens to address
        vm.broadcast();
        MockERC20(token).mint(receiver, 1e24);
    }
}
