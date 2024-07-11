// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {MultiStrategyERC4626} from "./dependencies/MultiStrategyERC4626.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC7575Share, IERC7575, IERC165} from "./interfaces/IERC7575.sol";

contract MSV7575Share is MultiStrategyERC4626, IERC7575Share {
  mapping(address => IERC7575) internal _entryPoints;

  error InvalidLength();
  error DuplicatedAsset(address asset, uint256 strategyIndex);
  error OnlyFromEntryPoint();

  /**
   * @dev Enables a strategy as entry point.
   * @param strategyIndex The index of the strategy (previously plugged)
   * @param isEntryPoint If true, the strategy will be enabled as entryPoint for the strategy.asset(), if false,
   *                     the entryPoint for the asset will be disabled
   */
  function setAs7575EntryPoint(uint256 strategyIndex, bool isEntryPoint) external onlyRole(STRATEGY_ADMIN_ROLE) {
    IERC7575 entryPoint = IERC7575(address(_strategies[strategyIndex]));
    address epAsset = entryPoint.asset();
    _entryPoints[epAsset] = isEntryPoint ? entryPoint : IERC7575(address(0));
    emit VaultUpdate(epAsset, address(_entryPoints[epAsset]));
  }

  // TO DO: hook into replaceStrategy or removeStrategy methods and check if it's changing an enabled entryPoint

  /**
   * @dev See {IERC7575Share-vault}.
   */
  function vault(address asset) external view returns (address vault_) {
    return address(_entryPoints[asset]);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControlUpgradeable, IERC165) returns (bool) {
    if (interfaceId == type(IERC7575Share).interfaceId) return true;
    if (interfaceId == type(IERC4626).interfaceId) return true;
    if (interfaceId == type(IERC20).interfaceId) return true;
    return AccessControlUpgradeable.supportsInterface(interfaceId);
  }

  function mintEntryPointShares(address asset, address receiver, uint256 shares) external {
    if (msg.sender != address(_entryPoints[asset])) revert OnlyFromEntryPoint();
    _mint(receiver, shares);
  }

  function burnEntryPointSharesAndTransfer(
    address asset,
    address caller,
    address owner,
    uint256 shares,
    address receiver,
    uint256 assets
  ) external {
    if (msg.sender != address(_entryPoints[asset])) revert OnlyFromEntryPoint();
    if (caller != owner) {
      _spendAllowance(owner, caller, shares);
    }
    _burn(owner, shares);
    SafeERC20.safeTransfer(IERC20(asset), receiver, assets);
  }
}
