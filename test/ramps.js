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
  let trustBountiesVoter;
  let rampFactory;
  let rampHelper;
  let rampHelper2;
  let rampAds;
  let ramp;
  let tFiat;
  let mockAggregatorV3;

  it("1) deploy market place", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("tFIAT");
    
    const ContractAddresses =  await ethers.getContractFactory("contracts/MarketPlace.sol:ContractAddresses")
    const NFTicket = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicket");
    const NFTicketHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper");
    const NFTicketHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper2");
    const MarketPlaceEvents = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceEvents");
    const MarketPlaceCollection = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceCollection");
    const MarketPlaceOrders = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceOrders");
    const MarketPlaceOrders02 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceOrders");
    const MarketPlaceTrades = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceTrades");
    const MarketPlaceHelper = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceHelper");
    const MarketPlaceHelper3 = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceHelper3");
    const MarketPlaceHelper03 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper3");
    const ValuepoolVoter = await ethers.getContractFactory("ValuepoolVoter");
    const BusinessGaugeFactory = await ethers.getContractFactory("BusinessGaugeFactory");
    const BusinessBribeFactory = await ethers.getContractFactory("BusinessBribeFactory");
    const ReferralBribeFactory = await ethers.getContractFactory("ReferralBribeFactory");
    const VavaHelper = await ethers.getContractFactory("ValuepoolHelper");
    const VavaHelper2 = await ethers.getContractFactory("ValuepoolHelper2");
    const RandomNumberGenerator = await ethers.getContractFactory("contracts/Vava.sol:RandomNumberGenerator");
    const Auditor = await ethers.getContractFactory("Auditor");
    const AuditorHelper = await ethers.getContractFactory("AuditorHelper");
    const AuditorHelper2 = await ethers.getContractFactory("AuditorHelper2");
    const AuditorFactory = await ethers.getContractFactory("AuditorFactory");
    const StakeMarket = await ethers.getContractFactory("StakeMarket");
    const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
    const SSI = await ethers.getContractFactory("SSI");
    const SponsorFactory = await ethers.getContractFactory("SponsorFactory");
    const TrustBounties = await ethers.getContractFactory("TrustBounties");
    const TrustBountiesHelper = await ethers.getContractFactory("TrustBountiesHelper");
    const BusinessVoter = await ethers.getContractFactory("BusinessVoter");
    const ReferralVoter = await ethers.getContractFactory("ReferralVoter");
    const Profile = await ethers.getContractFactory("Profile");
    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    const StakeMarketBribe =  await ethers.getContractFactory("Bribe")
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    
  BusinessBribe = await ethers.getContractFactory("BusinessBribe");
  BusinessGauge = await ethers.getContractFactory("BusinessGauge");

  ReferralBribe = await ethers.getContractFactory("ReferralBribe");
  MinterFactory = await ethers.getContractFactory("MinterFactory");

  vecontract = await ethers.getContractFactory("contracts/ve.sol:mve",{
    libraries: {
      Percentile: percentile.address,
    },
  });
  
  const VeFactory = await ethers.getContractFactory("contracts/Vava.sol:veFactory",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const VavaFactory = await ethers.getContractFactory("ValuepoolFactory",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const AuditorNote = await ethers.getContractFactory("AuditorNote",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  Va = await ethers.getContractFactory("contracts/Vava.sol:Ve",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  Vava = await ethers.getContractFactory("contracts/Vava.sol:Valuepool",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const ProfileHelper = await ethers.getContractFactory("ProfileHelper",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const StakeMarketVoter = await ethers.getContractFactory("StakeMarketVoter", {
    libraries: {
      Percentile: percentile.address,
    },
  })

  const TrustBountiesVoter = await ethers.getContractFactory("TrustBountiesVoter", {
    libraries: {
      Percentile: percentile.address,
    },
  })

  const SponsorNote = await ethers.getContractFactory("SponsorNote",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const MarketPlaceHelper2 = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceHelper2",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const MarketPlaceHelper02 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const RampFactory = await ethers.getContractFactory("RampFactory");
  const RampHelper = await ethers.getContractFactory("RampHelper");
  const RampAds = await ethers.getContractFactory("RampAds");
  const RampHelper2 = await ethers.getContractFactory("RampHelper2",{
    libraries: {
      Percentile: percentile.address,
    },
  });
  const MockAggregatorV3 = await ethers.getContractFactory("MockAggregatorV3");
  const INITIAL_PRICE = 10000000000; // $100, 8 decimal places
  mockAggregatorV3 = await MockAggregatorV3.deploy(18, 1)

  profile = await Profile.deploy()
  await profile.deployed()

  profileHelper = await ProfileHelper.deploy()
  await profileHelper.deployed()

  trustBounties = await TrustBounties.deploy()
  await trustBounties.deployed()

  trustBountiesHelper = await TrustBountiesHelper.deploy()
  await trustBountiesHelper.deployed()

  contractAddresses = await ContractAddresses.deploy()
  await contractAddresses.deployed()

  ust = await token.deploy('ust', 'ust', contractAddresses.address, profile.address, trustBounties.address);
  await ust.updateMinter(owner.address)
  await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
  await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
  await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
  await ust.deployed();

  ve_underlying = await token.deploy('FreeToken', 'FT', contractAddresses.address, profile.address, trustBounties.address);
  await ve_underlying.updateMinter(owner.address)
  await ve_underlying.mint(owner.address, ethers.BigNumber.from("2000000000000000000000000000"));
  await ve_underlying.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
  await ve_underlying.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
  await ve_underlying.deployed()

  ve = await vecontract.deploy(ve_underlying.address);
  await ve.deployed()

  ve_dist = await ve_distContract.deploy(ve.address);
  await ve_dist.deployed()

  minterFactory = await MinterFactory.deploy();
  await minterFactory.deployed()

  businessBribeFactory = await BusinessBribeFactory.deploy();
  await businessBribeFactory.deployed()

  businessGaugeFactory = await BusinessGaugeFactory.deploy();
  await businessGaugeFactory.deployed()

  referralBribeFactory = await ReferralBribeFactory.deploy();
  await referralBribeFactory.deployed()

  auditorNote = await AuditorNote.deploy();
  await auditorNote.deployed()

  auditorHelper = await AuditorHelper.deploy();
  await auditorHelper.deployed()

  businessVoter = await BusinessVoter.deploy();
  await businessVoter.deployed()

  referralVoter = await ReferralVoter.deploy();
  await referralVoter.deployed()

  sponsorFactory = await SponsorFactory.deploy();
  await sponsorFactory.deployed()

  sponsorNote = await SponsorNote.deploy();
  await sponsorNote.deployed()

  ssi = await SSI.deploy()
  await ssi.deployed()

  rampHelper = await RampHelper.deploy(ust.address,1)
  await rampHelper.deployed()

  rampHelper2 = await RampHelper2.deploy()
  await rampHelper2.deployed()

  rampAds = await RampAds.deploy()
  await rampAds.deployed()

  rampFactory = await RampFactory.deploy()
  await rampFactory.deployed()

  stakeMarket = await StakeMarket.deploy()
  await stakeMarket.deployed()

  stakeMarketNote = await StakeMarketNote.deploy()
  await stakeMarketNote.deployed()

  stakeMarketBribe = await StakeMarketBribe.deploy()
  await stakeMarketBribe.deployed()

  stakeMarketVoter = await StakeMarketVoter.deploy()
  await stakeMarketVoter.deployed()

  trustBountiesVoter = await TrustBountiesVoter.deploy()
  await trustBountiesVoter.deployed()

  nfticket = await NFTicket.deploy()
  await nfticket.deployed()

  nfticketHelper = await NFTicketHelper.deploy()
  await nfticketHelper.deployed()

  nfticketHelper2 = await NFTicketHelper2.deploy(contractAddresses.address)
  await nfticketHelper2.deployed()

  marketPlaceEvents = await MarketPlaceEvents.deploy()
  await marketPlaceEvents.deployed()

  marketPlaceCollection = await MarketPlaceCollection.deploy(
    owner.address,
    contractAddresses.address
  )

  marketPlaceOrders = await MarketPlaceOrders.deploy()
  await marketPlaceOrders.deployed()

  marketPlaceOrders02 = await MarketPlaceOrders02.deploy()
  await marketPlaceOrders02.deployed()

  marketPlaceTrades = await MarketPlaceTrades.deploy()
  await marketPlaceTrades.deployed()

  marketPlaceHelper = await MarketPlaceHelper.deploy()
  await marketPlaceHelper.deployed()

  marketPlaceHelper2 = await MarketPlaceHelper2.deploy()
  await marketPlaceHelper2.deployed()

  marketPlaceHelper02 = await MarketPlaceHelper02.deploy()
  await marketPlaceHelper02.deployed()

  marketPlaceHelper3 = await MarketPlaceHelper3.deploy()
  await marketPlaceHelper3.deployed()

  marketPlaceHelper03 = await MarketPlaceHelper03.deploy()
  await marketPlaceHelper03.deployed()

  vavaFactory = await VavaFactory.deploy(contractAddresses.address)
  await vavaFactory.deployed()

  vavaHelper = await VavaHelper.deploy()
  await vavaHelper.deployed()
  
  vavaHelper2 = await VavaHelper2.deploy()
  await vavaHelper2.deployed()

  veFactory = await VeFactory.deploy()
  await veFactory.deployed()

  valuepoolVoter = await ValuepoolVoter.deploy()
  await valuepoolVoter.deployed()

  // set ups
  await ve.setVoter(stakeMarketVoter.address)
  await ve.setVoter(businessVoter.address)
  await ve.setVoter(referralVoter.address)
  await ve.setVoter(trustBountiesVoter.address)
  
  await rampHelper.setContractAddress(contractAddresses.address)
  console.log("rampHelper.setContractAddress===========> Done!")

  await rampHelper2.setContractAddress(contractAddresses.address)
  console.log("rampHelper2.setContractAddress===========> Done!")

  await rampAds.setContractAddress(contractAddresses.address)
  console.log("rampAds.setContractAddress===========> Done!")

  await rampFactory.setContractAddress(contractAddresses.address)
  console.log("rampFactory.setContractAddress===========> Done!")

  await businessGaugeFactory.setContractAddress(contractAddresses.address)
  console.log("businessGaugeFactory.setContractAddress===========> Done!")
  
  await minterFactory.setContractAddress(contractAddresses.address)
  console.log("minterFactory.setContractAddress===========> Done!")

  await businessBribeFactory.setContractAddress(contractAddresses.address)
  console.log("businessBribeFactory.setContractAddress===========> Done!")
  
  await referralBribeFactory.setContractAddress(contractAddresses.address)
  console.log("referralBribeFactory.setContractAddress===========> Done!")

  await businessVoter.setContractAddress(contractAddresses.address)
  console.log("businessVoter.setContractAddress===========> Done!")
  
  await referralVoter.setContractAddress(contractAddresses.address)
  console.log("referralVoter.setContractAddress===========> Done!")

  await trustBounties.setContractAddress(contractAddresses.address)
  console.log("trustBounties.setContractAddress===========> Done!")

  await trustBountiesHelper.setContractAddress(contractAddresses.address)
  console.log("trustBountiesHelper.setContractAddress===========> Done!")

  await auditorNote.setContractAddress(contractAddresses.address)
  console.log("auditorNote.setContractAddress===========> Done!")

  await auditorHelper.setContractAddress(contractAddresses.address)
  console.log("auditorHelper.setContractAddress===========> Done!")

  await sponsorFactory.setContractAddress(contractAddresses.address)
  console.log("sponsorFactory.setContractAddress===========> Done!")

  await sponsorNote.setContractAddress(contractAddresses.address)
  console.log("sponsorNote.setContractAddress===========> Done!")

  await valuepoolVoter.setContractAddress(contractAddresses.address)
  console.log("valuepoolVoter.setContractAddress===========> Done!")
  
  await vavaHelper2.setContractAddress(contractAddresses.address)
  console.log("vavaHelper2.setContractAddress===========> Done!")
  
  await vavaHelper.setContractAddress(contractAddresses.address)
  console.log("vavaHelper.setContractAddress===========> Done!")

  await ssi.setContractAddress(contractAddresses.address)
  console.log("ssi.setContractAddress===========> Done!")

  await stakeMarket.setContractAddress(contractAddresses.address)
  console.log("stakeMarket.setContractAddress===========> Done!")

  await stakeMarketNote.setContractAddress(contractAddresses.address)
  console.log("stakeMarketNote.setContractAddress===========> Done!")
  
  await stakeMarketBribe.setContractAddress(contractAddresses.address)
  console.log("stakeMarketBribe.setContractAddress===========> Done!")

  await stakeMarketVoter.setContractAddress(contractAddresses.address)
  console.log("stakeMarketVoter.setContractAddress===========> Done!")

  await trustBountiesVoter.setContractAddress(contractAddresses.address)
  console.log("trustBountiesVoter.setContractAddress===========> Done!")

  await profile.setContractAddress(contractAddresses.address)
  console.log("profile.setContractAddress===========> Done!")

  await profileHelper.setContractAddress(contractAddresses.address)
  console.log("profileHelper.setContractAddress===========> Done!")

  await nfticket.setContractAddress(contractAddresses.address)
  console.log("nfticket.setContractAddress===========> Done!")
  
  await nfticketHelper.setContractAddress(contractAddresses.address)
  console.log("nfticketHelper.setContractAddress===========> Done!")
  
  await marketPlaceOrders.setContractAddress(contractAddresses.address)
  console.log("marketPlaceOrders.setContractAddress===========> Done!")

  await marketPlaceOrders02.setContractAddress(contractAddresses.address)
  console.log("marketPlaceOrders02.setContractAddress===========> Done!")
  
  await marketPlaceTrades.setContractAddress(contractAddresses.address)
  console.log("marketPlaceTrades.setContractAddress===========> Done!")
  
  await marketPlaceHelper.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper.setContractAddress===========> Done!")
  
  await marketPlaceHelper2.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper2.setContractAddress===========> Done!")

  await marketPlaceHelper02.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper02.setContractAddress===========> Done!")
  
  await marketPlaceHelper3.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper3.setContractAddress===========> Done!")
  
  await marketPlaceHelper03.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper03.setContractAddress===========> Done!")

  await marketPlaceEvents.setContractAddress(contractAddresses.address)
  console.log("marketPlaceEvents.setContractAddress===========> Done!")
  
  // ####################### setDev
  await contractAddresses.setDevaddr(owner.address)
  console.log("contractAddresses.setDevaddr===========> Done!")  

  await contractAddresses.addContent('nsfw')

  await businessGaugeFactory.updateVoter([businessVoter.address, referralVoter.address], true)
  
  await contractAddresses.setRampHelper(rampHelper.address)
  console.log("contractAddresses.setRampHelper===========> Done!")

  await contractAddresses.setRampHelper2(rampHelper2.address)
  console.log("rampHelper2.setContractAddress===========> Done!")

  await contractAddresses.setRampAds(rampAds.address)
  console.log("contractAddresses.setRampAds===========> Done!")

  await contractAddresses.setRampFactory(rampFactory.address)
  console.log("contractAddresses.setRampFactory===========> Done!")

  await contractAddresses.setBusinessGaugeFactory(businessGaugeFactory.address)
  console.log("contractAddresses.setBusinessGaugeFactory===========> Done!")

  await contractAddresses.setMinterFactory(minterFactory.address)
  console.log("contractAddresses.setminterFactory===========> Done!")

  await contractAddresses.setBusinessBribeFactory(businessBribeFactory.address)
  console.log("contractAddresses.setBusinessBribeFactory===========> Done!")

  await contractAddresses.setReferralBribeFactory(referralBribeFactory.address)
  console.log("contractAddresses.setReferralBribeFactory===========> Done!")

  await contractAddresses.setBusinessVoter(businessVoter.address)
  console.log("contractAddresses.setBusinessVoter===========> Done!")
  
  await contractAddresses.setReferralVoter(referralVoter.address)
  console.log("contractAddresses.setReferralVoter===========> Done!")

  await contractAddresses.setAuditorHelper(auditorHelper.address)
  console.log("contractAddresses.setAuditorHelper===========> Done!")

  await contractAddresses.setAuditorNote(auditorNote.address)
  console.log("contractAddresses.setAuditorNote===========> Done!")

  await contractAddresses.setTrustBounty(trustBounties.address)
  console.log("contractAddresses.setTrustBounty===========> Done!")

  await contractAddresses.setTrustBountyHelper(trustBountiesHelper.address)
  console.log("contractAddresses.setTrustBountyHelper===========> Done!")

  await trustBountiesHelper.updateVes(ve.address, true)
  await trustBountiesHelper.updateWhitelistedTokens([ust.address], true)
  await trustBountiesHelper.updateCanAttach(marketPlaceEvents.address, true)

  await contractAddresses.setSponsorFactory(sponsorFactory.address)
  console.log("contractAddresses.setSponsorFactory===========> Done!")

  await contractAddresses.setSponsorNote(sponsorNote.address)
  console.log("contractAddresses.setSponsorNote===========> Done!")

  await contractAddresses.setValuepoolFactory(vavaFactory.address)
  console.log("contractAddresses.setValuepoolFactory===========> Done!")

  await contractAddresses.setValuepoolFactory(vavaFactory.address)
  console.log("contractAddresses.setValuepoolFactory===========> Done!")

  await contractAddresses.setValuepoolHelper(vavaHelper.address)
  console.log("contractAddresses.setValuepoolHelper===========> Done!")

  await contractAddresses.setValuepoolHelper2(vavaHelper2.address)
  console.log("contractAddresses.setValuepoolHelper2===========> Done!")

  await contractAddresses.setVeFactory(veFactory.address)
  console.log("contractAddresses.setVeFactory===========> Done!")

  await contractAddresses.setValuepoolVoter(valuepoolVoter.address)
  console.log("contractAddresses.setValuepoolVoter===========> Done!")

  await contractAddresses.setSSI(ssi.address)
  console.log("contractAddresses.setSSI===========> Done!")

  await contractAddresses.setStakeMarket(stakeMarket.address)
  console.log("contractAddresses.setStakeMarket===========> Done!")

  await contractAddresses.setStakeMarketNote(stakeMarketNote.address)
  console.log("contractAddresses.setStakeMarketNote===========> Done!")

  await contractAddresses.setStakeMarketBribe(stakeMarketBribe.address)
  console.log("contractAddresses.setStakeMarketBribe===========> Done!")

  await contractAddresses.setStakeMarketVoter(stakeMarketVoter.address)
  console.log("contractAddresses.setStakeMarketVoter===========> Done!")

  await contractAddresses.setTrustBountyVoter(trustBountiesVoter.address)
  console.log("contractAddresses.setTrustBountyVoter===========> Done!")

  await contractAddresses.setProfile(profile.address)
  console.log("contractAddresses.setProfile===========> Done!")

  await contractAddresses.setProfileHelper(profileHelper.address)
  console.log("contractAddresses.setProfileHelper===========> Done!")

  await contractAddresses.setNfticket(nfticket.address)
  console.log("contractAddresses.setNfticket===========> Done!")
  
  await contractAddresses.setNfticketHelper(nfticketHelper.address)
  console.log("contractAddresses.setNfticketHelper===========> Done!")
  
  await contractAddresses.setNfticketHelper2(nfticketHelper2.address)
  console.log("contractAddresses.setNfticketHelper2===========> Done!")
  
  await contractAddresses.setToken(ust.address)
  console.log("contractAddresses.setToken===========> Done!")
  
  await contractAddresses.setNFTMarketHelpers3(marketPlaceHelper3.address)
  console.log("contractAddresses.setNFTMarketHelpers3===========> Done!")

  await contractAddresses.setMarketHelpers3(marketPlaceHelper03.address)
  console.log("contractAddresses.setMarketHelpers3===========> Done!")
  
  await contractAddresses.setNFTMarketHelpers2(marketPlaceHelper2.address)
  console.log("contractAddresses.setNFTMarketHelpers2===========> Done!")

  await contractAddresses.setMarketHelpers2(marketPlaceHelper02.address)
  console.log("contractAddresses.setMarketHelpers2===========> Done!")
  
  await contractAddresses.setNFTMarketHelpers(marketPlaceHelper.address)
  console.log("contractAddresses.setNFTMarketHelpers===========> Done!")
  
  await contractAddresses.setNFTMarketTrades(marketPlaceTrades.address)
  console.log("contractAddresses.setNFTMarketTrades===========> Done!")

  await contractAddresses.setMarketCollections(marketPlaceCollection.address)
  console.log("contractAddresses.setMarketCollections===========> Done!")

  await contractAddresses.setMarketPlaceEvents(marketPlaceEvents.address)
  console.log("contractAddresses.setMarketPlaceEvents===========> Done!")

  await contractAddresses.setMarketOrders(marketPlaceOrders02.address)
  console.log("contractAddresses.setMarketOrders===========> Done!")

  await contractAddresses.setNFTMarketOrders(marketPlaceOrders.address)
  console.log("contractAddresses.setNFTMarketOrders===========> Done!")
    
  await marketPlaceHelper03.addDtoken(ust.address)
  await marketPlaceHelper03.addVetoken(ve.address)
  await ust.updateMinter(rampHelper.address)
  
}).timeout(10000000);
  
  it("2) add collection", async function () {
    await marketPlaceCollection.addCollection(100,0,0,10,0,0,ust.address,false,false);
    
    expect((await marketPlaceCollection.addressToCollectionId(owner.address))).to.equal(1);
  }).timeout(10000000);

  it("3) create ramp", async function () {
    await profile.createSpecificProfile("Owner1",1,0)
    console.log("profile1==============>", (await profile.profileInfo(1)).name)
    await ssi.generateIdentityProof(owner.address,1,1,86700 * 7,"ssid","tepa")
    await ssi.updateSSID(1,1)
    await profile.updateSSID()
    await profile.addAccount(1, owner3.address)
    await ve_underlying.connect(owner3).attachProfile()

    await rampFactory.createGauge(owner.address)

    let rampAddress = (await rampHelper.getAllRamps(0))[0]
    const Ramp = await ethers.getContractFactory("Ramp");
    ramp = Ramp.attach(rampAddress)

    await rampHelper.addDtoken(ve.address)
    await rampHelper.addDtoken(ust.address)
    await rampHelper.removeDtoken(ust.address)

    await expect(ramp.createProtocol(ust.address, 0)).to.be.reverted
    expect((await ramp.getAllTokens(0)).length).to.equal(0)
    await rampHelper.addDtoken(ust.address)

    await ramp.createProtocol(ust.address, 0)
    console.log("allTokens==================>", await ramp.getAllTokens(0))

    expect((await ramp.getAllTokens(0)).length).to.equal(1)

  }).timeout(10000000);

  it("04) create lock", async function () {
    let ve_underlying_amount = ethers.BigNumber.from("1000000000000000000000");
    await ve_underlying.approve(ve.address, ve_underlying_amount);
    const lockDuration = 7 * 24 * 3600; // 1 week

    // Balance should be zero before and 1 after creating the lock
    expect(await ve.balanceOf(owner.address)).to.equal(0);
    await ve.create_lock(ve_underlying_amount, lockDuration);
    expect(await ve.ownerOf(1)).to.equal(owner.address);
    expect(await ve.balanceOf(owner.address)).to.equal(1);
  }).timeout(10000000);

  it("4) update token id", async function () {
    console.log("")
    await ramp.updateDevTokenId(ve.address, 1);
    await ramp.updateParameters(1000,1000,0,0,true)
    expect((await ramp.protocolInfo(ust.address)).tokenId).to.equal(0)
    await ramp.updateTokenId(ust.address, 1)
    expect((await ramp.protocolInfo(ust.address)).tokenId).to.equal(1)

  }).timeout(10000000);
  
  it("5) update profile id", async function () {
    expect((await ramp.protocolInfo(ust.address)).profileId).to.equal(0)
    await ramp.updateProfile(ust.address, 1)
    expect((await ramp.protocolInfo(ust.address)).profileId).to.equal(1)

  }).timeout(10000000);

  it("6) create bounty & add balance", async function () {
    await trustBounties.createBounty(
      owner.address,
      ust.address,
      ve.address,
      rampHelper.address,
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

    await ust.connect(owner).approve(trustBountiesHelper.address, 101)
    await trustBounties.addBalance(
      1, 
      trustBounties.address,
      0, 
      101
    )
    console.log("balance===========>", await trustBounties.getBalance(1))
    expect(await trustBounties.getBalance(1)).to.equal(100);
  }).timeout(10000000);

  it("7) update bounty", async function () {
    expect((await ramp.protocolInfo(ust.address)).bountyId).to.equal(0)
    await ramp.updateBounty(ust.address, 1)
    expect((await ramp.protocolInfo(ust.address)).bountyId).to.equal(1)
  }).timeout(10000000);

  it("8) update dev from token and undo", async function () {
    expect(await ramp.devaddr_()).to.equal(owner.address)
    await ve.transferFrom(owner.address, owner2.address, 1)
    await ramp.connect(owner2).updateDevFromToken(1)
    expect(await ramp.devaddr_()).to.equal(owner2.address)
    await ve.connect(owner2).transferFrom(owner2.address, owner.address, 1)
    await ramp.updateDevFromToken(1)
    expect(await ramp.devaddr_()).to.equal(owner.address)
  }).timeout(10000000);

  it("9) update protocol", async function () {
    expect((await ramp.protocolInfo(ust.address)).maxParters).to.equal(0)
    await expect(ramp.connect(owner3).updateProtocol(ust.address, false, 1000000, 0, 2)).to.be.reverted
    await ramp.updateProtocol(ust.address, false, 1000000, 0, 2)
    expect((await ramp.protocolInfo(ust.address)).maxParters).to.equal(2)
    await ramp.updateProtocol(ust.address, false, 1000000, 0, 0)
    expect((await ramp.protocolInfo(ust.address)).maxParters).to.equal(0)
  }).timeout(10000000);

  it("10) mint", async function () {
    await rampHelper.updateOracle(ust.address, mockAggregatorV3.address, true)

    // console.log("oracle============>", await rampHelper.tokenToOracle(ust.address))
    // expect((await rampHelper.tokenToOracle(ust.address))).to.equal(mockAggregatorV3.address)
    
    await rampHelper.updateTokenPrice(ust.address)
    // console.log("oracle price============>", await rampHelper.tokenPriceInNative(ust.address))
    // expect((await rampHelper.tokenPriceInNative(ust.address))).to.equal(1)

    console.log("convert============>", await rampHelper.convert(ust.address, 10))
    expect((await rampHelper.convert(ust.address, 10))).to.equal(10)

  }).timeout(10000000);

  it("11) mint", async function () {
    await ramp.updateParameters(1000,1000,0,0,true)
    await rampAds.updateMintFactors(ust.address, 8000)
    await rampHelper.updateParameters(
      1000, 
      0, 
      "0x0000000000000000000000000000000000000000"
    )
    console.log("rampAds.mintAvailable=============>", await rampAds.mintAvailable(ramp.address, ust.address))
    expect((await rampAds.mintAvailable(ramp.address, ust.address)).mintable).to.equal(40)
    expect((await rampAds.mintAvailable(ramp.address, ust.address)).balance).to.equal(100)
    expect((await rampAds.mintAvailable(ramp.address, ust.address)).status).to.equal(0)
    expect((await ramp.protocolInfo(ust.address)).minted).to.equal(0)
    expect(await ramp.totalRevenue(ust.address)).to.equal(0)
    let owner2BalanceBefore = await ust.balanceOf(owner2.address)
    expect(await ust.balanceOf(rampHelper.address)).to.equal(0)
    expect(await rampHelper.pendingRevenue(ust.address)).to.equal(0)

    await rampHelper.preMint(ramp.address, owner2.address, ust.address, 200, 0,"sessionId")
    await ramp.mint(ust.address, owner2.address, 200, 0, "sessionId")
    
    console.log("ramp.protocolInfo===========>", await ramp.protocolInfo(ust.address))
    console.log("ust.balanceOf===========>", await ust.balanceOf(owner2.address))
    console.log("ust.balanceOf===========>", await ust.balanceOf(rampHelper.address))
    console.log("ramp.totalRevenue===========>", await ramp.totalRevenue(ust.address))
    console.log("rampHelper.pendingRevenue===========>", await rampHelper.pendingRevenue(ust.address))

    expect(await ramp.totalRevenue(ust.address)).to.equal(4)
    expect(await ust.balanceOf(rampHelper.address)).to.equal(4)
    expect(await rampHelper.pendingRevenue(ust.address)).to.equal(4)
    expect(await ust.balanceOf(owner2.address)).to.equal(owner2BalanceBefore.add(40 - 4 - 4))
    expect((await ramp.protocolInfo(ust.address)).minted).to.equal(40 - 4 - 4)

  }).timeout(10000000);

  it("12) burn", async function () {
    expect(await ramp.totalRevenue(ust.address)).to.equal(4)
    expect(await ust.balanceOf(rampHelper.address)).to.equal(4)
    expect(await rampHelper.pendingRevenue(ust.address)).to.equal(4)
    expect((await ramp.protocolInfo(ust.address)).burnt).to.equal(0)
    await ramp.updateProtocol(ust.address, false, 1000000, 0, 1)
    
    await ust.connect(owner2).approve(rampHelper.address, 18)
    await ramp.connect(owner2).burn(ust.address, 90, 0)
    console.log("ramp.burn=============>", await ramp.totalRevenue(ust.address))
    expect(await ramp.totalRevenue(ust.address)).to.equal(4 + 3)
    
  }).timeout(10000000);

  it("13) create bounty & add balance", async function () {
    await trustBounties.connect(owner2).createBounty(
      owner2.address,
      ust.address,
      ve.address,
      rampHelper.address,
      0,
      1,
      86700 * 7 * 4,
      0,
      false,
      "http://link-to-avatar.com",
      "ramps"
    )
    console.log("trustBounties===========>", await trustBounties.getBalance(2))
    console.log("bountyInfo===========>", await trustBounties.bountyInfo(2))
    expect((await trustBounties.bountyInfo(2)).owner).to.equal(owner2.address);

    await ust.connect(owner2).approve(trustBountiesHelper.address, 101)
    await trustBounties.connect(owner2).addBalance(
      2, 
      trustBounties.address,
      0, 
      101
    )
    console.log("balance===========>", await trustBounties.getBalance(2))
    expect(await trustBounties.getBalance(2)).to.equal(100);

  }).timeout(10000000);

  it("14) add partner", async function () {
    expect((await ramp.getAllPartnerBounties(ust.address,0)).length).to.equal(0)
    
    await ramp.connect(owner2).addPartner(ust.address, 2)

    expect((await ramp.getAllPartnerBounties(ust.address,0)).length).to.equal(1)
    await rampAds.updateMintFactors(ust.address, 2500)
    
    console.log("mintAvailable2===========>", await rampAds.mintAvailable(ramp.address, ust.address))
    // await ramp.connect(owner2).addPartner(ust.address, 2)

    console.log("ramp.getAllPartnerBounties=============>", await ramp.getAllPartnerBounties(ust.address, 0))
    expect((await ramp.getAllPartnerBounties(ust.address,0)).length).to.equal(1)
    expect((await ramp.getAllPartnerBounties(ust.address,0))[0]).to.equal(2)

  }).timeout(10000000);

  it("15) create bounty & add balance", async function () {
    await trustBounties.connect(owner3).createBounty(
      owner3.address,
      ust.address,
      ve.address,
      rampHelper.address,
      0,
      1,
      86700 * 7 * 4,
      0,
      false,
      "http://link-to-avatar.com",
      "ramps"
    )
    console.log("trustBounties===========>", await trustBounties.getBalance(3))
    console.log("bountyInfo===========>", await trustBounties.bountyInfo(3))
    expect((await trustBounties.bountyInfo(3)).owner).to.equal(owner3.address);

    await ust.connect(owner3).approve(trustBountiesHelper.address, 101)
    await trustBounties.connect(owner3).addBalance(
      3, 
      trustBounties.address,
      0, 
      101
    )
    console.log("balance===========>", await trustBounties.getBalance(3))
    expect(await trustBounties.getBalance(3)).to.equal(100);
    
  }).timeout(10000000);

  it("16) create lock", async function () {
    let ve_underlying_amount = ethers.BigNumber.from("1000000000000000000000");
    await ve_underlying.connect(owner3).approve(ve.address, ve_underlying_amount);
    const lockDuration = 7 * 24 * 3600; // 1 week

    // Balance should be zero before and 1 after creating the lock
    expect(await ve.balanceOf(owner3.address)).to.equal(0);
    await ve.connect(owner3).create_lock(ve_underlying_amount, lockDuration);
    expect(await ve.ownerOf(2)).to.equal(owner3.address);
    expect(await ve.balanceOf(owner3.address)).to.equal(1);
  }).timeout(10000000);

  it("17) buy account", async function () {
    await ve_underlying.connect(owner3).approve(ramp.address, 1)
    await expect(ramp.connect(owner3).buyAccount(ust.address, 2, 3)).to.be.reverted
    // set sale price
    await ramp.updateProtocol(ust.address,false, 1000000, 1,0)

    expect((await ramp.protocolInfo(ust.address)).bountyId).to.equal(1)
    expect((await ramp.protocolInfo(ust.address)).tokenId).to.equal(1)
    expect(await ve.ownerOf(1)).to.equal(owner.address)
    expect((await ramp.protocolInfo(ust.address)).salePrice).to.equal(1)
    expect((await ramp.getParams())[5]).to.equal(0) //soldAccounts
    
    await trustBountiesHelper.updateAuthorizedSourceFactories([rampHelper.address], true)
    let veAddress = await ramp._ve()
    mve = vecontract.attach(veAddress)
    console.log("protocolInfo==============>", await mve.token(), ve_underlying.address, await ramp.protocolInfo(ust.address))
    await ramp.connect(owner3).buyAccount(ust.address, 2, 3)

    expect((await ramp.protocolInfo(ust.address)).bountyId).to.equal(3)
    expect((await ramp.protocolInfo(ust.address)).tokenId).to.equal(2)
    expect(await ve.ownerOf(2)).to.equal(owner3.address)
    expect((await ramp.protocolInfo(ust.address)).salePrice).to.equal(0)
    expect((await ramp.getParams())[5]).to.equal(1) //soldAccounts
    
  }).timeout(10000000);

  it("18) update individual protocol", async function () {
    expect((await ramp.protocolInfo(ust.address)).maxParters).to.equal(0)
    await expect(ramp.updateIndividualProtocol(ust.address, false, 100000, 0, 2)).to.be.reverted
    await ramp.connect(owner3).updateIndividualProtocol(ust.address, false, 100000, 0, 2)
    expect((await ramp.protocolInfo(ust.address)).maxParters).to.equal(2)
    await ramp.connect(owner3).updateIndividualProtocol(ust.address, false, 100000, 0, 0)
    expect((await ramp.protocolInfo(ust.address)).maxParters).to.equal(0)
  }).timeout(10000000);


  it("19) claim pending", async function () {
    console.log("share===========>", await rampHelper.getPartnerShare(200, 2))
    console.log("mintAvailable===========>", await rampAds.mintAvailable(ramp.address, ust.address))
    console.log("balance2===========>", await trustBounties.getBalance(2))
    console.log("totalRevenue===========>", await ramp.totalRevenue(ust.address))
    console.log("paidRevenue===========>", await ramp.paidRevenue(ust.address, 2))
    await expect(ramp.claimPendingRevenue(ust.address, 2)).to.be.reverted
    // expect(await ramp.paidRevenue(ust.address, 2)).to.equal(5)

    await ramp.connect(owner2).claimPendingRevenue(ust.address, 2)

    expect(await ramp.paidRevenue(ust.address, 2)).to.equal(3)
    
    await ramp.updateParameters(1000,1000,0,0,true)
    await rampHelper.preMint(ramp.address, owner2.address, ust.address, 200, 0,"sessionId2")
    await ramp.mint(ust.address, owner2.address, 200, 0, "sessionId2")
    console.log("totalRevenue after mint===========>", await ramp.totalRevenue(ust.address))
    ustBalanceBefore = await ust.balanceOf(owner2.address)

    await ramp.connect(owner2).claimPendingRevenue(ust.address, 2)

    // expect(await ust.balanceOf(owner2.address)).to.equal(ustBalanceBefore.add(1))
    // expect(await ramp.paidRevenue(ust.address, 2)).to.equal(6)
    
  }).timeout(10000000);

  it("20) create claim", async function () {
    console.log("balance ust of owner2==========>", await ust.balanceOf(owner2.address))
    console.log("balance ust of owner3==========>", await ust.balanceOf(owner3.address))
    console.log("protocolInfo===========>", (await ramp.protocolInfo(ust.address)).status)

    await ust.connect(owner2).approve(trustBounties.address, 10)
    await rampHelper.connect(owner2).createClaim(ramp.address, ust.address, 10, false, "","","")
    
    console.log("claims===========>", await trustBounties.claims(3,0))
    expect((await trustBounties.claims(3,0)).hunter).to.equal(owner2.address);
    
  }).timeout(10000000);

  it("21) buy ramp", async function () {
    await ramp.updateParameters(1000,1000,0,10,true)

    console.log("getAllTokens===================>", await ramp.getAllTokens(0))
    console.log("soldAccounts===================>", (await ramp.getParams())[5]) //soldAccounts
    console.log("tokenId=================>", (await ramp.getParams())[1])
    console.log("protocolInfo===========>", await ramp.protocolInfo(ust.address))
    expect((await ramp.getParams())[1]).to.equal(1)
    expect(await ramp.isAdmin(owner.address)).to.equal(true)
    expect(await ramp.isAdmin(owner3.address)).to.equal(false)
    expect(await ramp.devaddr_()).to.equal(owner.address)

    await ve_underlying.connect(owner3).approve(ramp.address, 10)
    await ramp.connect(owner3).buyRamp(ve.address, 2, [])
    
    expect((await ramp.getParams())[1]).to.equal(2)
    expect(await ramp.isAdmin(owner.address)).to.equal(false)
    expect(await ramp.isAdmin(owner3.address)).to.equal(true)
    expect(await ramp.devaddr_()).to.equal(owner3.address)
    
  }).timeout(10000000);

  it("22) delete protocol", async function () {
    await ramp.connect(owner3).withdraw(ust.address, 2)
    await ust.connect(owner3).transfer(owner2.address, 8)
    
    await rampHelper.withdrawFees(ust.address)
    await ust.transfer(owner2.address, 12)

    console.log("minted===========>", (await ramp.protocolInfo(ust.address)).minted)
    console.log("burnt===========>", (await ramp.protocolInfo(ust.address)).burnt)
    console.log("balance ust of owner==========>", await ust.balanceOf(owner.address))
    console.log("balance ust of owner2==========>", await ust.balanceOf(owner2.address))
    console.log("balance ust of owner3==========>", await ust.balanceOf(owner3.address))
    console.log("balance ust of ramp==========>", await ust.balanceOf(ramp.address))
    console.log("balance ust of rampHelper==========>", await ust.balanceOf(rampHelper.address))

    await ramp.connect(owner3).updateParameters(1000,0,0,0,true)
    await rampHelper.updateParameters(
      0, 
      0, 
      "0x0000000000000000000000000000000000000000"
    )
    await ust.connect(owner2).approve(rampHelper.address, 49)
    await ramp.connect(owner2).burn(ust.address, 49, 0)

    console.log("minted===========>", (await ramp.protocolInfo(ust.address)).minted)
    console.log("burnt===========>", (await ramp.protocolInfo(ust.address)).burnt)

    const endTimeBefore = (await trustBounties.bountyInfo(3)).endTime
    await ramp.connect(owner3).unlockBounty(ust.address, 3)
    const endTimeAfter = (await trustBounties.bountyInfo(3)).endTime
    await ramp.connect(owner3).deleteProtocol(ust.address)
    expect(endTimeBefore.sub(endTimeAfter)).gt(0)
    expect(endTimeAfter.sub(endTimeBefore)).lt(0)
    console.log("endTimeBefore===========>", endTimeBefore)
    console.log("endTimeAfter===========>", endTimeBefore.sub(endTimeAfter))
  }).timeout(10000000);
    
});
