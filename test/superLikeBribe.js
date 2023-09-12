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

  it("deploy base contracts", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    
    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("10000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("10000000000000000000000000"));
    
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);

    await ust.deployed();

    const SuperLikeGaugeFactory = await ethers.getContractFactory("SuperLikeGaugeFactory");
    superLikeGaugeFactory = await SuperLikeGaugeFactory.deploy();
    await superLikeGaugeFactory.deployed()

    const SuperLikeBribeFactory = await ethers.getContractFactory("SuperLikeBribeFactory");
    superLikeBribeFactory = await SuperLikeBribeFactory.deploy();
    await superLikeBribeFactory.deployed()

    const SuperLikeVoter = await ethers.getContractFactory("SuperLikeVoter");
    superLikeVoter = await SuperLikeVoter.deploy(
      ve.address, 
      superLikeGaugeFactory.address
    );
    await superLikeVoter.deployed();

    await superLikeBribeFactory.createBribe(
        superLikeVoter.address, 
        ve.address,
        ve_underlying.address,
        1,
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000"
    );
    SuperLikeBribe = await ethers.getContractFactory("SuperLikeBribe")
    superLikeBribe = SuperLikeBribe.attach(await superLikeBribeFactory.last_gauge())

  });

  it("create lock", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("500000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("500000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("495063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("500000000000000000"));
  });

  it("add new gauges", async function () {
    await superLikeVoter.createGauge(
      owner.address,
      1,
      0
    );
    gauge = await superLikeVoter.gauges(owner.address);
    
    expect(await superLikeBribe.isGauge(gauge)).to.equal(false)
    await superLikeBribe.addGauge(gauge);
    expect(await superLikeBribe.isGauge(gauge)).to.equal(true)
  });

  it("deposit votes", async function () {
    expect(await superLikeVoter.weights(owner.address)).to.equal(0)
    await superLikeVoter.vote(1, [owner.address], [5000])
    expect(await superLikeVoter.weights(owner.address)).to.not.equal(0)

    expect(await superLikeBribe.balanceOf(1)).to.equal(0)
    expect(await superLikeBribe.balanceOf(1)).to.equal(await superLikeBribe.totalSupply())
    await superLikeBribe.deposit(1)
    expect(await superLikeBribe.balanceOf(1)).to.not.equal(0)
    expect(await superLikeBribe.balanceOf(1)).to.equal(await superLikeBribe.totalSupply())

  });

  it("mint gauges nfts", async function () {
    await ve_underlying.connect(owner2).approve(
      superLikeBribe.address, 
      await superLikeBribe.balanceOf(1)
    )

    const BallerNFT = await ethers.getContractFactory("BallerNFT");
    gaugeNFT = BallerNFT.attach(await superLikeBribe.nfts(1));
    
    expect(await gaugeNFT.balanceOf(owner2.address, 1)).to.equal(0)
    await superLikeBribe.connect(owner2).mintGaugeNFT(1, 0)
    expect(await gaugeNFT.balanceOf(owner2.address, 1)).to.equal(1)

  });

  it("should note be able to mint past max q when restrictedMint is true", async function () {
    console.log(await superLikeBribe.getMaxQForMint())
    await ve_underlying.connect(owner3).approve(
      superLikeBribe.address, 
      await superLikeBribe.balanceOf(1)
    )
    await superLikeBribe.updateRestrictedMint(true)
    await superLikeBribe.connect(owner3).mintGaugeNFT(1, 0)
    expect(await gaugeNFT.balanceOf(owner3.address, 2)).to.equal(1)
    
  });

  it("claim reward", async function () {
    console.log(await superLikeBribe.pendingRevenueDev())
    console.log(await superLikeBribe.paidNFTHolders(owner2.address))
    expect(await superLikeBribe.paidNFTHolders(owner2.address)).to.equal(0)
    await superLikeBribe.claimPendingRevenue(0)
    await superLikeBribe.connect(owner2).claimPendingRevenue(1)
    console.log(await superLikeBribe.pendingRevenueDev())
    expect(await superLikeBribe.paidNFTHolders(owner2.address)).to.not.equal(0)
    console.log(await superLikeBribe.paidNFTHolders(owner2.address))
  });

  it("reimburse", async function () {
    console.log(await superLikeBribe.getAllPaidFromSponsor())
  });

  it("remove gauge", async function () {
    expect(await superLikeBribe.balanceOf(1)).to.not.equal(0)
    expect(await superLikeBribe.totalSupply()).to.not.equal(0)
    await superLikeBribe.removeGauge(gauge, 1)
    expect(await superLikeBribe.balanceOf(1)).to.equal(0)
    expect(await superLikeBribe.totalSupply()).to.equal(0)
  });
  
});
