// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Script
import {Script} from "forge-std/Script.sol";

// Mocks
import {MockERC20} from "test/mocks/MockERC20.sol";

abstract contract Constants is Script {
    /// @dev This is a testnet address
    address internal _atomicAuctionHouse = address(0xAA0000A0F9FF55d5F00aB9cc8d05eF78DE4f9E8f);
    /// @dev This is a testnet address
    address internal _batchAuctionHouse = address(0xBA00003Cc5713c5339f4fD5cA0339D54A88BC87b);

    address internal constant _OWNER = address(0x1);
    address internal constant _SELLER = address(0x2);
    address internal constant _PROTOCOL = address(0x3);
    address internal constant _REFERRER = address(0x4);
    address internal constant _BUYER = address(0x5);
    address internal constant _CURATOR = address(0x6);

    address internal constant _QUOTE_TOKEN = address(0x20);
    address internal constant _BASE_TOKEN = address(0x21);

    bool internal _quoteTokenDeployed;
    bool internal _baseTokenDeployed;

    function _getQuoteToken() internal returns (MockERC20) {
        if (_quoteTokenDeployed) {
            return MockERC20(_QUOTE_TOKEN);
        }

        // Deploy the new token
        MockERC20 quoteToken = new MockERC20();

        // Etch it onto the constant address
        vm.etch(_QUOTE_TOKEN, address(quoteToken).code);
        _quoteTokenDeployed = true;

        MockERC20 etchedQuoteToken = MockERC20(_QUOTE_TOKEN);

        // Initialize
        etchedQuoteToken.initialize("Quote Token", "QT", 18);

        return etchedQuoteToken;
    }

    function _getBaseToken() internal returns (MockERC20) {
        if (_baseTokenDeployed) {
            return MockERC20(_BASE_TOKEN);
        }

        // Deploy the new token
        MockERC20 baseToken = new MockERC20();

        // Etch it onto the constant address
        vm.etch(_BASE_TOKEN, address(baseToken).code);
        _baseTokenDeployed = true;

        MockERC20 etchedBaseToken = MockERC20(_BASE_TOKEN);

        // Initialize
        etchedBaseToken.initialize("Base Token", "BT", 18);

        return etchedBaseToken;
    }
}
