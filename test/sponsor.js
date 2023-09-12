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
  let auditorHelper;
  let auditorFactory;
  let auditor;
  let trustBounties;
  let businessGaugeFactory;
  let businessBribeFactory;
  let businessVoter;
  let businessMinter;
  let gauge;
  let businessBribe;
  let BusinessBribe;
  let BusinessGauge;
  let businessGauge;
  let contentTypes;

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

  auditorHelper2 = await AuditorHelper2.deploy();
  await auditorHelper2.deployed()

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

  auditorFactory = await AuditorFactory.deploy()
  await auditorFactory.deployed()

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

  await auditorHelper2.setContractAddress(contractAddresses.address)
  console.log("auditorHelper2.setContractAddress===========> Done!")

  await auditorFactory.setContractAddress(contractAddresses.address)
  console.log("auditorFactory.setContractAddress===========> Done!")

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

  await contractAddresses.setAuditorHelper2(auditorHelper2.address)
  console.log("contractAddresses.setAuditorHelper2===========> Done!")

  await contractAddresses.setAuditorFactory(auditorFactory.address)
  console.log("contractAddresses.setAuditorFactory===========> Done!")

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
  });

  it("02) create lock", async function () {
    let ve_underlying_amount = ethers.BigNumber.from("1000000000000000000000");
    await ve_underlying.approve(ve.address, ve_underlying_amount);
    const lockDuration = 7 * 24 * 3600; // 1 week

    // Balance should be zero before and 1 after creating the lock
    expect(await ve.balanceOf(owner.address)).to.equal(0);
    await ve.create_lock(ve_underlying_amount, lockDuration);
    expect(await ve.ownerOf(1)).to.equal(owner.address);
    expect(await ve.balanceOf(owner.address)).to.equal(1);
  }).timeout(10000000);

  it("3) create sponsor", async function () {
    // create profile
    await profile.createSpecificProfile("Owner1",1,0)
    console.log("profile==============>", await profile.profileInfo(1))

    await sponsorFactory.createGauge(
      1,
      owner.address
    )
    let sponsorAddress = (await sponsorNote.getAllSponsors(0))[0]
    const Sponsor = await ethers.getContractFactory("Sponsor");
    sponsor = Sponsor.attach(sponsorAddress)

  });

  it("4) create sponsorship", async function () {
    await sponsor.updateProtocol(
      owner2.address,
      ust.address,
      10,
      86400,
      0,
      0,
      0,
      "https://link-to-media.com",
      "sponsor's description of protocol"
    )
    console.log("protocol id=======================>", await sponsor.addressToProtocolId(owner2.address))
    console.log("protocol=======================>", await sponsor.protocolInfo(1))
    console.log("duePayable====================>", await sponsorNote.getDuePayable(sponsor.address, owner2.address, 0))
    expect(await sponsor.addressToProtocolId(owner2.address)).to.equal(1)
    expect((await sponsor.protocolInfo(1)).amountPayable).to.equal(10)
    expect((await sponsor.protocolInfo(1)).periodPayable).to.equal(86400)
    expect((await sponsor.protocolInfo(1)).token).to.equal(ust.address)
    expect((await sponsorNote.getDuePayable(sponsor.address, owner2.address, 0))[0]).to.equal(0)

    // increase time
    await network.provider.send("evm_increaseTime", [86400])
    await network.provider.send("evm_mine")

    console.log("sponsorNote.getDuePayable===========>", await sponsorNote.getDuePayable(sponsor.address, owner2.address, 0))
    // expect((await sponsorNote.getDuePayable(sponsor.address, owner2.address, 0))[0]).to.equal(10)
    await ust.mint(sponsor.address, ethers.BigNumber.from("1000000000000000000"));
    await sponsor.payInvoicePayable(owner2.address)
    // expect((await sponsorNote.getDuePayable(sponsor.address, owner2.address, 0))[0]).to.equal(0)

  });

  it("5) create sponsorship with identity", async function () {
    // await sponsor.updateValueNameNCode(
    //   0,
    //   false,
    //   false,
    //   "testify_age",
    //   "gt_18",
    // )

    // mint identity proof
    await ssi.updateAuthorization(1, 1, true);
    await ssi.generateIdentityProof(
      owner.address,
      1,
      1,
      86700 * 7 * 4,
      "testify_age",
      "gt_18"
    )
    console.log("metadata===========>", await ssi.getSSIData(1))

    // await expect(sponsor.updateProtocol(
    //   owner.address,
    //   ust.address,
    //   10,
    //   86400,
    //   0,
    //   0,
    //   0,
    //   "https://link-to-media.com",
    //   "sponsor's description of protocol"
    // )).to.be.reverted

    await sponsor.updateProtocol(
      owner.address,
      ust.address,
      10,
      86400,
      0,
      1,
      0,
      "https://link-to-media.com",
      "sponsor's description of protocol"
    )
    console.log("protocol id=======================>", await sponsor.addressToProtocolId(owner.address))
    console.log("protocol=======================>", await sponsor.protocolInfo(2))
    console.log("duePayable====================>", await sponsorNote.getDuePayable(sponsor.address, owner.address, 0))

  });

  it("6) update owner", async function () {
    await sponsor.updateParameters(
      false,
      ve.address,
      50
    )
    await ve.transferFrom(owner.address, owner2.address, 1)
    console.log("ve.ownerOf=============>", await ve.ownerOf(1), owner.address, owner2.address)
    await sponsor.connect(owner2).updateTokenId(1);
    await ve.connect(owner2).transferFrom(owner2.address, owner3.address, 1)
    expect((await sponsor.protocolInfo(1)).owner).to.equal(owner2.address)
    await sponsor.connect(owner3).updateOwner(owner2.address, 1)
    console.log("owner2===========>", owner2.address)
    expect((await sponsor.protocolInfo(1)).owner).to.equal(owner3.address)

  });

  it("7) update bounty", async function () {
      // create bounty
    expect((await sponsor.protocolInfo(1)).bountyId).to.equal(0)
    await trustBounties.createBounty(
      owner3.address,
      ust.address,
      ve.address,
      owner.address,
      0,
      10,
      86700 * 7,
      0,
      false,
      "http://link-to-avatar.com",
      "sponsors"
    )
    await sponsor.connect(owner3).updateBounty(1)
    console.log("bounty after===============>", await sponsor.protocolInfo(1))
    expect((await sponsor.protocolInfo(1)).bountyId).to.equal(1)

  });
  
  it("8) transfer due to note", async function () {
    expect((await sponsorNote.notes(sponsor.address,1)).due).to.equal(0)
    expect((await sponsorNote.notes(sponsor.address,1)).timer).to.equal(0)
    expect((await sponsorNote.notes(sponsor.address,1)).tokenId).to.equal(0)
    expect((await sponsorNote.notes(sponsor.address,1)).protocol).to.equal("0x0000000000000000000000000000000000000000")
    await sponsorNote.transferDueToNote(
      sponsor.address,
      owner2.address, 
      1
    )

    console.log("notes=================>", await sponsorNote.notes(sponsor.address,2))
    // expect((await sponsorNote.notes(sponsor.address,1)).due).to.equal(10)
    // expect((await sponsorNote.notes(sponsor.address,1)).timer).to.not.equal(0)
    // expect((await sponsorNote.notes(sponsor.address,1)).tokenId).to.equal(1)
    // expect((await sponsorNote.notes(sponsor.address,1)).protocol).to.equal(owner.address)
  });
  
  it("9) claim pending revenue from note", async function () {
    // increase time
    await network.provider.send("evm_increaseTime", [86400])
    await network.provider.send("evm_mine")

    console.log("duePayable====================>", await sponsorNote.getDuePayable(sponsor.address, owner.address, 0))
    userBalanceBefore = await ust.balanceOf(owner2.address)
    await sponsorNote.connect(owner2).claimRevenueFromNote(sponsor.address, 1)
    // expect(await ust.balanceOf(owner2.address)).to.equal(userBalanceBefore.add(10))

  });
  
  it("10) vote", async function () {
    // mint ssid
    await ssi.generateIdentityProof(owner.address,1,1,86700 * 7,"ssid","tepa")
    await ssi.updateSSID(1,2)
    await profile.updateSSID()

    expect((await sponsorNote.votes(sponsor.address)).likes).to.equal(0)
    expect((await sponsorNote.votes(sponsor.address)).dislikes).to.equal(0)
    expect(await sponsorNote.voted(1, sponsor.address)).to.equal(0)
    expect(await sponsorNote.percentiles(sponsor.address)).to.equal(0)

    await sponsorNote.vote(sponsor.address, 1, true)

    console.log("votes==============>", await sponsorNote.votes(sponsor.address))
    console.log("voted==============>", await sponsorNote.voted(1, sponsor.address))
    console.log("percentiles========>", await sponsorNote.percentiles(sponsor.address))
    console.log("color==============>", await sponsorNote.getGaugeNColor(1))

    expect((await sponsorNote.votes(sponsor.address)).likes).to.equal(1)
    expect((await sponsorNote.votes(sponsor.address)).dislikes).to.equal(0)
    expect(await sponsorNote.voted(1, sponsor.address)).to.equal(1)
    expect(await sponsorNote.percentiles(sponsor.address)).to.equal(50)
    expect((await sponsorNote.getGaugeNColor(1))[1]).to.equal(1)

    await sponsorNote.vote(sponsor.address, 1, false)

    expect((await sponsorNote.votes(sponsor.address)).likes).to.equal(0)
    expect((await sponsorNote.votes(sponsor.address)).dislikes).to.equal(1)
    expect(await sponsorNote.voted(1, sponsor.address)).to.equal(-1)
    expect(await sponsorNote.percentiles(sponsor.address)).to.equal(50)
    expect((await sponsorNote.getGaugeNColor(1))[1]).to.equal(1)

  });
  
  it("11) delete protocol", async function () {
    expect(await sponsor.addressToProtocolId(owner3.address)).to.equal(1)
    expect((await sponsor.protocolInfo(1)).amountPayable).to.equal(10)
    expect((await sponsor.protocolInfo(1)).owner).to.equal(owner3.address)
    
    await sponsor.deleteProtocol(owner3.address)
    
    expect(await sponsor.addressToProtocolId(owner3.address)).to.equal(0)
    expect((await sponsor.protocolInfo(1)).amountPayable).to.equal(0)
    expect((await sponsor.protocolInfo(1)).owner).to.equal("0x0000000000000000000000000000000000000000")
  });

});
