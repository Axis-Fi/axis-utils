// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {Script} from "forge-std/Script.sol";
import {Constants} from "script/guides/constants.s.sol";
import {console2} from "forge-std/console2.sol";

// Axis contracts
import {IBatchAuctionHouse} from "src/interfaces/IBatchAuctionHouse.sol";
import {IEncryptedMarginalPrice} from "src/interfaces/modules/auctions/IEncryptedMarginalPrice.sol";
import {IBatchAuction} from "src/interfaces/IBatchAuction.sol";

contract SettleScript is Script, Constants {
    bytes32 internal constant _QUEUE_START =
        0x0000000000000000ffffffffffffffffffffffff000000000000000000000001;

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

        // Load the EMP module
        address moduleAddress = address(auctionHouse.getModuleForId(lotId));

        // Submit the private key
        // The call can be performed by anyone
        {
            uint256 privateKey = vm.envUint("AUCTION_PRIVATE_KEY");

            // Submit private key can decrypt the bids, but we will skip this
            uint64 numBidsToDecrypt;
            bytes32[] memory sortHints;

            IEncryptedMarginalPrice(moduleAddress).submitPrivateKey(
                lotId, privateKey, numBidsToDecrypt, sortHints
            );
        }

        // Get the number of bids
        uint256 numBids = IBatchAuction(moduleAddress).getNumBids(lotId);

        // Decrypt the bids
        // The call can be performed by anyone
        {
            IEncryptedMarginalPrice empModule = IEncryptedMarginalPrice(moduleAddress);

            // Determine the number of 100-bid batches to decrypt
            uint256 numBatches = numBids / 100;

            // Prepare the sort hints
            // This will not result in optimal gas usage
            bytes32[] memory sortHints = new bytes32[](100);
            for (uint64 i = 0; i < 100; i++) {
                sortHints[i] = _QUEUE_START;
            }

            // Decrypt the bids in 100-bid batches
            // If the number of bids is less than 100, numBatches will be 0 due to integer division and rounding down
            for (uint64 i = 0; i <= numBatches; i++) {
                empModule.decryptAndSortBids(lotId, 100, sortHints);
            }
        }

        // Define callback data (unused)
        bytes memory callbackData = abi.encode("");

        // Perform the settlement
        // The call can be performed by anyone
        auctionHouse.settle(lotId, numBids, callbackData);
        console2.log("Settlement completed. Lot ID:", lotId);
    }
}
