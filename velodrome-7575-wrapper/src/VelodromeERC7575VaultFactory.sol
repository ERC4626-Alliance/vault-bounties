// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IPool} from "./interfaces/IPool.sol";
import {VelodromeERC7575Share} from "./VelodromeERC7575Share.sol";
import {VelodromeERC7575Vault} from "./VelodromeERC7575Vault.sol";

contract VelodromeERC7575VaultFactory {
    event PoolCreated(address indexed shareToken, address indexed vault0, address indexed vault1, address pool);

    function createVault(address token0, address token1, IPool pool)
        external
        returns (address shareToken, address vault0, address vault1)
    {
        require(pool.token0() == token0 && pool.token1() == token1, "INVALID_POOL");

        // Create share token
        // TODO: Dynaminally construct share token name and symbol using LibString
        shareToken = address(new VelodromeERC7575Share("ShareName", "ShareSymbol"));

        // Create vault for token0
        // TODO: Dynaminally construct vault name and symbol using LibString
        vault0 =
            address(new VelodromeERC7575Vault(token0, "Vault0", "Symbol0", pool, pool.stable(), ERC20((shareToken))));

        // Create vault for token1
        // TODO: Dynaminally construct vault name and symbol using LibString
        vault1 =
            address(new VelodromeERC7575Vault(token1, "Vault1", "Symbol1", pool, pool.stable(), ERC20((shareToken))));

        // Update vault address mapping in share token contract
        VelodromeERC7575Share(shareToken).updateVault(token0, vault0);
        VelodromeERC7575Share(shareToken).updateVault(token1, vault1);

        emit PoolCreated(shareToken, vault0, vault1, address(pool));
    }
}
