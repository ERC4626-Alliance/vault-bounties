// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Copied from https://github.com/ensuro/vaults/blob/main/contracts/MultiStrategyERC4626.sol
// Just has small changes to reduce the size of the contract and avoid spurious dragon limit
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {PermissionedERC4626} from "@ensuro/vaults/contracts/PermissionedERC4626.sol";
import {IInvestStrategy} from "@ensuro/vaults/contracts/interfaces/IInvestStrategy.sol";
import {IExposeStorage} from "@ensuro/vaults/contracts/interfaces/IExposeStorage.sol";
import {InvestStrategyClient} from "@ensuro/vaults/contracts/InvestStrategyClient.sol";

/**
 * @title MultiStrategyERC4626
 *
 * @dev Vault that invests/deinvests using a pluggable IInvestStrategy on each deposit/withdraw.
 *      The vault is permissioned to deposit/withdraw (not transfer). The owner of the shares must have LP_ROLE.
 *      Investment strategy can be changed. Also, custom messages can be sent to the IInvestStrategy contract.
 *
 *      The code of the IInvestStrategy is called using delegatecall, so it has full control over the assets and
 *      storage of this contract, so you must be very careful the kind of IInvestStrategy is plugged.
 *
 * @custom:security-contact security@ensuro.co
 * @author Ensuro
 */
