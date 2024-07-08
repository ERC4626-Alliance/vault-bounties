# MultiStrategyVault with 7575 endpoints

## Context

The [MultiStrategyVault (MSV)](https://github.com/ensuro/vaults/blob/main/contracts/MultiStrategyERC4626.sol) is a contract developed by Ensuro for its internal needs of asset management.
It allows plugging different strategy contracts into the vault, which will invest the asset in various ways.
These strategies' code is executed in the context of the vault (using delegatecall), in this way, the investment assets are owned by the main vault which is better for governance and transparency.

## Summary

In this project, I will extend the MSV to make it compatible with the ERC-7575.
The strategy contracts, previously meant just as code extensions of the core vault, will now become entry points that accept calls to enter or exit using directly the investment assets.
This will keep the extensibility of the MSV, and the same asset ownership (the invest assets will still be owned by the MSV),
but will provide new endpoints that can be used for efficiency and practicality.

## Presentation

TO DO.

## Feature achieved

TO DO.

## Architecture

TO DO.

## Pain points

TO DO.

## Libraries used

- https://www.npmjs.com/package/@ensuro/vaults

## EVM Address

0x4d68Cf31d613070b18E406AFd6A42719a62a0785

## Contact

https://x.com/gnarvaja
