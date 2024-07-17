// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Script setup
import {Script} from "@forge-std-1.9.1/Script.sol";
import {console2} from "@forge-std-1.9.1/console2.sol";
import {Constants} from "./constants.s.sol";

// Mocks
import {MockERC20} from "../../test/mocks/MockERC20.sol";

// Libraries
import {ECIES, Point} from "@axis-core-0.5.1/lib/ECIES.sol";

// Axis contracts
import {IAuctionHouse} from "@axis-core-0.5.1/interfaces/IAuctionHouse.sol";
import {IAuction} from "@axis-core-0.5.1/interfaces/modules/IAuction.sol";
import {ICallback} from "@axis-core-0.5.1/interfaces/ICallback.sol";
import {toKeycode} from "@axis-core-0.5.1/modules/Keycode.sol";
import {IEncryptedMarginalPrice} from
    "@axis-core-0.5.1/interfaces/modules/auctions/IEncryptedMarginalPrice.sol";

contract CreateAuctionScript is Script, Constants {
    function run() external {
        // Define the deployed AuctionHouse
        IAuctionHouse auctionHouse = IAuctionHouse(_batchAuctionHouse);

        // Define the tokens used in the auction
        MockERC20 quoteToken = _getQuoteToken();
        MockERC20 baseToken = _getBaseToken();

        // Define the auction routing parameters
        IAuctionHouse.RoutingParams memory routingParams = IAuctionHouse.RoutingParams({
            auctionType: toKeycode("EMPA"),
            baseToken: address(baseToken),
            quoteToken: address(quoteToken),
            curator: address(0), // Optional
            referrerFee: 0, // Optional
            callbacks: ICallback(address(0)), // Optional
            callbackData: abi.encode(""), // Optional
            derivativeType: toKeycode(""), // Optional
            derivativeParams: abi.encode(""), // Optional
            wrapDerivative: false
        });

        // Calculate the auction public key
        Point memory auctionPublicKey =
            ECIES.calcPubKey(Point(1, 2), vm.envUint("AUCTION_PRIVATE_KEY"));

        // Define the auction module parameters
        IEncryptedMarginalPrice.AuctionDataParams memory empParams = IEncryptedMarginalPrice
            .AuctionDataParams({
            minPrice: 1e18, // 1 quote token per base token
            minFillPercent: 10_000, // 10%
            minBidSize: 1e18, // 1 quote token
            publicKey: auctionPublicKey
        });

        // Define the auction parameters
        uint48 start = uint48(block.timestamp + 1 days);
        uint48 duration = uint48(3 days);
        bool capacityInQuote = false;
        uint256 capacity = 10e18;

        IAuction.AuctionParams memory auctionParams = IAuction.AuctionParams({
            start: start,
            duration: duration,
            capacityInQuote: capacityInQuote,
            capacity: capacity,
            implParams: abi.encode(empParams)
        });

        // Mint base tokens to the seller
        baseToken.mint(_SELLER, capacity);

        // The AuctionHouse will pull base tokens from the seller upon auction creation,
        // so approve the auction capacity
        vm.prank(_SELLER);
        baseToken.approve(address(auctionHouse), capacity);

        // Define the IPFS hash for additional information
        string memory ipfsHash = "";

        // Create the auction
        vm.prank(_SELLER);
        uint96 lotId = auctionHouse.auction(routingParams, auctionParams, ipfsHash);
        console2.log("Created auction with lot ID:", lotId);
    }
}
