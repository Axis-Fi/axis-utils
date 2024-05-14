// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {Constants} from "script/guides/constants.s.sol";

// Mocks
import {MockERC20} from "test/mocks/MockERC20.sol";

// Axis contracts
import {IBatchAuctionHouse} from "src/interfaces/IBatchAuctionHouse.sol";
import {IEncryptedMarginalPrice} from "src/interfaces/modules/auctions/IEncryptedMarginalPrice.sol";

// Libraries
import {EncryptedMarginalPriceBid} from "src/lib/EncryptedMarginalPriceBid.sol";
import {ECIES, Point} from "src/lib/ECIES.sol";

contract BidSubmitScript is Script, Constants {
    function run(bool usePermit2_) public {
        // Define the deployed BatchAuctionHouse
        IBatchAuctionHouse auctionHouse = IBatchAuctionHouse(_batchAuctionHouse);

        // Define the tokens used in the auction
        MockERC20 quoteToken = _getQuoteToken();

        // Obtain the lot from the environment variable
        uint96 lotId;
        {
            uint256 lotIdRaw = vm.envUint("LOT_ID");
            if (lotIdRaw > type(uint96).max) {
                revert("LOT_ID must be less than uint96 max");
            }
            lotId = uint96(lotIdRaw);
        }

        // Prepare inputs
        uint96 amount = 1e18;
        uint96 amountOut = 2e18;
        address bidder = address(0x10);

        // Fetch the public key from the EncryptedMarginalPrice contract
        Point memory auctionPublicKey;
        {
            IEncryptedMarginalPrice empModule =
                IEncryptedMarginalPrice(address(auctionHouse.getModuleForId(lotId)));
            IEncryptedMarginalPrice.AuctionData memory empAuctionData =
                empModule.getAuctionData(lotId);

            auctionPublicKey = empAuctionData.publicKey;
        }

        // Obtain the bid private key from the environment variable
        uint256 bidPrivateKey = vm.envUint("BID_PRIVATE_KEY");
        uint256 bidSeedRaw = vm.envUint("BID_SEED");
        if (bidSeedRaw > type(uint128).max) {
            revert("BID_SEED must be less than uint128 max");
        }
        uint128 bidSeed = uint128(bidSeedRaw);

        // Encrypt the bid amount out
        uint256 encryptedAmountOut = EncryptedMarginalPriceBid.encryptAmountOut(
            lotId, bidder, amount, amountOut, auctionPublicKey, bidSeed, bidPrivateKey
        );

        // Prepare parameters for the EncryptedMarginalPrice module
        IEncryptedMarginalPrice.BidParams memory empBidParams;
        {
            // Generate a public key for the bid
            Point memory bidPublicKey = ECIES.calcPubKey(auctionPublicKey, bidPrivateKey);

            empBidParams = IEncryptedMarginalPrice.BidParams({
                encryptedAmountOut: encryptedAmountOut,
                bidPublicKey: bidPublicKey
            });
        }

        // Prepare Permit2 approval (unused)
        bytes memory permit2Data = abi.encode("");

        // Define callback data (unused)
        bytes memory callbackData = abi.encode("");

        // Prepare parameters
        IBatchAuctionHouse.BidParams memory bidParams = IBatchAuctionHouse.BidParams({
            lotId: lotId,
            bidder: bidder, // Who should receive the purchased tokens
            referrer: _REFERRER, // The referrer (e.g. frontend) for the buyer
            amount: amount, // The amount of quote tokens in
            auctionData: abi.encode(empBidParams), // Auction module-specific data
            permit2Data: permit2Data // Permit 2 approval (optional)
        });

        // Mint the required quote tokens
        quoteToken.mint(_BUYER, amount);

        // Approve spending of quote tokens
        if (usePermit2_ == false) {
            vm.prank(_BUYER);
            quoteToken.approve(_batchAuctionHouse, amount);
        }

        // Conduct the purchase
        // The buyer must have enough quote tokens to complete the purchase
        vm.prank(_BUYER);
        uint64 bidId = auctionHouse.bid(bidParams, callbackData);
        console2.log("Purchase completed. Bid ID:", bidId);
    }
}
