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
  let stakeMarket;
  let stakeMarketVoter;
  let stakeMarketBribe;
  let owner;
  let owner2;
  let owner3;
  let vavaHelper;
  let vaFactory;
  let valuepoolVoter;
  let Vava;
  let Va;
  let trustBounties;
  let ssi;
  let profile;

  it("deploy initial contracts", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();

    ve_underlying = await token.deploy('FreeToken', 'FT', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("2000000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
    
    const TrustBounties = await ethers.getContractFactory("TrustBounties");
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    
    let percentile = await Percentile.deploy()
    const StakeMarketVoter = await ethers.getContractFactory("StakeMarketVoter", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    Va =  await ethers.getContractFactory("Va", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    const VavaHelper =  await ethers.getContractFactory("VavaHelper")
    const StakeMarketBribe =  await ethers.getContractFactory("Bribe")
    const VaFactory =  await ethers.getContractFactory("vaFactory", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    const BusinessMinter =  await ethers.getContractFactory("BusinessMinter")
    const SSI = await ethers.getContractFactory("SSI");
    const Profile = await ethers.getContractFactory("Profile",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    vecontract = await ethers.getContractFactory("contracts/ve.sol:mve",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    ve = await vecontract.deploy(ve_underlying.address);
    
    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    ve_dist = await ve_distContract.deploy(ve.address);

    nfticketHelperContract = await ethers.getContractFactory("NFTicketHelper");
    nfticketHelper = await nfticketHelperContract.deploy(
      ust.address,
      "0x0000000000000000000000000000000000000000"
    );

    nfticketContract = await ethers.getContractFactory("NFTicket");
    nfticket = await nfticketContract.deploy(ust.address, nfticketHelper.address);

    businessMinter = await BusinessMinter.deploy(
      nfticket.address,
      "0x0000000000000000000000000000000000000000"
    );
    await businessMinter.deployed();
    
    stakeMarketBribe = await StakeMarketBribe.deploy()
    await stakeMarketBribe.deployed();

    ssi = await SSI.deploy();
    await ssi.deployed();

    profile = await Profile.deploy(
      owner.address,
      "0x0000000000000000000000000000000000000000", 
      ssi.address 
    );
    await profile.deployed();

    stakeMarketVoter = await StakeMarketVoter.deploy(
      stakeMarketBribe.address,
      profile.address,
      ssi.address
    );
    await stakeMarketVoter.deployed();

    vaFactory = await VaFactory.deploy()
    await vaFactory.deployed();

    vavaHelper = await VavaHelper.deploy(
      "0x0000000000000000000000000000000000000000"
    )
    await vavaHelper.deployed();

    trustBounties = await TrustBounties.deploy(
      stakeMarketVoter.address,
      businessMinter.address
    );
    await trustBounties.deployed();

    await stakeMarketBribe.setVoter(stakeMarketVoter.address);
    await stakeMarketVoter.setMarket(trustBounties.address, true);
    await ve.setVoter(stakeMarketVoter.address);
    await trustBounties.updateVes(ve.address, true);
    await trustBounties.updateWhitelistedTokens([ust.address], true);
    await vaFactory.setContracts(
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      owner.address,
      vavaHelper.address
    );
    await ssi.setProfile(profile.address);
    
    // const WBNB = await ethers.getContractFactory("WBNB");
    // wrappedBNB = WBNB.deploy()
    // await wrappedBNB.deployed()
    // wrappedBNB = await WBNB.new({ from: owner });
    // console.log("wrappedBNB===============>", await ethers.provider.getBalance(owner.address))

    expect(stakeMarketBribe.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(stakeMarketVoter.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(ve.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(vaFactory.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(trustBounties.address).to.not.equal("0x0000000000000000000000000000000000000000");
  });
  
  it("create bounty", async function () {
    // create profile
    await profile.createProfile("Tepa", 0)
    console.log("profile==============>", await profile.profileInfo(1))
    // mint ssid
    await ssi.generateIdentityProof(owner.address,1,1,86700 * 7,"ssid","tepa")
    await ssi.updateSSID(1,1)
    await profile.updateSSID(1)

    await trustBounties.createBounty(
      owner.address,
      ust.address,
      ve.address,
      "0x0000000000000000000000000000000000000000",
      0,
      10,
      86700 * 7,
      0,
      false,
      "http://link-to-avatar.com",
      "trustbounty"
    )
    console.log("trustBounties===========>", trustBounties.address)
    console.log("bountyInfo===========>", await trustBounties.bountyInfo(1))
    expect((await trustBounties.bountyInfo(1)).owner).to.equal(owner.address);

  });

  it("add balance", async function () {
    await ust.connect(owner).approve(trustBounties.address, 100)
    await trustBounties.addBalance(
      1, 
      trustBounties.address,
      0, 
      100
    )
    
    console.log("balance===========>", await trustBounties.getBalance(1))
    expect(await trustBounties.getBalance(1)).to.equal(99);
    
  });

  it("create friendly claim", async function () {
    await trustBounties.createFriendlyClaim(
      owner2.address,
      1,
      20
    )
    console.log("claims===========>", await trustBounties.claims(1,0))
    expect((await trustBounties.claims(1,0)).hunter).to.equal(owner2.address);

    // concede
    await trustBounties.concede(1);
  });

  it("apply results", async function () {
    expect((await ust.balanceOf(owner2.address))).to.equal(ethers.BigNumber.from("1000000000000000000"));
    await trustBounties.applyClaimResults(1, 1, 0, "", "") 
    
    console.log("claims===========>", await trustBounties.claims(1,0))
    expect((await trustBounties.claims(1,0)).status).to.equal(0);
    expect((await ust.balanceOf(owner2.address))).to.equal(ethers.BigNumber.from("1000000000000000020"));
  });

  it("create lock", async function () {
    let ve_underlying_amount = ethers.BigNumber.from("1000000000000000000000");
    await ve_underlying.approve(ve.address, ve_underlying_amount);
    const lockDuration = 7 * 24 * 3600; // 1 week

    // Balance should be zero before and 1 after creating the lock
    expect(await ve.balanceOf(owner.address)).to.equal(0);
    await ve.create_lock(ve_underlying_amount, lockDuration);
    expect(await ve.ownerOf(1)).to.equal(owner.address);
    expect(await ve.balanceOf(owner.address)).to.equal(1);
  });

  it("create claim", async function () {
    await ust.connect(owner3).approve(trustBounties.address, 10)
    await trustBounties.createClaim(
      owner3.address,
      1,
      20,
      false,
      "Lier", 
      "Lier lier pants on fire"
    )
    
    console.log("claims===========>", await trustBounties.claims(1,1))
    expect((await trustBounties.claims(1,1)).hunter).to.equal(owner3.address);
    
    console.log("litigations===========>", await stakeMarketVoter.litigations(1))
    console.log("isGauge1===========>", await stakeMarketVoter.isGauge(ve.address, 1))
    console.log("gauges===========>", await stakeMarketVoter.gauges(ve.address, 2))
    // vote
    await stakeMarketVoter.vote(1, ve.address, 1, 1, 2, 1);
    console.log("weights1===========>", await stakeMarketVoter.weights(ve.address, 1))
    console.log("weights2===========>", await stakeMarketVoter.weights(ve.address, 2))
    // increase time by 1 week
    await network.provider.send("evm_increaseTime", [604800])
    await network.provider.send("evm_mine")
    // update 
    await stakeMarketVoter.updateStakeFromVoter(ve.address, 1);
    console.log("isGauge1===========>", await stakeMarketVoter.isGauge(ve.address, 1))
    console.log("claims after===========>", await trustBounties.claims(1,1))

  });
  
  it("appeal", async function () {
    await ust.connect(owner3).approve(trustBounties.address, 10)
    await trustBounties.applyClaimResults(1, 2, 10, "Unfair vote", "Attacker is lying") 
    console.log("claims before appeal vote===========>", await trustBounties.claims(1,2))
    expect((await trustBounties.claims(1,2)).hunter).to.equal(owner3.address);

    console.log("litigations===========>", await stakeMarketVoter.litigations(2))
    console.log("isGauge1===========>", await stakeMarketVoter.isGauge(ve.address, 1))
    console.log("isGauge3===========>", await stakeMarketVoter.isGauge(ve.address, 3))
    console.log("gauges===========>", await stakeMarketVoter.gauges(ve.address, 3))
    // vote
    await stakeMarketVoter.vote(2, ve.address, 1, 1, 3, -1);
    await stakeMarketVoter.updateStakeFromVoter(ve.address, 2);
    console.log("weights1===========>", await stakeMarketVoter.weights(ve.address, 1))
    console.log("weights3===========>", await stakeMarketVoter.weights(ve.address, 3))
    console.log("isGauge1===========>", await stakeMarketVoter.isGauge(ve.address, 1))
    console.log("isGauge3===========>", await stakeMarketVoter.isGauge(ve.address, 3))
    console.log("claims after appeal vote===========>", await trustBounties.claims(1,2))
  });

  it("apply results 2", async function () {
    expect((await ust.balanceOf(owner3.address))).to.equal(ethers.BigNumber.from("999999999999999980"));
    // increase time by 2 week
    await network.provider.send("evm_increaseTime", [604800 * 2])
    await network.provider.send("evm_mine")

    await trustBounties.applyClaimResults(1, 3, 0, "", "") 
    console.log("claims===========>", await trustBounties.claims(1,2))
    expect((await trustBounties.claims(1,2)).status).to.equal(0);
    // No funds transferred when attacker looses vote
    expect((await ust.balanceOf(owner3.address))).to.equal(ethers.BigNumber.from("999999999999999980"));
  });

  it("delete balance", async function () {})

  it("create bounty with ETH", async function () {
    await trustBounties.createBounty(
      owner.address,
      "0x0000000000000000000000000000000000000000",
      ve.address,
      "0x0000000000000000000000000000000000000000",
      0,
      107,
      86700 * 7,
      0,
      false,
      "http://link-to-avatar.com",
      "trustbounty"
    )
    
    console.log("trustBounties===========>", trustBounties.address)
    console.log("bountyInfo===========>", await trustBounties.bountyInfo(2))
    expect((await trustBounties.bountyInfo(2)).owner).to.equal(owner.address);
    
  });


});
