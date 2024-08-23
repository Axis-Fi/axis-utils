// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {console2} from "@forge-std-1.9.1/console2.sol";
import {Script} from "@forge-std-1.9.1/Script.sol";
import {Constants} from "./constants.s.sol";

// Axis contracts
import {IAuctionHouse} from "@axis-core-1.0.1/interfaces/IAuctionHouse.sol";
import {IFeeManager} from "@axis-core-1.0.1/interfaces/IFeeManager.sol";
import {Keycode, toKeycode} from "@axis-core-1.0.1/modules/Keycode.sol";

contract CuratorScript is Script, Constants {
    function setCuratorMaxFee() public {
        // Define the FeeManager (AuctionHouse)
        IFeeManager auctionHouse = IFeeManager(_atomicAuctionHouse);

        // Get the module keycode from the environment variable
        bytes memory keycodeRaw = vm.envBytes("MODULE_KEYCODE");
        Keycode keycode = toKeycode(bytes5(keycodeRaw));

        // Get the fee from the environment variable
        uint256 feeRaw = vm.envUint("FEE");
        if (feeRaw > type(uint48).max) {
            revert("Fee is greater than uint48 max");
        }
        uint48 fee = uint48(feeRaw);

        // Get the curator max fee
        (,, uint48 maxCuratorFee) = auctionHouse.getFees(keycode);
        console2.log("Current max curator fee: {}", maxCuratorFee);

        // Set the curator max fee
        // Must be performed as the AuctionHouse owner
        vm.prank(_OWNER);
        auctionHouse.setFee(keycode, IFeeManager.FeeType.MaxCurator, fee);
        console2.log("Set max curator fee to: {}", fee);
    }

    function setCuratorFee() public {
        // Define the FeeManager (AuctionHouse)
        IFeeManager auctionHouse = IFeeManager(_atomicAuctionHouse);

        // Get the module keycode from the environment variable
        bytes memory keycodeRaw = vm.envBytes("MODULE_KEYCODE");
        Keycode keycode = toKeycode(bytes5(keycodeRaw));

        // Get the fee from the environment variable
        uint256 feeRaw = vm.envUint("FEE");
        if (feeRaw > type(uint48).max) {
            revert("Fee is greater than uint48 max");
        }
        uint48 fee = uint48(feeRaw);

        // Get the curator fee
        uint48 curatorFee = auctionHouse.getCuratorFee(keycode, _CURATOR);
        console2.log("Current curator fee: {}", curatorFee);

        // Set the curator fee
        // Must be performed as the curator
        vm.prank(_CURATOR);
        auctionHouse.setCuratorFee(keycode, fee);
        console2.log("Set curator fee to: {}", fee);
    }

    function curate() public {
        // Define the AuctionHouse
        IAuctionHouse auctionHouse = IAuctionHouse(_atomicAuctionHouse);

        // Get the lot ID from the environment variable
        uint256 lotIdRaw = vm.envUint("LOT_ID");
        if (lotIdRaw > type(uint96).max) {
            revert("Lot ID is greater than uint96 max");
        }
        uint96 lotId = uint96(lotIdRaw);

        // Callback data is unused in this example
        bytes memory callbackData = abi.encode("");

        // Curate the lot
        // Must be performed as the curator
        vm.prank(_CURATOR);
        auctionHouse.curate(lotId, callbackData);
        console2.log("Curated lot: {}", lotId);
    }
}
