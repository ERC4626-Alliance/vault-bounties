// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {AaveV3InvestStrategy} from "@ensuro/vaults/contracts/AaveV3InvestStrategy.sol";
import {IInvestStrategy} from "@ensuro/vaults/contracts/interfaces/IInvestStrategy.sol";
import {IERC7575} from "./interfaces/IERC7575.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "@ensuro/vaults/contracts/dependencies/aave-v3/IPool.sol";

/**
 * @title AaveV3InvestStrategy7575
 * @dev Strategy that invests/deinvests into AaveV3 on each deposit/withdraw, with support for 7575 standard
 *
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
contract AaveV3InvestStrategy7575 is AaveV3InvestStrategy, IERC7575 {
  IERC4626 internal immutable _msvVault;

  constructor(IERC20 asset_, IPool aave_, IERC4626 msvVault_) AaveV3InvestStrategy(asset_, aave_) {
    _msvVault = msvVault_;
  }

  /**
   * @dev See {IERC7575-asset}.
   *      For this Strategy, the underlying asset is AAVE's aToken
   */
  function asset() external view override returns (address assetTokenAddress) {
    return _reserveData().aTokenAddress;
  }

  /**
   * @dev See {IERC7575-vault}.
   */
  function share() external view override returns (address shareTokenAddress) {
    return address(_msvVault);
  }

  /**
   * @dev See {IERC7575-convertToShares}.
   */
  function convertToShares(uint256 assets) public view override returns (uint256 shares) {
    return _msvVault.convertToShares(assets); // Since aToken converts 1:1 to _msvVault.asset()
  }

  /**
   * @dev See {IERC7575-convertToAssets}.
   */
  function convertToAssets(uint256 shares) external view override returns (uint256 assets) {
    return _msvVault.convertToAssets(shares); // Since aToken converts 1:1 to _msvVault.asset()
  }

  /**
   * @dev See {IERC7575-totalAssets}.
   */
  function totalAssets() external view override returns (uint256 totalManagedAssets) {
    return AaveV3InvestStrategy.totalAssets(address(_msvVault));
  }

  /**
   * @dev See {IERC7575-maxDeposit}.
   */
  function maxDeposit(
    address receiver
  ) public view override(IERC7575, AaveV3InvestStrategy) returns (uint256 maxAssets) {
    if (receiver == address(_msvVault)) {
      // Hack to overcome name collision issue, if receiver == _msvVault I assume it's an AaveV3InvestStrategy call
      return AaveV3InvestStrategy.maxDeposit(receiver);
    } else {
      return Math.min(AaveV3InvestStrategy.maxDeposit(receiver), _msvVault.maxDeposit(receiver));
    }
  }

  /**
   * @dev See {IERC7575-previewDeposit}.
   */
  function previewDeposit(uint256 assets) external view override returns (uint256 shares) {
    return _msvVault.previewDeposit(assets);
  }

  /**
   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   deposit execution, and are accounted for during deposit.
   * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
    return 0; // TODO
  }

  /**
   * @dev See {IERC7575-maxMint}.
   */
  function maxMint(address receiver) external view override returns (uint256 maxShares) {
    return Math.min(convertToShares(AaveV3InvestStrategy.maxDeposit(receiver)), _msvVault.maxMint(receiver));
  }

  /**
   * @dev See {IERC7575-previewMint}.
   */
  function previewMint(uint256 shares) external view override returns (uint256 assets) {
    return _msvVault.previewMint(shares);
  }

  /**
   * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
   *   execution, and are accounted for during mint.
   * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function mint(uint256 shares, address receiver) external override returns (uint256 assets) {
    return 0; // TODO
  }

  /**
   * @dev See {IERC7575-maxWithdraw}.
   */
  function maxWithdraw(address owner) public view override(IERC7575, AaveV3InvestStrategy) returns (uint256 maxAssets) {
    if (owner == address(_msvVault)) {
      // Hack to overcome name collision issue, if receiver == _msvVault I assume it's an AaveV3InvestStrategy call
      return AaveV3InvestStrategy.maxWithdraw(owner);
    } else {
      return Math.min(AaveV3InvestStrategy.maxWithdraw(owner), _msvVault.maxWithdraw(owner));
    }
  }

  /**
   * @dev See {IERC7575-previewWithdraw}.
   */
  function previewWithdraw(uint256 assets) external view override returns (uint256 shares) {
    return _msvVault.previewWithdraw(assets);
  }

  /**
   * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   withdraw execution, and are accounted for during withdraw.
   * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256 shares) {
    return 0; // TODO
  }

  /**
   * @dev See {IERC7575-maxRedeem}.
   */
  function maxRedeem(address owner) external view override returns (uint256 maxShares) {
    return Math.min(convertToShares(AaveV3InvestStrategy.maxWithdraw(owner)), _msvVault.maxRedeem(owner));
  }

  /**
   * @dev See {IERC7575-previewRedeem}.
   */
  function previewRedeem(uint256 shares) external view override returns (uint256 assets) {
    return _msvVault.previewRedeem(shares);
  }

  /**
   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   redeem execution, and are accounted for during redeem.
   * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function redeem(uint256 shares, address receiver, address owner) external override returns (uint256 assets) {
    return 0; // TODO
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    if (interfaceId == type(IERC7575).interfaceId) return true;
    if (interfaceId == type(IInvestStrategy).interfaceId) return true;
    return false;
  }
}
