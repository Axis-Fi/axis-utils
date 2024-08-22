// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {Script} from "@forge-std-1.9.1/Script.sol";
import {console2} from "@forge-std-1.9.1/console2.sol";
import {Constants} from "../constants.s.sol";

// Axis contracts
import {IBatchAuctionHouse} from "@axis-core-1.0.1/interfaces/IBatchAuctionHouse.sol";
import {IEncryptedMarginalPrice} from
    "@axis-core-1.0.1/interfaces/modules/auctions/IEncryptedMarginalPrice.sol";
import {IBatchAuction} from "@axis-core-1.0.1/interfaces/modules/IBatchAuction.sol";

contract SettleScript is Script, Constants {
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
        address moduleAddress = address(auctionHouse.getAuctionModuleForId(lotId));

        // Submit the private key
        // The call can be performed by anyone
        {
            uint256 privateKey = vm.envUint("AUCTION_PRIVATE_KEY");

            // Submit private key can decrypt the bids, but we will skip this
            uint64 submitNumBids;
            bytes32[] memory submitSortHints;

            IEncryptedMarginalPrice(moduleAddress).submitPrivateKey(
                lotId, privateKey, submitNumBids, submitSortHints
            );
        }

        // Get the number of bids
        uint256 numBids = IBatchAuction(moduleAddress).getNumBids(lotId);

        uint64 bidsPerBatch = 100;

        // Prepare the sort hints
        // This will not result in optimal gas usage
        bytes32 queueStart = 0x0000000000000000ffffffffffffffffffffffff000000000000000000000001;
        bytes32[] memory sortHints = new bytes32[](bidsPerBatch);
        for (uint64 i = 0; i < bidsPerBatch; i++) {
            sortHints[i] = queueStart;
        }

        // Decrypt the bids in 100-bid batches
        // If the number of bids is less than 100, numBatches will be 0 due to integer division and rounding down
        IEncryptedMarginalPrice empModule = IEncryptedMarginalPrice(moduleAddress);
        uint256 numBatches = numBids / bidsPerBatch;
        for (uint64 i = 0; i <= numBatches; i++) {
            // The call can be performed by anyone
            empModule.decryptAndSortBids(lotId, bidsPerBatch, sortHints);
        }

        // Define callback data (unused)
        bytes memory callbackData = abi.encode("");

        // Perform the settlement
        // The call can be performed by anyone
        auctionHouse.settle(lotId, numBids, callbackData);
        console2.log("Settlement completed. Lot ID:", lotId);
    }
}
