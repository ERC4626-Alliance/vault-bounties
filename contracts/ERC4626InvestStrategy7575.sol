// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {ERC4626InvestStrategy} from "./ERC4626InvestStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MSV7575Share} from "./MSV7575Share.sol";
import {MSV7575EntryPoint} from "./MSV7575EntryPoint.sol";

/**
 * @title ERC4626InvestStrategy7575
 * @dev Strategy that invests/deinvests into a 4626 vault, denominated in the same asset as MSV.asset() with support
 *      for 7575, meaning that it's possible to enter/exit directly with the 4626 shares
 *
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
contract ERC4626InvestStrategy7575 is ERC4626InvestStrategy, MSV7575EntryPoint {
  constructor(IERC4626 investVault_, MSV7575Share msvVault_)  ERC4626InvestStrategy(IERC20(msvVault_.asset()), investVault_) MSV7575EntryPoint(msvVault_) {}

  function _EPAsset() internal view override returns (address assetTokenAddress) {
    return address(_investVault);
  }

  function _convertToMSVAssets(uint256 epAssets) internal view override returns (uint256 msvAssets) {
    if (epAssets == type(uint256).max) return type(uint256).max;
    return _investVault.convertToAssets(epAssets);  // epAssets == _investVault shares
  }

  function _convertFromMSVAssets(uint256 msvAssets) internal view override returns (uint256 epAssets) {
    if (msvAssets == type(uint256).max) return type(uint256).max;
    return _investVault.convertToShares(msvAssets);  // epAssets == _investVault shares
  }

  /**
   * @dev See {IERC7575-totalAssets}.
   */
  function totalAssets() external view override returns (uint256 totalManagedAssets) {
    return _investVault.balanceOf(address(_msvVault));
  }

  function _strategyMaxDeposit() internal view override returns (uint256 maxAssetsInEPAssets) {
    return _investVault.maxMint(address(_msvVault));
  }

  function _strategyMaxWithdraw() internal view override returns (uint256 maxAssetsInEPAssets) {
    return _investVault.maxRedeem(address(_msvVault));
  }

  /**
   * @dev See {IERC7575-maxDeposit}.
   */
  function maxDeposit(
    address receiver
  ) public view virtual override(ERC4626InvestStrategy, MSV7575EntryPoint) returns (uint256 maxAssets) {
    if (receiver == address(_msvVault)) {
      // Hack to overcome name collision issue, if receiver == _msvVault I assume it's an IInvestStrategy call
      // returns in _msvVault.asset()
      return ERC4626InvestStrategy.maxDeposit(receiver);
    } else {
      return Math.min(_strategyMaxDeposit(), _convertFromMSVAssets(_msvVault.maxDeposit(receiver)));
    }
  }

  /**
   * @dev See {IERC7575-maxWithdraw}.
   */
  function maxWithdraw(
    address owner
  ) public view virtual override(ERC4626InvestStrategy, MSV7575EntryPoint) returns (uint256 maxAssets) {
    if (owner == address(_msvVault)) {
      // Hack to overcome name collision issue, if owner == _msvVault I assume it's an IInvestStrategy call
      // returns in _msvVault.asset()
      return ERC4626InvestStrategy.maxWithdraw(owner);
    } else {
      return Math.min(_strategyMaxWithdraw(), _convertFromMSVAssets(_msvVault.maxWithdraw(owner)));
    }
  }
}
