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
  let Betting;
  let betting;
  let bettingHelper;
  let bettingMinter;
  let bettingFactory;
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
  let nftSvg;

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
    // const ValuepoolVoter = await ethers.getContractFactory("ValuepoolVoter");
    // const BusinessGaugeFactory = await ethers.getContractFactory("BusinessGaugeFactory");
    // const BusinessBribeFactory = await ethers.getContractFactory("BusinessBribeFactory");
    // const ReferralBribeFactory = await ethers.getContractFactory("ReferralBribeFactory");
    // const VavaHelper = await ethers.getContractFactory("ValuepoolHelper");
    // const VavaHelper2 = await ethers.getContractFactory("ValuepoolHelper2");
    // const RandomNumberGenerator = await ethers.getContractFactory("contracts/Vava.sol:RandomNumberGenerator");
    Betting = await ethers.getContractFactory("Betting");
    const BettingFactory = await ethers.getContractFactory("BettingFactory");
    // const StakeMarket = await ethers.getContractFactory("StakeMarket");
    // const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
    const SSI = await ethers.getContractFactory("SSI");
    // const BILLFactory = await ethers.getContractFactory("BILLFactory");
    // const TrustBounties = await ethers.getContractFactory("TrustBounties");
    // const TrustBountiesHelper = await ethers.getContractFactory("TrustBountiesHelper");
    // const BusinessVoter = await ethers.getContractFactory("BusinessVoter");
    // const ReferralVoter = await ethers.getContractFactory("ReferralVoter");
    const Profile = await ethers.getContractFactory("Profile");
    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    // const StakeMarketBribe =  await ethers.getContractFactory("Bribe")
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    const PlusCodes = await ethers.getContractFactory("contracts/Library.sol:PlusCodes")
    let plusCodes = await PlusCodes.deploy()
    const BettingHelper = await ethers.getContractFactory("BettingHelper");
    const BettingMinter = await ethers.getContractFactory("BettingMinter");
    const NFTSVG = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTSVG")

  // BusinessBribe = await ethers.getContractFactory("BusinessBribe");
  // BusinessGauge = await ethers.getContractFactory("BusinessGauge");

  // ReferralBribe = await ethers.getContractFactory("ReferralBribe");
  MinterFactory = await ethers.getContractFactory("MinterFactory");

  vecontract = await ethers.getContractFactory("contracts/ve.sol:mve",{
    libraries: {
      Percentile: percentile.address,
    },
  });
  
  // const VeFactory = await ethers.getContractFactory("contracts/Vava.sol:veFactory",{
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // });

  // const VavaFactory = await ethers.getContractFactory("ValuepoolFactory",{
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // });

  // const AuditorNote = await ethers.getContractFactory("AuditorNote",{
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // });

  // Va = await ethers.getContractFactory("contracts/Vava.sol:Ve",{
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // });

  // Vava = await ethers.getContractFactory("contracts/Vava.sol:Valuepool",{
  //   libraries: {
  //     Percentile: percentile.address,
  //   },
  // });

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

  const MarketPlaceHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const MarketPlaceHelper02 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
    libraries: {
      Percentile: percentile.address,
    },
  });

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

  bettingFactory = await BettingFactory.deploy()
  await bettingFactory.deployed()

  bettingMinter = await BettingMinter.deploy()
  await bettingMinter.deployed()

  bettingHelper = await BettingHelper.deploy()
  await bettingHelper.deployed()

  profile = await Profile.deploy()
  await profile.deployed()

  profileHelper = await ProfileHelper.deploy()
  await profileHelper.deployed()

  // vavaFactory = await VavaFactory.deploy(contractAddresses.address)
  // await vavaFactory.deployed()

  // vavaHelper = await VavaHelper.deploy()
  // await vavaHelper.deployed()
  
  // vavaHelper2 = await VavaHelper2.deploy()
  // await vavaHelper2.deployed()

  marketPlaceCollection = await MarketPlaceCollection.deploy(
    owner.address,
    contractAddresses.address
  )
    
  marketPlaceHelper2 = await MarketPlaceHelper2.deploy()
  await marketPlaceHelper2.deployed()

  marketPlaceHelper3 = await MarketPlaceHelper3.deploy()
  await marketPlaceHelper3.deployed()

  nftSvg = await NFTSVG.deploy()
  await nftSvg.deployed()

  // veFactory = await VeFactory.deploy(contractAddresses.address)
  // await veFactory.deployed()

  // valuepoolVoter = await ValuepoolVoter.deploy()
  // await valuepoolVoter.deployed()

  // trustBounties = await TrustBounties.deploy()
  // await trustBounties.deployed()

  // trustBountiesHelper = await TrustBountiesHelper.deploy()
  // await trustBountiesHelper.deployed()

  // // set ups
  // await trustBounties.setContractAddress(contractAddresses.address)
  // console.log("trustBounties.setContractAddress===========> Done!")

  // await trustBountiesHelper.setContractAddress(contractAddresses.address)
  // console.log("trustBountiesHelper.setContractAddress===========> Done!")

  await nftSvg.setContractAddress(contractAddresses.address)
  console.log("nftSvg.setContractAddress===========> Done!")

  await ssi.setContractAddress(contractAddresses.address)
  console.log("ssi.setContractAddress===========> Done!")

  await bettingFactory.setContractAddress(contractAddresses.address)
  console.log("bettingFactory.setContractAddress===========> Done!")

  await bettingMinter.setContractAddress(contractAddresses.address)
  console.log("bettingMinter.setContractAddress===========> Done!")

  await bettingHelper.setContractAddress(contractAddresses.address)
  console.log("bettingHelper.setContractAddress===========> Done!")

  await profile.setContractAddress(contractAddresses.address)
  console.log("profile.setContractAddress===========> Done!")

  await profileHelper.setContractAddress(contractAddresses.address)
  console.log("profileHelper.setContractAddress===========> Done!")

  // await valuepoolVoter.setContractAddress(contractAddresses.address)
  // console.log("valuepoolVoter.setContractAddress===========> Done!")
  
  // await vavaHelper2.setContractAddress(contractAddresses.address)
  // console.log("vavaHelper2.setContractAddress===========> Done!")
  
  // await vavaHelper.setContractAddress(contractAddresses.address)
  // console.log("vavaHelper.setContractAddress===========> Done!")

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

  await contractAddresses.setNftSvg(nftSvg.address)
  console.log("contractAddresses.setNftSvg===========> Done!")

  // await contractAddresses.setTrustBounty(trustBounties.address)
  // console.log("contractAddresses.setTrustBounty===========> Done!")

  // await contractAddresses.setTrustBountyHelper(trustBountiesHelper.address)
  // console.log("contractAddresses.setTrustBountyHelper===========> Done!")

  // await trustBountiesHelper.updateVes(ust.address, true)
  // await trustBountiesHelper.updateWhitelistedTokens([ust.address], true)
  // await trustBountiesHelper.updateCanAttach(marketPlaceEvents.address, true)

  await contractAddresses.setMarketCollections(marketPlaceCollection.address)
  console.log("contractAddresses.setMarketCollections===========> Done!")

  await contractAddresses.setMarketHelpers2(marketPlaceHelper2.address)
  console.log("contractAddresses.setMarketHelpers2===========> Done!")

  await contractAddresses.setMarketHelpers3(marketPlaceHelper3.address)
  console.log("contractAddresses.setMarketHelpers3===========> Done!")

  await contractAddresses.setMarketPlaceEvents(marketPlaceEvents.address)
  console.log("contractAddresses.setMarketPlaceEvents===========> Done!")

  await contractAddresses.setBettingFactory(bettingFactory.address)
  console.log("contractAddresses.setBettingFactory===========> Done!")

  await contractAddresses.setBettingHelper(bettingHelper.address)
  console.log("contractAddresses.setBettingHelper===========> Done!")

  await contractAddresses.setBettingMinter(bettingMinter.address)
  console.log("contractAddresses.setBettingMinter===========> Done!")

  await contractAddresses.setSSI(ssi.address)
  console.log("contractAddresses.setSSI===========> Done!")

  await contractAddresses.setProfile(profile.address)
  console.log("contractAddresses.setProfile===========> Done!")

  await contractAddresses.setProfileHelper(profileHelper.address)
  console.log("contractAddresses.setProfileHelper===========> Done!")

  // await contractAddresses.setValuepoolFactory(vavaFactory.address)
  // console.log("contractAddresses.setValuepoolFactory===========> Done!")

  // await contractAddresses.setValuepoolHelper(vavaHelper.address)
  // console.log("contractAddresses.setValuepoolHelper===========> Done!")

  // await contractAddresses.setValuepoolHelper2(vavaHelper2.address)
  // console.log("contractAddresses.setValuepoolHelper2===========> Done!")

  // await contractAddresses.setVeFactory(veFactory.address)
  // console.log("contractAddresses.setVeFactory===========> Done!")

  // await contractAddresses.setValuepoolVoter(valuepoolVoter.address)
  // console.log("contractAddresses.setValuepoolVoter===========> Done!")

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

  it("3) create betting contract", async function () {
    await bettingFactory.createGauge(1, owner.address, "0x0000000000000000000000000000000000000000");
    
    let bettingAddress = (await bettingHelper.getAllBettings(0))[0]
    betting = Betting.attach(bettingAddress)
    console.log("betting===>", bettingAddress, betting.address)
    expect(bettingAddress).to.equal(betting.address)

  }).timeout(10000000);

  it("4) create betting event", async function () {
    await betting.updateBettingEvent(
      ust.address,
      false,
      0,
      0,
      0,
      [0,0,3000,10,1000],
      [7500,2500,0,0,0,0],
      "scores",
      "media",
      "desicription",
      "P1,P2,P3,P4,P5,P6"
    )

    console.log("bettingEvent=========>", await betting.protocolInfo(1))

  }).timeout(10000000);

  it("5) Buy Ticket", async function () {
    // // increase time
    // await network.provider.send("evm_increaseTime", [1000])
    // await network.provider.send("evm_mine")

    await ust.approve(betting.address, 30)
    await betting.buyWithContract(
      1, 
      owner.address, 
      "0x0000000000000000000000000000000000000000", 
      0, 
      0,
      // [1234567,1892345,1678923]
      [1120000,1020000,1320000]
    )

    console.log("ticket=========>", await betting.tickets(1))
    console.log("amountCollected=========>", await betting.amountCollected(1,0))
    console.log("balanceOf betting=========>", await ust.balanceOf(betting.address))
    console.log("balanceOf betting helper=========>", await ust.balanceOf(bettingHelper.address))

    // inject sponsor funds
    await ust.approve(betting.address, 30)
    await betting.injectFunds(1,0,30)
    console.log("balanceOf betting2=========>", await ust.balanceOf(betting.address))
    console.log("balanceOf betting helper2=========>", await ust.balanceOf(bettingHelper.address))

  }).timeout(10000000);

  it("6) Close Betting Period", async function () {
    // 1st PERIOD
    console.log("status period(0) before=========>", await betting.status(1,0))
    expect(await betting.status(1,0)).to.equal(0)  // status open
    await betting.closeBetting(1)
    console.log("status period(0) after=========>", await betting.status(1,0))
    expect(await betting.status(1,0)).to.equal(0)  // status still open

    // increase time
    await network.provider.send("evm_increaseTime", [3001])
    await network.provider.send("evm_mine")

    console.log("status period(0) before=========>", await betting.status(1,0), (await betting.protocolInfo(1)).nextToClose)
    expect(await betting.status(1,0)).to.equal(0)  // status open
    expect((await betting.protocolInfo(1)).nextToClose).to.equal(0) 
    await betting.closeBetting(1)
    console.log("status period(0) after=========>", await betting.status(1,0))
    expect(await betting.status(1,0)).to.equal(1)  // status closed
    console.log("nextToClose=========>", (await betting.protocolInfo(1)).nextToClose)
    expect((await betting.protocolInfo(1)).nextToClose).to.equal(1) 

    // 3nd PERIOD

    // increase time
    await network.provider.send("evm_increaseTime", [6001])
    await network.provider.send("evm_mine")

    console.log("status period(1) before=========>", await betting.status(1,1), (await betting.protocolInfo(1)).nextToClose)
    console.log("status period(2) before=========>", await betting.status(1,2), (await betting.protocolInfo(1)).nextToClose)
    expect(await betting.status(1,1)).to.equal(0)  // status open
    expect(await betting.status(1,2)).to.equal(0)  // status open
    await betting.closeBetting(1)
    console.log("status period(1) after=========>", await betting.status(1,1), (await betting.protocolInfo(1)).nextToClose)
    console.log("status period(2) after=========>", await betting.status(1,2), (await betting.protocolInfo(1)).nextToClose)
    expect(await betting.status(1,1)).to.equal(1)  // status closed
    expect(await betting.status(1,2)).to.equal(1)  // status closed
    expect((await betting.protocolInfo(1)).nextToClose).to.equal(3) 

  }).timeout(10000000);

  it("7) Set Result", async function () {
    await expect(betting.countWinnersPerBracket(1,0,0)).to.be.reverted
    await expect(betting.countWinnersPerBracket(1,0,1)).to.be.reverted
    await expect(betting.countWinnersPerBracket(1,0,2)).to.be.reverted
    await expect(betting.countWinnersPerBracket(1,0,3)).to.be.reverted
    await expect(betting.countWinnersPerBracket(1,0,4)).to.be.reverted
    await expect(betting.countWinnersPerBracket(1,0,5)).to.be.reverted
    await expect(betting.finalNumbers(1,0)).to.be.reverted
    
    await betting.setBettingResults(1,0,[1120000,1120000, 1120000])
    // await betting.setBettingResults(1,0,[1120000])
    console.log("tokenPerBracket========>", await betting.tokenPerBracket(1,0,0), await betting.tokenPerBracket(1,0,1))
    console.log("tokenPerBracket2========>", await betting.tokenPerBracket(1,0,2), await betting.tokenPerBracket(1,0,3))
    console.log("tokenPerBracket3========>", await betting.tokenPerBracket(1,0,4), await betting.tokenPerBracket(1,0,5))
    console.log("finalNumber after=========>", await betting.finalNumbers(1,0))
    expect(await betting.finalNumbers(1,0)).to.equal(1120000)
    expect(await betting.countWinnersPerBracket(1,0,0)).to.equal(0)
    expect(await betting.countWinnersPerBracket(1,0,1)).to.equal(0)
    expect(await betting.countWinnersPerBracket(1,0,2)).to.equal(0)
    expect(await betting.countWinnersPerBracket(1,0,3)).to.equal(0)
    expect(await betting.countWinnersPerBracket(1,0,4)).to.equal(2)
    expect(await betting.countWinnersPerBracket(1,0,5)).to.equal(1)
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(1,0,0))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(1,0,1))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(1,0,2))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(1,0,3))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(1,0,4))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(1,0,5))
    console.log("status=========>", await betting.status(1,0))
    console.log("ticket1=========>", (await betting.tickets(1)).number)
    console.log("ticket2=========>", (await betting.tickets(2)).number)
    console.log("ticket3=========>", (await betting.tickets(3)).number)
    expect(await betting.status(1,0)).to.equal(2)
    expect((await betting.tickets(1)).number).to.equal(1120000)
    expect((await betting.tickets(2)).number).to.equal(1020000)
    expect((await betting.tickets(3)).number).to.equal(1320000)
    console.log("calculateRewardsForTicketId(1)=========>", await betting.calculateRewardsForTicketId(1,1,0))
    console.log("calculateRewardsForTicketId(2)=========>", await betting.calculateRewardsForTicketId(1,2,1))
    console.log("calculateRewardsForTicketId(3)=========>", await betting.calculateRewardsForTicketId(1,3,1))
    expect(await betting.calculateRewardsForTicketId(1,1,0)).to.equal(44)
    expect(await betting.calculateRewardsForTicketId(1,2,1)).to.equal(7)
    expect(await betting.calculateRewardsForTicketId(1,3,1)).to.equal(7)
    
  }).timeout(10000000);

  it("8) Claim Ticket", async function () {
    console.log("tickets(1)=========>", (await betting.tickets(1)).rewards)
    console.log("tickets(2)=========>", (await betting.tickets(2)).rewards)
    console.log("tickets(3)=========>", (await betting.tickets(3)).rewards)
    expect((await betting.tickets(1)).rewards).to.equal(0)
    expect((await betting.tickets(2)).rewards).to.equal(0)
    expect((await betting.tickets(3)).rewards).to.equal(0)

    await betting.claimTickets(1,[1,2,3], [0,1,1])

    console.log("tickets(1) after=========>", (await betting.tickets(1)).rewards)
    console.log("tickets(2) after=========>", (await betting.tickets(2)).rewards)
    console.log("tickets(3) after=========>", (await betting.tickets(3)).rewards)
    expect((await betting.tickets(1)).rewards).to.equal(44)
    expect((await betting.tickets(2)).rewards).to.equal(7)
    expect((await betting.tickets(3)).rewards).to.equal(7)

    await betting.userWithdraw(1)

  }).timeout(10000000);

  it("9) create betting event with alpha encoding", async function () {
    await betting.updateParameters(
      0, 
      ethers.BigNumber.from("1000000000000000000000000000"),
      ethers.BigNumber.from("999999999999999999999999999"),
      27
    )

    await betting.updateBettingEvent(
      ust.address,
      true,
      0,
      0,
      0,
      [0,0,3000,10,1000],
      [10000,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
      "scores",
      "media",
      "desicription",
      "a-z"
    )

    console.log("bettingEvent=========>", await betting.protocolInfo(2))

  }).timeout(10000000);

  it("10) Buy Ticket", async function () {
    // increase time
    await network.provider.send("evm_increaseTime", [1000])
    await network.provider.send("evm_mine")

    await ust.approve(betting.address, 30)
    await betting.buyWithContract(
      2, 
      owner.address, 
      "0x0000000000000000000000000000000000000000", 
      0, 
      0,
      [
        ethers.BigNumber.from("1000020005000100000300000000"),
        ethers.BigNumber.from("1000020005000100000300000700"),
      ]
    )

    console.log("ticket=========>", await betting.tickets(4))
    console.log("amountCollected=========>", await betting.amountCollected(2,0))
    console.log("balanceOf betting=========>", await ust.balanceOf(betting.address))
    console.log("balanceOf betting helper=========>", await ust.balanceOf(bettingHelper.address))

    // inject sponsor funds
    await ust.approve(betting.address, 30)
    await betting.injectFunds(2,0,30)
    console.log("balanceOf betting2=========>", await ust.balanceOf(betting.address))
    console.log("balanceOf betting helper2=========>", await ust.balanceOf(bettingHelper.address))

  }).timeout(10000000);

  it("11) Close Betting Period", async function () {
    // increase time
    await network.provider.send("evm_increaseTime", [2000])
    await network.provider.send("evm_mine")

    console.log("status before=========>", await betting.status(2,0))
    await betting.closeBetting(2)
    console.log("status after=========>", await betting.status(2,0))
    console.log("nextToClose=========>", (await betting.protocolInfo(2)).nextToClose)

  }).timeout(10000000);

  it("12) Set Result", async function () {
    await expect(betting.countWinnersPerBracket(2,0,0)).to.be.reverted
    await expect(betting.countWinnersPerBracket(2,0,1)).to.be.reverted
    await expect(betting.countWinnersPerBracket(2,0,2)).to.be.reverted
    await expect(betting.countWinnersPerBracket(2,0,3)).to.be.reverted
    await expect(betting.countWinnersPerBracket(2,0,4)).to.be.reverted
    await expect(betting.countWinnersPerBracket(2,0,5)).to.be.reverted
    await expect(betting.finalNumbers(2,0)).to.be.reverted
    
    await betting.setBettingResults(2,0,[ethers.BigNumber.from("1000020005000100000300000000")])
    console.log("tokenPerBracket========>", await betting.tokenPerBracket(2,0,0), await betting.tokenPerBracket(2,0,1))
    console.log("tokenPerBracket2========>", await betting.tokenPerBracket(2,0,2), await betting.tokenPerBracket(2,0,3))
    console.log("tokenPerBracket3========>", await betting.tokenPerBracket(2,0,4), await betting.tokenPerBracket(2,0,5))
    console.log("finalNumber after=========>", await betting.finalNumbers(2,0))
    expect(await betting.finalNumbers(2,0)).to.equal(ethers.BigNumber.from("1000020005000100000300000000"))
    expect(await betting.countWinnersPerBracket(2,0,0)).to.equal(1)
    expect(await betting.countWinnersPerBracket(2,0,1)).to.equal(0)
    expect(await betting.countWinnersPerBracket(2,0,2)).to.equal(0)
    expect(await betting.countWinnersPerBracket(2,0,3)).to.equal(0)
    expect(await betting.countWinnersPerBracket(2,0,4)).to.equal(0)
    expect(await betting.countWinnersPerBracket(2,0,5)).to.equal(0)
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(2,0,0))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(2,0,1))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(2,0,2))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(2,0,3))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(2,0,4))
    console.log("countWinnersPerBracket after=========>", await betting.countWinnersPerBracket(2,0,5))
    console.log("status=========>", await betting.status(2,0))
    console.log("ticket4=========>", (await betting.tickets(4)).number)
    console.log("ticket5=========>", (await betting.tickets(5)).number)
    expect(await betting.status(2,0)).to.equal(2)
    expect((await betting.tickets(4)).number).to.equal(ethers.BigNumber.from("1000020005000100000300000000"))
    expect((await betting.tickets(5)).number).to.equal(ethers.BigNumber.from("1000020005000100000300000700"))
    console.log("calculateRewardsForTicketId(4)=========>", await betting.calculateRewardsForTicketId(2,4,0))
    console.log("calculateRewardsForTicketId(5)=========>", await betting.calculateRewardsForTicketId(2,5,0))
    expect(await betting.calculateRewardsForTicketId(2,4,0)).to.equal(49)
    expect(await betting.calculateRewardsForTicketId(2,5,0)).to.equal(0)
    
  }).timeout(10000000);

  it("13) Claim Ticket", async function () {
    console.log("tickets(4)=========>", (await betting.tickets(4)).rewards)
    console.log("tickets(5)=========>", (await betting.tickets(5)).rewards)
    expect((await betting.tickets(4)).rewards).to.equal(0)
    expect((await betting.tickets(5)).rewards).to.equal(0)

    await betting.claimTickets(2,[4],[0])

    console.log("tickets(4).rewards after=========>", (await betting.tickets(4)).rewards)
    console.log("tickets(5).rewards after=========>", (await betting.tickets(5)).rewards)
    expect((await betting.tickets(4)).rewards).to.equal(49)
    expect((await betting.tickets(5)).rewards).to.equal(0)

    console.log("tickets(4)=========>", await betting.tickets(4))
    console.log("tokenURI(1)=================>", await bettingMinter.tokenURI(4))

  }).timeout(10000000);

});