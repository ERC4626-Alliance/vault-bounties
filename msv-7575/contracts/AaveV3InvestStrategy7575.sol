// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {AaveV3InvestStrategy} from "@ensuro/vaults/contracts/AaveV3InvestStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPool} from "@ensuro/vaults/contracts/dependencies/aave-v3/IPool.sol";
import {MSV7575Share} from "./MSV7575Share.sol";
import {MSV7575EntryPoint} from "./MSV7575EntryPoint.sol";

/**
 * @title AaveV3InvestStrategy7575
 * @dev Strategy that invests/deinvests into AaveV3 on each deposit/withdraw, with support for 7575 standard
 *
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
contract AaveV3InvestStrategy7575 is AaveV3InvestStrategy, MSV7575EntryPoint {
  constructor(
    IERC20 asset_,
    IPool aave_,
    MSV7575Share msvVault_
  ) AaveV3InvestStrategy(asset_, aave_) MSV7575EntryPoint(msvVault_) {}

  // solhint-disable-next-line func-name-mixedcase
  function _EPAsset() internal view override returns (address assetTokenAddress) {
    return _reserveData().aTokenAddress;
  }

  /**
   * @dev See {IERC7575-totalAssets}.
   */
  function totalAssets() external view override returns (uint256 totalManagedAssets) {
    return AaveV3InvestStrategy.totalAssets(address(_msvVault));
  }

  function _strategyMaxDeposit() internal view override returns (uint256 maxAssetsInEPAssets) {
    return AaveV3InvestStrategy.maxDeposit(address(_msvVault));
  }

  function _strategyMaxWithdraw() internal view override returns (uint256 maxAssetsInEPAssets) {
    return AaveV3InvestStrategy.maxWithdraw(address(_msvVault));
  }

  /**
   * @dev See {IERC7575-maxDeposit}.
   */
  function maxDeposit(
    address receiver
  ) public view virtual override(AaveV3InvestStrategy, MSV7575EntryPoint) returns (uint256 maxAssets) {
    return MSV7575EntryPoint.maxDeposit(receiver);
  }

  /**
   * @dev See {IERC7575-maxWithdraw}.
   */
  function maxWithdraw(
    address owner
  ) public view virtual override(AaveV3InvestStrategy, MSV7575EntryPoint) returns (uint256 maxAssets) {
    return MSV7575EntryPoint.maxWithdraw(owner);
  }
}
