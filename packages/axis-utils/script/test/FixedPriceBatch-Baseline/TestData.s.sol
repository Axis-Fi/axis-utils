// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Scripting libraries
import {Script, console2} from "@forge-std-1.9.1/Script.sol";
import {WithEnvironment} from "../../WithEnvironment.s.sol";

// System contracts
import {IBatchAuctionHouse} from "@axis-core-1.0.1/interfaces/IBatchAuctionHouse.sol";
import {BatchAuctionHouse} from "@axis-core-1.0.1/BatchAuctionHouse.sol";
import {IAuctionHouse} from "@axis-core-1.0.1/interfaces/IAuctionHouse.sol";
import {toKeycode} from "@axis-core-1.0.1/modules/Modules.sol";
import {ICallback} from "@axis-core-1.0.1/interfaces/ICallback.sol";
import {IFixedPriceBatch} from "@axis-core-1.0.1/interfaces/modules/auctions/IFixedPriceBatch.sol";
import {IAuction} from "@axis-core-1.0.1/interfaces/modules/IAuction.sol";

// Baseline
import {BaselineAxisLaunch} from
    "@axis-periphery-1.0.0/callbacks/liquidity/BaselineV2/BaselineAxisLaunch.sol";

// Generic contracts
import {ERC20} from "@solmate-6.7.0/tokens/ERC20.sol";
import {MockERC20} from "@solmate-6.7.0/test/utils/mocks/MockERC20.sol";

contract TestData is Script, WithEnvironment {
    BatchAuctionHouse public auctionHouse;

    function mintTestTokens(address token, address receiver) public {
        // Mint tokens to address
        vm.broadcast();
        MockERC20(token).mint(receiver, 1e24);
    }

    function createAuction(
        string calldata chain_,
        address quoteToken_,
        address baseToken_,
        address callback_,
        bytes32 merkleRoot,
        uint24 poolPercent_,
        uint24 floorReservesPercent_,
        int24 floorRangeGap_,
        int24 anchorTickU_,
        int24 anchorTickWidth_
    ) public returns (uint96) {
        // Load addresses from .env
        _loadEnv(chain_);
        auctionHouse = BatchAuctionHouse(_envAddressNotZero("deployments.BatchAuctionHouse"));

        vm.startBroadcast();

        // Create Fixed Price Batch auction
        IAuctionHouse.RoutingParams memory routingParams;
        routingParams.auctionType = toKeycode("FPBA");
        routingParams.baseToken = baseToken_;
        routingParams.quoteToken = quoteToken_;
        routingParams.callbacks = ICallback(callback_);
        if (callback_ != address(0)) {
            console2.log("Setting callback parameters");
            routingParams.callbackData = abi.encode(
                BaselineAxisLaunch.CreateData({
                    recipient: msg.sender,
                    poolPercent: poolPercent_,
                    floorReservesPercent: floorReservesPercent_,
                    floorRangeGap: floorRangeGap_,
                    anchorTickU: anchorTickU_,
                    anchorTickWidth: anchorTickWidth_,
                    allowlistParams: abi.encode(merkleRoot)
                })
            );

            // No spending approval necessary, since the callback will handle it
        } else {
            console2.log("Callback disabled");

            // Approve spending of the base token
            ERC20(baseToken_).approve(address(auctionHouse), 10e18);
        }

        IFixedPriceBatch.AuctionDataParams memory auctionDataParams;
        auctionDataParams.price = 1e18; // 1 quote tokens per base token
        auctionDataParams.minFillPercent = uint24(1000); // 10%
        bytes memory implParams = abi.encode(auctionDataParams);

        uint48 duration = 86_400; // 1 day

        IFixedPriceBatch.AuctionParams memory auctionParams;
        auctionParams.start = uint48(0); // immediately
        auctionParams.duration = duration;
        // capaity is in base token
        auctionParams.capacity = 10e18; // 10 base tokens
        auctionParams.implParams = implParams;

        string memory infoHash = "";

        uint96 lotId = auctionHouse.auction(routingParams, auctionParams, infoHash);

        vm.stopBroadcast();

        console2.log("Fixed Price Batch auction created with lot ID: ", lotId);

        // Get the conclusion timestamp from the auction
        (, uint48 conclusion,,,,,,) =
            IAuction(address(auctionHouse.getBatchModuleForId(lotId))).lotData(lotId);
        console2.log("Auction ends at timestamp", conclusion);

        return lotId;
    }

    function cancelAuction(string calldata chain_, uint96 lotId_) public {
        _loadEnv(chain_);
        auctionHouse = BatchAuctionHouse(_envAddressNotZero("deployments.BatchAuctionHouse"));
        vm.broadcast();
        auctionHouse.cancel(lotId_, bytes(""));
    }

    function placeBid(
        string calldata chain_,
        uint96 lotId_,
        uint256 amount_,
        bytes32[] calldata merkleProofs_,
        uint256 allocatedAmount_
    ) public {
        _loadEnv(chain_);
        auctionHouse = BatchAuctionHouse(_envAddressNotZero("deployments.BatchAuctionHouse"));

        // Approve spending of the quote token
        {
            (,, address quoteTokenAddress,,,,,,) = auctionHouse.lotRouting(lotId_);

            vm.broadcast();
            ERC20(quoteTokenAddress).approve(address(auctionHouse), amount_);

            console2.log("Approved spending of quote token by BatchAuctionHouse");
        }

        vm.broadcast();
        uint64 bidId = auctionHouse.bid(
            IBatchAuctionHouse.BidParams({
                lotId: lotId_,
                bidder: msg.sender,
                referrer: address(0),
                amount: amount_,
                auctionData: abi.encode(""),
                permit2Data: bytes("")
            }),
            abi.encode(merkleProofs_, allocatedAmount_)
        );

        console2.log("Bid placed with ID: ", bidId);
    }

    function settleAuction(string calldata chain_, uint96 lotId_) public {
        _loadEnv(chain_);
        auctionHouse = BatchAuctionHouse(_envAddressNotZero("deployments.BatchAuctionHouse"));

        console2.log("Timestamp is", block.timestamp);

        vm.broadcast();
        auctionHouse.settle(lotId_, 100, abi.encode(""));

        console2.log("Auction settled with lot ID: ", lotId_);
    }
}
