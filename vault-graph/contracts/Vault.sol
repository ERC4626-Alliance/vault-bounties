// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract Vault is ERC4626 {
    constructor(IERC20 asset) ERC20("Vault", "VAULT") ERC4626(asset) {}
}
