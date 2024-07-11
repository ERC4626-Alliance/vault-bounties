const { expect } = require("chai");
const { amountFunction, _W, getRole } = require("@ensuro/core/js/utils");
const { initForkCurrency, setupChain } = require("@ensuro/core/js/test-utils");
const { buildUniswapConfig, buildCurveConfig } = require("@ensuro/swaplibrary/js/utils");
const { encodeSwapConfig } = require("./utils");
const hre = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const { ethers } = hre;
const { MaxUint256 } = hre.ethers;

const ADDRESSES = {
  // mainnet addresses
  UNISWAP: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
  USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  USDCWhale: "0xB9711550ec6Dc977f26B73809A2D6791c0F0E9C8",
  cUSDCv3: "0xc3d688B66703497DAA19211EEdff47f25384cdc3",
  REWARDS: "0x1B0e765F6224C21223AeA2af16c1C46E38885a40",
  COMP: "0xc00e94Cb662C3520282E6f5717214004A7f26888",
  AAVEv3: "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2",
  aUSDCv3: "0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c",
  COMP_CHAINLINK: "0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5",
  USDe: "0x4c9edd5852cd905f086c759e8383e09bff1e68b3",
  USDM: "0x59d9356e565ab3a36dd77763fc0d87feaf85508c", // i = 0 in USDM-3crv
  CURVE_ROUTER: "0x16C6521Dff6baB339122a0FE25a9116693265353",
  GAUNLET_METAMORPHO: "0x8eB67A509616cd6A7c1B3c8C21D48FF57df3d458", // a 4626 vault denominated in USDC
};

