// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {Constants} from "script/guides/constants.s.sol";

// Mocks
import {MockERC20} from "test/mocks/MockERC20.sol";

// Axis contracts
import {IAuctionHouse} from "src/interfaces/IAuctionHouse.sol";
import {IAtomicAuctionHouse} from "src/interfaces/IAtomicAuctionHouse.sol";

import {IAuction} from "src/interfaces/modules/IAuction.sol";
import {IFixedPriceSale} from "src/interfaces/modules/auctions/IFixedPriceSale.sol";

import {IDerivative} from "src/interfaces/modules/IDerivative.sol";
import {ILinearVesting} from "src/interfaces/modules/derivatives/ILinearVesting.sol";

import {ICallback} from "src/interfaces/ICallback.sol";
import {toKeycode} from "src/modules/Keycode.sol";

contract DerivativesScript is Script, Constants {
    function createAuction() external {
        // Define the deployed AuctionHouse
        IAtomicAuctionHouse auctionHouse = IAtomicAuctionHouse(_atomicAuctionHouse);

        // Define the tokens used in the auction
        MockERC20 quoteToken = _getQuoteToken();
        MockERC20 baseToken = _getBaseToken();

        // Prepare the parameters for the linear vesting derivative module
        uint48 vestingStart = uint48(block.timestamp + 7 days);
        uint48 vestingExpiry = vestingStart + 90 days;
        ILinearVesting.VestingParams memory vestingParams =
            ILinearVesting.VestingParams({start: vestingStart, expiry: vestingExpiry});

        // Define the auction routing parameters
        IAuctionHouse.RoutingParams memory routingParams = IAuctionHouse.RoutingParams({
            auctionType: toKeycode("EMPA"),
            baseToken: address(baseToken),
            quoteToken: address(quoteToken),
            curator: address(0), // Optional
            callbacks: ICallback(address(0)), // Optional
            callbackData: abi.encode(""), // Optional
            derivativeType: toKeycode("LIV"), // Linear vesting
            derivativeParams: abi.encode(vestingParams), // Linear vesting parameters
            wrapDerivative: false // true to wrap derivative tokens in an ERC20
        });

        // Define the auction module parameters
        IFixedPriceSale.AuctionDataParams memory fpsParams;
        {
            uint256 fpsPrice = 1e18;
            uint24 maxPayoutPercent = 10_000; // 10000 = 10%
            fpsParams = IFixedPriceSale.AuctionDataParams({
                price: fpsPrice,
                maxPayoutPercent: maxPayoutPercent
            });
        }

        // Define the auction parameters
        IAuction.AuctionParams memory auctionParams;
        uint256 capacity;
        {
            uint48 start = uint48(block.timestamp + 1 days);
            uint48 duration = uint48(3 days);
            bool capacityInQuote = false;
            capacity = 10e18;

            auctionParams = IAuction.AuctionParams({
                start: start,
                duration: duration,
                capacityInQuote: capacityInQuote,
                capacity: capacity,
                implParams: abi.encode(fpsParams)
            });
        }

        // Mint base tokens to the seller
        baseToken.mint(_SELLER, capacity);

        // The AuctionHouse will pull base tokens from the seller upon purchase
        // so approve the auction capacity
        vm.prank(_SELLER);
        baseToken.approve(_atomicAuctionHouse, capacity);

        // Define the IPFS hash for additional information
        string memory ipfsHash = "";

        // Create the auction
        vm.prank(_SELLER);
        uint96 lotId = auctionHouse.auction(routingParams, auctionParams, ipfsHash);
        console2.log("Created auction with lot ID:", lotId);
    }

    function redeem() external {
        IAtomicAuctionHouse auctionHouse = IAtomicAuctionHouse(_atomicAuctionHouse);

        // Obtain the lot from the environment variable
        uint256 lotIdRaw = vm.envUint("LOT_ID");
        if (lotIdRaw > type(uint96).max) {
            revert("LOT_ID must be less than uint96 max");
        }
        uint96 lotId = uint96(lotIdRaw);

        // Prepare inputs
        address recipient = address(0x10);

        // Obtain the lot routing information
        (, address baseToken,,,,,,, bytes memory derivativeParams) = auctionHouse.lotRouting(lotId);

        // Obtain the address of the derivative module
        IDerivative derivativeModule = auctionHouse.getDerivativeModuleForId(lotId);

        // Determine the token id
        uint256 tokenId = derivativeModule.computeId(baseToken, derivativeParams);

        // Determine how much can be redeemed
        uint256 redeemable = derivativeModule.redeemable(recipient, tokenId);
        console2.log("Redeemable amount:", redeemable);

        // Redeem the maximum amount
        // Must be run as the recipient
        vm.prank(recipient);
        derivativeModule.redeemMax(tokenId);
        console2.log("Redeemed maximum amount");
    }
}
