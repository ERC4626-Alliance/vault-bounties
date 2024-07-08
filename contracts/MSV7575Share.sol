// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {MultiStrategyERC4626} from "@ensuro/vaults/contracts/MultiStrategyERC4626.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IInvestStrategy} from "@ensuro/vaults/contracts/interfaces/IInvestStrategy.sol";
import {IERC7575Share, IERC7575, IERC165} from "./interfaces/IERC7575.sol";

contract MSV7575Share is MultiStrategyERC4626, IERC7575Share {
  mapping(address => IERC7575) internal _entryPoints;

  error InvalidLength();
  error DuplicatedAsset(address asset, uint256 strategyIndex);

  /**
   * @dev Initializes the MSV7575Share
   *
   * @param name_ Name of the ERC20/ERC4626 token
   * @param symbol_ Symbol of the ERC20/ERC4626 token
   * @param admin_ User that will receive the DEFAULT_ADMIN_ROLE and later can assign other permissions.
   * @param asset_ The asset() of the ERC4626
   * @param strategies_ The IInvestStrategys that will be used to manage the funds received.
   * @param initStrategyDatas Initialization data that will be sent to the strategies
   * @param depositQueue_ The order in which the funds will be deposited in the strategies
   * @param withdrawQueue_ The order in which the funds will be withdrawn from the strategies
   * @param is7575EntryPoint_ Array of the same size of strategies_ that indicates wether a specific strategy is
   *                          a 7575 entry point
   */
  function initialize(
    string memory name_,
    string memory symbol_,
    address admin_,
    IERC20Upgradeable asset_,
    IInvestStrategy[] memory strategies_,
    bytes[] memory initStrategyDatas,
    uint8[] memory depositQueue_,
    uint8[] memory withdrawQueue_,
    bool[] memory is7575EntryPoint_
  ) public virtual initializer {
    __MultiStrategyERC4626_init(
      name_,
      symbol_,
      admin_,
      asset_,
      strategies_,
      initStrategyDatas,
      depositQueue_,
      withdrawQueue_
    );
    if (is7575EntryPoint_.length != strategies_.length) revert InvalidLength();
    for (uint256 i; i < is7575EntryPoint_.length; i++) {
      if (!is7575EntryPoint_[i]) continue;
      IERC7575 entryPoint = IERC7575(address(strategies_[i]));
      address epAsset = entryPoint.asset();
      if (address(_entryPoints[epAsset]) != address(0)) revert DuplicatedAsset(epAsset, i);
      _entryPoints[epAsset] = entryPoint;
      emit VaultUpdate(epAsset, address(strategies_[i]));
    }
  }

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
}
