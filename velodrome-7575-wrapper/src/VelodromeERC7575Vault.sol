// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IPool} from "./interfaces/IPool.sol";
import {IRouter} from "./interfaces/IRouter.sol";

import {IERC7575} from "./interfaces/IERC7575.sol";

/// @title VelodromeERC7575Vault
contract VelodromeERC7575Vault is IERC7575 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                      IMMUATABLES & VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable manager;

    uint256 public immutable slippage = 5000; // 5%

    IRouter public immutable router = IRouter(0xa062aE8A9c5e11aaA026fc2670B0D65cCc8B2858);
    IPool public immutable pool;

    ERC20 public token0;
    ERC20 public token1;

    address public asset;
    ERC20 private shareToken;

    bool public immutable isStable; // denotes if the vault operates on Stable or Volatile pool.

    string public name;
    string public symbol;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Construct a new VelodromeERC7575 contract.
    /// @param _asset The address of the ERC20 token to be used as ASSET.
    /// @param _name The name of the ERC4626 token.
    /// @param _symbol The symbol of the ERC4626 token.
    /// @param _pool Address of the VElodrome pool contract
    /// @param _isStable Flag to specifiy if the vault operates on stable or volatile pool
    /// @param _share Address of the share token
    constructor(address _asset, string memory _name, string memory _symbol, IPool _pool, bool _isStable, ERC20 _share) {
        manager = msg.sender;
        asset = _asset;
        isStable = _isStable;
        name = _name;
        symbol = _symbol;
        pool = _pool;

        shareToken = _share;
        address token0_ = pool.token0();
        address token1_ = pool.token1();

        if (address(asset) == token0_) {
            token0 = ERC20(asset);
            token1 = ERC20(token1_);
        } else {
            token0 = ERC20(token0_);
            token1 = ERC20(asset);
        }
    }

    function deposit(uint256 assets_, address receiver_) public override returns (uint256 shares) {}

    function mint(uint256 shares_, address receiver_) public override returns (uint256 assets) {}

    function withdraw(uint256 assets_, address receiver_, address owner_) public override returns (uint256 shares) {}

    function redeem(uint256 shares_, address receiver_, address owner) public override returns (uint256 assets) {}

    function totalAssets() public view override returns (uint256) {}

    function previewDeposit(uint256 assets_) public view override returns (uint256 shares) {}

    function previewMint(uint256 shares_) public view override returns (uint256 assets) {}

    function previewWithdraw(uint256 assets_) public view override returns (uint256 shares) {}

    function previewRedeem(uint256 shares_) public view override returns (uint256 assets) {}

    function mintAssets(uint256 shares_) public view returns (uint256 assets) {}

    function redeemAssets(uint256 shares_) public view returns (uint256 assets) {}

    function share() external view returns (address) {
        return address(shareToken);
    }

    /// Helpers

    /// @notice Remove liquidity from the underlying pool. Receive both token0 and token1 on the Vault address.
    function _removeLiquidity(uint256, uint256 shares_) internal returns (uint256 assets0, uint256 assets1) {
        //
    }

    /// @notice Add liquidity to the underlying pool. Send both token0 and token1 from the Vault address.
    function _addLiquidity(uint256 assets0_, uint256 assets1_) internal returns (uint256 li) {
        //
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == 0x2f0a18c5 || interfaceId == 0x01ffc9a7;
    }

    /// 4626

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = shareToken.totalSupply();

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = shareToken.totalSupply();

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(shareToken.balanceOf(owner));
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return shareToken.balanceOf(owner);
    }
}
