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
  let tokenMinter;
  let rsrcnft;
  let nfticket;
  let nfticketHelper;
  let marketPlaceCollection;
  let marketPlaceOrders;
  let marketPlaceTrades;
  let marketPlaceHelper;
  let marketPlaceHelper2;
  let stakeMarket;
  let stakeMarketVoter;
  let stakeMarketBribe;
  let owner;
  let owner2;
  let owner3;
  let vavaHelper;
  let vaFactory;
  let vavaFactory;
  let valuepoolVoter;
  let Vava;
  let Va;
  let vava;
  let va;
  let sponsorNote;
  let sponsor;
  let sponsorFactory;
  let profile;
  let ssi;
  let auditorNote;
  let trustBounties;
  let businessGaugeFactory;
  let businessBribeFactory;
  let acceleratorVoter;
  let businessMinter;
  let gauge;
  let businessBribe;
  let BusinessBribe;
  let BusinessGauge;
  let businessGauge;
  let contentTypes;
  let rampFactory;
  let rampHelper;
  let ramp;
  let tFiat;
  let mockAggregatorV3;

  it("1) deploy contracts", async function () {
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
    
    nfticketHelperContract = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper");
    nfticketHelper = await nfticketHelperContract.deploy();

    nfticketContract = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicket");
    nfticket = await nfticketContract.deploy();

    const MarketPlaceEvents = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceEvents");
    const MarketPlaceCollection = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceCollection");
    const MarketPlaceOrders = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceOrders");
    const MarketPlaceTrades = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceTrades");
    const MarketPlaceHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper");
    const StakeMarket = await ethers.getContractFactory("StakeMarket");
    const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
    const SSI = await ethers.getContractFactory("SSI");
    // const SponsorFactory = await ethers.getContractFactory("SponsorFactory");
    const TrustBounties = await ethers.getContractFactory("TrustBounties");
    const AuditorHelper = await ethers.getContractFactory("AuditorHelper");
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    
    vecontract = await ethers.getContractFactory("contracts/ve.sol:mve",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    ve = await vecontract.deploy(ve_underlying.address);

    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    ve_dist = await ve_distContract.deploy(ve.address);

    const MarketPlaceHelper2 = await ethers.getContractFactory("MarketPlaceHelper2",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    // const SponsorNote = await ethers.getContractFactory("SponsorNote",{
    //   libraries: {
    //     Percentile: percentile.address,
    //   },
    // });
    const Profile = await ethers.getContractFactory("Profile",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    const AuditorNote = await ethers.getContractFactory("AuditorNote",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    const StakeMarketVoter = await ethers.getContractFactory("StakeMarketVoter", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    Vava =  await ethers.getContractFactory("Vava", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    Va =  await ethers.getContractFactory("Va", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    const StakeMarketBribe =  await ethers.getContractFactory("Bribe")
    const VavaHelper =  await ethers.getContractFactory("VavaHelper")
    const VaFactory =  await ethers.getContractFactory("vaFactory", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    const VavaFactory =  await ethers.getContractFactory("VavaFactory", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    const ValuepoolVoter =  await ethers.getContractFactory("ValuepoolVoter")

    const AcceleratorVoter =  await ethers.getContractFactory("AcceleratorVoter")
    BusinessBribe =  await ethers.getContractFactory("ReferralBribe")
    BusinessGauge =  await ethers.getContractFactory("BusinessGauge")
    const BusinessBribeFactory =  await ethers.getContractFactory("ReferralBribeFactory")
    const BusinessGaugeFactory =  await ethers.getContractFactory("BusinessGaugeFactory")
    const BusinessMinter =  await ethers.getContractFactory("BusinessMinter")
    const ContentTypes = await ethers.getContractFactory("ContentTypes");
    const RampFactory = await ethers.getContractFactory("RampFactory");
    const RampHelper = await ethers.getContractFactory("RampHelper",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    const fiatContract = await ethers.getContractFactory("tFIAT");
    const MockAggregatorV3 = await ethers.getContractFactory("MockAggregatorV3");
    const INITIAL_PRICE = 10000000000; // $100, 8 decimal places

    mockAggregatorV3 = await MockAggregatorV3.deploy(18, 1)

    ssi = await SSI.deploy();
    await ssi.deployed();

    profile = await Profile.deploy(
      owner.address,
      "0x0000000000000000000000000000000000000000", 
      ssi.address 
    );
    await profile.deployed();

    businessMinter = await BusinessMinter.deploy(
      nfticket.address,
      "0x0000000000000000000000000000000000000000"
    );
    await businessMinter.deployed();

    contentTypes = await ContentTypes.deploy();
    await contentTypes.deployed();

    marketPlaceEvents = await MarketPlaceEvents.deploy();
    await marketPlaceEvents.deployed();
    
    marketPlaceCollection = await MarketPlaceCollection.deploy(
      nfticket.address, 
      owner.address, 
      "0x0000000000000000000000000000000000000000", 
      marketPlaceEvents.address, 
      ssi.address 
    );
    await marketPlaceCollection.deployed();

    stakeMarketBribe = await StakeMarketBribe.deploy()
    await stakeMarketBribe.deployed();

    stakeMarketVoter = await StakeMarketVoter.deploy(
      stakeMarketBribe.address,
      profile.address,
      ssi.address
    );
    await stakeMarketVoter.deployed();

    trustBounties = await TrustBounties.deploy(
      stakeMarketVoter.address,
      businessMinter.address
    );
    await trustBounties.deployed();
    
    auditorNote = await AuditorNote.deploy(
      businessMinter.address,
      profile.address,
      trustBounties.address, 
      ssi.address
    );
    await auditorNote.deployed();

    rampHelper = await RampHelper.deploy(
      ssi.address,
      profile.address,
      trustBounties.address,
      auditorNote.address,
      ust.address,
      marketPlaceCollection.address
    )
    await rampHelper.deployed()

    tFiat = await fiatContract.deploy(
      "tFIAT",
      "tFIAT",
      profile.address,
      trustBounties.address
    );
    
    rampFactory = await RampFactory.deploy(
      profile.address,
      rampHelper.address,
      ssi.address
    )
    await rampFactory.deployed()

    marketPlaceOrders = await MarketPlaceOrders.deploy(
      marketPlaceCollection.address, 
      marketPlaceEvents.address, 
      trustBounties.address, 
      "0x0000000000000000000000000000000000000000"
    );
    await marketPlaceOrders.deployed();
    
    marketPlaceHelper = await MarketPlaceHelper.deploy(
      marketPlaceCollection.address, 
      marketPlaceEvents.address, 
      marketPlaceOrders.address,
      profile.address 
    );
    await marketPlaceHelper.deployed();

    businessBribeFactory = await BusinessBribeFactory.deploy();
    await businessBribeFactory.deployed();
      
    businessGaugeFactory = await BusinessGaugeFactory.deploy(
      trustBounties.address,
      marketPlaceCollection.address
    );
    await businessGaugeFactory.deployed();
    
    acceleratorVoter = await AcceleratorVoter.deploy(
      businessGaugeFactory.address, 
      businessBribeFactory.address,
      businessMinter.address,
      profile.address,
      marketPlaceCollection.address
    );
    await acceleratorVoter.deployed();

    auditorHelper = await AuditorHelper.deploy(
      ust.address,
      auditorNote.address,
      contentTypes.address,
      marketPlaceCollection.address
    );
    await auditorHelper.deployed();

    marketPlaceHelper2 = await MarketPlaceHelper2.deploy(
      profile.address,
      auditorHelper.address,
      auditorNote.address,
      marketPlaceOrders.address, 
      marketPlaceHelper.address,
      marketPlaceEvents.address,
      marketPlaceCollection.address
    );
    await marketPlaceHelper2.deployed();

    marketPlaceTrades = await MarketPlaceTrades.deploy(
      marketPlaceCollection.address, 
      marketPlaceEvents.address, 
      marketPlaceOrders.address, 
      marketPlaceHelper.address,
      marketPlaceHelper2.address,
      trustBounties.address
    );
    await marketPlaceTrades.deployed();
    
    stakeMarketNote = await StakeMarketNote.deploy(
      auditorNote.address,
      ssi.address
    );
    await stakeMarketNote.deployed();

    stakeMarket = await StakeMarket.deploy(
      trustBounties.address,
      profile.address,
      businessMinter.address,
      marketPlaceTrades.address,
      stakeMarketNote.address
    );
    await stakeMarket.deployed();

    vavaHelper = await VavaHelper.deploy(
      "0x0000000000000000000000000000000000000000"
    )
    await vavaHelper.deployed();

    vaFactory = await VaFactory.deploy()
    await vaFactory.deployed();

    vavaFactory = await VavaFactory.deploy(
      vavaHelper.address,
      vaFactory.address,
      marketPlaceCollection.address, 
      ssi.address
    )
    await vavaFactory.deployed();

    valuepoolVoter = await ValuepoolVoter.deploy(
      "0x0000000000000000000000000000000000000000",
      profile.address,
      ssi.address
    )
    await valuepoolVoter.deployed();

    // sponsorNote = await SponsorNote.deploy(
    //   businessMinter.address,
    //   profile.address,
    //   trustBounties.address,
    //   auditorHelper.address,
    //   ssi.address
    // );
    // await sponsorNote.deployed();

    // sponsorFactory = await SponsorFactory.deploy(
    //   sponsorNote.address,
    //   contentTypes.address,
    //   ssi.address
    // );
    // await sponsorFactory.deployed();
    
    // set ups
    await tFiat.updateMinter(owner.address)
    await tFiat.mint(owner.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await tFiat.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await tFiat.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
    
    await trustBounties.updateAuthorizedSourceFactories([rampHelper.address], true)
    await rampHelper.setFactory(rampFactory.address)
    await businessMinter.updateVes(
      [ve.address],
      [ve_dist.address],
      true
    );
    await businessMinter.updateContracts(
      ve.address,
      acceleratorVoter.address,
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000"
    );
    await ve_dist.setDepositor(businessMinter.address)
    await businessGaugeFactory.updateVoter([acceleratorVoter.address], true)
    await businessMinter.initialize()

    await ssi.setProfile(profile.address);
    await stakeMarketBribe.setVoter(stakeMarketVoter.address);
    await stakeMarket.setVoter(stakeMarketVoter.address);
    await stakeMarketVoter.setMarket(trustBounties.address, true);
    await stakeMarketVoter.setMarket(stakeMarket.address, true);
    await stakeMarketNote.setStakeMarket(stakeMarket.address);
    await trustBounties.updateVes(ve.address, true);
    await trustBounties.updateWhitelistedTokens([tFiat.address], true);
    await ve.setVoter(acceleratorVoter.address);
    await vavaHelper.setFactory(
      nfticket.address,
      valuepoolVoter.address,
      vavaFactory.address,
      marketPlaceTrades.address
    );
    await vaFactory.setContracts(
      trustBounties.address,
      valuepoolVoter.address,
      owner.address,
      vavaHelper.address
    );
    
    await marketPlaceOrders.setMarkets(
      marketPlaceTrades.address, 
      marketPlaceHelper.address,
      marketPlaceHelper2.address
    );
    await marketPlaceHelper.setMarketTrades(marketPlaceTrades.address);
    await marketPlaceHelper2.setMarketTrades(marketPlaceTrades.address);
    await nfticket.setMarkets(
      marketPlaceCollection.address, 
      marketPlaceOrders.address, 
      marketPlaceTrades.address,
      marketPlaceHelper.address
    );
    await nfticketHelper.setMarkets(
      marketPlaceEvents.address, 
      marketPlaceCollection.address
    );
    await marketPlaceCollection.setMarketOrders(marketPlaceOrders.address)
    await marketPlaceEvents.setContracts(
      nfticketHelper.address,
      marketPlaceCollection.address,
      marketPlaceOrders.address,
      marketPlaceTrades.address,
      marketPlaceHelper.address,
      marketPlaceHelper2.address,
      marketPlaceHelper.address,
      trustBounties.address,
      marketPlaceHelper.address,
      marketPlaceHelper.address,
    );
    
    // checks
    expect(marketPlaceCollection.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(marketPlaceHelper.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(profile.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(trustBounties.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(businessMinter.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(businessGaugeFactory.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(businessBribeFactory.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(mockAggregatorV3.address).to.not.equal("0x0000000000000000000000000000000000000000");
    
  });
  
  it("2) add collection", async function () {
    await marketPlaceCollection.addCollection(100,0,0,10,0,0,ust.address,false,false);
    
    expect((await marketPlaceCollection.addressToCollectionId(owner.address))).to.equal(1);
  });

  it("3) transfer with and without profile", async function () {
    const _limitWithoutProfile = await tFiat.limitWithoutProfile()
    const _limitWithProfile = await tFiat.limitWithProfile()
    console.log("limitWithProfile===========>", _limitWithProfile)
    console.log("limitWithoutProfile===========>", _limitWithoutProfile)
    console.log("getLimit===========>", await tFiat.getLimit(owner.address))
    console.log("token===========>", await tFiat.token())

    await expect(tFiat.transfer(owner2.address, await tFiat.limitWithProfile())).to.be.reverted
    await tFiat.transfer(owner2.address, await tFiat.limitWithoutProfile())
    await expect(tFiat.transfer(owner2.address, 1)).to.be.reverted

    await profile.createProfile("Tepa", 0)
    // mint ssid
    await ssi.generateIdentityProof(owner.address,1,1,86700 * 7,"ssid","tepa")
    await ssi.updateSSID(1,1)
    await profile.updateSSID(1)
    console.log("profile1==============>", (await profile.profileInfo(1)).name)
    
    await tFiat.attachProfile()
    console.log("==========================>", _limitWithProfile - _limitWithoutProfile)
    console.log("==========================>", (await tFiat.balanceOf(owner.address)) > _limitWithProfile - _limitWithoutProfile)
    console.log("vals=====================>", await tFiat.getVals())
    await tFiat.transfer(owner2.address, ethers.BigNumber.from(_limitWithProfile).sub(ethers.BigNumber.from(_limitWithoutProfile)))
    console.log("vals2=====================>", await tFiat.getVals())
    await expect(tFiat.transfer(owner2.address, 1)).to.be.reverted

    // increase time
    await network.provider.send("evm_increaseTime", [86400 * 7 * 4])
    await network.provider.send("evm_mine")

    await tFiat.transfer(owner2.address, _limitWithProfile)
    await expect(tFiat.transfer(owner2.address, 1)).to.be.reverted

    console.log("vals3=====================>", await tFiat.getVals())

  });

  it("4) create bounty & add balance", async function () {
    await trustBounties.createBounty(
      owner.address,
      tFiat.address,
      ve.address,
      tFiat.address,
      0,
      1,
      86700 * 7 * 4,
      0,
      false,
      "http://link-to-avatar.com",
      "ramps"
    )
    console.log("trustBounties===========>", await trustBounties.getBalance(1))
    console.log("bountyInfo===========>", await trustBounties.bountyInfo(1))
    expect((await trustBounties.bountyInfo(1)).owner).to.equal(owner.address);

    await tFiat.approve(trustBounties.address, ethers.BigNumber.from("100000000000000000000000"))
    await tFiat.updateWhitelist(trustBounties.address, false, true)
    await trustBounties.addBalance(
      1, 
      trustBounties.address,
      0, 
      ethers.BigNumber.from("100000000000000000000000")
    )
    console.log("balance===========>", await trustBounties.getBalance(1))
    expect(await trustBounties.getBalance(1)).to.equal(ethers.BigNumber.from("99000000000000000000000"));
  });

  it("5) Transfer with bounty", async function () {
    console.log("tFiat balance=====================>", await tFiat.balanceOf(owner.address))
    console.log("vals4=====================>", await tFiat.getVals())
    await expect(tFiat.transfer(owner2.address, 1)).to.be.reverted
    await tFiat.attachBounty(1)
    await tFiat.transfer(owner2.address, ethers.BigNumber.from("99000000000000000000000").sub((await tFiat.getVals())[1]))
    await expect(tFiat.transfer(owner2.address, 1)).to.be.reverted

  });
});
