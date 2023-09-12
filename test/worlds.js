const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("core", function () {

  let token;
  let ust;
  let tokenMinter;
  let rsrcnft;
  let nfticket;
  let nfticketHelper;
  let marketPlaceCollection;
  let marketPlaceOrders;
  let marketPlaceOrders02;
  let marketPlaceTrades;
  let marketPlaceHelper;
  let marketPlaceHelper2;
  let marketPlaceHelper02;
  let stakeMarket;
  let stakeMarketVoter;
  let stakeMarketBribe;
  let owner;
  let owner2;
  let owner3;
  let owner4;
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
  let World;
  let world;
  let world2;
  let world3;
  let world4;
  let worldNote;
  let worldHelper;
  let worldHelper2;
  let worldHelper3;
  let worldFactory;
  let billMinter;
  let billFactory;
  let trustBounties;
  let businessBribe;
  let referralBribe;
  let BusinessBribe;
  let ReferralBribe;
  let MinterFactory;
  let minterFactory;
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
  let marketPlaceHelper03;
  let customMinter;

  it("1) deploy market place", async function () {
    [owner, owner2, owner3, owner4] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner4.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();

    ve_underlying = await token.deploy('FreeToken', 'FT', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("2000000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await ve_underlying.mint(owner4.address, ethers.BigNumber.from("1000000000000000000000000000"));
    
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
    const MarketPlaceHelper3 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper3");
    const ValuepoolVoter = await ethers.getContractFactory("ValuepoolVoter");
    const BusinessGaugeFactory = await ethers.getContractFactory("BusinessGaugeFactory");
    const BusinessBribeFactory = await ethers.getContractFactory("BusinessBribeFactory");
    const ReferralBribeFactory = await ethers.getContractFactory("ReferralBribeFactory");
    const VavaHelper = await ethers.getContractFactory("ValuepoolHelper");
    const VavaHelper2 = await ethers.getContractFactory("ValuepoolHelper2");
    const RandomNumberGenerator = await ethers.getContractFactory("contracts/Vava.sol:RandomNumberGenerator");
    World = await ethers.getContractFactory("World");
    const WorldHelper = await ethers.getContractFactory("WorldHelper");
    const WorldHelper3 = await ethers.getContractFactory("WorldHelper3");
    const WorldFactory = await ethers.getContractFactory("WorldFactory");
    // const StakeMarket = await ethers.getContractFactory("StakeMarket");
    // const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
    const SSI = await ethers.getContractFactory("SSI");
    // const BILLFactory = await ethers.getContractFactory("BILLFactory");
    const TrustBounties = await ethers.getContractFactory("TrustBounties");
    const TrustBountiesHelper = await ethers.getContractFactory("TrustBountiesHelper");
    // const BusinessVoter = await ethers.getContractFactory("BusinessVoter");
    // const ReferralVoter = await ethers.getContractFactory("ReferralVoter");
    const Profile = await ethers.getContractFactory("Profile");
    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    // const StakeMarketBribe =  await ethers.getContractFactory("Bribe")
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    const PlusCodes = await ethers.getContractFactory("contracts/Library.sol:PlusCodes")
    let plusCodes = await PlusCodes.deploy()
    
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

  // const AuditorNote = await ethers.getContractFactory("AuditorNote",{
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // });

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

  // const StakeMarketVoter = await ethers.getContractFactory("StakeMarketVoter", {
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // })

  const WorldNote = await ethers.getContractFactory("WorldNote",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const WorldHelper2 = await ethers.getContractFactory("WorldHelper2",{
    libraries: {
      PlusCodes: plusCodes.address,
    },
  });

  const MarketPlaceHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  // const MarketPlaceHelper02 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // });

  marketPlaceEvents = await MarketPlaceEvents.deploy()
  await marketPlaceEvents.deployed()

  ve = await vecontract.deploy(ve_underlying.address);
  await ve.deployed()

  ve_dist = await ve_distContract.deploy(ve.address);
  await ve_dist.deployed()

  contractAddresses = await ContractAddresses.deploy()
  await contractAddresses.deployed()

  ssi = await SSI.deploy()
  await ssi.deployed()

  worldFactory = await WorldFactory.deploy()
  await worldFactory.deployed()

  worldHelper = await WorldHelper.deploy()
  await worldHelper.deployed()

  worldHelper2 = await WorldHelper2.deploy()
  await worldHelper2.deployed()

  worldHelper3 = await WorldHelper3.deploy()
  await worldHelper3.deployed()

  worldNote = await WorldNote.deploy()
  await worldNote.deployed()

  profile = await Profile.deploy()
  await profile.deployed()

  profileHelper = await ProfileHelper.deploy()
  await profileHelper.deployed()

  vavaFactory = await VavaFactory.deploy(contractAddresses.address)
  await vavaFactory.deployed()

  vavaHelper = await VavaHelper.deploy()
  await vavaHelper.deployed()
  
  vavaHelper2 = await VavaHelper2.deploy()
  await vavaHelper2.deployed()

  marketPlaceCollection = await MarketPlaceCollection.deploy(
    owner.address,
    contractAddresses.address
  )
    
  marketPlaceHelper2 = await MarketPlaceHelper2.deploy()
  await marketPlaceHelper2.deployed()

  marketPlaceHelper3 = await MarketPlaceHelper3.deploy()
  await marketPlaceHelper3.deployed()

  veFactory = await VeFactory.deploy()
  await veFactory.deployed()

  valuepoolVoter = await ValuepoolVoter.deploy()
  await valuepoolVoter.deployed()

  trustBounties = await TrustBounties.deploy()
  await trustBounties.deployed()

  trustBountiesHelper = await TrustBountiesHelper.deploy()
  await trustBountiesHelper.deployed()

  // set ups
  await trustBounties.setContractAddress(contractAddresses.address)
  console.log("trustBounties.setContractAddress===========> Done!")

  await trustBountiesHelper.setContractAddress(contractAddresses.address)
  console.log("trustBountiesHelper.setContractAddress===========> Done!")

  await ssi.setContractAddress(contractAddresses.address)
  console.log("ssi.setContractAddress===========> Done!")

  await worldFactory.setContractAddress(contractAddresses.address)
  console.log("worldFactory.setContractAddress===========> Done!")

  await worldNote.setContractAddress(contractAddresses.address)
  console.log("worldNote.setContractAddress===========> Done!")

  await worldHelper3.setContractAddress(contractAddresses.address)
  console.log("worldHelper3.setContractAddress===========> Done!")

  await worldHelper2.setContractAddress(contractAddresses.address)
  console.log("worldHelper2.setContractAddress===========> Done!")

  await worldHelper.setContractAddress(contractAddresses.address)
  console.log("worldHelper.setContractAddress===========> Done!")
  
  await profile.setContractAddress(contractAddresses.address)
  console.log("profile.setContractAddress===========> Done!")

  await profileHelper.setContractAddress(contractAddresses.address)
  console.log("profileHelper.setContractAddress===========> Done!")

  await valuepoolVoter.setContractAddress(contractAddresses.address)
  console.log("valuepoolVoter.setContractAddress===========> Done!")
  
  await vavaHelper2.setContractAddress(contractAddresses.address)
  console.log("vavaHelper2.setContractAddress===========> Done!")
  
  await vavaHelper.setContractAddress(contractAddresses.address)
  console.log("vavaHelper.setContractAddress===========> Done!")

  // await vavaFactory.setContractAddress(contractAddresses.address)
  // console.log("vavaFactory.setContractAddress===========> Done!")

  await marketPlaceHelper2.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper2.setContractAddress===========> Done!")

  await marketPlaceHelper3.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper3.setContractAddress===========> Done!")

  await marketPlaceEvents.setContractAddress(contractAddresses.address)
  console.log("marketPlaceEvents.setContractAddress===========> Done!")

  // ####################### setDev
  await contractAddresses.setDevaddr(owner.address)
  console.log("contractAddresses.setDevaddr===========> Done!")  

  await contractAddresses.setToken(ust.address)
  await contractAddresses.addContent('nsfw')

  await contractAddresses.setTrustBounty(trustBounties.address)
  console.log("contractAddresses.setTrustBounty===========> Done!")

  await contractAddresses.setTrustBountyHelper(trustBountiesHelper.address)
  console.log("contractAddresses.setTrustBountyHelper===========> Done!")

  await trustBountiesHelper.updateVes(ust.address, true)
  await trustBountiesHelper.updateWhitelistedTokens([ust.address], true)
  await trustBountiesHelper.updateCanAttach(marketPlaceEvents.address, true)

  await contractAddresses.setMarketCollections(marketPlaceCollection.address)
  console.log("contractAddresses.setMarketCollections===========> Done!")

  await contractAddresses.setMarketHelpers2(marketPlaceHelper2.address)
  console.log("contractAddresses.setMarketHelpers2===========> Done!")

  await contractAddresses.setMarketHelpers3(marketPlaceHelper3.address)
  console.log("contractAddresses.setMarketHelpers3===========> Done!")

  await contractAddresses.setMarketPlaceEvents(marketPlaceEvents.address)
  console.log("contractAddresses.setMarketPlaceEvents===========> Done!")

  await contractAddresses.setWorldFactory(worldFactory.address)
  console.log("contractAddresses.setWorldFactory===========> Done!")

  await contractAddresses.setWorldNote(worldNote.address)
  console.log("contractAddresses.setWorldNote===========> Done!")

  await contractAddresses.setWorldHelper2(worldHelper2.address)
  console.log("contractAddresses.setWorldHelper2===========> Done!")

  await contractAddresses.setWorldHelper3(worldHelper3.address)
  console.log("contractAddresses.setWorldHelper3===========> Done!")

  await contractAddresses.setWorldHelper(worldHelper.address)
  console.log("contractAddresses.setWorldHelper===========> Done!")

  await contractAddresses.setSSI(ssi.address)
  console.log("contractAddresses.setSSI===========> Done!")

  await contractAddresses.setProfile(profile.address)
  console.log("contractAddresses.setProfile===========> Done!")

  await contractAddresses.setProfileHelper(profileHelper.address)
  console.log("contractAddresses.setProfileHelper===========> Done!")

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

  await marketPlaceHelper3.addDtoken(ust.address)
  await marketPlaceHelper3.addVetoken(ust.address)

}).timeout(10000000);

it("2) add profile & collection", async function () {
  // create profile
  await profile.createSpecificProfile("Owner1",1,0)
  await profile.shareEmail(owner2.address)
  await profile.connect(owner2).createProfile("Owner2",0)
  console.log("addressToProfileId===========>", await profile.addressToProfileId(owner2.address))

  await ssi.generateIdentityProof(owner.address,1,1,86700 * 7,"ssid","tepa")
  await ssi.generateIdentityProof(owner2.address,2,1,86700 * 7,"ssid","tepa2")
  await ssi.updateSSID(1,1)
  await ssi.connect(owner2).updateSSID(2,2)
  await profile.updateSSID()
  await profile.connect(owner2).updateSSID()

  await marketPlaceCollection.addCollection(100,0,0,10,0,0,ust.address,false,false);
  await marketPlaceCollection.connect(owner2).addCollection(100,0,0,10,0,0,ust.address,false,false);
  
  expect((await marketPlaceCollection.addressToCollectionId(owner.address))).to.equal(1);
  expect((await marketPlaceCollection.addressToCollectionId(owner2.address))).to.equal(2);
}).timeout(10000000);

  it("3) create RP World", async function () {
    await worldFactory.createGauge(1, owner.address);
    await worldFactory.createGauge(2, owner2.address);
    
    let worldAddress = (await worldNote.getAllWorlds(0))[0]
    let worldAddress2 = (await worldNote.getAllWorlds(0))[1]
    world = World.attach(worldAddress)
    world2 = World.attach(worldAddress2)
    console.log("world===>", worldAddress, world.address)
    expect(worldAddress).to.equal(world.address)

    await worldHelper2.updateCategory(world.address, 1)
    await worldNote.updateProfile(world.address)

    await worldHelper2.connect(owner2).updateCategory(world2.address, 1)
    await worldNote.connect(owner2).updateProfile(world2.address)

  }).timeout(10000000);

  it("4) create bounty & add balance", async function () {
    await trustBounties.createBounty(
      owner.address,
      ust.address,
      ust.address,
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

    await trustBountiesHelper.updateCanAttach(worldNote.address, true)
    await world.updateBounty(1, 0)
    console.log("adminBountyId=================>", await world.adminBountyId(ust.address))
    
    await worldHelper2.updateBounty(world.address, 1)
  }).timeout(10000000);

  it("5) Mint new code", async function () {
    expect((await worldHelper.codeInfo(1)).world).to.equal("0x0000000000000000000000000000000000000000")
    expect((await worldHelper.codeInfo(1)).start).to.equal(0)
    expect((await worldHelper.codeInfo(1)).end).to.equal(0)
    expect((await worldHelper.codeInfo(1)).planet).to.equal(0)
    expect((await worldHelper.codeInfo(1)).rating).to.equal(0)
    expect((await worldHelper.codeInfo(1)).first4).to.equal('')
    expect((await worldHelper.codeInfo(1)).last4).to.equal('')
    expect((await worldHelper.codeInfo(1)).ext).to.equal('')
    expect((await worldHelper.codeInfo(1)).color).to.equal(0)
    expect((await worldHelper.codeInfo(1)).worldType).to.equal(0)

    console.log("getGaugeNColor========>", await worldNote.getGaugeNColor(1, 1))
    console.log("getGaugeNColor========>", await worldNote.percentiles(world.address))
    // console.log("getGaugeNColor========>", await worldNote._getColor(0))

    await worldHelper2.batchMint(
      owner2.address, 
      world.address, 
      1, 
      [["6","f","r","3"], ["6","f","r","3"]], 
      [["7","6","g","8"], ["7","6","g","8"]],
      [["26"], ["27"]]
    )
    console.log("codeInfo1==============>", await worldHelper.codeInfo(1))
    console.log("codeInfo2==============>", await worldHelper.codeInfo(2))
    expect((await worldHelper.codeInfo(1)).world).to.equal(world.address)
    expect((await worldHelper.codeInfo(2)).world).to.equal(world.address)
    expect((await worldHelper.codeInfo(1)).start).gt(0)
    expect((await worldHelper.codeInfo(2)).start).gt(0)
    expect((await worldHelper.codeInfo(1)).end).gt(0)
    expect((await worldHelper.codeInfo(2)).end).gt(0)
    expect((await worldHelper.codeInfo(1)).planet).to.equal(1)
    expect((await worldHelper.codeInfo(2)).planet).to.equal(1)
    expect((await worldHelper.codeInfo(1)).rating).to.equal(0)
    expect((await worldHelper.codeInfo(2)).rating).to.equal(0)
    expect((await worldHelper.codeInfo(1)).first4).to.equal('6fr3')
    expect((await worldHelper.codeInfo(2)).first4).to.equal('6fr3')
    expect((await worldHelper.codeInfo(1)).last4).to.equal('76g8')
    expect((await worldHelper.codeInfo(2)).last4).to.equal('76g8')
    expect((await worldHelper.codeInfo(1)).ext).to.equal('26')
    expect((await worldHelper.codeInfo(2)).ext).to.equal('27')
    expect((await worldHelper.codeInfo(1)).color).to.equal(0)
    expect((await worldHelper.codeInfo(2)).color).to.equal(0)
    expect((await worldHelper.codeInfo(1)).worldType).to.equal(1)
    expect((await worldHelper.codeInfo(2)).worldType).to.equal(1)


  }).timeout(10000000);

  it("6) create protocol", async function () {
    expect((await world.protocolInfo(1)).owner).to.equal("0x0000000000000000000000000000000000000000")
    expect((await world.protocolInfo(1)).token).to.equal("0x0000000000000000000000000000000000000000")
    expect((await world.protocolInfo(1)).bountyId).to.equal(0)
    expect((await world.protocolInfo(1)).amountReceivable).to.equal(0)
    expect((await world.protocolInfo(1)).periodReceivable).to.equal(0)
    expect((await world.protocolInfo(1)).paidReceivable).to.equal(0)
    expect((await world.protocolInfo(1)).startReceivable).to.equal(0)
    expect((await world.protocolInfo(1)).rating).to.equal(0)
    expect((await world.protocolInfo(1)).optionId).to.equal(0)
    expect(await world.addressToProtocolId(owner2.address)).to.equal(0)

    await world.updateProtocol(
      owner2.address,
      ust.address,
      [1000,3000,0,0],
      0,
      0,
      5,
      "link_to_media",
      "description"
    )

    console.log("protocolInfo============>", await world.protocolInfo(1))
    expect((await world.protocolInfo(1)).owner).to.equal(owner2.address)
    expect((await world.protocolInfo(1)).token).to.equal(ust.address)
    expect((await world.protocolInfo(1)).bountyId).to.equal(0)
    expect((await world.protocolInfo(1)).amountReceivable).to.equal(1000)
    expect((await world.protocolInfo(1)).periodReceivable).to.equal(3000)
    expect((await world.protocolInfo(1)).paidReceivable).to.equal(0)
    expect((await world.protocolInfo(1)).startReceivable).gt(0)
    expect((await world.protocolInfo(1)).rating).to.equal(5)
    expect((await world.protocolInfo(1)).optionId).to.equal(0)
    expect(await world.addressToProtocolId(owner2.address)).to.equal(1)
    expect(await world.media(1)).to.equal("link_to_media")
    expect(await world.description(1)).to.equal("description")

    expect(await world.totalSupply()).to.equal(0)
    await world.connect(owner2).updateTokenIds([1,2], true)
    expect(await world.totalSupply()).to.equal(2)

    console.log("getAllTokenIds==========>", await world.getAllTokenIds(owner2.address, 0))
    
  }).timeout(10000000);

  it("7) autocharge", async function () {
    console.log("dueReceivable before=========>", await worldNote.getDueReceivable(world.address, 1, 0))
    expect((await worldNote.getDueReceivable(world.address, 1, 0))[0]).to.equal(0)
    expect((await worldNote.getDueReceivable(world.address, 1, 0))[2]).lte(-2000)

    // increase time
    await network.provider.send("evm_increaseTime", [3000])
    await network.provider.send("evm_mine")

    console.log("dueReceivable after=========>", await worldNote.getDueReceivable(world.address, 1, 0))
    console.log("protocolInfo after=========>", await world.protocolInfo(1))
    console.log("totalprocessed after=========>", await world.totalProcessed(ust.address))
    expect((await worldNote.getDueReceivable(world.address, 1, 0))[0]).to.equal(1000)
    expect((await worldNote.getDueReceivable(world.address, 1, 0))[2]).lte(5)

    expect(await ust.balanceOf(world.address)).to.equal(0)
    await ust.connect(owner2).approve(world.address, 1000);
    await world.connect(owner2).autoCharge([1], 0)
    console.log("balanceOf============>", await ust.balanceOf(world.address))
    expect(await ust.balanceOf(world.address)).to.equal(990)

    console.log("dueReceivable after autocharge=========>", await worldNote.getDueReceivable(world.address, 1, 0))
    expect((await worldNote.getDueReceivable(world.address, 1, 0))[0]).to.equal(0)
    expect((await worldNote.getDueReceivable(world.address, 1, 0))[2]).lte(10)
    
    console.log("protocolInfo after autocharge==========>", await world.protocolInfo(1))
    expect((await world.protocolInfo(1)).paidReceivable).to.equal(1000)

  }).timeout(10000000);

  it("8) Mint same codes when user color < minColor", async function () {
    await expect(worldHelper2.connect(owner2).batchMint(
      owner3.address, 
      world2.address, 
      1, 
      [["6","f","r","3"]], 
      [["7","6","g","8"]],
      [["26"]]
    )).to.be.reverted

    await worldHelper2.updateTimeFrame(26, 1)

    expect(await worldNote.percentiles(world2.address)).to.equal(0)
    // vote
    await worldNote.vote(world2.address, 1, true)

    console.log("vote==============>", await worldNote.percentiles(world2.address))
    console.log("color==============>", await worldNote.getGaugeNColor(2, 1))
    expect(await worldNote.percentiles(world2.address)).gt(0)

    expect(await worldHelper2.ownerOf(1)).to.equal(owner2.address)
    worldHelper2.connect(owner2).batchMint(
      owner3.address, 
      world2.address, 
      1, 
      [["6","f","r","3"]], 
      [["7","6","g","8"]],
      [["26"]]
    )
    console.log("codeInfo1==============>", await worldHelper.codeInfo(1))
    expect((await worldHelper.codeInfo(1)).world).to.equal(world2.address)
    expect(await worldHelper2.ownerOf(1)).to.equal(owner3.address)

  }).timeout(10000000);

  it("9) Create BP & Green worlds", async function () {
      await worldFactory.createGauge(1, owner.address);
      await worldFactory.createGauge(2, owner2.address);
      
      let worldAddress3 = (await worldNote.getAllWorlds(0))[2]
      let worldAddress4 = (await worldNote.getAllWorlds(0))[3]
      world3 = World.attach(worldAddress3)
      world4 = World.attach(worldAddress4)
      console.log("world===>", worldAddress3, world3.address)
      expect(worldAddress3).to.equal(world3.address)
      expect(worldAddress4).to.equal(world4.address)
  
      await worldHelper2.updateCategory(world3.address, 2)
      await worldNote.updateProfile(world3.address)

      await worldHelper2.connect(owner2).updateCategory(world4.address, 3)
      await worldNote.connect(owner2).updateProfile(world4.address)
  
  }).timeout(10000000);
  
  it("10) Mint same codes when user time passes", async function () {
    expect(await worldNote.percentiles(world3.address)).to.equal(0)
    // vote
    await worldNote.vote(world3.address, 1, true)
    await worldNote.vote(world4.address, 1, true)

    console.log("vote==============>", await worldNote.percentiles(world3.address))
    console.log("vote==============>", await worldNote.percentiles(world4.address))
    console.log("color==============>", await worldNote.getGaugeNColor(1, 2))
    console.log("color==============>", await worldNote.getGaugeNColor(2, 3))
    expect(await worldNote.percentiles(world3.address)).gt(0)

    await expect(worldHelper2.batchMint(
      owner3.address, 
      world.address, 
      1, 
      [["6","f","r","3"]], 
      [["7","6","g","8"]],
      [["26"]]
    )).to.be.reverted

    await network.provider.send("evm_increaseTime", [7 * 86400 * 26])
    await network.provider.send("evm_mine")

    expect(await worldHelper2.ownerOf(1)).to.equal(owner2.address)
    worldHelper2.connect(owner2).batchMint(
      owner3.address, 
      world3.address, 
      1, 
      [["6","f","r","3"]], 
      [["7","6","g","8"]],
      [["26"]]
    )

    await worldHelper2.batchMint(
      owner3.address, 
      world.address, 
      1, 
      [["6","f","r","3"]], 
      [["7","6","g","8"]],
      [["26"]]
    )

    // console.log("codeInfo2==============>", await worldHelper.codeInfo(1))
    // expect((await worldHelper.codeInfo(1)).world).to.equal(world2.address)
    // expect(await worldHelper2.ownerOf(1)).to.equal(owner3.address)

  }).timeout(10000000);

  // // it("15) transfer admin note", async function () {
  // //   console.log("dueReceivable before transfer=========>", await billNote.getDueReceivable(bill.address, 1, 0))
  // //   console.log("note====================>", await billNote.notes(1))
  // //   await expect(billNote.ownerOf(1)).to.be.reverted
  // //   const due = (await billNote.getDueReceivable(bill.address, 1, 0))[0]
  // //   const timer = (await billNote.getDueReceivable(bill.address, 1, 0))[1]
  // //   expect(due).gt(0)
  // //   expect(timer).gt(0)

  // //   await billNote.transferDueToNoteReceivable(
  // //     bill.address,
  // //     owner2.address,
  // //     1,
  // //     0
  // //   )
  // //   console.log("dueReceivable after transfer=========>", await billNote.getDueReceivable(bill.address, 1, 0))
  // //   console.log("note after====================>", await billNote.notes(1))
  // //   expect(await billNote.ownerOf(1)).to.equal(owner2.address)
  // //   expect((await billNote.notes(1)).due).to.equal(due - due/100)
  // //   expect((await billNote.notes(1)).token).to.equal(ust.address)
  // //   expect((await billNote.notes(1)).timer).to.equal(timer)
  // //   expect((await billNote.notes(1)).protocolId).to.equal(1)
  // //   expect((await billNote.notes(1)).bill).to.equal(bill.address)
    
  // // })

  // // it("16) claim admin note", async function () {
  // //   console.log("pendingRevenue========>", await bill.pendingRevenue(ust.address))    
  // //   console.log("pendingRevenueFromNote========>", await billNote.pendingRevenueFromNote(1))    
  // //   expect(await billNote.pendingRevenueFromNote(1)).to.equal(0)
  // //   await expect(billNote.claimPendingRevenueFromNote(1)).to.be.reverted;

  // //   await ust.connect(owner2).approve(bill.address, 2000);
  // //   await bill.connect(owner2).autoCharge([1], 0)

  // //   console.log("pendingRevenueFromNote ========>", await billNote.pendingRevenueFromNote(1))    
  // //   expect(await billNote.pendingRevenueFromNote(1)).to.equal(1980)

  // //   await billNote.connect(owner2).claimPendingRevenueFromNote(1)
  // //   expect(await billNote.pendingRevenueFromNote(1)).to.equal(0)
  // //   await expect(billNote.ownerOf(1)).to.be.reverted

  // // })

  // // it("17) transfer user note", async function () {
  // //   console.log("duePayable before transfer=========>", await billNote.getDuePayable(bill.address, 1, 0))
  // //   console.log("note====================>", await billNote.notes(2))
  // //   await expect(billNote.ownerOf(2)).to.be.reverted
  // //   const due = (await billNote.getDuePayable(bill.address, 1, 0))[0]
  // //   const timer = (await billNote.getDuePayable(bill.address, 1, 0))[1]
  // //   expect(due).gt(0)
  // //   expect(timer).gt(0)

  // //   await billNote.connect(owner2).transferDueToNotePayable(
  // //     bill.address,
  // //     owner2.address,
  // //     1,
  // //     0
  // //   )
  // //   console.log("duePayable after transfer=========>", await billNote.getDuePayable(bill.address, 1, 0))
  // //   console.log("note after====================>", await billNote.notes(2))
  // //   expect(await billNote.ownerOf(2)).to.equal(owner2.address)
  // //   expect((await billNote.notes(2)).due).to.equal(due - due/100)
  // //   expect((await billNote.notes(2)).token).to.equal(ust.address)
  // //   expect((await billNote.notes(2)).timer).to.equal(timer)
  // //   expect((await billNote.notes(2)).protocolId).to.equal(1)
  // //   expect((await billNote.notes(2)).bill).to.equal(bill.address)

  // // })

  // // it("18) claim user note", async function () {
  // //   console.log("pendingRevenue========>", await bill.pendingRevenue(ust.address))    
  // //   console.log("duePayable before claim=========>", await billNote.getDuePayable(bill.address, 1, 0))

  // //   await ust.approve(bill.address, 2000);
  // //   await bill.notifyReward(ust.address, 2000)
    
  // //   await billNote.connect(owner2).claimPendingRevenueFromNote(2)
  // //   console.log("duePayable after claim=========>", await billNote.getDuePayable(bill.address, 1, 0))
    
  // //   await expect(billNote.ownerOf(2)).to.be.reverted

  // // })

  // // it("20) admin bounty", async function () {
    

  // // })

  // // it("21) user bounty", async function () {
    

  // // })
  
});