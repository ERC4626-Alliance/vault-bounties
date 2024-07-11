// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {VelodromeERC7575Vault} from "./../../src/VelodromeERC7575Vault.sol";
import {IPool} from "./../../src/interfaces/IPool.sol";
import {ERC20} from "./../../lib/solmate/src/tokens/ERC20.sol";

contract VeloERC7575VaultHarness is VelodromeERC7575Vault {
    constructor(address _asset, string memory _name, string memory _symbol, IPool _pool, bool _isStable, ERC20 _share)
        VelodromeERC7575Vault(_asset, _name, _symbol, _pool, _isStable, _share)
    {}

    function swapHalfExposed(uint256 _amountIn) external returns (uint256, uint256) {
        return _swapHalf(_amountIn);
    }

    function swapFullExposed(uint256 _amountIn) external {
        return _swapFull(_amountIn);
    }
}
