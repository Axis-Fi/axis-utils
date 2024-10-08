// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {Script} from "@forge-std-1.9.1/Script.sol";
import {console2} from "@forge-std-1.9.1/console2.sol";
import {Constants} from "../constants.s.sol";

// Mocks
import {MockERC20} from "../../../test/mocks/MockERC20.sol";

// Axis contracts
import {IAtomicAuctionHouse} from "@axis-core-1.0.1/interfaces/IAtomicAuctionHouse.sol";
import {IFixedPriceSale} from "@axis-core-1.0.1/interfaces/modules/auctions/IFixedPriceSale.sol";

contract PurchaseScript is Script, Constants {
    function run(bool usePermit2_) public {
        // Define the deployed AtomicAuctionHouse
        IAtomicAuctionHouse auctionHouse = IAtomicAuctionHouse(_atomicAuctionHouse);

        // Define the tokens used in the auction
        MockERC20 quoteToken = _getQuoteToken();

        // Obtain the lot from the environment variable
        uint256 lotIdRaw = vm.envUint("LOT_ID");
        if (lotIdRaw > type(uint96).max) {
            revert("LOT_ID must be less than uint96 max");
        }
        uint96 lotId = uint96(lotIdRaw);

        // Prepare inputs
        uint256 amount = 1e18;
        uint256 minAmountOut = 2e18;
        address recipient = address(0x10);

        // Prepare parameters for the FixedPriceSale module
        IFixedPriceSale.PurchaseParams memory fpsPurchaseParams =
            IFixedPriceSale.PurchaseParams({minAmountOut: minAmountOut});

        // Prepare Permit2 approval (unused)
        bytes memory permit2Data = abi.encode("");

        // Define callback data (unused)
        bytes memory callbackData = abi.encode("");

        // Prepare parameters
        IAtomicAuctionHouse.PurchaseParams memory purchaseParams = IAtomicAuctionHouse
            .PurchaseParams({
            recipient: recipient, // Who should receive the purchased tokens
            referrer: _REFERRER, // The referrer (e.g. frontend) for the buyer
            lotId: lotId,
            amount: amount, // The amount of quote tokens in
            minAmountOut: minAmountOut, // The minimum amount of base tokens out, otherwise it will revert
            auctionData: abi.encode(fpsPurchaseParams), // Auction module-specific data
            permit2Data: permit2Data // Permit 2 approval (optional)
        });

        // Mint the required quote tokens
        quoteToken.mint(_BUYER, amount);

        // Approve spending of quote tokens
        if (usePermit2_ == false) {
            vm.prank(_BUYER);
            quoteToken.approve(_atomicAuctionHouse, amount);
        }

        // Conduct the purchase
        // The buyer must have enough quote tokens to complete the purchase
        vm.prank(_BUYER);
        uint256 payout = auctionHouse.purchase(purchaseParams, callbackData);
        console2.log("Purchase completed. Payout:", payout);
    }
}
