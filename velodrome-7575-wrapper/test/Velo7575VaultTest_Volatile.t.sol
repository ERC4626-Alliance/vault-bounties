// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VeloERC7575VaultHarness} from "./harness/VeloERC7575VaultHarness.sol";
import {VelodromeERC7575Share} from "./../src/VelodromeERC7575Share.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IPool} from "./../src/interfaces/IPool.sol";
import {IRouter} from "./../src/interfaces/IRouter.sol";

/// @notice Tests for Volatile pool 7575Vault wrapper 
contract VeloERC7575VaultVolatile_ForkTest is Test {
    VeloERC7575VaultHarness public sut;
    IPool public pool;
    ERC20 public usdc;
    ERC20 public velo;
    IRouter public router;
    VelodromeERC7575Share public share;

    address constant POOL_ADDRESS = 0xa0A215dE234276CAc1b844fD58901351a50fec8A;
    address constant ROUTER_ADDRESS = 0x9c12939390052919aF3155f41Bf4160Fd3666A6f;
    address constant USDC_ADDRESS = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address constant VELO_ADDRESS = 0x9560e827aF36c94D2Ac33a39bCE1Fe78631088Db;
    uint256 constant FORK_BLOCK = 122524782;
    uint256 constant INITIAL_AMOUNT_USDC = 1000000 * 1e6; // 1 million
    uint256 constant INITIAL_AMOUNT_VELO = 1000000 * 1e18; // 1 million

    function setUp() public {
        // Fork Optimism mainnet
        vm.createSelectFork("https://1rpc.io/op", FORK_BLOCK);

        pool = IPool(POOL_ADDRESS);
        usdc = ERC20(pool.token0());
        velo = ERC20(pool.token1());
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
        uint256 initialVeloBalance = velo.balanceOf(address(sut));

        uint256 amountIn = 1000 * 1e6; // 1000 USDC
        (uint256 amountA, uint256 amountB) = sut.swapHalfExposed(amountIn);

        uint256 finalUsdcBalance = usdc.balanceOf(address(sut));
        uint256 finalVeloBalance = velo.balanceOf(address(sut));

        assertEq(finalUsdcBalance, initialUsdcBalance - amountA, "Incorrect USDC balance after swap");
        assertEq(finalVeloBalance, initialVeloBalance + amountB, "Incorrect VELO balance after swap");
        assertApproxEqRel(amountA, amountIn / 2, 1e16, "amountA should be approximately half of amountIn");
        assertTrue(amountB > 0, "amountB should be greater than 0");
    }

    function testSwapFull_ShouldSwapAll() public {
        deal(address(velo), address(sut), INITIAL_AMOUNT_VELO);
        uint256 initialUsdcBalance = usdc.balanceOf(address(sut));
        uint256 initialVeloBalance = velo.balanceOf(address(sut));

        uint256 amountIn = 1000 * 1e18; // 1000 VELO
        sut.swapFullExposed(amountIn);

        uint256 finalUsdcBalance = usdc.balanceOf(address(sut));
        uint256 finalVeloBalance = velo.balanceOf(address(sut));

        assertTrue(finalUsdcBalance > initialUsdcBalance, "USDC balance should change");
        assertApproxEqRel(initialVeloBalance, finalVeloBalance, 1e17, "Velo balance should not increase");
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
        // uint256 initialVaultVeloBalance = velo.balanceOf(address(sut));

        // Perform deposit
        uint256 expectedShares = sut.previewDeposit(depositAmount);
        uint256 receivedShares = sut.deposit(depositAmount, address(this));

        // Check received shares
        assertGt(receivedShares, expectedShares, "Received less than expected shares");

        // Check final balances
        // uint256 finalUsdcBalance = usdc.balanceOf(address(this));
        uint256 finalShareBalance = share.balanceOf(address(this));
        uint256 finalVaultUsdcBalance = usdc.balanceOf(address(sut));
        uint256 finalVaultVeloBalance = velo.balanceOf(address(sut));

        // Should deposit all (minimal dust okay)
        // assertApproxEqRel(finalVaultUsdcBalance, 0, 1e17, "Incorrect final USDC balance for vault");
        // assertApproxEqRel(finalVaultVeloBalance, 0, 1e17, "Incorrect final Velo balance for vault");

        // Assert shares were minted to user
         assertEq(finalShareBalance, initialShareBalance + receivedShares, "Incorrect final share balance for user");
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
        assertGe(
            finalShareBalance, initialShareBalance + sharesToMint, "Incorrect final share balance for user"
        );

        // Assert USDC was transferred from user to vault
        assertEq(finalUsdcBalance, initialUsdcBalance - actualAssets, "Incorrect final USDC balance for user");

        // Assert LP tokens were received by the vault
        assertGt(finalVaultLpBalance, initialVaultLpBalance, "Vault should have received LP tokens");

        // Assert actual assets used is close to expected assets
        assertApproxEqRel(actualAssets, expectedAssets, 1e16, "Actual assets should be close to expected assets");

    
        // DUST ISSUE!!!
        // assertApproxEqAbs(velo.balanceOf(address(sut)), 0, 1, "Vault should have no leftover VELO");
        // Assert vault has no leftover USDC or VELO
        //assertApproxEqAbs(usdc.balanceOf(address(sut)), 0, 1, "Vault should have no leftover USDC");
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

    function testDepositWithdraw() public {
        uint256 amount = 100e6;
        address alice = address(0x1);
        deal(address(usdc), alice, 1000 ether);
        vm.startPrank(alice);

        usdc.approve(address(sut), amount);

        uint256 aliceShareAmount = sut.deposit(amount, alice);
        uint256 aliceShareBalance = share.balanceOf(alice);
        uint256 aliceAssetsToWithdraw = sut.previewRedeem(aliceShareAmount);
        uint256 previewWithdraw = sut.previewWithdraw(aliceAssetsToWithdraw);

        console.log("aliceShareAmount", aliceShareAmount);
        console.log("aliceShareBalance", aliceShareBalance);
        console.log(previewWithdraw, "shares to burn for", aliceAssetsToWithdraw, "assets");

        uint256 sharesBurned = sut.withdraw(aliceAssetsToWithdraw, alice, alice);

        console.log("aliceSharesBurned", sharesBurned);
        console.log("aliceShareBalance", share.balanceOf(alice));

        aliceAssetsToWithdraw = sut.previewRedeem(share.balanceOf(alice));

        console.log("assetsLeftover", aliceAssetsToWithdraw);
    }

    function testMultipleDepositWithdraw() public {
        uint256 amount = 100e6;
        uint256 amountAdjusted = 95e6;
        address alice = address(0x1);
        address bob = address(0x2);
        deal(address(usdc), alice, 1000 ether);
        deal(address(usdc), bob, 1000 ether);
        /// Step 1: Alice deposits 100 tokens, no withdraw
        vm.startPrank(alice);
        usdc.approve(address(sut), amount);
        uint256 aliceShareAmount = sut.deposit(amount, alice);
        console.log("aliceShareAmount", aliceShareAmount);
        vm.stopPrank();

        /// Step 2: Bob deposits 100 tokens, no withdraw
        vm.startPrank(bob);
        usdc.approve(address(sut), amount);
        uint256 bobShareAmount = sut.deposit(amount, bob);
        console.log("bobShareAmount", bobShareAmount);
        vm.stopPrank();

        /// Step 3: Alice withdraws 95 tokens
        vm.startPrank(alice);
        uint256 sharesBurned = sut.withdraw(amountAdjusted, alice, alice);
        console.log("aliceSharesBurned", sharesBurned);
        vm.stopPrank();

        /// Step 4: Bob withdraws max amount of asset from shares
        vm.startPrank(bob);
        uint256 assetsToWithdraw = sut.previewRedeem(bobShareAmount);
        console.log("assetsToWithdraw", assetsToWithdraw);
        sharesBurned = sut.withdraw(assetsToWithdraw, bob, bob);
        console.log("bobSharesBurned", sharesBurned);
        vm.stopPrank();

        /// Step 5: Alice withdraws max amount of asset from remaining shares
        vm.startPrank(alice);
        assetsToWithdraw = sut.previewRedeem(share.balanceOf(alice));
        console.log("assetsToWithdraw", assetsToWithdraw);
        sharesBurned = sut.withdraw(assetsToWithdraw, alice, alice);
        console.log("aliceSharesBurned", sharesBurned);
    }

        function testMintRedeem() public {
            address alice = address(0x1);
            deal(address(usdc), alice, 1000 ether);
        /// NOTE:   uniShares          44367471942413
        /// we "overmint" shares to avoid revert, all is returned to the user
        /// previewMint() returns a correct amount of assets required to be approved to receive this
        /// as MINIMAL amount of shares. where function differs is that if user was to run calculations
        /// himself, directly against UniswapV2 Pair, calculations would output smaller number of assets
        /// required for that amountOfSharesToMint, that is because UniV2 Pair doesn't need to swapJoin()
        uint256 amountOfSharesToMint = 44_323_816_369_031;
        console.log("amountOfSharesToMint", amountOfSharesToMint);
        vm.startPrank(alice);

        /// NOTE: In case of this ERC4626 adapter, its highly advisable to ALWAYS call previewMint() before mint()
        uint256 assetsToApprove = sut.previewMint(amountOfSharesToMint);
        console.log("aliceAssetsToApprove", assetsToApprove);

        usdc.approve(address(sut), assetsToApprove);

        uint256 aliceAssetsMinted = sut.mint(amountOfSharesToMint, alice);
        console.log("aliceAssetsMinted", aliceAssetsMinted);

        uint256 aliceBalanceOfShares = share.balanceOf(alice);
        console.log("aliceBalanceOfShares", aliceBalanceOfShares);

        /// TODO: Verify calculation, because it demands more shares than the ones minted for same asset
        /// @dev not used for redemption
        uint256 alicePreviewRedeem = sut.previewWithdraw(aliceAssetsMinted);
        console.log("alicePreviewRedeem", alicePreviewRedeem);
        //  aliceBalanceOfShares 44071500607485
        //  alicePreviewRedeem   41867925577110
        // alice has more shares than previewRedeem asks for to get assetsMinted
        uint256 sharesBurned = sut.redeem(alicePreviewRedeem, alice, alice);
        console.log("sharesBurned", sharesBurned);

        aliceBalanceOfShares = share.balanceOf(alice);
        console.log("aliceBalanceOfShares2", aliceBalanceOfShares);
    }
}
