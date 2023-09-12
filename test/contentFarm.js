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
  let contentfarm_factory;
  let contentfarm;
  let contentfarm2;
  let contentfarm3;
  let bribe;
  let bribe2;
  let bribe3;
  let minter;
  let ve_dist;
  let library;
  let staking;
  let owner2;
  let owner3;

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

  it("BaseV1Router01 addLiquidity", async function () {
    const ust_1000 = ethers.BigNumber.from("100000000000");
    const mim_1000 = ethers.BigNumber.from("100000000000000000000000");
    const mim_100000000 = ethers.BigNumber.from("100000000000000000000000000");
    const dai_100000000 = ethers.BigNumber.from("100000000000000000000000000");
    const expected_2000 = ethers.BigNumber.from("2000000000000");
    await ust.approve(router.address, ust_1000);
    await mim.approve(router.address, mim_1000);
    const expected = await router.quoteAddLiquidity(mim.address, ust.address, true, mim_1000, ust_1000);
    await router.addLiquidity(mim.address, ust.address, true, mim_1000, ust_1000, expected.amountA, expected.amountB, owner.address, Date.now());
    await ust.approve(router.address, ust_1000);
    await mim.approve(router.address, mim_1000);
    await router.addLiquidity(mim.address, ust.address, false, mim_1000, ust_1000, mim_1000, ust_1000, owner.address, Date.now());
    await dai.approve(router.address, dai_100000000);
    await mim.approve(router.address, mim_100000000);
    await router.addLiquidity(mim.address, dai.address, true, mim_100000000, dai_100000000, 0, 0, owner.address, Date.now());
  });

  it("BaseV1Router01 removeLiquidity", async function () {
    const ust_1000 = ethers.BigNumber.from("100000000000");
    const mim_1000 = ethers.BigNumber.from("100000000000000000000000");
    const mim_100000000 = ethers.BigNumber.from("100000000000000000000000000");
    const dai_100000000 = ethers.BigNumber.from("100000000000000000000000000");
    const expected_2000 = ethers.BigNumber.from("2000000000000");
    await ust.approve(router.address, ust_1000);
    await mim.approve(router.address, mim_1000);
    const expected = await router.quoteAddLiquidity(mim.address, ust.address, true, mim_1000, ust_1000);
    const output = await router.quoteRemoveLiquidity(mim.address, ust.address, true, ust_1000);
  });

  it("BaseV1Router01 addLiquidity owner2", async function () {
    const ust_1000 = ethers.BigNumber.from("100000000000");
    const mim_1000 = ethers.BigNumber.from("100000000000000000000000");
    const mim_100000000 = ethers.BigNumber.from("100000000000000000000000000");
    const dai_100000000 = ethers.BigNumber.from("100000000000000000000000000");
    const expected_2000 = ethers.BigNumber.from("2000000000000");
    await ust.connect(owner2).approve(router.address, ust_1000);
    await mim.connect(owner2).approve(router.address, mim_1000);
    await router.connect(owner2).addLiquidity(mim.address, ust.address, true, mim_1000, ust_1000, mim_1000, ust_1000, owner.address, Date.now());
    await ust.connect(owner2).approve(router.address, ust_1000);
    await mim.connect(owner2).approve(router.address, mim_1000);
    await router.connect(owner2).addLiquidity(mim.address, ust.address, false, mim_1000, ust_1000, mim_1000, ust_1000, owner.address, Date.now());
    await dai.connect(owner2).approve(router.address, dai_100000000);
    await mim.connect(owner2).approve(router.address, mim_100000000);
    await router.connect(owner2).addLiquidity(mim.address, dai.address, true, mim_100000000, dai_100000000, 0, 0, owner.address, Date.now());
  });

  it("BaseV1Router01 pair1 getAmountsOut & swapExactTokensForTokens", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const route = {from:ust.address, to:mim.address, stable:true}

    expect((await router.getAmountsOut(ust_1, [route]))[1]).to.be.equal(await pair.getAmountOut(ust_1, ust.address));

    const before = await mim.balanceOf(owner.address);
    const expected_output_pair = await pair.getAmountOut(ust_1, ust.address);
    const expected_output = await router.getAmountsOut(ust_1, [route]);
    await ust.approve(router.address, ust_1);
    await router.swapExactTokensForTokens(ust_1, expected_output[1], [route], owner.address, Date.now());
    const fees = await pair.fees()
    expect(await ust.balanceOf(fees)).to.be.equal(100);
    const b = await ust.balanceOf(owner.address);
    await pair.claimFees();
    expect(await ust.balanceOf(owner.address)).to.be.above(b);
  });

  it("BaseV1Router01 pair1 getAmountsOut & swapExactTokensForTokens owner2", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const route = {from:ust.address, to:mim.address, stable:true}

    expect((await router.getAmountsOut(ust_1, [route]))[1]).to.be.equal(await pair.getAmountOut(ust_1, ust.address));

    const before = await mim.balanceOf(owner2.address);
    const expected_output_pair = await pair.getAmountOut(ust_1, ust.address);
    const expected_output = await router.getAmountsOut(ust_1, [route]);
    await ust.connect(owner2).approve(router.address, ust_1);
    await router.connect(owner2).swapExactTokensForTokens(ust_1, expected_output[1], [route], owner2.address, Date.now());
    const fees = await pair.fees()
    expect(await ust.balanceOf(fees)).to.be.equal(101);
    const b = await ust.balanceOf(owner.address);
    await pair.connect(owner2).claimFees();
    expect(await ust.balanceOf(owner.address)).to.be.equal(b);
  });

  it("BaseV1Router01 pair2 getAmountsOut & swapExactTokensForTokens", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const route = {from:ust.address, to:mim.address, stable:false}

    expect((await router.getAmountsOut(ust_1, [route]))[1]).to.be.equal(await pair2.getAmountOut(ust_1, ust.address));

    const before = await mim.balanceOf(owner.address);
    const expected_output_pair = await pair.getAmountOut(ust_1, ust.address);
    const expected_output = await router.getAmountsOut(ust_1, [route]);
    await ust.approve(router.address, ust_1);
    await router.swapExactTokensForTokens(ust_1, expected_output[1], [route], owner.address, Date.now());
  });

  it("BaseV1Router01 pair3 getAmountsOut & swapExactTokensForTokens", async function () {
    const mim_1000000 = ethers.BigNumber.from("1000000000000000000000000");
    const route = {from:mim.address, to:dai.address, stable:true}

    expect((await router.getAmountsOut(mim_1000000, [route]))[1]).to.be.equal(await pair3.getAmountOut(mim_1000000, mim.address));

    const before = await mim.balanceOf(owner.address);
    const expected_output_pair = await pair3.getAmountOut(mim_1000000, mim.address);
    const expected_output = await router.getAmountsOut(mim_1000000, [route]);
    await mim.approve(router.address, mim_1000000);
    await router.swapExactTokensForTokens(mim_1000000, expected_output[1], [route], owner.address, Date.now());
  });

  it("deploy ContentFarmVoter", async function () {
    const ContentFarmFactory = await ethers.getContractFactory("ContentFarmFactory");
    contentfarms_factory = await ContentFarmFactory.deploy();
    await contentfarms_factory.deployed();
    const BaseV1BribeFactory = await ethers.getContractFactory("BaseV1BribeFactory");
    const bribe_factory = await BaseV1BribeFactory.deploy();
    await bribe_factory.deployed();
    const ContentFarmVoter = await ethers.getContractFactory("ContentFarmVoter");
    contentfarm_factory = await ContentFarmVoter.deploy(ve.address, contentfarms_factory.address, bribe_factory.address);
    await contentfarm_factory.deployed();

    await ve.setVoter(contentfarm_factory.address);

    expect(await contentfarm_factory.length()).to.equal(0);
  });

  it("deploy BaseV1Minter", async function () {
    const VeDist = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    ve_dist = await VeDist.deploy(ve.address);
    await ve_dist.deployed();

    const BaseV1Minter = await ethers.getContractFactory("BaseV1Minter");
    minter = await BaseV1Minter.deploy(contentfarm_factory.address, ve.address, ve_dist.address);
    await minter.deployed();
    await ve_dist.setDepositor(minter.address);
    await contentfarm_factory.updateMinter(minter.address);
  });

  it("create lock 4", async function () {
    await ve_underlying.connect(owner2).approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.connect(owner2).create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(4)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("4000000000000000000"));
  });

  it("deploy ContentFarmFactory contentfarm", async function () {
    const pair_1000 = ethers.BigNumber.from("1000000000");

    await ve_underlying.approve(contentfarm_factory.address, ethers.BigNumber.from("1500000000000000000000000"));
    await contentfarm_factory.createGauge(
      1, 
      "_video_cid",
      "_creative_cid",
      "_cancan_email",
      "_website_link"  
    );
    await contentfarm_factory.connect(owner2).createGauge(
      4, 
      "_video_cid",
      "_creative_cid",
      "_cancan_email",
      "_website_link"  
    );
    expect(await contentfarm_factory.gauges(owner.address)).to.not.equal(0x0000000000000000000000000000000000000000);
    expect(await contentfarm_factory.gauges(owner2.address)).to.not.equal(0x0000000000000000000000000000000000000000);

    sr = await ethers.getContractFactory("StakingRewards");
    staking = await sr.deploy(pair.address, ve_underlying.address);

    const contentfarm_address = await contentfarm_factory.gauges(1);
    const bribe_address = await contentfarm_factory.bribes(contentfarm_address);

    const contentfarm_address2 = await contentfarm_factory.gauges(4);
    const bribe_address2 = await contentfarm_factory.bribes(contentfarm_address2);

    const ContentFarm = await ethers.getContractFactory("ContentFarm");
    contentfarm = await ContentFarm.attach(contentfarm_address);
    contentfarm2 = await ContentFarm.attach(contentfarm_address2);

    const Bribe = await ethers.getContractFactory("Bribe");
    bribe = await Bribe.attach(bribe_address);
    bribe2 = await Bribe.attach(bribe_address2);

    await contentfarm.updateVideoCid("_video_cid2");
    expect(await contentfarm.video_cid()).to.equal("_video_cid2");

    await contentfarm.updateCreativeCid("_creative_cid2");
    expect(await contentfarm.creative_cid()).to.equal("_creative_cid2");

    await contentfarm.updateCancanEmail("cancan_email2");
    expect(await contentfarm.cancan_email()).to.equal("cancan_email2");

    await expect(contentfarm.connect(owner2).updateWebsiteLink("website_link2")).to.be.reverted;

    await contentfarm.updateWebsiteLink("website_link2");
    expect(await contentfarm.website_link()).to.equal("website_link2");

    await contentfarm2.connect(owner2).updateWebsiteLink("website_link2");
    expect(await contentfarm2.website_link()).to.equal("website_link2");
  });

  it("add to contentfarm & bribe rewards", async function () {
    const pair_1000 = ethers.BigNumber.from("1000000000");

    await ve_underlying.approve(contentfarm.address, pair_1000);
    await ve_underlying.approve(bribe.address, pair_1000);
    await ve_underlying.approve(staking.address, pair_1000);

    await contentfarm.notifyRewardAmount(ve_underlying.address, pair_1000);
    await bribe.notifyRewardAmount(ve_underlying.address, pair_1000);
    await staking.notifyRewardAmount(pair_1000);

    expect(await ve_underlying.balanceOf(contentfarm.address)).to.be.equal(pair_1000);
    expect(await bribe.rewardRate(ve_underlying.address)).to.equal(ethers.BigNumber.from(1653));
    expect(await staking.rewardRate()).to.equal(ethers.BigNumber.from(1653));

    await contentfarm.withdrawAll(ve_underlying.address);
    expect(await ve_underlying.balanceOf(contentfarm.address)).to.be.equal(0);
  });

  it("vote hacking", async function () {
    await contentfarm_factory.vote(1, [1], [5000]);
    expect(await contentfarm_factory.usedWeights(1)).to.closeTo((await ve.balanceOfNFT(1)), 1000);
    expect(await bribe.balanceOf(1)).to.equal(await contentfarm_factory.votes(1, 1));
    await contentfarm_factory.reset(1);
    expect(await contentfarm_factory.usedWeights(1)).to.below(await ve.balanceOfNFT(1));
    expect(await contentfarm_factory.usedWeights(1)).to.equal(0);
    expect(await bribe.balanceOf(1)).to.equal(await contentfarm_factory.votes(1, 1));
    expect(await bribe.balanceOf(1)).to.equal(0);
  });

  it("contentfarm poke hacking", async function () {
    expect(await contentfarm_factory.usedWeights(1)).to.equal(0);
    expect(await contentfarm_factory.votes(1, 1)).to.equal(0);
    await contentfarm_factory.poke(1);
    expect(await contentfarm_factory.usedWeights(1)).to.equal(0);
    expect(await contentfarm_factory.votes(1, pair.address)).to.equal(0);
  });

  it("contentfarm vote & bribe balanceOf", async function () {
    await contentfarm_factory.vote(1, [1, 4], [5000,5000]);
    await contentfarm_factory.connect(owner2).vote(4, [1, 4], [500000,500000]);
    console.log(await contentfarm_factory.usedWeights(1));
    console.log(await contentfarm_factory.usedWeights(4));
    expect(await contentfarm_factory.totalWeight()).to.not.equal(0);
    expect(await bribe.balanceOf(1)).to.not.equal(0);
  });

  it("vote hacking break mint", async function () {
    await contentfarm_factory.vote(1, [1], [5000]);

    expect(await contentfarm_factory.usedWeights(1)).to.closeTo((await ve.balanceOfNFT(1)), 1000);
    expect(await bribe.balanceOf(1)).to.equal(await contentfarm_factory.votes(1, 1));
  });

  it("contentfarm poke hacking", async function () {
    expect(await contentfarm_factory.usedWeights(1)).to.equal(await contentfarm_factory.votes(1, 1));
    await contentfarm_factory.poke(1);
    expect(await contentfarm_factory.usedWeights(1)).to.equal(await contentfarm_factory.votes(1, 1));
  });

  it("contentfarm distribute based on voting", async function () {
    const pair_1000 = ethers.BigNumber.from("1000000000");
    await ve_underlying.approve(contentfarm_factory.address, pair_1000);
    await contentfarm_factory.notifyRewardAmount(pair_1000);
    await contentfarm_factory.updateAll();
    await contentfarm_factory.distro();
  });

  it("bribe claim rewards", async function () {
    await bribe.getReward(1, [ve_underlying.address]);
    await network.provider.send("evm_increaseTime", [691200])
    await network.provider.send("evm_mine")
    await bribe.getReward(1, [ve_underlying.address]);
  });

  it("minter mint", async function () {
    console.log(await ve_dist.last_token_time());
    console.log(await ve_dist.timestamp());
    await minter.initialize([owner.address],[ethers.BigNumber.from("1000000000000000000")], ethers.BigNumber.from("1000000000000000000"));
    await minter.update_period();
    await contentfarm_factory.updateGauge(contentfarm.address);
    console.log(await ve_underlying.balanceOf(ve_dist.address));
    console.log(await ve_dist.claimable(1));
    const claimable = await contentfarm_factory.claimable(contentfarm.address);
    console.log(await ve_underlying.balanceOf(contentfarm_factory.address));
    console.log(claimable);
    await ve_underlying.approve(staking.address, claimable);
    await staking.notifyRewardAmount(claimable);
    await contentfarm_factory.distro();
    await network.provider.send("evm_increaseTime", [1800])
    await network.provider.send("evm_mine")
    // expect(await contentfarm.rewardRate(ve_underlying.address)).to.be.equal(await staking.rewardRate());
  });

  it("minter mint", async function () {
    const before = await ve_underlying.balanceOf(contentfarm.address)
    await network.provider.send("evm_increaseTime", [86400 * 7 * 2])
    await network.provider.send("evm_mine")
    await minter.update_period();
    await contentfarm_factory.updateGauge(contentfarm.address);
    const claimable = await contentfarm_factory.claimable(contentfarm.address);
    await ve_underlying.approve(staking.address, claimable);
    await staking.notifyRewardAmount(claimable);
    await contentfarm_factory.updateFor([contentfarm.address]);
    await contentfarm_factory.distro();
    await contentfarm_factory.claimRewards([contentfarm.address], [[ve_underlying.address]]);
    const after = await ve_underlying.balanceOf(contentfarm.address)
    expect(after).to.be.above(before);
    // expect(await contentfarm.rewardRate(ve_underlying.address)).to.be.equal(await staking.rewardRate());
    // console.log(await contentfarm.rewardPerTokenStored(ve_underlying.address))
  });

});
