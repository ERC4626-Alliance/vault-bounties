// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "./../../lib/forge-std/src/interfaces/IERC20.sol";
/// @title Velodrome Pool interface

interface IERC20MintableBurnable is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}
