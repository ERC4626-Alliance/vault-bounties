// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IInvestStrategy} from "@ensuro/vaults/contracts/interfaces/IInvestStrategy.sol";
import {InvestStrategyClient} from "@ensuro/vaults/contracts/InvestStrategyClient.sol";

/**
 * @title ERC4626InvestStrategy
 * @dev Strategy that invests/deinvests into a 4626 vault, denominated in the same asset as MSV.asset()
 *
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
contract ERC4626InvestStrategy is IInvestStrategy {
  address private immutable __self = address(this);
  bytes32 public immutable storageSlot = InvestStrategyClient.makeStorageSlot(this);

  IERC4626 internal immutable _investVault;
  IERC20 internal immutable _asset; // MSV asset

  // From OZ v5
  error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
  error CanBeCalledOnlyThroughDelegateCall();
  error CannotDisconnectWithAssets();
  error NoExtraDataAllowed();
  error VaultMustHaveTheSameAsset();

  modifier onlyDelegCall() {
    if (address(this) == __self) revert CanBeCalledOnlyThroughDelegateCall();
    _;
  }

  constructor(IERC20 asset_, IERC4626 investVault_) {
    if (investVault_.asset() != address(asset_)) revert VaultMustHaveTheSameAsset();
    _investVault = investVault_;
    _asset = asset_;
  }

  function connect(bytes memory initData) external virtual override onlyDelegCall {
    if (initData.length != 0) revert NoExtraDataAllowed();
  }

  function disconnect(bool force) external virtual override onlyDelegCall {
    if (!force && _investVault.balanceOf(address(this)) != 0) revert CannotDisconnectWithAssets();
  }

  function maxWithdraw(address contract_) public view virtual override returns (uint256) {
    return _investVault.maxWithdraw(contract_);
  }

  function maxDeposit(address contract_) public view virtual override returns (uint256) {
    return _investVault.maxDeposit(contract_);
  }

  function asset(address) public view virtual override returns (address) {
    return address(_asset);
  }

  function totalAssets(address contract_) public view virtual override returns (uint256 assets) {
    return _investVault.convertToAssets(_investVault.balanceOf(contract_));
  }

  function withdraw(uint256 assets) external virtual override onlyDelegCall {
    _investVault.withdraw(assets, address(this), address(this));
  }

  function deposit(uint256 assets) external virtual override onlyDelegCall {
    IERC20(_asset).approve(address(_investVault), assets);
    _investVault.deposit(assets, address(this));
  }

  function forwardEntryPoint(uint8, bytes memory) external view onlyDelegCall returns (bytes memory) {
    // solhint-disable-next-line custom-errors,reason-string
    revert();
  }
}
