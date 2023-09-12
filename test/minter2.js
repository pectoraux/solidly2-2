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

describe("minter", function () {

  let token;
  let ve_underlying;
  let ve;
  let owner;
  let minter;
  let ve_dist;
  let bs_factory;
  let acc_factory;
  let refer_factory;
  let contr_factory;
  let pair;

  it("deploy base", async function () {
    [owner] = await ethers.getSigners(1);
    token = await ethers.getContractFactory("Token");
    basev1 = await ethers.getContractFactory("BaseV1");
    mim = await token.deploy('MIM', 'MIM', 18, owner.address);
    await mim.mint(owner.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    ve_underlying = await basev1.deploy();
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("10000000000000000000000000"));
    const BaseV1Factory = await ethers.getContractFactory("BaseV1Factory");
    factory = await BaseV1Factory.deploy();
    await factory.deployed();
    const BaseV1Router = await ethers.getContractFactory("BaseV1Router01");
    router = await BaseV1Router.deploy(factory.address, owner.address);
    await router.deployed();
    const BaseV1GaugeFactory = await ethers.getContractFactory("ContentFarmFactory");
    gauges_factory = await BaseV1GaugeFactory.deploy();
    await gauges_factory.deployed();
    const BaseV1BribeFactory = await ethers.getContractFactory("BaseV1BribeFactory");
    const bribe_factory = await BaseV1BribeFactory.deploy();
    await bribe_factory.deployed();
    const BaseV1Voter = await ethers.getContractFactory("ContentFarmVoter");
    bs_factory = await BaseV1Voter.deploy(ve.address, gauges_factory.address, bribe_factory.address);
    await bs_factory.deployed();
    acc_factory = await BaseV1Voter.deploy(ve.address, gauges_factory.address, bribe_factory.address);
    await acc_factory.deployed();
    contr_factory = await BaseV1Voter.deploy(ve.address, gauges_factory.address, bribe_factory.address);
    await contr_factory.deployed();
    refer_factory = await BaseV1Voter.deploy(ve.address, gauges_factory.address, bribe_factory.address);
    await refer_factory.deployed();

    await ve_underlying.approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    const VeDist = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    ve_dist = await VeDist.deploy(ve.address);
    await ve_dist.deployed();
    await ve.setVoter(bs_factory.address);
    await ve.setVoter(acc_factory.address);
    await ve.setVoter(contr_factory.address);
    await ve.setVoter(refer_factory.address);
    
    const BaseV1Minter = await ethers.getContractFactory("BaseV1Minter2");
    minter = await BaseV1Minter.deploy(
      bs_factory.address, 
      acc_factory.address, 
      contr_factory.address, 
      refer_factory.address, 
      ve.address, 
      ve_dist.address
    );
    await minter.deployed();
    await ve_dist.setDepositor(minter.address);
    await ve_underlying.setMinter(minter.address);

    const mim_1 = ethers.BigNumber.from("1000000000000000000");
    const ve_underlying_1 = ethers.BigNumber.from("1000000000000000000");
    await ve_underlying.approve(router.address, ve_underlying_1);
    await mim.approve(router.address, mim_1);
    await router.addLiquidity(mim.address, ve_underlying.address, false, mim_1, ve_underlying_1, 0, 0, owner.address, Date.now());

    pair = await router.pairFor(mim.address, ve_underlying.address, false);

    await ve_underlying.approve(bs_factory.address, ethers.BigNumber.from("500000000000000000000000"));
    await bs_factory.createGauge(1, 'test', 'test', 'test', 'test');
    await ve_underlying.approve(acc_factory.address, ethers.BigNumber.from("500000000000000000000000"));
    await acc_factory.createGauge(1, 'test', 'test', 'test', 'test');
    await ve_underlying.approve(contr_factory.address, ethers.BigNumber.from("500000000000000000000000"));
    await contr_factory.createGauge(1, 'test', 'test', 'test', 'test');
    await ve_underlying.approve(refer_factory.address, ethers.BigNumber.from("500000000000000000000000"));
    await refer_factory.createGauge(1, 'test', 'test', 'test', 'test');
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("1000000000000000000"));

  });

  it("initialize veNFT", async function () {
    expect(await ve.ownerOf(2)).to.equal("0x0000000000000000000000000000000000000000");
    await network.provider.send("evm_mine")
    expect(await ve_underlying.balanceOf(minter.address)).to.equal(ethers.BigNumber.from("0"));
  });

  it("minter weekly distribute", async function () {
    // use custom percentages
    await minter.updateTeamPercent(true, 100, 2000, 2000, 2000, 4000);
    await minter.update_period();
    expect(await minter.weekly()).to.equal(ethers.BigNumber.from("20000000000000000000000000"));
    await network.provider.send("evm_increaseTime", [86400 * 7])
    await network.provider.send("evm_mine")
    await minter.update_period();
    expect(await ve_underlying.balanceOf(minter.address)).to.equal(0);
    expect(await ve_dist.claimable(1)).to.equal(0);
    expect(await minter.weekly()).to.equal(ethers.BigNumber.from("20000000000000000000000000"));
    await network.provider.send("evm_increaseTime", [86400 * 7])
    await network.provider.send("evm_mine")
    await minter.update_period();
    const claimable = await ve_dist.claimable(1);
    console.log("claimable", claimable);
    console.log("ve_underlying.balanceOf", await ve_underlying.balanceOf(minter.address));
    console.log("weeklyBusinessEmission", await minter.weeklyBusinessEmission());
    console.log("weeklyContributorEmission", await minter.weeklyContributorEmission());
    console.log("weeklyReferralEmission", await minter.weeklyReferralEmission());
    console.log("weeklyAcceleratorEmission", await minter.weeklyAcceleratorEmission());
    // expect(await ve_underlying.balanceOf(minter.address)).to.be.above(ethers.BigNumber.from("19000000000000000000000000"));
    // expect(claimable).to.be.above(ethers.BigNumber.from("690068653351059655"));
    const before = await ve.balanceOfNFT(1);
    await ve_dist.claim(1);
    const after = await ve.balanceOfNFT(1);
    expect(await ve_dist.claimable(1)).to.equal(0);

    const weekly = await minter.weekly();
    console.log("weekly", weekly);
    console.log("minter.calculate_growth", await minter.calculate_growth(weekly));
    console.log("ve_underlying.totalSupply", await ve_underlying.totalSupply());
    console.log("ve.totalSupply", await ve.totalSupply());

    const weekly_less_1_percent = ethers.BigNumber.from(weekly.sub(weekly.div(100)));
    //percentages should be as inputed above
    expect(await minter.referralsPercent()).to.be.closeTo(ethers.BigNumber.from(2000), 1);
    expect(await minter.contributorsPercent()).to.be.closeTo(ethers.BigNumber.from(4000), 1);
    expect(await minter.acceleratorPercent()).to.be.closeTo(ethers.BigNumber.from(2000), 1);
    expect(await minter.businessesPercent()).to.be.closeTo(ethers.BigNumber.from(2000), 1);
    console.log("weekly_less_1_percent", weekly_less_1_percent);
    // expect(voters_emission).to.be.closeTo(weekly_less_1_percent, 10);

    // switch to percentages based on votes
    await minter.updateTeamPercent(false, 0,0,0,0,0);
    await bs_factory.vote(1, [1], [5000]);
    await acc_factory.vote(1, [1], [5000]);
    await contr_factory.vote(1, [1], [5000]);
    // await refer_factory.vote(1, [1], [0]);

    await network.provider.send("evm_increaseTime", [86400 * 7])
    await network.provider.send("evm_mine")
    await minter.update_period();
    const bs1 = await ve_underlying.balanceOf(bs_factory.address);
    const acc1 = await ve_underlying.balanceOf(acc_factory.address);
    const refer1 = await ve_underlying.balanceOf(refer_factory.address);
    const contr1 = await ve_underlying.balanceOf(contr_factory.address);
    const voters_emission = ethers.BigNumber.from(bs1.add(acc1).add(refer1).add(contr1));
    console.log("voters_emission", voters_emission);
    console.log("claimable", await ve_dist.claimable(1));
    console.log("weekly", await minter.weekly_emission());
    console.log("ve_underlying.balanceOf", await ve_underlying.balanceOf(minter.address));
    console.log("weeklyBusinessEmission", await minter.weeklyBusinessEmission());
    console.log("weeklyContributorEmission", await minter.weeklyContributorEmission());
    console.log("weeklyReferralEmission", await minter.weeklyReferralEmission());
    console.log("weeklyAcceleratorEmission", await minter.weeklyAcceleratorEmission());
    console.log(await ve_dist.claimable(1));
    await ve_dist.claim(1);
    // // percentages should be 33.33 or close
    console.log("contributorsPercent", await minter.contributorsPercent());
    console.log("acceleratorPercent", await minter.acceleratorPercent());
    console.log("businessesPercent", await minter.businessesPercent());
    console.log("referralsPercent", await minter.referralsPercent());
    
    await network.provider.send("evm_increaseTime", [86400 * 7])
    await network.provider.send("evm_mine")
    await minter.update_period();
    console.log("claimable", await ve_dist.claimable(1));
    console.log("weekly", await minter.weekly_emission());
    console.log("ve_underlying.balanceOf", await ve_underlying.balanceOf(minter.address));
    console.log("weeklyBusinessEmission", await minter.weeklyBusinessEmission());
    console.log("weeklyContributorEmission", await minter.weeklyContributorEmission());
    console.log("weeklyReferralEmission", await minter.weeklyReferralEmission());
    console.log("weeklyAcceleratorEmission", await minter.weeklyAcceleratorEmission());
    console.log(await ve_dist.claimable(1));
    await ve_dist.claim_many([1]);
    await network.provider.send("evm_increaseTime", [86400 * 7])
    await network.provider.send("evm_mine")
    await minter.update_period();
    console.log("claimable", await ve_dist.claimable(1));
    console.log("weekly", await minter.weekly_emission());
    console.log("ve_underlying.balanceOf", await ve_underlying.balanceOf(minter.address));
    console.log("weeklyBusinessEmission", await minter.weeklyBusinessEmission());
    console.log("weeklyContributorEmission", await minter.weeklyContributorEmission());
    console.log("weeklyReferralEmission", await minter.weeklyReferralEmission());
    console.log("weeklyAcceleratorEmission", await minter.weeklyAcceleratorEmission());
    console.log(await ve_dist.claimable(1));
    await ve_dist.claim(1);
    await network.provider.send("evm_increaseTime", [86400 * 7])
    await network.provider.send("evm_mine")
    await minter.update_period();
    console.log("claimable", await ve_dist.claimable(1));
    console.log("weekly", await minter.weekly_emission());
    console.log("ve_underlying.balanceOf", await ve_underlying.balanceOf(minter.address));
    console.log("weeklyBusinessEmission", await minter.weeklyBusinessEmission());
    console.log("weeklyContributorEmission", await minter.weeklyContributorEmission());
    console.log("weeklyReferralEmission", await minter.weeklyReferralEmission());
    console.log("weeklyAcceleratorEmission", await minter.weeklyAcceleratorEmission());
    console.log(await ve_dist.claimable(1));
    await ve_dist.claim_many([1]);
    await network.provider.send("evm_increaseTime", [86400 * 7])
    await network.provider.send("evm_mine")
    await minter.update_period();
    console.log("claimable", await ve_dist.claimable(1));
    console.log("weekly", await minter.weekly_emission());
    console.log("ve_underlying.balanceOf", await ve_underlying.balanceOf(minter.address));
    console.log("weeklyBusinessEmission", await minter.weeklyBusinessEmission());
    console.log("weeklyContributorEmission", await minter.weeklyContributorEmission());
    console.log("weeklyReferralEmission", await minter.weeklyReferralEmission());
    console.log("weeklyAcceleratorEmission", await minter.weeklyAcceleratorEmission());
    console.log(await ve_dist.claimable(1));
    await ve_dist.claim(1);
  });

});
