// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VelodromeERC7575VaultFactory} from "./../src/VelodromeERC7575VaultFactory.sol";

contract DeployVelodromeERC7575VaultFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        VelodromeERC7575VaultFactory factory = new VelodromeERC7575VaultFactory();
        console.log("VelodromeERC7575VaultFactory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