const ChainlinkABI = [
  {
    inputs: [],
    name: "latestRoundData",
    outputs: [
      { internalType: "uint80", name: "roundId", type: "uint80" },
      { internalType: "int256", name: "answer", type: "int256" },
      { internalType: "uint256", name: "startedAt", type: "uint256" },
      { internalType: "uint256", name: "updatedAt", type: "uint256" },
      { internalType: "uint80", name: "answeredInRound", type: "uint80" },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const CURRENCY_DECIMALS = 6;
const _A = amountFunction(CURRENCY_DECIMALS);
const TEST_BLOCK = 20275000;
const CENT = _A("0.01");
const HOUR = 3600;
const DAY = HOUR * 24;
const MONTH = DAY * 30;
const INITIAL = 10000;
const NAME = "MSV7575";
const SYMB = "USDCmsv";

const FEETIER = 3000;

async function setUp() {
  const [, lp, lp2, anon, guardian, admin] = await ethers.getSigners();
  const currency = await initForkCurrency(ADDRESSES.USDC, ADDRESSES.USDCWhale, [lp, lp2], [_A(INITIAL), _A(INITIAL)]);

  const SwapLibrary = await ethers.getContractFactory("SwapLibrary");
  const swapLibrary = await SwapLibrary.deploy();

  const swapConfig = buildUniswapConfig(_W("0.00001"), FEETIER, ADDRESSES.UNISWAP);
  const adminAddr = await ethers.resolveAddress(admin);

  // I leave this strategy as non-7575 strategy
  const CompoundV3InvestStrategy = await ethers.getContractFactory("CompoundV3InvestStrategy", {
    libraries: {
      SwapLibrary: await ethers.resolveAddress(swapLibrary),
    },
  });
  const compoundStrategy = await CompoundV3InvestStrategy.deploy(ADDRESSES.cUSDCv3, ADDRESSES.REWARDS);
  const MSV7575Share = await ethers.getContractFactory("MSV7575Share");
  const vault = await hre.upgrades.deployProxy(
    MSV7575Share,
    [
      NAME,
      SYMB,
      adminAddr,
      await ethers.resolveAddress(currency),
      await Promise.all([compoundStrategy].map(ethers.resolveAddress)),
      [encodeSwapConfig(swapConfig)],
      [0],
      [0],
    ],
    {
      kind: "uups",
      unsafeAllow: ["delegatecall"],
    }
  );
  await currency.connect(lp).approve(vault, MaxUint256);
  await currency.connect(lp2).approve(vault, MaxUint256);
  await vault.connect(admin).grantRole(getRole("LP_ROLE"), lp);
  await vault.connect(admin).grantRole(getRole("LP_ROLE"), lp2);
  await vault.connect(admin).grantRole(getRole("REBALANCER_ROLE"), admin);
  await vault.connect(admin).grantRole(getRole("STRATEGY_ADMIN_ROLE"), admin);

  const AaveV3InvestStrategy7575 = await ethers.getContractFactory("AaveV3InvestStrategy7575");
  const aaveStrategy = await AaveV3InvestStrategy7575.deploy(ADDRESSES.USDC, ADDRESSES.AAVEv3, vault);
  await vault.connect(admin).addStrategy(aaveStrategy, ethers.toUtf8Bytes(""));
  await vault.connect(admin).setAs7575EntryPoint(1, true);

  const aUSDCv3 = await ethers.getContractAt("IERC20", ADDRESSES.aUSDCv3);

  const COMPPrice = await ethers.getContractAt(ChainlinkABI, ADDRESSES.COMP_CHAINLINK);

  return {
    currency,
    swapConfig,
    adminAddr,
    lp,
    lp2,
    anon,
    guardian,
    admin,
    swapLibrary,
    CompoundV3InvestStrategy,
    AaveV3InvestStrategy7575,
    aUSDCv3,
    MSV7575Share,
    aaveStrategy,
    compoundStrategy,
    vault,
    COMPPrice,
  };
}

function usdm2usdcSwapConfig() {
  // TO DO: I don't have the precise route in mainnet for this
  return buildCurveConfig(_W("0.02"), ADDRESSES.CURVE_ROUTER, [
    {
      route: [
        ADDRESSES.USDC,
        "0xc83b79c07ece44b8b99ffa0e235c00add9124f9e", // USDM-3crv
        ADDRESSES.USDM,
      ],
      swapParams: [[0, 1, 1, 1, 2]],
      pools: ["0xc83b79c07ece44b8b99ffa0e235c00add9124f9e"],
    },
    {
      route: [
        ADDRESSES.USDM,
        "0xc83b79c07ece44b8b99ffa0e235c00add9124f9e", // USDM-3crv
        ADDRESSES.USDC,
      ],
      swapParams: [[0, 1, 1, 1, 2]],
      pools: ["0xc83b79c07ece44b8b99ffa0e235c00add9124f9e"],
    },
  ]);
}

describe("MSV7575 Integration fork tests", function () {
  before(async () => {
    await setupChain(TEST_BLOCK);
  });

  it("Can perform a basic smoke test (doesn't use endpoints)", async () => {
    const { vault, currency, lp, lp2, admin, aaveStrategy, compoundStrategy } = await helpers.loadFixture(setUp);
    expect(await vault.name()).to.equal(NAME);
    await vault.connect(lp).deposit(_A(5000), lp);
    await vault.connect(lp2).deposit(_A(7000), lp2);

    expect(await vault.totalAssets()).to.be.closeTo(_A(12000), CENT);

    await vault.connect(admin).rebalance(0, 1, _A(7000));

    expect(await aaveStrategy["totalAssets(address)"](vault)).to.closeTo(_A(7000), CENT);
    expect(await compoundStrategy.totalAssets(vault)).to.closeTo(_A(5000), CENT);

    await helpers.time.increase(MONTH);
    expect(await aaveStrategy["totalAssets(address)"](vault)).to.closeTo(_A("7029.864071"), CENT);
    expect(await compoundStrategy.totalAssets(vault)).to.closeTo(_A("5022.716093"), CENT);
    expect(await vault.totalAssets()).to.be.closeTo(_A("12052.580164"), CENT);

    expect(await compoundStrategy.totalAssets(vault)).to.closeTo(_A("5022.716102"), CENT);
    expect(await vault.totalAssets()).to.be.closeTo(_A("12052.580164"), CENT);

    // Withdraw all the funds
    await vault.connect(lp).redeem(_A(5000), lp, lp);
    await vault.connect(lp2).redeem(await vault.balanceOf(lp2), lp2, lp2);
    expect(await vault.totalAssets()).to.be.closeTo(_A("0"), CENT);

    expect(await currency.balanceOf(lp)).to.closeTo(_A(INITIAL) + _A("22.004665"), CENT);
    expect(await currency.balanceOf(lp2)).to.closeTo(_A(INITIAL) + _A("30.671779"), CENT);
  });

  it("Can perform a basic smoke test - Using AAVEv3 7575 endpoint", async () => {
    const { vault, lp, lp2, admin, aaveStrategy, compoundStrategy, aUSDCv3 } = await helpers.loadFixture(setUp);
    expect(await vault.name()).to.equal(NAME);
    await vault.connect(lp).deposit(_A(5000), lp);
    await vault.connect(lp2).deposit(_A(7000), lp2);

    expect(await vault.totalAssets()).to.be.closeTo(_A(12000), CENT);

    // Move 6.5K from Compound to AAVEv3
    await vault.connect(admin).rebalance(0, 1, _A(6500));

    expect(await aaveStrategy["totalAssets(address)"](vault)).to.closeTo(_A(6500), CENT);
    expect(await compoundStrategy.totalAssets(vault)).to.closeTo(_A(5500), CENT);

    // Now test the 7575 views
    expect(await aaveStrategy["totalAssets()"](vault)).to.closeTo(_A(6500), CENT);

    // maxMint and maxDeposit use vault's validations and entry point limits
    expect(await aaveStrategy.maxDeposit(lp)).to.equal(MaxUint256);
    expect(await aaveStrategy.maxMint(lp)).to.gt(_W(9999999999999)); // A lot, not MaxUint256
    expect(await aaveStrategy.maxDeposit(admin)).to.equal(0);
    expect(await aaveStrategy.maxMint(admin)).to.equal(0);

    expect(await aaveStrategy.maxWithdraw(lp)).to.closeTo(_A(5000), CENT);
    expect(await aaveStrategy.maxRedeem(lp)).to.closeTo(_A(5000), CENT);
    expect(await aaveStrategy.maxWithdraw(lp2)).to.closeTo(_A(6500), CENT);
    expect(await aaveStrategy.maxRedeem(lp2)).to.closeTo(_A(6500), CENT);

    expect(await vault.maxWithdraw(lp2)).to.closeTo(_A(7000), CENT);
    expect(await vault.maxRedeem(lp2)).to.closeTo(_A(7000), CENT);

    // I can withdraw and redeem directly from entry point
    expect(await aaveStrategy.connect(lp).withdraw(_A(2000), lp, lp)).to.emit(aaveStrategy, "Withdraw");
    expect(await aUSDCv3.balanceOf(lp)).to.equal(_A(2000));

    // Redeem with owner=lp2 and receiver=lp
    expect(await aaveStrategy.connect(lp2).redeem(_A(1000), lp, lp2)).to.emit(aaveStrategy, "Withdraw");
    expect(await aUSDCv3.balanceOf(lp)).to.closeTo(_A(3000), CENT);

    // Redeem with owner=lp, receiver=lp2, caller = lp2
    await expect(aaveStrategy.connect(lp2).redeem(_A(1000), lp2, lp)).to.be.revertedWith(
      "ERC20: insufficient allowance"
    );
    await vault.connect(lp).approve(lp2, _A(1001));
    expect(await aaveStrategy.connect(lp2).redeem(_A(1000), lp2, lp)).to.emit(aaveStrategy, "Withdraw");
    expect(await aUSDCv3.balanceOf(lp)).to.closeTo(_A(3000), CENT);
    expect(await aUSDCv3.balanceOf(lp2)).to.closeTo(_A(1000), CENT);
    expect(await vault.allowance(lp, lp2)).to.equal(_A(1));

    await helpers.time.increase(MONTH);
    expect(await aaveStrategy["totalAssets(address)"](vault)).to.closeTo(_A("2510.665764"), CENT);
    expect(await compoundStrategy.totalAssets(vault)).to.closeTo(_A("5524.987726"), CENT);
    expect(await vault.totalAssets()).to.be.closeTo(_A("8035.653490"), CENT);

    // I can deposit and mint directly using aUSDCv3
    await aUSDCv3.connect(lp).approve(aaveStrategy, MaxUint256);
    await aUSDCv3.connect(lp2).approve(aaveStrategy, MaxUint256);
    // Deposit directly with receiver of the shares = lp2
    let expectedShares = (await vault.balanceOf(lp2)) + (await vault.convertToShares(_A(1500)));
    expect(await aaveStrategy.connect(lp)["deposit(uint256, address)"](_A(1500), lp2)).to.emit(aaveStrategy, "Deposit");
    expect(await vault.balanceOf(lp2)).to.closeTo(expectedShares, CENT);
    // Mint directly
    let expectedAssets = (await aUSDCv3.balanceOf(lp2)) - (await vault.convertToAssets(_A(1100)));
    expect(await aaveStrategy.previewMint(_A(1100))).to.closeTo(await vault.convertToAssets(_A(1100)), CENT);
    expect(await aaveStrategy.connect(lp2).mint(_A(1100), lp2)).to.emit(aaveStrategy, "Deposit");
    expect(await aUSDCv3.balanceOf(lp2)).to.closeTo(expectedAssets, CENT);
    expect(await vault.balanceOf(lp2)).to.closeTo(expectedShares + _A(1100), CENT);
  });

  it("Can invest in another 4646 using ERC4626InvestStrategy7575", async () => {
    const { currency, vault, lp, lp2, admin, compoundStrategy } = await helpers.loadFixture(setUp);
    const ERC4626InvestStrategy7575 = await ethers.getContractFactory("ERC4626InvestStrategy7575");
    const metamorpho = await ethers.getContractAt("IERC4626", ADDRESSES.GAUNLET_METAMORPHO);
    const morphoStrategy = await ERC4626InvestStrategy7575.deploy(metamorpho, vault);
    await vault.connect(admin).addStrategy(morphoStrategy, ethers.toUtf8Bytes(""));
    await vault.connect(admin).setAs7575EntryPoint(2, true);
    expect(await vault.vault(metamorpho)).to.equal(morphoStrategy);

    await vault.connect(lp).deposit(_A(5000), lp);

    expect(await vault.totalAssets()).to.be.closeTo(_A(5000), CENT);

    // Move 4.5K from Compound to morphoStrategy
    await vault.connect(admin).rebalance(0, 2, _A(4500));

    // totalAssets 7575 returns the number of metamorpho shares
    expect(await morphoStrategy["totalAssets()"](vault)).to.equal(await metamorpho.balanceOf(vault));
    expect(await morphoStrategy["totalAssets()"](vault)).to.closeTo(_W(4401), _W(1)); // Clearly different
    expect(await compoundStrategy.totalAssets(vault)).to.closeTo(_A(500), CENT);
    // totalAssets IInvestStrategy returns the amount in USDC
    expect(await morphoStrategy["totalAssets(address)"](vault)).to.closeTo(_A(4500), CENT);

    await currency.connect(lp2).approve(metamorpho, MaxUint256);
    await metamorpho.connect(lp2).deposit(_A(3000), lp2);
    const lp2Shares = await metamorpho.balanceOf(lp2);

    await metamorpho.connect(lp2).approve(morphoStrategy, _W(500));

    expect(await morphoStrategy.maxDeposit(lp2)).to.equal(await metamorpho.maxMint(vault));

    expect(await morphoStrategy.connect(lp2)["deposit(uint256, address)"](_W(500), lp2)).to.emit(
      morphoStrategy,
      "Deposit"
    );
    expect(await metamorpho.balanceOf(lp2)).to.equal(lp2Shares - _W(500));

    // Now test in metamorpho shares withdraw
    expect(await morphoStrategy.connect(lp).withdraw(_W(100), lp, lp)).to.emit(morphoStrategy, "Withdraw");
    expect(await metamorpho.balanceOf(lp)).to.equal(_W(100));
  });
});
