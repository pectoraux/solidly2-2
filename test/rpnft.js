const { expect } = require("chai");
const { ethers } = require("hardhat");

function getCreate2Address(
  factoryAddress,
  [tokenA, tokenB],
  bytecode
) {
  const [token0, token1] = tokenA < tokenB ? [tokenA, tokenB] : [tokenB, tokenA]
  const create2Inputs = [
    '0xff',
    factoryAddress,
    keccak256(solidityPack(['address', 'address'], [token0, token1])),
    keccak256(bytecode)
  ]
  const sanitizedInputs = `0x${create2Inputs.map(i => i.slice(2)).join('')}`
  return getAddress(`0x${keccak256(sanitizedInputs).slice(-40)}`)
}

describe("core", function () {

  let token;
  let ust;
  let mim;
  let dai;
  let ve_underlying;
  let late_reward;
  let ve;
  let factory;
  let router;
  let pair;
  let pair2;
  let pair3;
  let owner;
  let gauge_factory;
  let gauge;
  let gauge2;
  let gauge3;
  let bribe;
  let bribe2;
  let bribe3;
  let minter;
  let ve_dist;
  let library;
  let staking;
  let owner2;
  let owner3;

  let codes;
  let prev_threshold;
  let codes_planets_years;
  
  it("deploy base coins", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    mim = await token.deploy('MIM', 'MIM', 18, owner.address);
    await mim.mint(owner.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await mim.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await mim.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    dai = await token.deploy('DAI', 'DAI', 18, owner.address);
    await dai.mint(owner.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await dai.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await dai.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("10000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("10000000000000000000000000"));
    late_reward = await token.deploy('LR', 'LR', 18, owner.address);
    await late_reward.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);

    await ust.deployed();
    await mim.deployed();
  });

  it("create lock", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("500000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("500000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("495063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("500000000000000000"));
  });

  it("increase lock", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("500000000000000000"));
    await ve.increase_amount(1, ethers.BigNumber.from("500000000000000000"));
    await expect(ve.increase_unlock_time(1, 4 * 365 * 86400)).to.be.reverted;
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("1000000000000000000"));
  });

  it("ve views", async function () {
    const block = await ve.block_number();
    expect(await ve.balanceOfAtNFT(1, block)).to.equal(await ve.balanceOfNFT(1));
    expect(await ve.totalSupplyAt(block)).to.equal(await ve.totalSupply());

    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("1000000000000000000"));
  });


  it("steal NFT", async function () {
    await expect(ve.connect(owner2).transferFrom(owner.address, owner2.address, 1)).to.be.reverted
    await expect(ve.connect(owner2).approve(owner2.address, 1)).to.be.reverted
    await expect(ve.connect(owner2).merge(1, 2)).to.be.reverted
  });


  it("ve merge", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(2)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("2000000000000000000"));
    console.log(await ve.totalSupply());
    await ve.merge(2, 1);
    console.log(await ve.totalSupply());
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("1990063075414519385"));
    expect(await ve.balanceOfNFT(2)).to.equal(ethers.BigNumber.from("0"));
    expect((await ve.locked(2)).amount).to.equal(ethers.BigNumber.from("0"));
    expect(await ve.ownerOf(2)).to.equal('0x0000000000000000000000000000000000000000');
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(3)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("3000000000000000000"));
    console.log(await ve.totalSupply());
    await ve.merge(3, 1);
    console.log(await ve.totalSupply());
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("1990063075414519385"));
    expect(await ve.balanceOfNFT(3)).to.equal(ethers.BigNumber.from("0"));
    expect((await ve.locked(3)).amount).to.equal(ethers.BigNumber.from("0"));
    expect(await ve.ownerOf(3)).to.equal('0x0000000000000000000000000000000000000000');
  });

  it("confirm ust deployment", async function () {
    expect(await ust.name()).to.equal("ust");
  });

  it("confirm mim deployment", async function () {
    expect(await mim.name()).to.equal("MIM");
  });

  it("deploy BaseV1Factory and test pair length", async function () {
    const BaseV1Factory = await ethers.getContractFactory("BaseV1Factory");
    factory = await BaseV1Factory.deploy();
    await factory.deployed();

    expect(await factory.allPairsLength()).to.equal(0);
  });

  it("deploy BaseV1Router and test factory address", async function () {
    const BaseV1Router = await ethers.getContractFactory("BaseV1Router01");
    router = await BaseV1Router.deploy(factory.address, owner.address);
    await router.deployed();

    expect(await router.factory()).to.equal(factory.address);
  });

  it("deploy pair via BaseV1Factory owner", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const mim_1 = ethers.BigNumber.from("1000000000000000000");
    const dai_1 = ethers.BigNumber.from("1000000000000000000");
    await mim.approve(router.address, mim_1);
    await ust.approve(router.address, ust_1);
    await router.addLiquidity(mim.address, ust.address, true, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.approve(router.address, mim_1);
    await ust.approve(router.address, ust_1);
    await router.addLiquidity(mim.address, ust.address, false, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.approve(router.address, mim_1);
    await dai.approve(router.address, dai_1);
    await router.addLiquidity(mim.address, dai.address, true, mim_1, dai_1, 0, 0, owner.address, Date.now());
    expect(await factory.allPairsLength()).to.equal(3);
  });

  it("deploy pair via BaseV1Factory owner2", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const mim_1 = ethers.BigNumber.from("1000000000000000000");
    const dai_1 = ethers.BigNumber.from("1000000000000000000");
    await mim.connect(owner2).approve(router.address, mim_1);
    await ust.connect(owner2).approve(router.address, ust_1);
    await router.connect(owner2).addLiquidity(mim.address, ust.address, true, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.connect(owner2).approve(router.address, mim_1);
    await ust.connect(owner2).approve(router.address, ust_1);
    await router.connect(owner2).addLiquidity(mim.address, ust.address, false, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.connect(owner2).approve(router.address, mim_1);
    await dai.connect(owner2).approve(router.address, dai_1);
    await router.connect(owner2).addLiquidity(mim.address, dai.address, true, mim_1, dai_1, 0, 0, owner.address, Date.now());
    expect(await factory.allPairsLength()).to.equal(3);
  });

  it("confirm pair for mim-ust", async function () {
    const create2address = await router.pairFor(mim.address, ust.address, true);
    const BaseV1Pair = await ethers.getContractFactory("BaseV1Pair");
    const address = await factory.getPair(mim.address, ust.address, true);
    const allpairs0 = await factory.allPairs(0);
    pair = await BaseV1Pair.attach(address);
    const address2 = await factory.getPair(mim.address, ust.address, false);
    pair2 = await BaseV1Pair.attach(address2);
    const address3 = await factory.getPair(mim.address, dai.address, true);
    pair3 = await BaseV1Pair.attach(address3);

    expect(pair.address).to.equal(create2address);
  });

  it("confirm tokens for mim-ust", async function () {
    [token0, token1] = await router.sortTokens(ust.address, mim.address);
    expect((await pair.token0()).toUpperCase()).to.equal(token0.toUpperCase());
    expect((await pair.token1()).toUpperCase()).to.equal(token1.toUpperCase());
  });

  it("mint & burn tokens for pair mim-ust", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const mim_1 = ethers.BigNumber.from("1000000000000000000");
    const before_balance = await ust.balanceOf(owner.address);
    await ust.transfer(pair.address, ust_1);
    await mim.transfer(pair.address, mim_1);
    await pair.mint(owner.address);
    expect(await pair.getAmountOut(ust_1, ust.address)).to.equal(ethers.BigNumber.from("982117769725505988"));
    const output = await router.getAmountOut(ust_1, ust.address, mim.address);
    expect(await pair.getAmountOut(ust_1, ust.address)).to.equal(output.amount);
    expect(output.stable).to.equal(true);
    expect(await router.isPair(pair.address)).to.equal(true);
  });

  it("mint & burn tokens for pair mim-ust owner2", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const mim_1 = ethers.BigNumber.from("1000000000000000000");
    const before_balance = await ust.balanceOf(owner.address);
    await ust.connect(owner2).transfer(pair.address, ust_1);
    await mim.connect(owner2).transfer(pair.address, mim_1);
    await pair.connect(owner2).mint(owner2.address);
    expect(await pair.connect(owner2).getAmountOut(ust_1, ust.address)).to.equal(ethers.BigNumber.from("992220948146798746"));
  });

  it("deploy BaseV1Voter", async function () {
    const BaseV1GaugeFactory = await ethers.getContractFactory("RPBusinessGaugeFactory");
    gauges_factory = await BaseV1GaugeFactory.deploy();
    await gauges_factory.deployed();
    const BaseV1BribeFactory = await ethers.getContractFactory("BaseV1BribeFactory");
    const bribe_factory = await BaseV1BribeFactory.deploy();
    await bribe_factory.deployed();
    const BaseV1Voter = await ethers.getContractFactory("RPBusinessVoter");
    gauge_factory = await BaseV1Voter.deploy(ve.address, factory.address, gauges_factory.address, bribe_factory.address);
    await gauge_factory.deployed();

    await ve.setVoter(gauge_factory.address);

    expect(await gauge_factory.minter()).to.equal(owner.address);
    await gauge_factory.setMinter(owner2.address);
    expect(await gauge_factory.minter()).to.equal(owner2.address);
    await gauge_factory.connect(owner2).setMinter(owner.address);

    expect(await gauge_factory.length()).to.equal(0);
  });

  it("test current & next year", async function () {
    await gauge_factory.updateCurrentYear();
    const before = await gauge_factory.current_year();
    await network.provider.send("evm_increaseTime", [86400 * 7 * 54])
    await network.provider.send("evm_mine")
    await gauge_factory.updateCurrentYear();
    expect(await gauge_factory.current_year()).to.equal(before.add(86400 * 7 * 54 * 1));
    expect(await gauge_factory.next_year()).to.equal(before.add(86400 * 7 * 54 * 2));
    await network.provider.send("evm_increaseTime", [86400 * 7 * 54])
    await network.provider.send("evm_mine")
    await gauge_factory.updateCurrentYear();
    expect(await gauge_factory.current_year()).to.equal(before.add(86400 * 7 * 54 * 2));
    expect(await gauge_factory.next_year()).to.equal(before.add(86400 * 7 * 54 * 3));
  });

  it("test generate codes", async function () {
    codes = await gauge_factory.generateCodes(
                ['32222222+22', '32222222+22', '7h2qxvhg+22', '7h2qxvhg+22'], 
                'earth',
                await gauge_factory.current_year()
                );
    expect(codes[0]).to.equal(codes[1]);
    expect(codes[1]).to.not.equal(codes[2]);
    expect(codes[2]).to.equal(codes[3]);
  });

  it("test canAttachCodesToWorld", async function () {
    expect(await gauge_factory.claimable(owner.address)).to.equal(0);
    await gauge_factory.updateMinted(codes);
    codes_planets_years = await gauge_factory.canAttachCodesToWorld(
      codes, 
      'earth', 
      await gauge_factory.current_year()
    );
    
    expect(codes_planets_years[0][0]).to.equal(codes[0]);
    expect(codes_planets_years[0][1]).to.equal(codes[1]);
    expect(codes_planets_years[0][2]).to.equal(codes[2]);
    expect(codes_planets_years[0][3]).to.equal(codes[3]);

    expect(codes_planets_years[1][0]).to.equal('earth');
    expect(codes_planets_years[1][1]).to.equal('earth');
    expect(codes_planets_years[1][2]).to.equal('earth');
    expect(codes_planets_years[1][3]).to.equal('earth');

    expect(codes_planets_years[2][0]).to.equal(await gauge_factory.current_year());
    expect(codes_planets_years[2][1]).to.equal(await gauge_factory.current_year());
    expect(codes_planets_years[2][2]).to.equal(await gauge_factory.current_year());
    expect(codes_planets_years[2][3]).to.equal(await gauge_factory.current_year());
    
    await gauge_factory.updateThreshold(0);
    const codes_planets_years2 = await gauge_factory.canAttachCodesToWorld(
      codes, 
      'earth', 
      await gauge_factory.current_year()
    );
    expect(codes_planets_years2[0][0]).to.equal(0);
    expect(codes_planets_years2[0][1]).to.equal(0);
    expect(codes_planets_years2[0][2]).to.equal(0);
    expect(codes_planets_years2[0][3]).to.equal(0);

    expect(codes_planets_years2[1][0]).to.equal('');
    expect(codes_planets_years2[1][1]).to.equal('');
    expect(codes_planets_years2[1][2]).to.equal('');
    expect(codes_planets_years2[1][3]).to.equal('');

    expect(codes_planets_years2[2][0]).to.equal(0);
    expect(codes_planets_years2[2][1]).to.equal(0);
    expect(codes_planets_years2[2][2]).to.equal(0);
    expect(codes_planets_years2[2][3]).to.equal(0);
    
    await gauge_factory.updateThreshold(10000);
  });

  it("deploy BaseV1Factory gauge", async function () {
    await ve_underlying.approve(gauge_factory.address, ethers.BigNumber.from("1500000000000000000000000"));
    expect(await gauge_factory.worlds(owner.address)).to.equal('0x0000000000000000000000000000000000000000');
    await gauge_factory.createGauge(1, ['32222222+22', '32222222+22', '7h2qxvhg+22', '7h2qxvhg+22'], 'earth', await gauge_factory.current_year());
    expect(await gauge_factory.worlds(owner.address)).to.not.equal('0x0000000000000000000000000000000000000000');
    
    const gauge_address = await gauge_factory.worlds(owner.address);
    const bribe_address = await gauge_factory.bribes(gauge_address);

    const Gauge = await ethers.getContractFactory("RPBusinessGauge");
    gauge = await Gauge.attach(gauge_address);

    const Bribe = await ethers.getContractFactory("Bribe");
    bribe = await Bribe.attach(bribe_address);

    console.log("gauge", gauge.address);
    console.log("bribe", bribe.address);

    expect(await gauge._years(0)).to.equal(await gauge_factory.current_year());
    expect(await gauge._years(1)).to.equal(await gauge_factory.current_year());
    expect(await gauge._years(2)).to.equal(await gauge_factory.current_year());
    expect(await gauge._years(3)).to.equal(await gauge_factory.current_year());

    await gauge.deposit(1, [1,2,3,4,5]);
    expect(await gauge.totalSupply()).to.equal(5);
    console.log(await gauge.earned(ve.address, owner.address));
    expect(await gauge.earned(ve.address, owner.address)).to.equal(0);

    expect(await gauge.tokenIds(owner.address)).to.equal(1);
    await expect(gauge.withdrawToken(5, 2)).to.be.reverted;
    await expect(gauge.withdrawToken(2, 1));
    expect(await gauge.tokenIds(owner.address)).to.equal(1);
    await expect(gauge.withdrawToken(3, 1));
    expect(await gauge.tokenIds(owner.address)).to.equal(0);

    await gauge.deposit(1, [1,2,3,4,5]);
    expect(await gauge.totalSupply()).to.equal(5);
    
  });

  it("add gauge & bribe rewards", async function () {
    const pair_1000 = ethers.BigNumber.from("1000000000");
    sr = await ethers.getContractFactory("StakingRewards");
    staking = await sr.deploy(pair.address, ve_underlying.address);

    await ve_underlying.approve(gauge.address, pair_1000);
    await ve_underlying.approve(bribe.address, pair_1000);
    await ve_underlying.approve(staking.address, pair_1000);

    await gauge.notifyRewardAmount(ve_underlying.address, pair_1000);
    await bribe.notifyRewardAmount(ve_underlying.address, pair_1000);
    await staking.notifyRewardAmount(pair_1000);

    expect(await gauge.rewardRate(ve_underlying.address)).to.equal(ethers.BigNumber.from(1653));
    // team takes 1% of total bribe = 16 ==> 1653 - 16 = 1636
    expect(await bribe.rewardRate(ve_underlying.address)).to.equal(ethers.BigNumber.from(1636));
    expect(await staking.rewardRate()).to.equal(ethers.BigNumber.from(1653));
  });

  it("gauge reset", async function () {
    await gauge_factory.reset(1);
  });

  it("gauge poke self", async function () {
    await gauge_factory.poke(1);
  });

  it("create lock 2", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(4)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("4000000000000000000"));
  });

  it("vote hacking", async function () {
    await gauge_factory.vote(4, [owner.address], [5000]);
    expect(await gauge_factory.usedWeights(4)).to.closeTo((await ve.balanceOfNFT(4)), 1000);
    expect(await bribe.balanceOf(4)).to.equal(await gauge_factory.votes(4, owner.address));
    await gauge_factory.reset(4);
    expect(await gauge_factory.usedWeights(4)).to.below(await ve.balanceOfNFT(4));
    expect(await gauge_factory.usedWeights(4)).to.equal(0);
    expect(await bribe.balanceOf(4)).to.equal(await gauge_factory.votes(4, owner.address));
    expect(await bribe.balanceOf(4)).to.equal(0);
  });

  it("gauge poke hacking", async function () {
    expect(await gauge_factory.usedWeights(4)).to.equal(0);
    expect(await gauge_factory.votes(4, owner.address)).to.equal(0);
    await gauge_factory.poke(4);
    expect(await gauge_factory.usedWeights(4)).to.equal(0);
    expect(await gauge_factory.votes(4, owner.address)).to.equal(0);
  });

  it("gauge vote & bribe balanceOf", async function () {
    await gauge_factory.vote(1, [owner.address, owner2.address], [5000,5000]);
    await gauge_factory.vote(4, [owner.address, owner2.address], [500000,500000]);
    console.log(await gauge_factory.usedWeights(1));
    console.log(await gauge_factory.usedWeights(4));
    expect(await gauge_factory.totalWeight()).to.not.equal(0);
    expect(await bribe.balanceOf(1)).to.not.equal(0);
  });

  // it("gauge poke hacking", async function () {
  //   const weight_before = (await gauge_factory.usedWeights(1));
  //   const votes_before = (await gauge_factory.votes(1, owner.address));
  //   await gauge_factory.poke(1);
  //   expect(await gauge_factory.usedWeights(1)).to.be.below(weight_before);
  //   expect(await gauge_factory.votes(1, owner.address)).to.be.below(votes_before);
  // });

  it("vote hacking break mint", async function () {
    await gauge_factory.vote(1, [owner.address], [5000]);

    expect(await gauge_factory.usedWeights(1)).to.closeTo((await ve.balanceOfNFT(1)), 1000);
    expect(await bribe.balanceOf(1)).to.equal(await gauge_factory.votes(1, owner.address));
  });

  it("gauge poke hacking", async function () {
    expect(await gauge_factory.usedWeights(1)).to.equal(await gauge_factory.votes(1, owner.address));
    await gauge_factory.poke(1);
    expect(await gauge_factory.usedWeights(1)).to.equal(await gauge_factory.votes(1, owner.address));
  });

  it("gauge distribute based on voting", async function () {
    await ve_underlying.connect(owner2).approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.connect(owner2).create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    await gauge_factory.connect(owner2).createGauge(5, ['32222222+22', '32222222+22', '7h2qxvhg+22', '7h2qxvhg+22'], 'earth', await gauge_factory.current_year());
    const gauge_address2 = await gauge_factory.worlds(owner2.address);
    const Gauge = await ethers.getContractFactory("RPBusinessGauge");
    gauge2 = await Gauge.attach(gauge_address2);

    console.log("claimable ==>", await gauge_factory.claimable(gauge.address));
    console.log("claimable ==>", await gauge_factory.claimable(gauge2.address));
    await gauge_factory.connect(owner2).vote(5, [owner.address], [5000]);
    await gauge_factory.vote(1, [owner2.address], [5000]);
    await gauge_factory.vote(4, [owner2.address], [500000]);
    const owner_1000 = ethers.BigNumber.from("1000000000");
    await ve_underlying.approve(gauge_factory.address, owner_1000);
    await gauge_factory.notifyRewardAmount(owner_1000);
    await gauge_factory.updateAll();
    console.log("claimable ==>", await gauge_factory.claimable(gauge.address));
    console.log("claimable ==>", await gauge_factory.claimable(gauge2.address));
  });

  it("mint NFTs from codes", async function () {
    expect(await gauge_factory.isMinted(await gauge.codes(0))).to.equal(0);
    expect(await gauge_factory.isMinted(await gauge.codes(1))).to.equal(0);
    expect(await gauge_factory.isMinted(await gauge.codes(2))).to.equal(0);
    expect(await gauge_factory.isMinted(await gauge.codes(3))).to.equal(0);
    expect(await gauge_factory.claimable(gauge.address)).to.be.above(0);
    prev_threshold = await gauge_factory.threshold();
    await gauge_factory.updateThreshold(
      (await gauge_factory.claimable(gauge.address)).add(1));
    await expect(gauge.mintNFTsFromCodes()).to.be.reverted;
    await gauge_factory.updateThreshold(prev_threshold);
    await gauge.mintNFTsFromCodes();
    expect(await gauge_factory.isMinted(await gauge.codes(0))).to.equal(await gauge_factory.claimable(gauge.address));
    expect(await gauge_factory.isMinted(await gauge.codes(1))).to.equal(await gauge_factory.claimable(gauge.address));
    expect(await gauge_factory.isMinted(await gauge.codes(2))).to.equal(await gauge_factory.claimable(gauge.address));
    expect(await gauge_factory.isMinted(await gauge.codes(3))).to.equal(await gauge_factory.claimable(gauge.address));
  });

  it("test initialize already minted codes", async function () {
    // cannot mine codes above threshold
    await expect(
      gauge_factory.initialize(
        gauge.address,
        ['32222222+22', '32222222+22', '7h2qxvhg+22', '7h2qxvhg+22'], 
        'earth', 
        await gauge_factory.current_year()
      )
    ).to.be.reverted;
    // simulates falling below the threshold
    await gauge_factory.updateThreshold(
      (await gauge_factory.claimable(gauge.address)).add(1));
    // codes below threshold can now be mined
    await gauge_factory.initialize(
      gauge.address,
      ['32222222+22', '32222222+22', '7h2qxvhg+22', '7h2qxvhg+22'], 
      'earth', 
      await gauge_factory.current_year()
    );

    await gauge_factory.updateThreshold(prev_threshold);
  });

});
