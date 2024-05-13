// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Constants {
    /// @dev This is a testnet address
    address internal _auctionHouse = address(0xAA0000A0F9FF55d5F00aB9cc8d05eF78DE4f9E8f);

    address internal constant _OWNER = address(0x1);
    address internal constant _SELLER = address(0x2);
    address internal constant _PROTOCOL = address(0x3);
    address internal constant _REFERRER = address(0x4);
    address internal constant _BUYER = address(0x5);
}
