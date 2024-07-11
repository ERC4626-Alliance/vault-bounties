// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IERC20MintableBurnable} from "./interfaces/IERC20MintableBurnable.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IERC7575} from "./interfaces/IERC7575.sol";
import {console} from "forge-std/console.sol";

/// @title VelodromeERC7575Vault Wrapper contract
/// @dev Unaudited and will have bugs. Don't use in PRODUCTION
contract VelodromeERC7575Vault is IERC7575 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                      IMMUATABLES & VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable manager;

    uint256 public slippage = 5000; // 5%

    IRouter public constant ROUTER = IRouter(0xa062aE8A9c5e11aaA026fc2670B0D65cCc8B2858);
    address public constant FACTORY = 0xF1046053aa5682b4F9a81b5481394DA16BE5FF5a;
    uint256 private constant MAX_BPS = 100000; // 100%

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

        // Pre-approve
        token0.approve(address(ROUTER), type(uint256).max);
        token1.approve(address(ROUTER), type(uint256).max);
        ERC20(address(pool)).approve(address(ROUTER), type(uint256).max);
    }

    function deposit(uint256 _assets, address _reciever) public override returns (uint256 shares) {
        shares = previewDeposit(_assets);
        /// @dev 100% of tokenX/Y is transferred to this contract
        ERC20(asset).safeTransferFrom(msg.sender, address(this), _assets);

        (uint256 _amount0, uint256 _amount1) = _swapHalf(_assets);
        uint256 receivedLpTokens = _addLiquidity(_amount0, _amount1);
        require(receivedLpTokens >= shares, "NOT_ENOUGH_SHARES");

        /// @dev track 1:1 shares
        shares = receivedLpTokens;

        IERC20MintableBurnable(address(shareToken)).mint(_reciever, receivedLpTokens);

        emit Deposit(msg.sender, _reciever, _assets, receivedLpTokens);
    }

    function mint(uint256 _shares, address _receiver) public override returns (uint256 assets) {
        assets = previewMint(_shares);

        ERC20(address(asset)).safeTransferFrom(msg.sender, address(this), assets);

        (uint256 a0, uint256 a1) = _swapHalf(assets);

        uint256 receivedLpTokens = _addLiquidity(a0, a1);


        /// NOTE: PreviewMint needs to output reasonable amount of shares
        require(receivedLpTokens >= _slippageAdjusted(_shares), "INSUFFICENT_SHARES");

        IERC20MintableBurnable(address(shareToken)).mint(_receiver, receivedLpTokens);

        emit Deposit(msg.sender, _receiver, assets, _shares);
    }

    /// @notice Receive amount of `assets` of underlying token of this Vault
    function withdraw(uint256 assets_, address receiver_, address owner_) public override returns (uint256 shares) {
        shares = previewWithdraw(assets_);

        (uint256 assets0, uint256 assets1) = _removeLiquidity(shares);

        IERC20MintableBurnable(address(shareToken)).burn(owner_, shares);

        uint256 amount = asset == address(token0) ? _swapFull(assets1) + assets0 : _swapFull(assets0) + assets1;

        ERC20(asset).safeTransfer(receiver_, amount);

        emit Withdraw(msg.sender, receiver_, owner_, amount, shares);
    }

    /// @notice Burn amount of 'shares' of this Vault to receive some amount of underlying
    /// token of this vault
    function redeem(uint256 _shares, address _receiver, address _owner) public override returns (uint256 assets) {
        assets = previewRedeem(_shares);
        require(assets > 0, "ZERO_SHARES");

        (uint256 assets0, uint256 assets1) = _removeLiquidity(_shares);
        IERC20MintableBurnable(address(shareToken)).burn(_owner, _shares);

        uint256 amount = asset == address(token0) ? _swapFull(assets1) + assets0 : _swapFull(assets0) + assets1;

        ERC20(address(asset)).safeTransfer(_receiver, amount);

        emit Withdraw(msg.sender, _receiver, _owner, amount, _shares);
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20MintableBurnable(address(pool)).balanceOf(address(this));
    }

    function previewDeposit(uint256 _assets) public view override returns (uint256 shares) {
        return getSharesFromAssets(_assets);
    }

    /// @notice For this many shares/lp we need to pay at least this many assets
    function previewMint(uint256 _shares) public view override returns (uint256 assets) {
        /// NOTE: This method assumes that it covers liquidity requested for a block!
        assets = mintAssets(_shares);
    }

    function previewWithdraw(uint256 assets_) public view override returns (uint256 shares) {
        return getSharesFromAssets(assets_);
    }

    function previewRedeem(uint256 _shares) public view override returns (uint256 assets) {
        return redeemAssets(_shares);
    }

    // Revisit - hacky
    function mintAssets(uint256 shares_) public view returns (uint256 assets) {
        (uint256 reserveA, uint256 reserveB,) = pool.getReserves();
        /// shares of pool contract
        uint256 lpSupply = IERC20MintableBurnable(address(pool)).totalSupply();

        /// amount of token0 to provide to receive poolLpAmount
        uint256 _amount0 = reserveA.mulDivUp(shares_,lpSupply);

        /// amount of token1 to provide to receive poolLpAmount
        uint256 _amount1 = reserveB.mulDivUp(shares_,lpSupply);

        if (_amount1 == 0 || _amount0 == 0) return 0;

        if (asset == address(token0)) {
            assets = _amount0 + pool.getAmountOut(_amount1, address(token1));
        } else {
            assets = _amount1 + pool.getAmountOut(_amount0, address(token0));
        }

        assets += (assets * (isStable ? 5000 : 30000)) / MAX_BPS; //include fee
    }

    function redeemAssets(uint256 _shares) public view returns (uint256 assets) {
        (uint256 amount0, uint256 amount1) =
            ROUTER.quoteRemoveLiquidity(address(token0), address(token1), isStable, FACTORY, _shares);
        if (amount1 == 0 || amount0 == 0) return 0;

        if (asset == address(token0)) {
            assets = amount0 + pool.getAmountOut(amount1, address(token1));
        } else {
            assets = amount1 + pool.getAmountOut(amount0, address(token0));
        }
    }

    function setSlippage(uint256 _newSlippage) external {
        require(msg.sender == manager, "UNAUTHORIZED");
        slippage = _newSlippage;
    }

    function share() external view returns (address) {
        return address(shareToken);
    }

    /// Helpers

    // Swaps 50% of input token to other pool token.
    // Naive implementation, needs improvement. Will result in dust after addLiquidity()
    // TODO: Revisit and split logic for stable and volatile pools?
    function _swapHalf(uint256 _amountA) internal returns (uint256 amountA, uint256 amountB) {
        address tokenIn;
        address tokenOut;
        if (address(token0) == asset) {
            tokenIn = address(token0);
            tokenOut = address(token1);
        } else {
            tokenIn = address(token1);
            tokenOut = address(token0);
        }

        uint256 amountIn = _amountA / 2;
        uint256 amountOutMin = pool.getAmountOut(amountIn, tokenIn);
        IRouter.Route memory route = IRouter.Route(tokenIn, tokenOut, isStable, FACTORY);
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = route;
        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
            amountIn, _slippageAdjusted(amountOutMin), routes, address(this), block.timestamp
        );
        return (amounts[0], amounts[1]);
    }

    // Swaps 100% of input token amount to other pool token.
    function _swapFull(uint256 _amountA) internal returns (uint256) {
        address tokenIn;
        address tokenOut;
        if (address(token0) == asset) {
            tokenIn = address(token1);
            tokenOut = address(token0);
        } else {
            tokenIn = address(token0);
            tokenOut = address(token1);
        }

        uint256 amountIn = _amountA;
        uint256 amountOutMin = pool.getAmountOut(amountIn, tokenIn);
        IRouter.Route memory route = IRouter.Route(tokenIn, tokenOut, isStable, FACTORY);
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = route;
        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(
            amountIn, _slippageAdjusted(amountOutMin), routes, address(this), block.timestamp
        );

        return amounts[1];
    }

    /// @notice Add liquidity to the underlying pool. Send both token0 and token1 from the Vault address.
    function _addLiquidity(uint256 _amount0, uint256 _amount1) internal returns (uint256 lpTokensReceived) {
        (_amount0, _amount1,) =
            ROUTER.quoteAddLiquidity(address(token0), address(token1), isStable, FACTORY, _amount0, _amount1);
        (,, lpTokensReceived) = ROUTER.addLiquidity(
            address(token0),
            address(token1),
            isStable,
            _amount0,
            _amount1,
            _slippageAdjusted(_amount0),
            _slippageAdjusted(_amount1),
            address(this),
            block.timestamp
        );
    }

    /// @notice Remove liquidity from the underlying pool. Receive both token0 and token1 on the Vault address.
    function _removeLiquidity(uint256 _shares) internal returns (uint256 token0Recvd, uint256 token1Recvd) {
        (uint256 _amount0, uint256 _amount1) =
            ROUTER.quoteRemoveLiquidity(address(token0), address(token1), isStable, FACTORY, _shares);

        (token0Recvd, token1Recvd) = ROUTER.removeLiquidity(
            address(token0),
            address(token1),
            isStable,
            _shares,
            _slippageAdjusted(_amount0),
            _slippageAdjusted(_amount1),
            address(this),
            block.timestamp
        );
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

    function _slippageAdjusted(uint256 _amount) internal view returns (uint256) {
        return (_amount * (MAX_BPS - slippage)) / MAX_BPS;
    }

    function getSharesFromAssets(uint256 assets_) public view returns (uint256 poolLpAmount) {
        (uint256 assets0, uint256 assets1) = getSplitAssetAmounts(assets_);
        (,, poolLpAmount) = ROUTER.quoteAddLiquidity(
            address(token0), address(token1), isStable, FACTORY, _slippageAdjusted(assets0), _slippageAdjusted(assets1)
        );
    }

    function getSplitAssetAmounts(uint256 assets_) public view returns (uint256 assets0, uint256 assets1) {
        uint256 halfAssets = assets_ / 2;

        if (address(token0) == asset) {
            assets1 = pool.getAmountOut(halfAssets, address(token0));
            assets0 = assets_ - halfAssets;
        } else {
            assets0 = pool.getAmountOut(halfAssets, address(token1));
            assets1 = assets_ - halfAssets;
        }
    }
}
