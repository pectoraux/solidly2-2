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
  let vavaHelper2;
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
  let profileHelper;
  let ssi;
  let Auditor;
  let auditor;
  let auditorNote;
  let trustBounties;
  let businessBribe;
  let referralBribe;
  let BusinessBribe;
  let ReferralBribe;
  let BusinessGauge;
  let businessGauge;
  let businessGaugeFactory;
  let businessBribeFactory;
  let referralBribeFactory;
  let businessVoter;
  let referralVoter;
  let businessMinter;
  let veFactory;
  let contractAddresses;
  let nfticketHelper2;
  let nftSvg;

  it("1) deploy market place", async function () {
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
    
    const ContractAddresses =  await ethers.getContractFactory("contracts/MarketPlace.sol:ContractAddresses")
    const NFTicket = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicket");
    const NFTicketHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper");
    const NFTicketHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper2");
    const MarketPlaceEvents = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceEvents");
    const MarketPlaceCollection = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceCollection");
    const MarketPlaceOrders = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceOrders");
    const NFTMarketPlaceOrders = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceOrders");
    const PaywallMarketPlaceOrders = await ethers.getContractFactory("contracts/PaywallMarketPlace.sol:PaywallMarketPlaceOrders");
    const MarketPlaceTrades = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceTrades");
    const MarketPlaceHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper");
    const MarketPlaceHelper3 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper3");
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
    const NFTSVG = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTSVG")
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    
    BusinessBribe = await ethers.getContractFactory("BusinessBribe");
    BusinessGauge = await ethers.getContractFactory("BusinessGauge");

    ReferralBribe = await ethers.getContractFactory("ReferralBribe");

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

    const SponsorNote = await ethers.getContractFactory("SponsorNote",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const MarketPlaceHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
      libraries: {
        Percentile: percentile.address,
      },
    });

  ve = await vecontract.deploy(ve_underlying.address);
  await ve.deployed()

  ve_dist = await ve_distContract.deploy(ve.address);
  await ve_dist.deployed()

  businessBribeFactory = await BusinessBribeFactory.deploy();
  await businessBribeFactory.deployed()

  businessGaugeFactory = await BusinessGaugeFactory.deploy();
  await businessGaugeFactory.deployed()

  referralBribeFactory = await ReferralBribeFactory.deploy();
  await referralBribeFactory.deployed()

  nftSvg = await NFTSVG.deploy()
  await nftSvg.deployed()

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

  profile = await Profile.deploy()
  await profile.deployed()

  profileHelper = await ProfileHelper.deploy()
  await profileHelper.deployed()

  stakeMarket = await StakeMarket.deploy()
  await stakeMarket.deployed()

  stakeMarketNote = await StakeMarketNote.deploy()
  await stakeMarketNote.deployed()

  stakeMarketBribe = await StakeMarketBribe.deploy()
  await stakeMarketBribe.deployed()

  stakeMarketVoter = await StakeMarketVoter.deploy()
  await stakeMarketVoter.deployed()

  contractAddresses = await ContractAddresses.deploy()
  await contractAddresses.deployed()

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

  paywallMarketPlaceOrders = await PaywallMarketPlaceOrders.deploy()
  await paywallMarketPlaceOrders.deployed()

  nftMarketPlaceOrders = await NFTMarketPlaceOrders.deploy()
  await nftMarketPlaceOrders.deployed()

  marketPlaceTrades = await MarketPlaceTrades.deploy()
  await marketPlaceTrades.deployed()

  marketPlaceHelper = await MarketPlaceHelper.deploy()
  await marketPlaceHelper.deployed()

  marketPlaceHelper2 = await MarketPlaceHelper2.deploy()
  await marketPlaceHelper2.deployed()

  marketPlaceHelper3 = await MarketPlaceHelper3.deploy()
  await marketPlaceHelper3.deployed()

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

  trustBounties = await TrustBounties.deploy()
  await trustBounties.deployed()

  trustBountiesHelper = await TrustBountiesHelper.deploy()
  await trustBountiesHelper.deployed()

  // set ups
  await ve.setVoter(stakeMarketVoter.address)
  await ve.setVoter(businessVoter.address)
  await ve.setVoter(referralVoter.address)

  await nftSvg.setContractAddress(contractAddresses.address)
  console.log("nftSvg.setContractAddress===========> Done!")

  await businessGaugeFactory.setContractAddress(contractAddresses.address)
  console.log("businessGaugeFactory.setContractAddress===========> Done!")

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
  
  await marketPlaceTrades.setContractAddress(contractAddresses.address)
  console.log("marketPlaceTrades.setContractAddress===========> Done!")
  
  await marketPlaceHelper.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper.setContractAddress===========> Done!")
  
  await marketPlaceHelper2.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper2.setContractAddress===========> Done!")
  
  await marketPlaceHelper3.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper3.setContractAddress===========> Done!")

  await marketPlaceEvents.setContractAddress(contractAddresses.address)
  console.log("marketPlaceEvents.setContractAddress===========> Done!")
  
  // ####################### setDev
  await contractAddresses.setDevaddr(owner.address)
  console.log("contractAddresses.setDevaddr===========> Done!")  

  await contractAddresses.addContent('nsfw')
  
  await businessGaugeFactory.updateVoter([businessVoter.address, referralVoter.address], true)

  await contractAddresses.setBusinessGaugeFactory(businessGaugeFactory.address)
  console.log("contractAddresses.setBusinessGaugeFactory===========> Done!")

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
  
  await contractAddresses.setMarketHelpers3(marketPlaceHelper3.address)
  console.log("contractAddresses.setMarketHelpers3===========> Done!")
  
  await contractAddresses.setMarketHelpers2(marketPlaceHelper2.address)
  console.log("contractAddresses.setMarketHelpers2===========> Done!")
  
  await contractAddresses.setMarketHelpers(marketPlaceHelper.address)
  console.log("contractAddresses.setMarketHelpers===========> Done!")
  
  await contractAddresses.setMarketTrades(marketPlaceTrades.address)
  console.log("contractAddresses.setMarketTrades===========> Done!")

  await contractAddresses.setMarketCollections(marketPlaceCollection.address)
  console.log("contractAddresses.setMarketCollections===========> Done!")

  await contractAddresses.setMarketPlaceEvents(marketPlaceEvents.address)
  console.log("contractAddresses.setMarketPlaceEvents===========> Done!")

  await contractAddresses.setMarketOrders(marketPlaceOrders.address)
  console.log("contractAddresses.setMarketOrders===========> Done!")

  await contractAddresses.setPaywallMarketOrders(paywallMarketPlaceOrders.address)
  console.log("contractAddresses.setPaywallMarketOrders===========> Done!")

  await contractAddresses.setNFTMarketOrders(nftMarketPlaceOrders.address)
  console.log("contractAddresses.setNFTMarketOrders===========> Done!")

  await contractAddresses.setNftSvg(nftSvg.address)
  console.log("contractAddresses.setNftSvg===========> Done!")
    
  await marketPlaceHelper3.addDtoken(ust.address)
  await marketPlaceHelper3.addVetoken(ve.address)
}).timeout(10000000);


  it("2) add collection", async function () {
    await marketPlaceCollection.addCollection(100,0,0,10,0,0,ust.address,false,false);
    
    expect((await marketPlaceCollection.addressToCollectionId(owner.address))).to.equal(1);
  }).timeout(10000000);

  it("3) create ask order", async function () {
    await marketPlaceOrders.createAskOrder(
      "uber",
      10,
      0,
      0,
      true,
      true,
      true,
      0,
      10,
      0,
      ust.address,
      ve.address
    );
    await marketPlaceCollection.emitAskInfo(
      "uber",
      "string memory description",
      [],
      0,
      0,
      0,
      true,
      "",
      "Togo",
      "Lome-Togo",
      "All"
    )
  }).timeout(10000000);

  it("4) buy with contract", async function () {
    await ust.connect(owner).approve(marketPlaceTrades.address, 10);
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(0);
    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      "0x0000000000000000000000000000000000000000", 
      "uber",
      0,
      0,
      []
    );
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(1);

    await marketPlaceCollection.emitReview(
      1,
      "uber",
      0,
      0,
      true,
      "my review"
    )
    console.log("nfticket.isPaywall============>", await nfticket.isPaywall(1))
    console.log("============>", await nfticketHelper2.tokenURI(1))

  }).timeout(10000000);

  it("5) buy through stake market", async function () {
    await ust.connect(owner).approve(stakeMarket.address, 150);
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(1);
    expect((await ust.balanceOf(stakeMarket.address))).to.equal(0);
    // create stake
    await stakeMarket.createStake(
      [ve.address, ust.address, marketPlaceTrades.address, "0x0000000000000000000000000000000000000000", owner.address, owner.address],
      "uber",
      "1",
      [], 
      0,
      0,
      [0,10,0,0,0,0,0],
      true
    );
    expect((await ust.balanceOf(stakeMarket.address))).to.equal(10);
    expect((await stakeMarket.stakesBalances(1))).to.equal(10);
    // apply to stake
    await stakeMarket.createAndApply(owner.address, [10,0,0,0,0,0,0],86400,0,1,"1");
    // signal client still wants item
    await stakeMarket.lockStake(2,1,0,true);    
    expect((await stakeMarket.stakesBalances(1))).to.equal(10);
    // merchant procures item to client and signals with AGREEMENT "good"
    await stakeMarket.updateStake(2, 2);
    // client is satisfied with item and signals with AGREEMENT "good"
    await stakeMarket.updateStake(1, 2);
    expect((await stakeMarket.stakesBalances(1))).to.equal(10);
    expect((await stakeMarket.getStake(1)).parentStakeId).to.equal(1);
    expect((await stakeMarket.getStake(2)).parentStakeId).to.equal(1);
    expect((await stakeMarketNote.getDuePayable(2,0))[0]).to.equal(10);
    // merchant processes transaction
    await stakeMarket.unlockStake(2, 0, false);
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(2);

    // console.log("stake1===>", await stakeMarket.getStake(1))
    // console.log("stake2===>", await stakeMarket.getStake(2))
  }).timeout(10000000);

  it("6) create lock", async function () {
    let ve_underlying_amount = ethers.BigNumber.from("1000000000000000000000");
    await ve_underlying.approve(ve.address, ve_underlying_amount);
    const lockDuration = 7 * 24 * 3600; // 1 week

    // Balance should be zero before and 1 after creating the lock
    expect(await ve.balanceOf(owner.address)).to.equal(0);
    await ve.create_lock(ve_underlying_amount, lockDuration);
    expect(await ve.ownerOf(1)).to.equal(owner.address);
    expect(await ve.balanceOf(owner.address)).to.equal(1);

    await marketPlaceCollection.emitReview(
      1,
      "uber",
      1,
      0,
      true,
      "my review"
    )
  }).timeout(10000000);

  it("7) resolve conflict through stake market", async function () {
    // create profile
    await profile.createSpecificProfile("Owner1",1,0)
    await profile.shareEmail(owner2.address)
    await profile.shareEmail(owner3.address)
    await profile.connect(owner2).createProfile("Owner2",1)
    await profile.connect(owner3).createProfile("Owner3",0)
    console.log("profile1==============>", await profile.profileInfo(1))
    console.log("profile2==============>", await profile.profileInfo(2))
    console.log("profile3==============>", await profile.profileInfo(3))
    // mint ssid
    console.log("====================>", ssi.address, owner3.address)
    await ssi.generateIdentityProof(owner.address,1,1,86700 * 7,"ssid","tepa")
    await ssi.updateSSID(1,1)
    await profile.updateSSID()

    await ust.connect(owner).approve(stakeMarket.address, 100)
    // create stake
    await stakeMarket.createStake(
      [ve.address, ust.address, marketPlaceTrades.address, "0x0000000000000000000000000000000000000000", owner.address, owner.address],
      "uber",
      "1",
      [], 
      0,
      0,
      [0,100,0,0,200,0,0],
      true
    );
    // set gas percent
    await stakeMarket.updateRequirements(3,0,0,false,false,0,1000,"",[],[],[]);
    // apply to stake
    await stakeMarket.createAndApply(owner.address, [100,0,0,0,200,0,0],86400,0,3,"1");
    // set gas percent
    await stakeMarket.updateRequirements(4,0,0,false,false,0,1000,"",[],[],[]);
    // signal client still wants item
    await stakeMarket.lockStake(4,3,0,true);
    // merchant signals AGREEMENT good
    await stakeMarket.updateStake(4, 2);
    // client creates gauge
    await stakeMarket.createGauge(3, 4, "", "", "");
    // client updates his/her stake as well as source
    await stakeMarket.updateStaked(3, 100, 0, owner.address)
    // increase time
    await network.provider.send("evm_increaseTime", [200])
    await network.provider.send("evm_mine")
    // proceed to voter
    await stakeMarket.createGauge(3, 4, "Counterfeit Item", "I was delivered a counterfeit item by this merchant", "");
    expect((await ust.balanceOf(stakeMarket.address))).to.equal(91) //gasPercent=10% goes to voters
    // vote
    await stakeMarketVoter.vote(1, ve.address, 1, 1, 3, -1);
    // increase time by 1 week
    await network.provider.send("evm_increaseTime", [604800])
    await network.provider.send("evm_mine")
    // check state
    console.log("stakeMarketVoter===============>", await stakeMarketVoter.gauges(ve.address, 3))
    console.log("stakes(3) before ===============>", (await stakeMarket.getStake(3)).ownerAgreement, (await stakeMarket.getStake(3)).bank.amountPayable, (await stakeMarket.getStake(3)).bank.amountReceivable)
    console.log("stakes(4) before ===============>", (await stakeMarket.getStake(4)).ownerAgreement, (await stakeMarket.getStake(4)).bank.amountPayable, (await stakeMarket.getStake(4)).bank.amountReceivable)
    console.log("user balance before ===============>", await ust.balanceOf(owner.address))
    expect((await stakeMarket.getStake(3)).ownerAgreement).to.equal(4)
    expect((await stakeMarket.getStake(4)).ownerAgreement).to.equal(4)
    expect((await stakeMarket.getStake(3)).bank.amountReceivable).to.equal(0)
    expect((await stakeMarket.getStake(3)).bank.amountPayable).to.equal(100)
    expect((await stakeMarket.getStake(4)).bank.amountReceivable).to.equal(0)
    expect((await stakeMarket.getStake(4)).bank.amountPayable).to.equal(100)
    // update 
    await stakeMarketVoter.updateStakeFromVoter(ve.address, 1);
    console.log("stakeStatus3===========>", await stakeMarket.stakeStatus(3))
    console.log("stakeStatus4===========>", await stakeMarket.stakeStatus(4))
    expect((await stakeMarket.stakeStatus(3)).winnerId).to.equal(4)
    expect((await stakeMarket.stakeStatus(3)).loserId).to.equal(3)
    // await stakeMarket.updateStatusOrAppeal(4, "", "")
    // appeal
    let gas = (await stakeMarket.getStake(3)).bank.paidReceivable * (await stakeMarket.getStake(3)).bank.gasPercent / 10000 + (await stakeMarket.getStake(4)).bank.paidReceivable * (await stakeMarket.getStake(4)).bank.gasPercent / 10000;
    console.log("gas====================>", gas)
    await ust.connect(owner).approve(stakeMarket.address, gas)
    await expect(stakeMarket.updateStatusOrAppeal(4, "Appeal", "Appealing decision", "")).to.be.reverted; // winner cannot appeal
    await stakeMarket.updateStatusOrAppeal(3, "Appeal", "Appealing decision", "")
    expect((await ust.balanceOf(stakeMarket.address))).to.equal(91) //gasPercent=10% goes to voters
    // vote
    await stakeMarketVoter.vote(1, ve.address, 1, 1, 3, 1);
    // increase time by 2 weeks to pass appeal period
    await network.provider.send("evm_increaseTime", [604800*2])
    await network.provider.send("evm_mine")
    // update 
    await stakeMarketVoter.updateStakeFromVoter(ve.address, 2);
    expect((await stakeMarket.stakeStatus(3)).winnerId).to.equal(3)
    expect((await stakeMarket.stakeStatus(3)).loserId).to.equal(4)
    // attempt appeal after appeal window updates status to peace and does not create any litigation
    expect((await stakeMarket.stakeStatus(3)).status).to.equal(1) //war
    expect(await stakeMarketVoter.litigationId()).to.equal(3) 
    await stakeMarket.updateStatusOrAppeal(3, "", "", "")
    expect((await stakeMarket.stakeStatus(3)).status).to.equal(0) //peace
    expect(await stakeMarketVoter.litigationId()).to.equal(3) // same litigation id
    let userBalanceBefore = await ust.balanceOf(owner.address)
    // unlock stake
    await stakeMarket.unlockStake(3, 0, false);
    // check state
    console.log("stakes(3) after ===============>", (await stakeMarket.getStake(3)).ownerAgreement, (await stakeMarket.getStake(3)).bank.amountPayable, (await stakeMarket.getStake(3)).bank.amountReceivable)
    console.log("stakes(4) after ===============>", (await stakeMarket.getStake(4)).ownerAgreement, (await stakeMarket.getStake(4)).bank.amountPayable, (await stakeMarket.getStake(4)).bank.amountReceivable)
    console.log("user balance after ===============>", await ust.balanceOf(owner.address), await ust.balanceOf(stakeMarket.address))
    expect((await stakeMarket.getStake(3)).ownerAgreement).to.equal(2)
    expect((await stakeMarket.getStake(4)).ownerAgreement).to.equal(2)
    expect((await stakeMarket.getStake(3)).bank.amountReceivable).to.equal(0)
    expect((await stakeMarket.getStake(3)).bank.amountPayable).to.equal(100)
    expect((await stakeMarket.getStake(4)).bank.amountReceivable).to.equal(100)
    expect((await stakeMarket.getStake(4)).bank.amountPayable).to.equal(0) 
    console.log("====================>", (await ust.balanceOf(owner.address)), userBalanceBefore)
    console.log("====================>", userBalanceBefore.gt((await ust.balanceOf(owner.address))))
    console.log("====================>", userBalanceBefore.eq((await ust.balanceOf(owner.address))))
    expect((await ust.balanceOf(owner.address))).to.equal(userBalanceBefore.add(91)) // 10% of the 100 went to voters when creating gauge
    expect((await ust.balanceOf(stakeMarket.address))).to.equal(0)
    expect((await stakeMarketNote.getDuePayable(3,0))[0]).to.equal(9)
    console.log("duePayable3===============>", await stakeMarketNote.getDuePayable(3,0))
    console.log("duePayable4===============>", await stakeMarketNote.getDuePayable(4,0))

  }).timeout(10000000);

  it("8) create and set up valuepool", async function () {
    await vavaFactory.createValuePool(
      ust.address,
      owner.address,
      marketPlaceTrades.address,
      false,
      false
    )
    let vavaAddress = (await vavaHelper.getAllVavas(0))[0]
    vava = Vava.attach(vavaAddress)
    console.log("vava===>", vavaAddress, vava.address)
    expect(vavaAddress).to.equal(vava.address)
    await veFactory.createVe(ust.address, vavaAddress, false)
    let vaAddress = await vava._ve()
    va = Va.attach(vaAddress)
    expect(vaAddress).to.equal(va.address)
    console.log("va===>", vaAddress, va.address)
    await va.setParams(
      "vaNFT", 
      "vaNFT", 
      18,
      0,
      ethers.BigNumber.from("1000000000000000000"),
      ethers.BigNumber.from("1000000000000000000"),
      0,
      true
    )
    
    await ust.connect(owner).approve(va.address, ethers.BigNumber.from("100000000000000000"));
    expect(await va.balanceOfNFT(1)).to.equal(0)
    await va.create_lock_for(ethers.BigNumber.from("100000000000000000"), 4 * 365 * 86400, 0, owner.address)
    expect(await va.balanceOfNFT(1)).to.not.equal(0)
    console.log("va balance===>", await va.balanceOfNFT(1))
  }).timeout(10000000);

  it("9) create bounty & add balance", async function () {
    await trustBounties.createBounty(
      owner.address,
      ust.address,
      ve.address,
      "0x0000000000000000000000000000000000000000",
      0,
      1,
      86700 * 7 * 4,
      0,
      false,
      "http://link-to-avatar.com",
      "1"
    )
    console.log("trustBounties===========>", await trustBounties.getBalance(1))
    console.log("bountyInfo===========>", await trustBounties.bountyInfo(1))
    expect((await trustBounties.bountyInfo(1)).owner).to.equal(owner.address);

    await ust.connect(owner).approve(trustBountiesHelper.address, 10)
    await trustBounties.addBalance(
      1, 
      trustBounties.address,
      0, 
      10
    )
    console.log("balance===========>", await trustBounties.getBalance(1))
    expect(await trustBounties.getBalance(1)).to.equal(10);

  }).timeout(10000000);

  it("10) Create and Add sponsor", async function () {
    await sponsorFactory.createGauge(1, owner.address)
    let sponsorAddress = (await sponsorNote.getAllSponsors(0))[0]
    console.log("sponsor=============>", sponsorAddress)
    const Sponsor = await ethers.getContractFactory("Sponsor");
    sponsor = Sponsor.attach(sponsorAddress)
    await sponsor.updateContents("nsfw", true)
    expect(sponsor.address).to.equal(sponsorAddress)
    
    sponsor.updateBounty(1)
    
    await ust.mint(sponsor.address, ethers.BigNumber.from("1000000000000000000"));
    await sponsor.updateProtocol(
      vava.address,
      ust.address,
      ethers.BigNumber.from("1000000000000000000"),
      0,
      0,
      0,
      0,
      "https://link.to.media.com",
      "sponsor description"
    )
    console.log("protocol=============>", await sponsor.protocolInfo(1))
    expect((await sponsor.protocolInfo(1)).amountPayable).to.equal(ethers.BigNumber.from("1000000000000000000"))
    await vava.addSponsor(sponsor.address, 1, 0)
    console.log("vava sponsors=============>", await vava.sponsors(sponsor.address))
    console.log("due============>", await sponsorNote.getDuePayable(sponsor.address, vava.address, 0))
    expect((await sponsorNote.getDuePayable(sponsor.address, vava.address, 0))[0]).to.equal(ethers.BigNumber.from("1000000000000000000"))
    await vava.notifyPayment(sponsor.address)
    console.log("due============>", await sponsorNote.getDuePayable(sponsor.address, vava.address, 0))
    expect((await sponsorNote.getDuePayable(sponsor.address, vava.address, 0))[0]).to.equal(0)

  }).timeout(10000000);

  it("11) buy item with valuepool", async function () {
    await vava.pickRank(1, 0)
    await vavaHelper.checkRank(
      vava.address, 
      owner.address, 
      "0x0000000000000000000000000000000000000000", 
      "uber", 
      [],
      [0, 0, 0, 1, 100]
    )
    console.log("vava userinfo===========>", await vava.userInfo(1))
    console.log("va percentile===========>", await va.percentiles(1))
    console.log("scheduled purchase===========>", await vava.scheduledPurchases(1,1))
    rank = (await vava.scheduledPurchases(1,1)).rank
    console.log("rank, queue before===========>", rank, await vava.getQueue(rank))
    console.log("getSupplyAvailable===========>", await vavaHelper.getSupplyAvailable(vava.address))
    expect((await vava.getQueue(rank)).length).to.equal(1);
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(2);
    await vava.executeNextPurchase()
    expect((await vava.getQueue(rank)).length).to.equal(0);
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(3);
    console.log("rank, queue after===========>", rank, await vava.getQueue(rank))

  }).timeout(10000000);

  it("12) add identityproof", async function () {
    await marketPlaceOrders.modifyAskOrderIdentity(
      "uber",
      "testify_age",
      "gt_18",
      false,
      false,
      100,
      0
    )
  }).timeout(10000000);

  it("13) buy with identityproof", async function () {
    await ust.connect(owner).approve(marketPlaceTrades.address, 10);
    await ssi.updateAuthorization(1, 1, true);
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(3);
    await expect(marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      "0x0000000000000000000000000000000000000000",
      "uber",
      0,
      0,
      []
    )).to.be.reverted;
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(3);

    console.log("profile id==============>", await profile.addressToProfileId(owner.address))

    // mint identity proof
    await ssi.generateIdentityProof(
      owner.address,
      1,
      1,
      86700 * 7 * 4,
      "testify_age",
      "gt_15"
    )
    console.log("metadata==============>", await ssi.metadata(2))

    await expect(marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      "0x0000000000000000000000000000000000000000",
      "uber",
      0,
      1,
      []
    )).to.be.reverted;
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(3);

    // mint identity proof
    await ssi.generateIdentityProof(
      owner.address,
      1,
      1,
      86700 * 7 * 4,
      "testify_age",
      "gt_18"
    )
    console.log("metadata==============>", await ssi.metadata(3))

    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      "0x0000000000000000000000000000000000000000",
      "uber",
      0,
      3,
      []
    )
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(4);

  }).timeout(10000000);

  it("14) add unique accounts", async function () {
    await marketPlaceOrders.modifyAskOrderIdentity(
      "uber",
      "testify_age",
      "gt_18",
      false,
      false,
      1,
      0
    )

    await ust.connect(owner).approve(marketPlaceTrades.address, 10);
    await expect(marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      "0x0000000000000000000000000000000000000000",
      "uber",
      0,
      3,
      []
    )).to.be.reverted;
    
    // mint identity proof
    await ssi.connect(owner2).updateAuthorization(2, 1, true);
    await ssi.generateIdentityProof(owner2.address,2,1,86700 * 7,"ssid","owner2")
    await ssi.generateIdentityProof(
      owner2.address,
      2,
      1,
      86700 * 7 * 4,
      "testify_age",
      "gt_18"
    )
    await ssi.connect(owner2).updateSSID(2,4)
    await profile.connect(owner2).updateSSID()
    await ust.connect(owner2).approve(marketPlaceTrades.address, 100);
    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner2.address,
      "0x0000000000000000000000000000000000000000",
      "uber",
      0,
      5,
      []
    )

    // add account to profile
    await profile.addAccount(1, owner3.address)
    expect((await profile.addressToProfileId(owner3.address))).to.equal(1);

    // fails because the ssid attached to token id 5 has already been used
    await expect(marketPlaceTrades.connect(owner2).buyWithContract(
      owner.address,
      owner2.address,
      "0x0000000000000000000000000000000000000000",
      "uber",
      0,
      5,
      []
    )).to.be.reverted;
    
  }).timeout(10000000);

  it("15) Modify Ask order", async function () {
    console.log("ask order before=============>", await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96'))
    await marketPlaceOrders.modifyAskOrder(
      owner.address,
      "uber",
      11,
      0,
      0,
      true,
      true,
      0,
      11,
      0
    )
    expect((await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).price).to.equal(11)
    expect((await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).maxSupply).to.equal(11)

  }).timeout(10000000);

  it("16) Buy with options", async function () {
    await marketPlaceHelper.updateOptions(
      "uber",
      [0,0],
      [10,10],
      [1,2],
      ["meat","meat"],
      ["1$ Tilapia","2$ Tilapia"],
      ["meat","meat"],
      ["1$ Tilapia", "2$ Tilapia"],
      ["#","#"]
    )
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[0]).to.equal(11)
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[1]).to.equal(false)
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0],0,11))[0]).to.equal(12)
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0],0,11))[1]).to.equal(false)
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[1],0,11))[0]).to.equal(13)
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[1],0,11))[1]).to.equal(false)
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0,1],0,11))[0]).to.equal(14)
    await expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0,1],0,11))[1]).to.equal(false)
  
  })

  it("17) Buy discounted with account limits", async function () {
    await marketPlaceOrders.modifyAskOrderIdentity(
      "uber",
      "testify_age",
      "gt_18",
      false,
      false,  
      100,// turn off unique accounts
      0
    )
    const cursor = (await nfticket.ticketInfo_(1)).date
    await marketPlaceOrders.modifyAskOrderDiscountPriceReductors(
      "uber",
      1,   
      0,   
      false,
      false,
      false,
      [cursor,cursor.add(86700),1000,0,1000000,1],
      [cursor,cursor.add(86700),1000,0,1000000,1],
    )
    console.log("ask order discount=============>", (await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).priceReductor)
    console.log("cursor=======>", cursor)
    console.log("nft1==========>", await nfticket.getUserTicketsPagination(
      owner.address, 
      1, 
      cursor,
      cursor.add(86700),
      "uber"
    ))
    console.log("nft2==========>", await nfticket.getUserTicketsPagination(
      owner.address, 
      1, 
      0,
      0,
      "uber"
    ))
    expect((await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).priceReductor.discountStatus).to.equal(1)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[0]).to.equal(9) //2% discount
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[1]).to.equal(true)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0],0,11))[0]).to.equal(10) //2% discount
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0],0,11))[1]).to.equal(true)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[1],0,11))[0]).to.equal(11) //2% discount
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[1],0,11))[1]).to.equal(true)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0,1],0,11))[0]).to.equal(12) //2% discount
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[0,1],0,11))[1]).to.equal(true)

    console.log("real price after discount=============>", await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))

    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(4);
    await ust.approve(marketPlaceTrades.address, 12);
    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      "0x0000000000000000000000000000000000000000", 
      "uber",
      0,
      3,
      [0,1]
    );
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(5);
    console.log("nfticket 6==================>", await nfticket.ticketInfo_(6))
    console.log("nfticket.isPaywall============>", await nfticket.isPaywall(6))
    console.log("marketPlaceHelper.getOptions============>", await marketPlaceHelper.getOptions(1,"uber",[0]))
    console.log("marketPlaceHelper.getOptions============>", await marketPlaceHelper.getOptions(1,"uber",[0,0]))
    console.log("marketPlaceHelper.getOptions============>", await marketPlaceHelper.getOptions(1,"uber",[1,1]))
    console.log("nfticketHelper2.getTicketOptions============>", await nfticketHelper2.getTicketOptions(6))
    console.log("nfticketHelper2.tokenURI============>", await nfticketHelper2.tokenURI(6))
    console.log("real price after discount limit=============>", await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[0]).to.equal(11) //discount no longer available
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[1]).to.equal(false) //discount no longer available
  }).timeout(10000000);

  it("18) Reinitialize discounts w/o identity", async function () {
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[0]).to.equal(11) //2% discount no more available
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[1]).to.equal(false)
    await marketPlaceTrades.reinitializeDiscountLimits("uber")
    await marketPlaceTrades.reinitializeCashbackLimits("uber")
    await marketPlaceTrades.updateVersion(1, "uber", owner.address)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[0]).to.equal(9) //2% discount available again
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))[1]).to.equal(true)

  }).timeout(10000000);

  it("19) Buy discounted with identity limits", async function () {
    const cursor = (await nfticket.ticketInfo_(1)).date
    await marketPlaceOrders.modifyAskOrderDiscountPriceReductors(
      "uber",
      1,   
      0,   
      false,
      false,
      true,
      [cursor,cursor.add(86700),1000,0,1000000,1],
      [cursor,cursor.add(86700),1000,0,1000000,1],
    )
    console.log("real price before discount account limits=============>", await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],0,11))
    console.log("real price before discount account limits=============>", await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],2,11))
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[0]).to.equal(9) //2% discount
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[1]).to.equal(true)

    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(5);
    await ust.connect(owner).approve(marketPlaceTrades.address, 9);
    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      "0x0000000000000000000000000000000000000000", 
      "uber",
      0,
      3,
      []
    );
    
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(6);
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[0]).to.equal(11) //discount no longer available
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[1]).to.equal(false)
  }).timeout(10000000);

  it("20) Receive cashback with account limits", async function () {
    const cursor = (await nfticket.ticketInfo_(1)).date
    await marketPlaceOrders.modifyAskOrderCashbackPriceReductors(
      "uber",
      1,   
      0,   
      true,
      false,
      [cursor,cursor.add(86700),1000,0,1000000,1],
      [cursor,cursor.add(86700),1000,0,1000000,1],
    )
    console.log("ask order cashback=============>", (await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).priceReductor)
    console.log("payment credits============>", await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber"))
    await marketPlaceTrades.processCashBack(
      owner.address, 
      "uber",
      true,
      "uber"
    )
    console.log("payment credits after============>", await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber"))
    console.log("merch==========>", await nfticket.getMerchantTicketsPagination(
      1, 
      cursor,
      cursor.add(86700),
      "uber"
    ))
    console.log("nft==========>", await nfticket.getUserTicketsPagination(
      owner.address, 
      1, 
      cursor,
      cursor.add(86700),
      "uber"
    ))
    expect(await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber")).to.equal(4)
    await expect(marketPlaceTrades.processCashBack(
      owner.address, 
      "uber",
      true,
      "uber"
    )).to.be.reverted
    
  }).timeout(10000000);
  
  it("21) Reinitialize discounts w/ identity", async function () {
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[0]).to.equal(11) //discount no longer available
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[1]).to.equal(false)
    await marketPlaceTrades.reinitializeIdentityLimits("uber")
    await marketPlaceTrades.updateIdVersion(1, "uber", 3)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[0]).to.equal(9) //2% discount available again
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,11))[1]).to.equal(true)
  }).timeout(10000000);

  it("22) Receive cashback lowerbound", async function () {
    const cursor = (await nfticket.ticketInfo_(6)).date
    await marketPlaceOrders.modifyAskOrderCashbackPriceReductors(
      "uber",
      1,   
      0,   
      false,
      false,
      [cursor,cursor.add(86700),1000,1,1000000,1],
      [cursor,cursor.add(86700),1000,1,1000000,1],
    )

    console.log("ask order cashback with id=============>", (await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).priceReductor)
    console.log("payment credits before lb============>", await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber"))
    await expect(marketPlaceTrades.processCashBack(
      owner.address, 
      "uber",
      true,
      "uber"
    )).to.be.reverted
    
    await marketPlaceTrades.reinitializeCashbackLimits("uber")
    await marketPlaceTrades.updateVersion(1, "uber", owner.address)

    await marketPlaceTrades.processCashBack(
      owner.address, 
      "uber",
      true,
      "uber"
    )

    console.log("payment credits after lb============>", await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber"))
    console.log("merch==========>", await nfticket.getMerchantTicketsPagination(
      1, 
      cursor,
      cursor.add(86700),
      "uber"
    ))
    console.log("nft==========>", await nfticket.getUserTicketsPagination(
      owner.address, 
      1, 
      cursor,
      cursor.add(86700),
      "uber"
    ))
  }).timeout(10000000);

  it("23) Receive cashback in cash", async function () {
    // increase time so cashback can be updated
    await network.provider.send("evm_increaseTime", [86700])
    await network.provider.send("evm_mine")

    const cursor = (await nfticket.ticketInfo_(6)).date
    await marketPlaceOrders.modifyAskOrderCashbackPriceReductors(
      "uber",
      1,   
      0,   
      false,
      true,
      [cursor,cursor.add(86700),1000,1,1000000,2], //increase limit so users who benefited from last offer are still eligible
      [cursor,cursor.add(86700),1000,1,1000000,2],
    )
    let userBalanceBefore = await ust.balanceOf(owner.address)
    await marketPlaceTrades.processCashBack(
      owner.address, 
      "uber",
      false, // withdraw cash
      "uber"
    )
    console.log("balance before===========>", userBalanceBefore)
    console.log("balance after===========>", await ust.balanceOf(owner.address))
    expect((await ust.balanceOf(owner.address))).to.equal(userBalanceBefore.add(4));

  }).timeout(10000000);

  it("24) Register user with identity limits", async function () {
    // first add user identity req to collection
    await marketPlaceCollection.modifyIdentityProof(
      owner.address,
      "testify_age",
      "gt_18",
      false,
      1,
      false,
      true,
      0
    )
    console.log("metadata5===========>", await ssi.getSSIData(5))
    console.log("metadata3===========>", await ssi.getSSIData(3))
    // await expect(marketPlaceEvents.emitUserRegistration(1, 1, 5, 1, true)).to.be.reverted
    // await expect(marketPlaceEvents.emitUserRegistration(1, 1, 5, 0, true)).to.be.reverted
    await marketPlaceHelper3.emitUserRegistration(1, 1, 3, 1, true)
  }).timeout(10000000);

  it("25) Add referral with identity limits", async function () {
    // first add partner identity req to collection
    await marketPlaceCollection.modifyIdentityProof(
      owner.address,
      "testify_age",
      "gt_18",
      false,
      100,
      false,
      false,
      0
    )

    await expect(marketPlaceOrders.addReferral(
      owner.address,
      owner.address,
      "uber",
      [0,1,0]
    )).to.be.reverted

    // add min bounty to collection
    await marketPlaceCollection.modifyCollection(
      owner.address,
      1000,
      0,
      0,
      10,
      0,
      false,
      false
    )

    await marketPlaceOrders.addReferral(
      owner.address,
      owner.address,
      "uber",
      [1000,0,3]
    )
  }).timeout(10000000);

  it("26) Add referral with min bounty", async function () {
    // add min bounty to collection
    await marketPlaceCollection.modifyCollection(
      owner.address,
      1000,
      0,
      10,
      10,
      0,
      false,
      false
    )
    
    await marketPlaceOrders.addReferral(
      owner.address,
      owner.address,
      "uber",
      [1000,1,3]
    )
  }).timeout(10000000);

  it("27) create recurring bounty & add balance", async function () {
    await trustBounties.createBounty(
      owner.address,
      ust.address,
      ve.address,
      "0x0000000000000000000000000000000000000000",
      0,
      10,
      86700 * 7 * 4,
      0,
      true,
      "http://link-to-avatar.com",
      "1"
    )
    console.log("trustBounties===========>", await trustBounties.getBalance(2))
    console.log("bountyInfo===========>", await trustBounties.bountyInfo(2))
    expect((await trustBounties.bountyInfo(2)).owner).to.equal(owner.address);

    await ust.connect(owner).approve(trustBountiesHelper.address, 10)
    await trustBounties.addBalance(
      2, 
      trustBounties.address,
      0, 
      10
    )
    console.log("balance===========>", await trustBounties.getBalance(2))
    expect(await trustBounties.getBalance(2)).to.equal(10);
  }).timeout(10000000);

  it("28) Add referral with recurring bounty", async function () {
    // add min bounty to collection
    await marketPlaceCollection.modifyCollection(
      owner.address,
      1000,
      0,
      10,
      10,
      1000,
      false,
      false
    )

    await marketPlaceOrders.modifyAskOrder(
      owner.address,
      "uber",
      100,
      0,
      0,
      true,
      true,
      0,
      10,
      0
    )

    await expect(marketPlaceOrders.addReferral(
      owner.address,
      owner.address,
      "uber",
      [1000,1,3]
    )).to.be.reverted
    
    await marketPlaceOrders.addReferral(
      owner.address,
      owner.address,
      "uber",
      [1000,2,3]
    )
  }).timeout(10000000);

  it("29) create gauge", async function () {
    await businessVoter.createGauge(ve.address)
    // await referralVoter.createGauge(ve.address)

    gauge = await businessVoter.gauges(1,ve.address)
    // gauge2 = await referralVoter.gauges(1,ve.address)
    
    console.log("gauge==================>", gauge)
    // console.log("gauge2==================>", gauge2)
    console.log("bribe==================>", await businessVoter.bribes(gauge))
    // console.log("bribe2==================>", await referralVoter.bribes(gauge2))
    console.log("poolForGauge==================>", await businessVoter.poolForGauge(gauge))
    // console.log("poolForGauge2==================>", await referralVoter.poolForGauge(gauge2))
    console.log("isGauge==================>", await businessVoter.isGauge(gauge))
    // console.log("isGauge2==================>", await referralVoter.isGauge(gauge2))
    console.log("pools==================>", await businessVoter.pools(ve.address,0))
    // console.log("pools2==================>", await referralVoter.pools(ve.address,0))

    businessBribe = BusinessBribe.attach(await businessVoter.bribes(gauge))
    businessGauge = BusinessGauge.attach(gauge)

    // referralBribe = ReferralBribe.attach(await referralVoter.bribes(gauge2))
    // referralGauge = BusinessGauge.attach(gauge2)

    expect(gauge).to.not.equal("0x0000000000000000000000000000000000000000")
    // expect(gauge2).to.not.equal("0x0000000000000000000000000000000000000000")
    expect(await businessVoter.bribes(gauge)).to.not.equal("0x0000000000000000000000000000000000000000")
    // expect(await referralVoter.bribes(gauge2)).to.not.equal("0x0000000000000000000000000000000000000000")
    expect(await businessVoter.poolForGauge(gauge)).to.equal(1)
    // expect(await referralVoter.poolForGauge(gauge2)).to.equal(1)
    expect(await businessVoter.isGauge(gauge)).to.equal(true)
    // expect(await referralVoter.isGauge(gauge2)).to.equal(true)
    expect((await businessVoter.pools(ve.address,0))).to.equal(1)
    // expect((await referralVoter.pools(ve.address,0))).to.equal(1)

  }).timeout(10000000);

  it("30) Effects of Buy - vote/nfticket/lottery/treasury/cashbackfund/recurring revenue ", async function () {
    await ust.connect(owner).approve(marketPlaceTrades.address, 100);
    await marketPlaceCollection.updateParams(1000, 1000, 50)
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(1);
    expect(await marketPlaceTrades.recurringBountyBalance(1,ust.address)).to.equal(0);
    expect(await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber")).to.equal(8)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner.address,"uber",[],3,100))[0]).to.equal(80)
    expect(await marketPlaceTrades.pendingRevenue(ust.address,1)).to.equal(65)
    expect(await marketPlaceTrades.lotteryRevenue(ust.address)).to.equal(0)
    expect(await marketPlaceTrades.cashbackFund(ust.address,1)).to.equal(0)
    expect(await businessBribe.ownerOf(2)).to.equal("0x0000000000000000000000000000000000000000")
    expect(await businessBribe.balanceOf(2)).to.equal(0)
    expect(await businessVoter.weights(1,ve.address)).to.equal(0)
    console.log("createAccount==================>", await profile.addressToProfileId(owner.address), await profile.addressToProfileId(owner2.address))
    await ssi.createAccount(1,"publicKey","encyptedPrivateKey")
    // console.log("referrer==============>", await ssi.referrer(3))
    expect(await businessBribe.ownerOf(2)).to.equal("0x0000000000000000000000000000000000000000")
    expect(await businessBribe.balanceOf(2)).to.equal(0)
    expect(await businessVoter.weights(1,ve.address)).to.equal(0)

    await referralVoter.createGauge(ve.address)
    gauge2 = await referralVoter.gauges(1,ve.address)
    console.log("gauge2==================>", gauge2)
    console.log("bribe2==================>", await referralVoter.bribes(gauge2))
    console.log("poolForGauge2==================>", await referralVoter.poolForGauge(gauge2))
    console.log("isGauge2==================>", await referralVoter.isGauge(gauge2))
    console.log("pools2==================>", await referralVoter.pools(ve.address,0))
    console.log("lotteryCredits==============>", await nfticketHelper.lotteryCredits(owner.address, ve.address))
    console.log("lotteryCredits==============>", await nfticketHelper.lotteryCredits(owner.address, ust.address))
    referralBribe = ReferralBribe.attach(await referralVoter.bribes(gauge2))
    expect(gauge2).to.not.equal("0x0000000000000000000000000000000000000000")
    expect(await referralVoter.bribes(gauge2)).to.not.equal("0x0000000000000000000000000000000000000000")
    expect(await referralVoter.poolForGauge(gauge2)).to.equal(1)
    expect(await referralVoter.isGauge(gauge2)).to.equal(true)
    expect((await referralVoter.pools(ve.address,0))).to.equal(1)
    expect(await referralVoter.weights(2,ve.address)).to.equal(0)
    expect(await referralVoter.pools(ve.address,0)).to.equal(1)
    expect(await nfticketHelper.lotteryCredits(owner.address, ust.address)).to.equal(0)
    await ve.transferFrom(owner.address,owner2.address,1)
    await ssi.transferFrom(owner.address,owner2.address,3)
    await marketPlaceTrades.connect(owner2).buyWithContract(
      owner.address,
      owner2.address,
      owner.address,
      "uber",
      1,
      3,
      []
    );
    console.log("referrerFromAddress============>", await profile.referrerFromAddress(owner2.address))
    console.log("weights============>", await businessVoter.weights(1,ve.address))
    console.log("balanceOf============>", await businessBribe.balanceOf(1))
    console.log("ownerOf============>", await businessBribe.ownerOf(1))
    console.log("weights2============>", await referralVoter.weights(1,ve.address))
    console.log("balanceOf2============>", await referralBribe.balanceOf(1))
    let refAddress = await profileHelper.getAccountAt(1,0)
    console.log("lotteryCredits2==============>", await nfticketHelper.lotteryCredits(owner2.address, ust.address), refAddress)

    expect(await nfticketHelper.lotteryCredits(owner2.address, ust.address)).to.equal(8)
    expect(await referralVoter.weights(1,ve.address)).to.not.equal(0)
    expect(await referralBribe.balanceOf(1)).to.not.equal(0)
    expect(await businessBribe.balanceOf(1)).to.not.equal(0)
    expect(await businessBribe.ownerOf(1)).to.equal(refAddress)
    expect(await businessVoter.weights(1,ve.address)).to.not.equal(0)
    expect(await marketPlaceOrders.getPaymentCredits(owner2.address,1,"uber")).to.equal(0)
    expect(await marketPlaceTrades.recurringBountyBalance(1,ust.address)).to.equal(8);
    expect(await marketPlaceTrades.pendingRevenue(ust.address,1)).to.equal(112) //65 + 8 + 39 (netPrice + referrerFee)
    expect((await marketPlaceHelper.getRealPrice(owner.address,owner2.address,"uber",[],3,100))[0]).to.equal(100)
    expect(await marketPlaceTrades.lotteryRevenue(ust.address)).to.equal(8)
    expect(await marketPlaceTrades.cashbackFund(ust.address,1)).to.equal(9)
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(2);
    // reset
    // await ve.connect(owner2).transferFrom(owner2.address,owner.address,1)
    await ssi.connect(owner2).transferFrom(owner2.address,owner.address,3)

  }).timeout(10000000);

  it("31) Mint external nfticket", async function () {
    await marketPlaceHelper.mintNFTicket(
      owner.address, 
      "0x0000000000000000000000000000000000000000",
      "uber", 
      [1,2]
    )
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(7);
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(2);
    console.log("external tickets================>", await nfticket.ticketInfo_(9))
  }).timeout(10000000);

  it("32) Burn FT for credit", async function () {
    await marketPlaceHelper.updateBurnTokenForCredit(
      ust.address,
      "0x0000000000000000000000000000000000000000",
      marketPlaceOrders.address,
      1000,
      1,
      false,
      "uber"
    )
    
    console.log("payment credits before============>", await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber"))
    console.log("ust.balanceOf============>", await ust.balanceOf(marketPlaceTrades.address))
    expect(await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber")).to.equal(8)
    marketPlaceOrdersBalanceBefore = await ust.balanceOf(marketPlaceOrders.address)
    expect(marketPlaceOrdersBalanceBefore).to.equal(0)
    await ust.approve(marketPlaceHelper.address, 100);
    await marketPlaceHelper.burnForCredit(
      owner.address, 
      0, 
      100,
      "uber"
    )
    console.log("payment credits after============>", await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber"))
    expect(await marketPlaceOrders.getPaymentCredits(owner.address,1,"uber")).to.equal(18)
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(2);
    expect(await ust.balanceOf(marketPlaceOrders.address)).to.equal(marketPlaceOrdersBalanceBefore.add(100))

  }).timeout(10000000);

  it("33) Burn NFT for credit", async function () {
    await marketPlaceHelper.updateBurnTokenForCredit(
      nfticketHelper2.address, 
      nfticketHelper.address, 
      marketPlaceTrades.address,
      20000,
      1,
      false,
      "uber"
    )
    
    console.log("payment credits before============>", await marketPlaceOrders.getPaymentCredits(owner2.address,1,"uber"))
    console.log("nfticket==============>", await nfticket.ticketInfo_(9))
    console.log("burnTokenForCredit============>", await marketPlaceHelper.burnTokenForCredit(1,1))
    expect(await marketPlaceOrders.getPaymentCredits(owner2.address,1,"uber")).to.equal(0)
    await nfticketHelper2.transferFrom(owner.address, owner2.address, 9)
    await nfticketHelper2.connect(owner2).approve(marketPlaceHelper.address, 9);
    sellerBalanceBefore = await nfticketHelper2.balanceOf(owner.address)
    console.log("nfticket balance before==============>", await nfticketHelper2.balanceOf(owner.address))
    await marketPlaceHelper.connect(owner2).burnForCredit(
      owner.address, 
      1, 
      9,
      "uber"
    )
    console.log("payment credits after============>", await marketPlaceOrders.getPaymentCredits(owner2.address,1,"uber"))
    expect(await marketPlaceOrders.getPaymentCredits(owner2.address,1,"uber")).to.equal(2)
    expect(await nfticketHelper2.balanceOf(owner.address)).to.equal(sellerBalanceBefore)
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    console.log("nfticket balance after==============>", await nfticketHelper2.balanceOf(owner.address))

  }).timeout(10000000);

  it("34) Sponsor tag", async function () {
    // set up price
    await nfticketHelper.updatePricePerAttachMinutes(1)
    await nfticketHelper.updateTag("uber", "devices")

    await ust.approve(nfticketHelper.address, 10);
    await nfticketHelper.sponsorTag(
      sponsor.address,
      1, 
      10, 
      "devices", 
      "https://www.youtube.com/embed/e8mpj7fG7PI"
    )

    expect((await nfticketHelper.scheduledMedia(1)).amount).to.equal(10)
    expect((await nfticketHelper.scheduledMedia(1)).message).to.equal("https://www.youtube.com/embed/e8mpj7fG7PI")
    console.log("scheduledMedia============>", await nfticketHelper.scheduledMedia(1))
      
    await nfticketHelper.updateExcludedContent("devices", "nsfw", true)
    await ust.approve(nfticketHelper.address, 10);
    await expect(nfticketHelper.sponsorTag(
      sponsor.address,
      1, 
      10, 
      "devices", 
      "https://www.youtube.com/embed/e8mpj7fG7PI"
    )).to.be.reverted
    
    console.log("tokenURI=============================>", await nfticketHelper2.tokenURI(1))
  }).timeout(10000000);

  it("35) claimPendingRevenue", async function () {
    console.log("collection===================>", await marketPlaceCollection.getCollection(1))
    console.log("pendingRevenue======================>", await marketPlaceTrades.pendingRevenue(ust.address,1))
    expect(await marketPlaceTrades.pendingRevenue(ust.address,1)).to.equal(112)
    ustBalanceBefore = await ust.balanceOf(owner.address)
    await marketPlaceTrades.claimPendingRevenue(ust.address, owner.address, 2)
    expect(await marketPlaceTrades.pendingRevenue(ust.address,1)).to.equal(0)
    expect(await await ust.balanceOf(owner.address)).to.equal(ustBalanceBefore.add(112))

  }).timeout(10000000);

  it("36) claimTreasuryRevenue", async function () {
    console.log("treasuryRevenue======================>", await marketPlaceTrades.treasuryRevenue(ust.address))
    expect(await marketPlaceTrades.treasuryRevenue(ust.address)).to.equal(14)
    ustBalanceBefore = await ust.balanceOf(owner.address)
    await marketPlaceTrades.claimTreasuryRevenue(ust.address)
    expect(await marketPlaceTrades.treasuryRevenue(ust.address)).to.equal(0)
    expect(await await ust.balanceOf(owner.address)).to.equal(ustBalanceBefore.add(14))

  }).timeout(10000000);

  it("37) Transfer future revenue to note", async function () {
    expect(await marketPlaceTrades.permissionaryNoteTokenId()).to.equal(1)
    await marketPlaceTrades.transferDueToNote(10, 86400)
    expect(await marketPlaceTrades.permissionaryNoteTokenId()).to.equal(2)
    console.log("note================>", await marketPlaceTrades.notes(owner.address))

    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(6);
    console.log("pending from note before==============>", await marketPlaceTrades.pendingRevenueFromNote(ust.address,1))
    expect(await marketPlaceTrades.pendingRevenueFromNote(ust.address,1)).to.equal(0)
    await ust.approve(marketPlaceTrades.address, 100);
    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      owner.address,
      "uber",
      0,
      3,
      []
    );
    console.log("pending from note after==============>", await marketPlaceTrades.pendingRevenueFromNote(ust.address,1))
    expect(await marketPlaceTrades.pendingRevenueFromNote(ust.address,1)).to.equal(0)
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(7);
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    // increase time
    await network.provider.send("evm_increaseTime", [86400])
    await network.provider.send("evm_mine")
    
    await marketPlaceTrades.transferDueToNote(0, 86400)
    expect(await marketPlaceTrades.permissionaryNoteTokenId()).to.equal(3)
    expect(await marketPlaceTrades.pendingRevenueFromNote(ust.address,2)).to.equal(0)
    pendingRevenueBefore = await marketPlaceTrades.pendingRevenue(ust.address,1)
    lotteryRevenueBefore = await marketPlaceTrades.lotteryRevenue(ust.address)
    cashBackBefore = await marketPlaceTrades.cashbackFund(ust.address,1)
    recurringBefore = await marketPlaceTrades.recurringBountyBalance(1,ust.address)
    console.log("pendingRevenue==============>", pendingRevenueBefore)
    console.log("lotteryRevenue==============>", lotteryRevenueBefore)
    console.log("cashbackFund==============>", cashBackBefore)
    console.log("recurring bounty==============>", recurringBefore)
    await ust.approve(marketPlaceTrades.address, 100);
    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      owner.address,
      "uber",
      0,
      3,
      []
    );
    console.log("pendingRevenue after==============>", await marketPlaceTrades.pendingRevenue(ust.address,1))
    console.log("lotteryRevenue after==============>", await marketPlaceTrades.lotteryRevenue(ust.address))
    console.log("cashbackFund after==============>", await marketPlaceTrades.cashbackFund(ust.address,1))
    console.log("recurring bounty after==============>", await marketPlaceTrades.recurringBountyBalance(1,ust.address))
    expect(await marketPlaceTrades.pendingRevenueFromNote(ust.address,2)).to.equal(48)
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(8);
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    expect(await marketPlaceTrades.pendingRevenue(ust.address,1)).to.equal(pendingRevenueBefore.add(10)); //only adds referrer fee
    expect(await marketPlaceTrades.lotteryRevenue(ust.address)).to.equal(lotteryRevenueBefore.add(10));
    expect(await marketPlaceTrades.cashbackFund(ust.address,1)).to.equal(cashBackBefore.add(12));
    expect(await marketPlaceTrades.recurringBountyBalance(1,ust.address)).to.equal(recurringBefore.add(10));

  }).timeout(10000000);

  it("38) Claim Pending from note", async function () {
    console.log("pendingRevenueFromNote======================>", await marketPlaceTrades.pendingRevenueFromNote(ust.address,1))
    pendingRevenueBefore = await marketPlaceTrades.pendingRevenue(ust.address,1)
    expect(await marketPlaceTrades.pendingRevenueFromNote(ust.address,2)).to.equal(48)
    userBalanceBefore = await ust.balanceOf(owner.address)
    await marketPlaceTrades.claimPendingRevenueFromNote(ust.address, 2, 2)
    expect(await marketPlaceTrades.pendingRevenueFromNote(ust.address,2)).to.equal(0)
    expect(await await ust.balanceOf(owner.address)).to.equal(userBalanceBefore.add(48))
    expect(await marketPlaceTrades.pendingRevenue(ust.address,1)).to.equal(pendingRevenueBefore);
  
  }).timeout(10000000);

  it("39) Buy through incrementing auctions", async function () {
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    // create and auction
    await marketPlaceOrders.createAskOrder(
      "Chimpanzee",
      10,
      100000,
      1000,
      true,
      true,
      true,
      0,
      10,
      0,
      ust.address,
      ve.address
    );

    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).lastBidTime).to.equal(0)
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).price).to.equal(10)
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).lastBidder).to.equal("0x0000000000000000000000000000000000000000")
    ownerBalanceBefore = await ust.balanceOf(owner.address)
    marketPlaceTradesBalanceBefore = await ust.balanceOf(marketPlaceTrades.address)
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(8);
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    await ust.approve(marketPlaceHelper.address, 10);
    await marketPlaceTrades.buyWithContract(
      owner.address,
      owner.address,
      owner.address,
      "Chimpanzee",
      0,
      0,
      []
    );
    console.log("======================>", await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41'))
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).lastBidTime).to.not.equal(0)
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).price).to.equal(10)
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).lastBidder).to.equal(owner.address)
    expect(await ust.balanceOf(owner.address)).to.equal(ownerBalanceBefore.sub(10))
    expect(await ust.balanceOf(marketPlaceTrades.address)).to.equal(marketPlaceTradesBalanceBefore.add(10))
    
    owner2BalanceBefore = await ust.balanceOf(owner2.address)
    await ust.connect(owner2).approve(marketPlaceHelper.address, 11);
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    await marketPlaceTrades.connect(owner2).buyWithContract(
      owner.address,
      owner2.address,
      owner.address,
      "Chimpanzee",
      0,
      0,
      []
    );
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).price).to.equal(11)
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).lastBidder).to.equal(owner2.address)
    expect((await marketPlaceOrders.getAskDetails(1,'0x8e0e0aa45bf85bb33dcdbd9fb6b2124c8bf908577980bf95162223176fc90c41')).lastBidTime).to.not.equal(0)
    expect(await ust.balanceOf(owner2.address)).to.equal(owner2BalanceBefore.sub(11))
    expect(await ust.balanceOf(owner.address)).to.equal(ownerBalanceBefore)
    expect(await ust.balanceOf(marketPlaceTrades.address)).to.equal(marketPlaceTradesBalanceBefore.add(11))
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    
    await expect(marketPlaceHelper.connect(owner2).processAuction(
      owner.address,
      owner.address,
      owner2.address,
      "Chimpanzee",
      0,
      []
    )).to.be.reverted;

    // increase time
    await network.provider.send("evm_increaseTime", [100000])
    await network.provider.send("evm_mine")

    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(3);
    await marketPlaceHelper.connect(owner2).processAuction(
      owner.address,
      owner.address,
      owner2.address,
      "Chimpanzee",
      0,
      []
    )
    expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(4);
    expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(8);


    const lastTicket = (await nfticket.ticketID()) - 1
    console.log("tokenURI============================>", await nfticketHelper2.tokenURI(lastTicket))
    console.log("ticketID==================>", lastTicket, await nfticket.ticketInfo_(lastTicket))

  }).timeout(10000000);

  // it("40) Buy through decrementing auctions", async function () {
  //   // create and auction
  //   await marketPlaceOrders.createAskOrder(
  //     "Chimpanzee2",
  //     10,
  //     100000,
  //     -1000,
  //     true,
  //     true,
  //     true,
  //     0,
  //     10,
  //     0,
  //     ust.address,
  //     ve.address
  //   );

  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).lastBidTime).to.equal(0)
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).price).to.equal(10)
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).lastBidder).to.equal("0x0000000000000000000000000000000000000000")
  //   ownerBalanceBefore = await ust.balanceOf(owner.address)
  //   marketPlaceTradesBalanceBefore = await ust.balanceOf(marketPlaceTrades.address)
  //   await ust.approve(marketPlaceHelper.address, 10);
  //   await marketPlaceTrades.buyWithContract(
  //     owner.address,
  //     owner.address,
  //     owner.address,
  //     "Chimpanzee2",
  //     0,
  //     0,
  //     []
  //   );
  //   console.log("======================>", await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc'))
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).lastBidTime).to.not.equal(0)
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).price).to.equal(10)
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).lastBidder).to.equal(owner.address)
  //   expect(await ust.balanceOf(owner.address)).to.equal(ownerBalanceBefore.sub(10))
  //   expect(await ust.balanceOf(marketPlaceTrades.address)).to.equal(marketPlaceTradesBalanceBefore.add(10))
    
  //   owner2BalanceBefore = await ust.balanceOf(owner2.address)
  //   await ust.connect(owner2).approve(marketPlaceHelper.address, 9);
  //   await marketPlaceTrades.connect(owner2).buyWithContract(
  //     owner.address,
  //     owner2.address,
  //     owner.address,
  //     "Chimpanzee2",
  //     0,
  //     0,
  //     []
  //   );
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).price).to.equal(9)
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).lastBidder).to.equal(owner2.address)
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).lastBidTime).to.not.equal(0)
  //   expect(await ust.balanceOf(owner2.address)).to.equal(owner2BalanceBefore.sub(9))
  //   expect(await ust.balanceOf(owner.address)).to.equal(ownerBalanceBefore)
  //   expect(await ust.balanceOf(marketPlaceTrades.address)).to.equal(marketPlaceTradesBalanceBefore.add(9))
    
  //   await expect(marketPlaceHelper.connect(owner2).processAuction(
  //     owner.address,
  //     owner.address,
  //     owner2.address,
  //     "Chimpanzee2",
  //     0,
  //     []
  //   )).to.be.reverted;

  //   // increase time
  //   await network.provider.send("evm_increaseTime", [100000])
  //   await network.provider.send("evm_mine")

  //   expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(4);

  //   await marketPlaceHelper.connect(owner2).processAuction(
  //     owner.address,
  //     owner.address,
  //     owner2.address,
  //     "Chimpanzee2",
  //     0,
  //     []
  //   )
  //   expect((await nfticketHelper2.balanceOf(owner2.address))).to.equal(5);
  //   expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(8);
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x80068e59f2c282b732cc142afe42460324fc89d402d74b8a6aeb9be645e79fcc')).maxSupply).to.equal(9)

  // }).timeout(10000000);

  // it("41) Ask order with drop-in timer", async function () {
  //   // create and auction
  //   await marketPlaceOrders.createAskOrder(
  //     "Chimpanzee3",
  //     10,
  //     0,
  //     0,
  //     true,
  //     true,
  //     true,
  //     0,
  //     10,
  //     100000,
  //     ust.address,
  //     ve.address
  //   );

  //   await ust.approve(marketPlaceTrades.address, 10);
  //   await expect(marketPlaceTrades.buyWithContract(
  //     owner.address,
  //     owner.address,
  //     owner.address,
  //     "Chimpanzee3",
  //     0,
  //     0,
  //     []
  //   )).to.be.reverted;

  //   // increase time
  //   await network.provider.send("evm_increaseTime", [100000])
  //   await network.provider.send("evm_mine")

  //   expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(8);
  //   await marketPlaceTrades.buyWithContract(
  //     owner.address,
  //     owner.address,
  //     owner.address,
  //     "Chimpanzee3",
  //     0,
  //     0,
  //     []
  //   )

  //   expect((await nfticketHelper2.balanceOf(owner.address))).to.equal(9);

  // }).timeout(10000000);

  // it("42) cancelAskOrder", async function () {
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).seller).to.not.equal("0x0000000000000000000000000000000000000000")
  //   await marketPlaceOrders.cancelAskOrder("uber")
  //   console.log("ask order=============>", await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96'))
  //   expect((await marketPlaceOrders.getAskDetails(1,'0x7380266989d9485aa283717a6eb249d7d56d141257e11deabb1a892587361f96')).seller).to.equal("0x0000000000000000000000000000000000000000")
  
  // }).timeout(10000000);

  // it("43) closeCollectionForTradingAndListing", async function () {
  //   expect(await marketPlaceCollection.addressToCollectionId(owner.address)).to.equal(1)
  //   expect((await marketPlaceCollection.getCollection(1)).status).to.equal(1)
  //   await marketPlaceCollection.closeCollectionForTradingAndListing(owner.address)
  //   expect(await marketPlaceCollection.addressToCollectionId(owner.address)).to.equal(0)
  //   expect((await marketPlaceCollection.getCollection(1)).status).to.equal(2)

  // }).timeout(10000000);
  
  // // it("44) closeReferral", async function () {


  // // }).timeout(10000000);

});