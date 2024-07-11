// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/VelodromeERC7575VaultFactory.sol";
import "../src/interfaces/IPool.sol";

/// @notice Script to create vaults via the {VelodromeERC7575VaultFactory} contract
contract CreateVaultScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Replace with the actual factory address post deployment
        address factoryAddress = 0x1234567890123456789012345678901234567890;
        VelodromeERC7575VaultFactory factory = VelodromeERC7575VaultFactory(factoryAddress);

        // Replace with the token and pool addresses
        address token0 = 0x0987654321098765432109876543210987654321;
        address token1 = 0x1111111111111111111111111111111111111111;
        address poolAddress = 0x2222222222222222222222222222222222222222;

        (address shareToken, address vault0, address vault1) = factory.createVault(token0, token1, IPool(poolAddress));
        console.log("Share Token deployed at:", shareToken);
        console.log("Vault for Token0 deployed at:", vault0);
        console.log("Vault for Token1 deployed at:", vault1);

        vm.stopBroadcast();
    }
}