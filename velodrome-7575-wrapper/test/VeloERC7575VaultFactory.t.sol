// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VelodromeERC7575VaultFactory} from "./../src/VelodromeERC7575VaultFactory.sol";
import {VelodromeERC7575Share} from "./../src/VelodromeERC7575Share.sol";
import {VelodromeERC7575Vault} from "./../src/VelodromeERC7575Vault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IPool} from "./../src/interfaces/IPool.sol";

contract VeloERC7575VaultFactory_ForkTest is Test {
    VelodromeERC7575VaultFactory public sut;
    IPool public pool;
    ERC20 public usdc;
    ERC20 public dai;

    address constant POOL_ADDRESS = 0x19715771E30c93915A5bbDa134d782b81A820076; // USDC-DAI
    uint256 constant FORK_BLOCK = 122524782;

    event PoolCreated(address indexed shareToken, address indexed vault0, address indexed vault1, address pool);

    function setUp() public {
        // Fork Optimism mainnet
        vm.createSelectFork("https://1rpc.io/op", FORK_BLOCK);

        sut = new VelodromeERC7575VaultFactory();
        pool = IPool(POOL_ADDRESS);
        usdc = ERC20(pool.token0());
        dai = ERC20(pool.token1());
    }

    function testCreateVault_ShouldCreateVaultWithCorrectConfig() public {
        vm.expectEmit(false, false, false, true);
        emit PoolCreated(address(0), address(0), address(0), POOL_ADDRESS);

        (address shareToken, address vault0, address vault1) = sut.createVault(address(usdc), address(dai), pool);

        assertTrue(shareToken != address(0), "Share token address should not be zero");
        assertTrue(vault0 != address(0), "Vault0 address should not be zero");
        assertTrue(vault1 != address(0), "Vault1 address should not be zero");

        VelodromeERC7575Share share = VelodromeERC7575Share(shareToken);
        assertEq(share.vault(address(usdc)), vault0, "Incorrect vault0 address in share token");
        assertEq(share.vault(address(dai)), vault1, "Incorrect vault1 address in share token");

        VelodromeERC7575Vault vaultUsdc = VelodromeERC7575Vault(vault0);
        assertEq(address(vaultUsdc.asset()), address(usdc), "Incorrect asset for vault0");
        assertEq(address(vaultUsdc.pool()), POOL_ADDRESS, "Incorrect pool for vault0");
        assertEq(vaultUsdc.isStable(), pool.stable(), "Incorrect stable flag for vault0");

        VelodromeERC7575Vault vaultDai = VelodromeERC7575Vault(vault1);
        assertEq(address(vaultDai.asset()), address(dai), "Incorrect asset for vault1");
        assertEq(address(vaultDai.pool()), POOL_ADDRESS, "Incorrect pool for vault1");
        assertEq(vaultDai.isStable(), pool.stable(), "Incorrect stable flag for vault1");

        assertEq(ERC20(shareToken).name(), "ShareName", "Incorrect share token name");
        assertEq(ERC20(shareToken).symbol(), "ShareSymbol", "Incorrect share token symbol");
        assertEq(ERC20(vault0).name(), "Vault0", "Incorrect vault0 name");
        assertEq(ERC20(vault0).symbol(), "Symbol0", "Incorrect vault0 symbol");
        assertEq(ERC20(vault1).name(), "Vault1", "Incorrect vault1 name");
        assertEq(ERC20(vault1).symbol(), "Symbol1", "Incorrect vault1 symbol");
    }

    function testCreateVault_WithInvalidPool() public {
        address invalidPool = address(0x1234);

        vm.mockCall(invalidPool, abi.encodeWithSelector(IPool.token0.selector), abi.encode(address(0)));

        vm.mockCall(invalidPool, abi.encodeWithSelector(IPool.token1.selector), abi.encode(address(0)));

        vm.expectRevert("INVALID_POOL");
        sut.createVault(address(usdc), address(dai), IPool(invalidPool));
    }
}
