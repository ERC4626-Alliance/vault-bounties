// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {SwapStableInvestStrategy} from "@ensuro/vaults/contracts/SwapStableInvestStrategy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MSV7575Share} from "./MSV7575Share.sol";
import {MSV7575EntryPoint} from "./MSV7575EntryPoint.sol";

/**
 * @title SwapStableInvestStrategy7575
 * @dev Strategy that invests/deinvests by swapping into another token that has a stable price compared to the asset.
 *      Useful for yield bearing rebasing tokens like Lido o USDM
 *
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
contract SwapStableInvestStrategy7575 is SwapStableInvestStrategy, MSV7575EntryPoint {
  constructor(
    IERC20Metadata investAsset_,
    uint256 price_,
    MSV7575Share msvVault_
  ) SwapStableInvestStrategy(IERC20Metadata(msvVault_.asset()), investAsset_, price_) MSV7575EntryPoint(msvVault_) {}

  function _EPAsset() internal view override returns (address assetTokenAddress) {
    return address(_investAsset);
  }

  /**
   * @dev See {IERC7575-totalAssets}.
   */
  function totalAssets() external view override returns (uint256 totalManagedAssets) {
    return _investAsset.balanceOf(address(_msvVault));
  }

  function _strategyMaxDeposit() internal view override returns (uint256 maxAssetsInEPAssets) {
    return SwapStableInvestStrategy.maxDeposit(address(_msvVault));
  }

  function _strategyMaxWithdraw() internal view override returns (uint256 maxAssetsInEPAssets) {
    return _investAsset.balanceOf(address(_msvVault));
  }

  /**
   * @dev See {IERC7575-maxDeposit}.
   */
  function maxDeposit(
    address receiver
  ) public view virtual override(SwapStableInvestStrategy, MSV7575EntryPoint) returns (uint256 maxAssets) {
    return MSV7575EntryPoint.maxDeposit(receiver);
  }

  /**
   * @dev See {IERC7575-maxWithdraw}.
   */
  function maxWithdraw(
    address receiver
  ) public view virtual override(SwapStableInvestStrategy, MSV7575EntryPoint) returns (uint256 maxAssets) {
    return MSV7575EntryPoint.maxWithdraw(receiver);
  }
}