contract MultiStrategyERC4626 is PermissionedERC4626, IExposeStorage {
  using SafeERC20 for IERC20Metadata;
  using Address for address;
  using InvestStrategyClient for IInvestStrategy;

  bytes32 internal constant STRATEGY_ADMIN_ROLE = keccak256("STRATEGY_ADMIN_ROLE");
  bytes32 internal constant QUEUE_ADMIN_ROLE = keccak256("QUEUE_ADMIN_ROLE");
  bytes32 internal constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");

  uint8 internal constant MAX_STRATEGIES = 32;

  uint8[MAX_STRATEGIES] internal _depositQueue;
  uint8[MAX_STRATEGIES] internal _withdrawQueue;
  IInvestStrategy[MAX_STRATEGIES] internal _strategies;

  // Events duplicated here from InvestStrategyClient library, so they go to the ABI
  event StrategyChanged(IInvestStrategy oldStrategy, IInvestStrategy newStrategy);
  event WithdrawFailed(bytes reason);
  event DepositFailed(bytes reason);
  event DisconnectFailed(bytes reason);
  event StrategyAdded(IInvestStrategy indexed strategy, uint8 index);
  event StrategyRemoved(IInvestStrategy indexed strategy, uint8 index);
  event DepositQueueChanged(uint8[] queue);
  event WithdrawQueueChanged(uint8[] queue);
  event Rebalance(IInvestStrategy indexed strategyFrom, IInvestStrategy indexed strategyTo, uint256 amount);

  error InvalidStrategiesLength();
  error InvalidStrategy();
  error DuplicatedStrategy(IInvestStrategy strategy);
  error InvalidStrategyInDepositQueue(uint8 index);
  error InvalidStrategyInWithdrawQueue(uint8 index);
  error WithdrawError();
  error DepositError();
  error OnlyStrategyStorageExposed();
  error CannotRemoveStrategyWithAssets();
  error InvalidQueue();
  error InvalidQueueLength();
  error InvalidQueueIndexDuplicated(uint8 index);
  error RebalanceAmountExceedsMaxDeposit(uint256 max);
  error RebalanceAmountExceedsMaxWithdraw(uint256 max);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Initializes the SingleStrategyERC4626
   *
   * @param name_ Name of the ERC20/ERC4626 token
   * @param symbol_ Symbol of the ERC20/ERC4626 token
   * @param admin_ User that will receive the DEFAULT_ADMIN_ROLE and later can assign other permissions.
   * @param asset_ The asset() of the ERC4626
   * @param strategies_ The IInvestStrategys that will be used to manage the funds received.
   * @param initStrategyDatas Initialization data that will be sent to the strategies
   * @param depositQueue_ The order in which the funds will be deposited in the strategies
   * @param withdrawQueue_ The order in which the funds will be withdrawn from the strategies
   */
  function initialize(
    string memory name_,
    string memory symbol_,
    address admin_,
    IERC20Upgradeable asset_,
    IInvestStrategy[] memory strategies_,
    bytes[] memory initStrategyDatas,
    uint8[] memory depositQueue_,
    uint8[] memory withdrawQueue_
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
  }

  // solhint-disable-next-line func-name-mixedcase
  function __MultiStrategyERC4626_init(
    string memory name_,
    string memory symbol_,
    address admin_,
    IERC20Upgradeable asset_,
    IInvestStrategy[] memory strategies_,
    bytes[] memory initStrategyDatas,
    uint8[] memory depositQueue_,
    uint8[] memory withdrawQueue_
  ) internal onlyInitializing {
    __PermissionedERC4626_init(name_, symbol_, admin_, asset_);
    __MultiStrategyERC4626_init_unchained(strategies_, initStrategyDatas, depositQueue_, withdrawQueue_);
  }

  // solhint-disable-next-line func-name-mixedcase
  function __MultiStrategyERC4626_init_unchained(
    IInvestStrategy[] memory strategies_,
    bytes[] memory initStrategyDatas,
    uint8[] memory depositQueue_,
    uint8[] memory withdrawQueue_
  ) internal onlyInitializing {
    if (
      strategies_.length == 0 ||
      strategies_.length > MAX_STRATEGIES ||
      strategies_.length != initStrategyDatas.length ||
      strategies_.length != depositQueue_.length ||
      strategies_.length != withdrawQueue_.length
    ) revert InvalidStrategiesLength();
    bool[MAX_STRATEGIES] memory presentInDeposit;
    bool[MAX_STRATEGIES] memory presentInWithdraw;
    for (uint256 i; i < strategies_.length; i++) {
      if (address(strategies_[i]) == address(0)) revert InvalidStrategy();
      strategies_[i].checkAsset(asset());
      // Check strategies_[i] not duplicated
      for (uint256 j; j < i; j++) {
        if (strategies_[i] == strategies_[j]) revert DuplicatedStrategy(strategies_[i]);
      }
      // Check depositQueue_[i] and withdrawQueue_[i] not duplicated and within bounds
      if (depositQueue_[i] >= strategies_.length || presentInDeposit[depositQueue_[i]])
        revert InvalidStrategyInDepositQueue(depositQueue_[i]);
      if (withdrawQueue_[i] >= strategies_.length || presentInWithdraw[withdrawQueue_[i]])
        revert InvalidStrategyInWithdrawQueue(withdrawQueue_[i]);
      presentInDeposit[depositQueue_[i]] = true;
      presentInWithdraw[withdrawQueue_[i]] = true;
      _strategies[i] = strategies_[i];
      _depositQueue[i] = depositQueue_[i] + 1; // Adding one, so we know when 0 is end of array
      _withdrawQueue[i] = withdrawQueue_[i] + 1; // Adding one, so we know when 0 is end of array
      strategies_[i].dcConnect(initStrategyDatas[i]);
      emit StrategyAdded(strategies_[i], uint8(i));
    }
    emit DepositQueueChanged(depositQueue_);
    emit WithdrawQueueChanged(withdrawQueue_);
  }

  /**
   * @dev See {IERC4626-maxWithdraw}.
   */
  function maxWithdraw(address owner) public view virtual override returns (uint256) {
    uint256 ownerAssets = super.maxWithdraw(owner);
    return _maxWithdrawable(ownerAssets);
  }

  function _maxWithdrawable(uint256 limit) internal view returns (uint256 ret) {
    for (uint256 i; address(_strategies[i]) != address(0) && i < MAX_STRATEGIES; i++) {
      ret += _strategies[i].maxWithdraw();
      if (ret >= limit) return limit;
    }
    return ret;
  }

  /**
   * @dev See {IERC4626-maxRedeem}.
   */
  function maxRedeem(address owner) public view virtual override returns (uint256) {
    uint256 shares = super.maxRedeem(owner);
    uint256 ownerAssets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    uint256 maxAssets = _maxWithdrawable(ownerAssets);
    return (maxAssets == ownerAssets) ? shares : _convertToShares(maxAssets, MathUpgradeable.Rounding.Down);
  }

  /**
   * @dev See {IERC4626-maxDeposit}.
   */
  function maxDeposit(address owner) public view virtual override returns (uint256 ret) {
    if (super.maxDeposit(owner) == 0) return 0;
    for (uint256 i; address(_strategies[i]) != address(0) && i < MAX_STRATEGIES; i++) {
      uint256 maxDep = _strategies[i].maxDeposit();
      if (maxDep == type(uint256).max) return maxDep;
      ret += maxDep;
    }
  }

  /**
   * @dev See {IERC4626-maxMint}.
   */
  function maxMint(address owner) public view virtual override returns (uint256) {
    if (super.maxMint(owner) == 0) return 0;
    uint256 maxDep = maxDeposit(owner);
    return maxDep == type(uint256).max ? type(uint256).max : _convertToShares(maxDep, MathUpgradeable.Rounding.Down);
  }

  /**
   * @dev See {IERC4626-totalAssets}.
   */
  function totalAssets() public view virtual override returns (uint256 assets) {
    for (uint256 i; address(_strategies[i]) != address(0) && i < MAX_STRATEGIES; i++) {
      assets += _strategies[i].totalAssets();
    }
  }

  function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 assets,
    uint256 shares
  ) internal virtual override {
    uint256 left = assets;
    for (uint256 i; left != 0 && _withdrawQueue[i] != 0 && i < MAX_STRATEGIES; i++) {
      IInvestStrategy strategy = _strategies[_withdrawQueue[i] - 1];
      uint256 toWithdraw = MathUpgradeable.min(left, strategy.maxWithdraw());
      if (toWithdraw == 0) continue;
      strategy.dcWithdraw(toWithdraw, false);
      left -= toWithdraw;
    }
    if (left != 0) revert WithdrawError(); // This shouldn't happen, since assets must be <= maxWithdraw(owner)
    super._withdraw(caller, receiver, owner, assets, shares);
  }

  function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
    // Transfers the assets from the caller and supplies to compound
    super._deposit(caller, receiver, assets, shares);
    uint256 left = assets;
    for (uint256 i; left != 0 && _depositQueue[i] != 0 && i < MAX_STRATEGIES; i++) {
      IInvestStrategy strategy = _strategies[_depositQueue[i] - 1];
      uint256 toDeposit = MathUpgradeable.min(left, strategy.maxDeposit());
      if (toDeposit == 0) continue;
      strategy.dcDeposit(toDeposit, false);
      left -= toDeposit;
    }
    if (left != 0) revert DepositError(); // This shouldn't happen, since assets must be <= maxDeposit(owner)
  }

  /**
   * @dev Exposes a given slot as a bytes array. To be used by the IInvestStrategy views to access their storage.
   *      Only the slot==strategyStorageSlot() can be accessed.
   */
  function getBytesSlot(bytes32 slot) external view override returns (bytes memory) {
    for (uint256 i; _strategies[i] != IInvestStrategy(address(0)) && i < MAX_STRATEGIES; i++) {
      if (slot == _strategies[i].storageSlot()) {
        StorageSlot.BytesSlot storage r = StorageSlot.getBytesSlot(slot);
        return r.value;
      }
    }
    revert OnlyStrategyStorageExposed();
  }

  /**
   * @dev Used to call specific methods on the strategies. Anyone can call this method, is responsability of the
   *      IInvestStrategy to check access permissions when needed.
   * @param strategyIndex The index of the strategy in the _strategies array
   * @param method Id of the method to call. Is recommended that the strategy defines an enum with the methods that
   *               can be called externally and validates this value.
   * @param extraData Additional parameters sent to the method.
   * @return Returns the output received from the IInvestStrategy.
   */
  function forwardToStrategy(
    uint8 strategyIndex,
    uint8 method,
    bytes memory extraData
  ) external returns (bytes memory) {
    IInvestStrategy strategy = _strategies[strategyIndex];
    if (address(strategy) == address(0)) revert InvalidStrategy();
    return _strategies[strategyIndex].dcForward(method, extraData);
  }

  /**
   * @dev Changes one investment strategy to a new one, keeping the deposit and withdraw queues unaffected.
   *      When this happens, all funds are withdrawn from the old strategy and deposited on the new one.
   *      This reverts if any of this fails, unless the force parameter is true, in that case errors in withdrawal
   *      or deposit are silented.
   * @param strategyIndex The index of the strategy in the _strategies array
   * @param newStrategy The new strategy to plug into the vault
   * @param initStrategyData Initialization parameters for this new strategy
   * @param force Boolean to indicate if errors on withdraw or deposit should be accepted. Normally you should send
   *              this value in `false`. Only use `true` if you know what you are doing and trying to replace a faulty
   *              strategy.
   */
  function replaceStrategy(
    uint8 strategyIndex,
    IInvestStrategy newStrategy,
    bytes memory initStrategyData,
    bool force
  ) external onlyRole(STRATEGY_ADMIN_ROLE) {
    IInvestStrategy strategy = _strategies[strategyIndex];
    if (address(strategy) == address(0)) revert InvalidStrategy();
    for (uint256 i; i < MAX_STRATEGIES && _strategies[i] != IInvestStrategy(address(0)); i++) {
      if (_strategies[i] == newStrategy && i != strategyIndex) revert DuplicatedStrategy(newStrategy);
    }
    InvestStrategyClient.strategyChange(strategy, newStrategy, initStrategyData, IERC20Metadata(asset()), force);
    _strategies[strategyIndex] = newStrategy;
  }

  /**
   * @dev Adds a new strategy to the vault. The new strategy will be added at the end of the deposit and withdraw
   *      queues.
   * @param newStrategy The new strategy to plug into the vault
   * @param initStrategyData Initialization parameters for this new strategy
   */
  function addStrategy(
    IInvestStrategy newStrategy,
    bytes memory initStrategyData
  ) external onlyRole(STRATEGY_ADMIN_ROLE) {
    if (address(newStrategy) == address(0)) revert InvalidStrategy();
    uint256 i;
    for (; i < MAX_STRATEGIES && _strategies[i] != IInvestStrategy(address(0)); i++) {
      if (_strategies[i] == newStrategy) revert DuplicatedStrategy(newStrategy);
    }
    if (i == MAX_STRATEGIES) revert InvalidStrategiesLength();
    _strategies[i] = newStrategy;
    _depositQueue[i] = uint8(i + 1);
    _withdrawQueue[i] = uint8(i + 1);
    newStrategy.checkAsset(asset());
    newStrategy.dcConnect(initStrategyData);
    emit StrategyAdded(newStrategy, uint8(i));
  }

  /**
   * @dev Remove an strategy from the vault. It's only possible if the strategy doesn't have assets.
   *      The strategy is removed from deposit and withdraw queues
   * @param strategyIndex The index of the strategy in the _strategies array
   * @param force If strategy.disconnect fails, this parameter indicates whether the operation is reverted or not.
   */
  function removeStrategy(uint8 strategyIndex, bool force) external onlyRole(STRATEGY_ADMIN_ROLE) {
    if (strategyIndex >= MAX_STRATEGIES) revert InvalidStrategy();
    IInvestStrategy strategy = _strategies[strategyIndex];
    if (address(strategy) == address(0)) revert InvalidStrategy();
    if (strategy.totalAssets() != 0) revert CannotRemoveStrategyWithAssets();
    // Check isn't removing the last one
    if (strategyIndex == 0 && address(_strategies[1]) == address(0)) revert InvalidStrategiesLength();
    // Shift the following strategies in the array
    uint256 i = strategyIndex + 1;
    for (; i < MAX_STRATEGIES && _strategies[i] != IInvestStrategy(address(0)); i++) {
      _strategies[i - 1] = _strategies[i];
    }
    _strategies[i - 1] = IInvestStrategy(address(0));
    // Shift and change the indexes in the queues
    bool shiftDeposit;
    bool shiftWithdraw;
    for (i = 0; _withdrawQueue[i] != 0 && i < MAX_STRATEGIES; i++) {
      if (shiftWithdraw) {
        // Already saw the deleted index, shift and change index if greater
        _withdrawQueue[i - 1] = _withdrawQueue[i] - ((_withdrawQueue[i] > (strategyIndex + 1)) ? 1 : 0);
      } else {
        if (_withdrawQueue[i] == (strategyIndex + 1)) {
          // Index to delete found, it will be deleted in the next interation
          shiftWithdraw = true;
        } else if (_withdrawQueue[i] > (strategyIndex + 1)) {
          // If index is greater, substract one
          _withdrawQueue[i] -= 1;
        }
      }

      // Same for deposit
      if (shiftDeposit) {
        // Already saw the deleted index, shift and change index if greater
        _depositQueue[i - 1] = _depositQueue[i] - ((_depositQueue[i] > (strategyIndex + 1)) ? 1 : 0);
      } else {
        if (_depositQueue[i] == (strategyIndex + 1)) {
          // Index to delete found, it will be deleted in the next interation
          shiftDeposit = true;
        } else if (_depositQueue[i] > (strategyIndex + 1)) {
          // If index is greater, substract one
          _depositQueue[i] -= 1;
        }
      }
    }
    _depositQueue[i - 1] = 0;
    _withdrawQueue[i - 1] = 0;
    strategy.dcDisconnect(force);
    emit StrategyRemoved(strategy, strategyIndex);
  }

  function changeDepositQueue(uint8[] memory newDepositQueue_) external onlyRole(QUEUE_ADMIN_ROLE) {
    bool[MAX_STRATEGIES] memory seen;
    uint256 i = 0;
    if (newDepositQueue_.length > MAX_STRATEGIES) revert InvalidQueue();
    for (; i < newDepositQueue_.length; i++) {
      if (newDepositQueue_[i] >= MAX_STRATEGIES || address(_strategies[newDepositQueue_[i]]) == address(0))
        revert InvalidQueue();
      if (seen[newDepositQueue_[i]]) revert InvalidQueueIndexDuplicated(newDepositQueue_[i]);
      seen[newDepositQueue_[i]] = true;
      _depositQueue[i] = newDepositQueue_[i] + 1;
    }
    if (i < MAX_STRATEGIES && address(_strategies[i]) != address(0)) revert InvalidQueueLength();
    emit DepositQueueChanged(newDepositQueue_);
  }

  function changeWithdrawQueue(uint8[] memory newWithdrawQueue_) external onlyRole(QUEUE_ADMIN_ROLE) {
    bool[MAX_STRATEGIES] memory seen;
    uint8 i = 0;
    if (newWithdrawQueue_.length > MAX_STRATEGIES) revert InvalidQueue();
    for (; i < newWithdrawQueue_.length; i++) {
      if (newWithdrawQueue_[i] >= MAX_STRATEGIES || address(_strategies[newWithdrawQueue_[i]]) == address(0))
        revert InvalidQueue();
      if (seen[newWithdrawQueue_[i]]) revert InvalidQueueIndexDuplicated(newWithdrawQueue_[i]);
      seen[newWithdrawQueue_[i]] = true;
      _withdrawQueue[i] = newWithdrawQueue_[i] + 1;
    }
    if (i < MAX_STRATEGIES && address(_strategies[i]) != address(0)) revert InvalidQueueLength();
    emit WithdrawQueueChanged(newWithdrawQueue_);
  }

  /**
   * @dev Moves funds from one strategy to the other.
   * @param strategyFromIdx The index of the strategy that will provide the funds in the _strategies array
   * @param strategyToIdx The index of the strategy that will receive the funds in the _strategies array
   * @param amount The amount to transfer from one strategy to the other. type(uint256).max to move all the assets.
   */
  function rebalance(
    uint8 strategyFromIdx,
    uint8 strategyToIdx,
    uint256 amount
  ) external onlyRole(REBALANCER_ROLE) returns (uint256) {
    if (strategyFromIdx >= MAX_STRATEGIES || strategyToIdx >= MAX_STRATEGIES) revert InvalidStrategy();
    IInvestStrategy strategyFrom = _strategies[strategyFromIdx];
    IInvestStrategy strategyTo = _strategies[strategyToIdx];
    if (address(strategyFrom) == address(0) || address(strategyTo) == address(0)) revert InvalidStrategy();
    if (amount == type(uint256).max) amount = strategyFrom.totalAssets();
    if (amount == 0) return 0; // Don't revert if nothing to do, just to make life easier for devs
    if (amount > strategyFrom.maxWithdraw()) revert RebalanceAmountExceedsMaxWithdraw(strategyFrom.maxWithdraw());
    if (amount > strategyTo.maxDeposit()) revert RebalanceAmountExceedsMaxDeposit(strategyTo.maxDeposit());
    strategyFrom.dcWithdraw(amount, false);
    strategyTo.dcDeposit(amount, false);
    emit Rebalance(strategyFrom, strategyTo, amount);
    return amount;
  }

  function strategies() external view returns (IInvestStrategy[MAX_STRATEGIES] memory) {
    return _strategies;
  }

  /**
   * @dev Returns the order in which the deposits will be made, expressed as index+1 in the _strategies array,
   *      filled with zeros at the end
   */
  function depositQueue() external view returns (uint8[MAX_STRATEGIES] memory) {
    return _depositQueue;
  }

  /**
   * @dev Returns the order in which the withdraws will be made, expressed as index+1 in the _strategies array,
   *      filled with zeros at the end
   */
  function withdrawQueue() external view returns (uint8[MAX_STRATEGIES] memory) {
    return _withdrawQueue;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[16] private __gap;
}
