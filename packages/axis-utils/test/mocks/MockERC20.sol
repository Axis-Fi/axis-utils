// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MockERC20 as ForgeERC20} from "@forge-std-1.9.1/mocks/MockERC20.sol";

contract MockERC20 is ForgeERC20 {
    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}
