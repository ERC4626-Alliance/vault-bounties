// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IInvestStrategy} from "@ensuro/vaults/contracts/interfaces/IInvestStrategy.sol";
import {IERC7575} from "./interfaces/IERC7575.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MSV7575Share} from "./MSV7575Share.sol";

/**
 * @title MSV7575EntryPoint
 * @dev Base contract with most of the implementation to convert a strategy into a 7575
 *
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
abstract contract MSV7575EntryPoint is IERC7575 {
  MSV7575Share internal immutable _msvVault;

  error MoreThanMax();

  constructor(MSV7575Share msvVault_) {
    _msvVault = msvVault_;
  }

  /**
   * @dev Implement this with the same behaviour as {IERC7575-asset}
   */
  // solhint-disable-next-line func-name-mixedcase
  function _EPAsset() internal view virtual returns (address assetTokenAddress);

  /**
   * @dev See {IERC7575-asset}.
   */
  function asset() external view override returns (address assetTokenAddress) {
    return _EPAsset();
  }

  /**
   * @dev See {IERC7575-vault}.
   */
  function share() external view override returns (address shareTokenAddress) {
    return address(_msvVault);
  }

  function _convertToMSVAssets(uint256 epAssets) internal view virtual returns (uint256 msvAssets) {
    return epAssets; // Override this method if the conversion is not 1:1 to _msvVault.asset()
  }

  function _convertFromMSVAssets(uint256 msvAssets) internal view virtual returns (uint256 epAssets) {
    return msvAssets; // Override this method if the conversion is not 1:1 to _msvVault.asset()
  }

  /**
   * @dev See {IERC7575-convertToShares}.
   */
  function convertToShares(uint256 assets) public view override returns (uint256 shares) {
    return _msvVault.convertToShares(_convertToMSVAssets(assets));
  }

  /**
   * @dev See {IERC7575-convertToAssets}.
   */
  function convertToAssets(uint256 shares) external view override returns (uint256 assets) {
    return _convertFromMSVAssets(_msvVault.convertToAssets(shares));
  }

  /**
   * @dev Implement to return the maxDeposit in the strategy, expressed in EPAssets
   */
  function _strategyMaxDeposit() internal view virtual returns (uint256 maxAssetsInEPAssets);

  /**
   * @dev See {IERC7575-maxDeposit}.
   */
  function maxDeposit(address receiver) public view virtual override returns (uint256 maxAssets) {
    if (receiver == address(_msvVault)) {
      // Hack to overcome name collision issue, if receiver == _msvVault I assume it's an IInvestStrategy call
      return _strategyMaxDeposit();
    } else {
      return Math.min(_strategyMaxDeposit(), _convertFromMSVAssets(_msvVault.maxDeposit(receiver)));
    }
  }

  /**
   * @dev See {IERC7575-previewDeposit}.
   */
  function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
    return _msvVault.previewDeposit(_convertToMSVAssets(assets));
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
    if (assets > maxDeposit(receiver)) revert MoreThanMax();

    shares = previewDeposit(assets);
    _deposit(msg.sender, receiver, assets, shares);
    return shares;
  }

  /**
   * @dev See {IERC7575-maxMint}.
   */
  function maxMint(address receiver) public view override returns (uint256 maxShares) {
    uint256 maxDepositEP = _strategyMaxDeposit();
    return
      Math.min(
        maxDepositEP == type(uint256).max ? type(uint256).max : convertToShares(maxDepositEP),
        _msvVault.maxMint(receiver)
      );
  }

  /**
   * @dev See {IERC7575-previewMint}.
   */
  function previewMint(uint256 shares) public view override returns (uint256 assets) {
    return _convertFromMSVAssets(_msvVault.previewMint(shares));
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
    if (shares > maxMint(receiver)) revert MoreThanMax();

    assets = previewMint(shares);
    _deposit(msg.sender, receiver, assets, shares);
    return assets;
  }

  /**
   * @dev Implement to return the maxWithdraw in the strategy, expressed in EPAssets
   */
  function _strategyMaxWithdraw() internal view virtual returns (uint256 maxAssetsInEPAssets);

  /**
   * @dev See {IERC7575-maxWithdraw}.
   */
  function maxWithdraw(address owner) public view virtual override returns (uint256 maxAssets) {
    if (owner == address(_msvVault)) {
      // Hack to overcome name collision issue, if receiver == _msvVault I assume it's an AaveV3InvestStrategy call
      return _strategyMaxWithdraw();
    } else {
      return Math.min(_strategyMaxWithdraw(), _convertFromMSVAssets(_msvVault.maxWithdraw(owner)));
    }
  }

  /**
   * @dev See {IERC7575-previewWithdraw}.
   */
  function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
    return _msvVault.previewWithdraw(_convertToMSVAssets(assets));
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
    if (assets > maxWithdraw(owner)) revert MoreThanMax();

    shares = previewWithdraw(assets);
    _withdraw(msg.sender, receiver, owner, assets, shares);

    return shares;
  }

  /**
   * @dev See {IERC7575-maxRedeem}.
   */
  function maxRedeem(address owner) public view override returns (uint256 maxShares) {
    return Math.min(convertToShares(_strategyMaxWithdraw()), _msvVault.maxRedeem(owner));
  }

  /**
   * @dev See {IERC7575-previewRedeem}.
   */
  function previewRedeem(uint256 shares) public view override returns (uint256 assets) {
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
    if (shares > maxRedeem(owner)) revert MoreThanMax();

    assets = previewRedeem(shares);
    _withdraw(msg.sender, receiver, owner, assets, shares);

    return assets;
  }

  function _receiveAssets(address caller, uint256 assets) internal virtual {
    SafeERC20.safeTransferFrom(IERC20(_EPAsset()), caller, address(this), assets);
  }

  /**
   * @dev Deposit/mint common workflow.
   */
  function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
    _receiveAssets(caller, assets);
    _msvVault.mintEntryPointShares(_EPAsset(), receiver, shares);
    emit Deposit(caller, receiver, assets, shares);
  }

  /**
   * @dev Withdraw/redeem common workflow.
   */
  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal virtual {
    _msvVault.burnEntryPointSharesAndTransfer(_EPAsset(), caller, owner, shares, receiver, assets);

    emit Withdraw(caller, receiver, owner, assets, shares);
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    if (interfaceId == type(IERC7575).interfaceId) return true;
    if (interfaceId == type(IInvestStrategy).interfaceId) return true;
    return false;
  }
}
