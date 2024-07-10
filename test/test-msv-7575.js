const { expect } = require("chai");
const { amountFunction, _W, getRole } = require("@ensuro/core/js/utils");
const { initForkCurrency, setupChain } = require("@ensuro/core/js/test-utils");
const { buildUniswapConfig } = require("@ensuro/swaplibrary/js/utils");
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
    MSV7575Share,
    aaveStrategy,
    compoundStrategy,
    vault,
    COMPPrice,
  };
}

const CompoundV3StrategyMethods = {
  harvestRewards: 0,
  setSwapConfig: 1,
};

describe("MSV7575 Integration fork tests", function () {
  before(async () => {
    await setupChain(TEST_BLOCK);
  });

  it("Can perform a basic smoke test", async () => {
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
});
