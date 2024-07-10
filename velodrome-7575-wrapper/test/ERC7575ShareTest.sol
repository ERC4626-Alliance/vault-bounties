// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VelodromeERC7575Share} from "./../src/VelodromeERC7575Share.sol";


contract ERC7575Share_UnitTest is Test {
    VelodromeERC7575Share public sut; // system-under-test

    address asset1 = makeAddr("asset1");
    address asset2 = makeAddr("asset2");

    address vault1 = makeAddr("vault1");
    address vault2 = makeAddr("vault2");
    function setUp() public {
        sut = new VelodromeERC7575Share("TEST-NAME", "TEST_SYMBOL");
    }

    function testUpdateVault_ShouldUpdateVaultAddress() public {
        sut.updateVault(asset1, vault1);
        assertEq(sut.vault(asset1), vault1);
    }

    function testUpdateVault_ShouldUpdateIsVault() public {
        sut.updateVault(asset1, vault1);
        assertEq(sut.isVault(vault1), true);
    }

     function testMint_OnlyVaultShouldBeAbleToMintShares() public {
        sut.updateVault(asset1, vault1);
        assertEq(sut.balanceOf(address(this)),0);

        vm.prank(vault1);

        sut.mint(address(this),100);

        assertEq(sut.balanceOf(address(this)),100);

        vm.expectRevert("UNAUTHORIZED");
        sut.mint(address(this), 1);
    }

    function testMint_OnlyVaultShouldBeAbleToBurnShares() public {
        sut.updateVault(asset1, vault1);

        vm.prank(vault1);
        sut.mint(address(this),100);

        assertEq(sut.balanceOf(address(this)),100);

        vm.prank(vault1);
        sut.burn(address(this), 100);

        assertEq(sut.balanceOf(address(this)),0);

        vm.expectRevert("UNAUTHORIZED");
        sut.burn(address(this), 1);
    }
}