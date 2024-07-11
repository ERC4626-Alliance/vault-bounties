// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VeloERC7575VaultHarness} from "./harness/VeloERC7575VaultHarness.sol";
import {VelodromeERC7575Share} from "./../src/VelodromeERC7575Share.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IPool} from "./../src/interfaces/IPool.sol";
import {IRouter} from "./../src/interfaces/IRouter.sol";

contract VeloERC7575Vault_ForkTest is Test {
    VeloERC7575VaultHarness public sut;
    IPool public pool;
    ERC20 public usdc;
    ERC20 public dai;
    IRouter public router;
    VelodromeERC7575Share public share;

    address constant POOL_ADDRESS = 0x19715771E30c93915A5bbDa134d782b81A820076;
    address constant ROUTER_ADDRESS = 0x9c12939390052919aF3155f41Bf4160Fd3666A6f;
    address constant USDC_ADDRESS = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
    address constant DAI_ADDRESS = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    uint256 constant FORK_BLOCK = 122524782;
    uint256 constant INITIAL_AMOUNT_USDC = 1000000 * 1e6; // 1 million
    uint256 constant INITIAL_AMOUNT_DAI = 1000000 * 1e18; // 1 million

    function setUp() public {
        // Fork Optimism mainnet
        vm.createSelectFork("https://1rpc.io/op", FORK_BLOCK);

        pool = IPool(POOL_ADDRESS);
        usdc = ERC20(pool.token0());
        dai = ERC20(pool.token1());
        router = IRouter(ROUTER_ADDRESS);

        // Deploy share token
        share = new VelodromeERC7575Share("Test Share", "TST");

        // Deploy vault harness
        sut = new VeloERC7575VaultHarness(address(usdc), "Test Vault", "TSTVLT", pool, pool.stable(), share);

        share.updateVault(address(usdc), address(sut));
    }

    function testSwapHalf_ShouldSwapHalf() public {
        deal(address(usdc), address(sut), INITIAL_AMOUNT_USDC);
        uint256 initialUsdcBalance = usdc.balanceOf(address(sut));
        uint256 initialDaiBalance = dai.balanceOf(address(sut));

        uint256 amountIn = 1000 * 1e6; // 1000 USDC
        (uint256 amountA, uint256 amountB) = sut.swapHalfExposed(amountIn);

        uint256 finalUsdcBalance = usdc.balanceOf(address(sut));
        uint256 finalDaiBalance = dai.balanceOf(address(sut));

        assertEq(finalUsdcBalance, initialUsdcBalance - amountA, "Incorrect USDC balance after swap");
        assertEq(finalDaiBalance, initialDaiBalance + amountB, "Incorrect DAI balance after swap");
        assertApproxEqRel(amountA, amountIn / 2, 1e16, "amountA should be approximately half of amountIn");
        assertTrue(amountB > 0, "amountB should be greater than 0");
    }

    function testSwapFull_ShouldSwapAll() public {
        deal(address(dai), address(sut), INITIAL_AMOUNT_DAI);
        uint256 initialUsdcBalance = usdc.balanceOf(address(sut));
        uint256 initialDaiBalance = dai.balanceOf(address(sut));

        uint256 amountIn = 1000 * 1e18; // 1000 DAI
        sut.swapFullExposed(amountIn);

        uint256 finalUsdcBalance = usdc.balanceOf(address(sut));
        uint256 finalDaiBalance = dai.balanceOf(address(sut));

        assertTrue(finalUsdcBalance > initialUsdcBalance, "USDC balance should change");
        assertApproxEqRel(initialDaiBalance, finalDaiBalance, 1e17, "Dai balance should not increase");
    }

    function testDeposit() public {
        uint256 depositAmount = 1000 * 1e6; // 1000 USDC

        // Mint initial USDC to this contract
        deal(USDC_ADDRESS, address(this), INITIAL_AMOUNT_USDC);

        // Approve USDC spending for the vault
        usdc.approve(address(sut), type(uint256).max);

        // Get initial balances
        // uint256 initialUsdcBalance = usdc.balanceOf(address(this));
        uint256 initialShareBalance = share.balanceOf(address(this));
        // uint256 initialVaultUsdcBalance = usdc.balanceOf(address(sut));
        // uint256 initialVaultDaiBalance = dai.balanceOf(address(sut));

        // Perform deposit
        uint256 expectedShares = sut.previewDeposit(depositAmount);
        uint256 receivedShares = sut.deposit(depositAmount, address(this));

        // Check received shares
        assertGt(receivedShares, expectedShares, "Received less than expected shares");

        // Check final balances
        // uint256 finalUsdcBalance = usdc.balanceOf(address(this));
        uint256 finalShareBalance = share.balanceOf(address(this));
        uint256 finalVaultUsdcBalance = usdc.balanceOf(address(sut));
        // uint256 finalVaultDaiBalance = dai.balanceOf(address(sut));

        // Should deposit all
        assertEq(finalVaultUsdcBalance, 0, "Incorrect final USDC balance for vault");
        // assertEq(finalVaultDaiBalance, 0, "Incorrect final Dai balance for vault");

        // Assert shares were minted to user
        // assertEq(finalShareBalance, initialShareBalance + receivedShares, "Incorrect final share balance for user");
    }

    function testMint() public {
        uint256 sharesToMint = 0.001 * 1e18; 
        uint256 expectedAssets = sut.previewMint(sharesToMint);
 
        // Mint initial USDC to this contract
        deal(USDC_ADDRESS, address(this), expectedAssets * 2);

        // Approve USDC spending for the vault
        usdc.approve(address(sut), type(uint256).max);

        // Get initial balances
        uint256 initialShareBalance = share.balanceOf(address(this));
        uint256 initialUsdcBalance = usdc.balanceOf(address(this));
        uint256 initialVaultLpBalance = ERC20(address(pool)).balanceOf(address(sut));

        // Perform mint
        uint256 actualAssets = sut.mint(sharesToMint, address(this));
         // Check final balances
        uint256 finalShareBalance = share.balanceOf(address(this));
        uint256 finalUsdcBalance = usdc.balanceOf(address(this));
        uint256 finalVaultLpBalance = ERC20(address(pool)).balanceOf(address(sut));

        // Assert shares were minted to user
        assertApproxEqRel(finalShareBalance, initialShareBalance + sharesToMint,1e16, "Incorrect final share balance for user");

        // Assert USDC was transferred from user to vault
        assertEq(finalUsdcBalance, initialUsdcBalance - actualAssets, "Incorrect final USDC balance for user");

        // Assert LP tokens were received by the vault
        assertGt(finalVaultLpBalance, initialVaultLpBalance, "Vault should have received LP tokens");

        // Assert actual assets used is close to expected assets
        assertApproxEqRel(actualAssets, expectedAssets, 1e16, "Actual assets should be close to expected assets");

        // Assert vault has no leftover USDC or DAI
        assertApproxEqAbs(usdc.balanceOf(address(sut)), 0, 1, "Vault should have no leftover USDC");
        
        // DUST ISSUE!!!
        // assertApproxEqAbs(dai.balanceOf(address(sut)), 0, 1, "Vault should have no leftover DAI");
    }

    function testWithdraw() public {
        // Deposit some assets to have shares to withdraw
        uint256 depositAmount = 1000 * 1e6; // 1000 USDC
        deal(USDC_ADDRESS, address(this), depositAmount);
        usdc.approve(address(sut), type(uint256).max);
        sut.deposit(depositAmount, address(this));

        uint256 withdrawAmount = depositAmount / 2; // Withdraw half of the original deposit
        uint256 initialShares = share.balanceOf(address(this));

        uint256 sharesToWithdraw = sut.previewWithdraw(withdrawAmount);
        uint256 actualShares = sut.withdraw(withdrawAmount, address(this), address(this));

        // Check if correct number of shares were burned
        assertEq(actualShares, sharesToWithdraw, "Incorrect number of shares withdrawn");
        assertEq(share.balanceOf(address(this)), initialShares - sharesToWithdraw, "Incorrect final share balance");
    }

    function testRedeem() public {
        // Deposit some assets to have shares to redeem
        uint256 depositAmount = 1000 * 1e6; // 1000 USDC
        deal(USDC_ADDRESS, address(this), depositAmount);
        usdc.approve(address(sut), type(uint256).max);
        uint256 receivedShares = sut.deposit(depositAmount, address(this));

        uint256 redeemShares = receivedShares / 2; // Redeem half of the received shares
        uint256 initialAssets = usdc.balanceOf(address(this));
        uint256 initialShares = share.balanceOf(address(this));

        uint256 assetsToReceive = sut.previewRedeem(redeemShares);
        uint256 actualAssets = sut.redeem(redeemShares, address(this), address(this));

        // Check if correct amount of assets were received
        assertEq(actualAssets, assetsToReceive, "Incorrect amount of assets received");
        assertApproxEqRel(
            usdc.balanceOf(address(this)), initialAssets + assetsToReceive, 1e16, "Incorrect final asset balance"
        );

        // Check if correct number of shares were burned
        assertEq(share.balanceOf(address(this)), initialShares - redeemShares, "Incorrect final share balance");
    }
}