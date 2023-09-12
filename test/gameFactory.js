const { expect } = require("chai");
const { ethers } = require("hardhat");
const { expectEvent } = require("@openzeppelin/test-helpers");

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

const PRICE_BNB = 400;

function gasToBNB(gas, gwei = 5) {
  const num = gas * gwei * 10 ** -9;
  return num.toFixed(4);
}

function gasToUSD(gas, gwei = 5, priceBNB = PRICE_BNB) {
  const num = gas * priceBNB * gwei * 10 ** -9;
  return num.toFixed(2);
}

describe("core", function () {

  let token;
  let ust;
  let lottery;
  let lotteryHelper;
  let owner;
  let owner2;
  let owner3;
  let ticketsBought;
  let marketPlaceCollection;
  let contractAddresses;
  let marketPlaceHelper3;
  let gameHelper;
  let gameHelper2;
  let gameMinter;
  let gameFactory;
  let auditorFactory
  let auditorHelper;
  let auditorNote;
  let auditor;

  it("deploy contracts", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();

    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("2000000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
    
    // vecontract = await ethers.getContractFactory("contracts/ve.sol:mve");
    // ve = await vecontract.deploy(ve_underlying.address);
    
    const RandomNumberGenerator = await ethers.getContractFactory("contracts/Lottery.sol:RandomNumberGenerator")
    const ContractAddresses =  await ethers.getContractFactory("contracts/MarketPlace.sol:ContractAddresses")
    const Lottery = await ethers.getContractFactory("LotteryContract");
    const LotteryHelper = await ethers.getContractFactory("LotteryHelper");
    const NFTicket = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicket");
    const NFTicketHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper");
    const NFTicketHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper2");
    const MarketPlaceEvents = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceEvents");
    const MarketPlaceCollection = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceCollection");
    const MarketPlaceOrders = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceOrders");
    const MarketPlaceTrades = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceTrades");
    const MarketPlaceHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper");
    const MarketPlaceHelper3 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper3");
    const ValuepoolVoter = await ethers.getContractFactory("ValuepoolVoter");
    const VavaHelper = await ethers.getContractFactory("ValuepoolHelper");
    const VavaHelper2 = await ethers.getContractFactory("ValuepoolHelper2");
    const Profile = await ethers.getContractFactory("Profile");
    const SSI = await ethers.getContractFactory("SSI");
    const GameHelper = await ethers.getContractFactory("GameHelper");
    const GameHelper2 = await ethers.getContractFactory("GameHelper2");
    const GameFactory = await ethers.getContractFactory("GameFactory");
    const Auditor = await ethers.getContractFactory("Auditor");
    const AuditorHelper = await ethers.getContractFactory("AuditorHelper");
    const AuditorHelper2 = await ethers.getContractFactory("AuditorHelper2");
    const AuditorFactory = await ethers.getContractFactory("AuditorFactory");
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    
    const ProfileHelper = await ethers.getContractFactory("ProfileHelper",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const AuditorNote = await ethers.getContractFactory("AuditorNote",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const GameMinter = await ethers.getContractFactory("GameMinter",{
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
    
    const MarketPlaceHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    
    contractAddresses = await ContractAddresses.deploy()
    await contractAddresses.deployed()

    randomNumberGenerator = await RandomNumberGenerator.deploy(
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      contractAddresses.address
    )

    lottery = await Lottery.deploy(
      randomNumberGenerator.address
    );
    await lottery.deployed()

    lotteryHelper = await LotteryHelper.deploy();
    await lotteryHelper.deployed()

    auditorNote = await AuditorNote.deploy();
  await auditorNote.deployed()

  auditorHelper = await AuditorHelper.deploy();
  await auditorHelper.deployed()

  auditorHelper2 = await AuditorHelper2.deploy();
  await auditorHelper2.deployed()

  auditorFactory = await AuditorFactory.deploy();
  await auditorFactory.deployed()

    valuepoolVoter = await ValuepoolVoter.deploy()
    await valuepoolVoter.deployed()

    gameMinter = await GameMinter.deploy()
  await gameMinter.deployed()

  gameHelper = await GameHelper.deploy()
  await gameHelper.deployed()

  gameHelper2 = await GameHelper2.deploy()
  await gameHelper2.deployed()

  gameFactory = await GameFactory.deploy()
  await gameFactory.deployed()

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

  ssi = await SSI.deploy()
  await ssi.deployed()

  profile = await Profile.deploy()
  await profile.deployed()

  profileHelper = await ProfileHelper.deploy()
  await profileHelper.deployed()

  // set ups
  await auditorNote.setContractAddress(contractAddresses.address)
  console.log("auditorNote.setContractAddress===========> Done!")

  await auditorHelper.setContractAddress(contractAddresses.address)
  console.log("auditorHelper.setContractAddress===========> Done!")

  await auditorHelper2.setContractAddress(contractAddresses.address)
  console.log("auditorHelper2.setContractAddress===========> Done!")

  await auditorFactory.setContractAddress(contractAddresses.address)
  console.log("auditorFactory.setContractAddress===========> Done!")

    await gameMinter.setContractAddress(contractAddresses.address)
  console.log("gameMinter.setContractAddress===========> Done!")

  await gameHelper.setContractAddress(contractAddresses.address)
  console.log("gameHelper.setContractAddress===========> Done!")

  await gameHelper2.setContractAddress(contractAddresses.address)
  console.log("gameHelper2.setContractAddress===========> Done!")

  await gameFactory.setContractAddress(contractAddresses.address)
  console.log("gameFactory.setContractAddress===========> Done!")

    await valuepoolVoter.setContractAddress(contractAddresses.address)
    console.log("valuepoolVoter.setContractAddress===========> Done!")
    
    await vavaHelper2.setContractAddress(contractAddresses.address)
    console.log("vavaHelper2.setContractAddress===========> Done!")
    
    await vavaHelper.setContractAddress(contractAddresses.address)
    console.log("vavaHelper.setContractAddress===========> Done!")

    await lottery.setContractAddress(contractAddresses.address)
    console.log("lottery.setContractAddress===========> Done!")

    await lotteryHelper.setContractAddress(contractAddresses.address)
    console.log("lotteryHelper.setContractAddress===========> Done!")

    await profile.setContractAddress(contractAddresses.address)
    console.log("profile.setContractAddress===========> Done!")

    await ssi.setContractAddress(contractAddresses.address)
    console.log("ssi.setContractAddress===========> Done!")

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

    await gameFactory.updateWhitelist(ust.address, true)

    randomNumberGenerator.setLotteryAddress(lottery.address)

    await contractAddresses.setAuditorHelper(auditorHelper.address)
  console.log("contractAddresses.setAuditorHelper===========> Done!")

  await contractAddresses.setAuditorHelper2(auditorHelper2.address)
  console.log("contractAddresses.setAuditorHelper2===========> Done!")

  await contractAddresses.setAuditorFactory(auditorFactory.address)
  console.log("contractAddresses.setAuditorFactory===========> Done!")

  await contractAddresses.setAuditorNote(auditorNote.address)
  console.log("contractAddresses.setAuditorNote===========> Done!")

    await contractAddresses.setGameMinter(gameMinter.address)
    console.log("contractAddresses.setGameMinter===========> Done!")

    await contractAddresses.setGameHelper(gameHelper.address)
    console.log("contractAddresses.setGameHelper===========> Done!")

    await contractAddresses.setGameHelper2(gameHelper2.address)
    console.log("contractAddresses.setGameHelper2===========> Done!")

    await contractAddresses.setGameFactory(gameFactory.address)
    console.log("contractAddresses.setGameFactory===========> Done!")
    
    await contractAddresses.setToken(ust.address)
    console.log("contractAddresses.setToken===========> Done!")

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

    await contractAddresses.setLotteryAddress(lottery.address)
    console.log("contractAddresses.setLotteryAddress===========> Done!")

    await contractAddresses.setLotteryHelper(lotteryHelper.address)
    console.log("contractAddresses.setLotteryHelper===========> Done!")

    await contractAddresses.setProfile(profile.address)
    console.log("contractAddresses.setProfile===========> Done!")

    await contractAddresses.setSSI(ssi.address)
    console.log("contractAddresses.setSSI===========> Done!")
  
    await contractAddresses.setProfileHelper(profileHelper.address)
    console.log("contractAddresses.setProfileHelper===========> Done!")
  
    await contractAddresses.setNfticket(nfticket.address)
    console.log("contractAddresses.setNfticket===========> Done!")
    
    await contractAddresses.setNfticketHelper(nfticketHelper.address)
    console.log("contractAddresses.setNfticketHelper===========> Done!")
    
    await contractAddresses.setNfticketHelper2(nfticketHelper2.address)
    console.log("contractAddresses.setNfticketHelper2===========> Done!")

    await contractAddresses.setMarketTrades(marketPlaceTrades.address)
  console.log("contractAddresses.setMarketTrades===========> Done!")

  await contractAddresses.setMarketCollections(marketPlaceCollection.address)
  console.log("contractAddresses.setMarketCollections===========> Done!")

  await contractAddresses.setMarketPlaceEvents(marketPlaceEvents.address)
  console.log("contractAddresses.setMarketPlaceEvents===========> Done!")

  await contractAddresses.setMarketHelpers3(marketPlaceHelper3.address)
  console.log("contractAddresses.setMarketHelpers3===========> Done!")
  
  await contractAddresses.setMarketHelpers2(marketPlaceHelper2.address)
  console.log("contractAddresses.setMarketHelpers2===========> Done!")
  
  await contractAddresses.setMarketHelpers(marketPlaceHelper.address)
  console.log("contractAddresses.setMarketHelpers===========> Done!")

  await marketPlaceHelper3.addDtoken(ust.address)
  await marketPlaceHelper3.addVetoken(ust.address)

  }).timeout(10000000);

  it("2) add collection", async function () {
    await marketPlaceCollection.addCollection(100,0,0,10,0,0,ust.address,false,false);
    
    expect((await marketPlaceCollection.addressToCollectionId(owner.address))).to.equal(1);
  }).timeout(10000000);

  it("start game", async function () {
    await gameFactory.addProtocol(
      ust.address,
      "0x0000000000000000000000000000000000000000",
      1,
      1000,
      1000,
      true
    );

    expect((await gameFactory.ticketInfo_(1)).owner).to.equal(owner.address)
    expect((await gameFactory.ticketInfo_(1)).gameContract).to.equal("0x0000000000000000000000000000000000000000")
    expect((await gameFactory.ticketInfo_(1)).pricePerMinutes).to.equal(1)
    expect((await gameFactory.ticketInfo_(1)).token).to.equal(ust.address)
    expect((await gameFactory.ticketInfo_(1)).teamShare).to.equal(100)
    expect((await gameFactory.ticketInfo_(1)).creatorShare).to.equal(1000)
    expect((await gameFactory.ticketInfo_(1)).referrerFee).to.equal(1000)
    expect((await gameFactory.ticketInfo_(1)).claimable).to.equal(true)
    console.log("ticketInfo_===========>", await gameFactory.ticketInfo_(1))

    await gameFactory.updateProtocol(
      owner.address, 
      owner.address,
      1, 
      1000,
      1000,
      true
    )

    expect((await gameFactory.ticketInfo_(1)).gameContract).to.equal(owner.address)

  
  }).timeout(10000000);

  it("mint gaming tickets", async function () {
    expect(await gameHelper.balanceOf(owner2.address)).to.equal(0)
    expect(await gameHelper.balanceOf(owner3.address)).to.equal(0)

    await gameMinter.mint(owner2.address, 1)
    await gameMinter.mint(owner3.address, 1)
    console.log("gameHelper.ownerOf(1)=====================>", await gameHelper.ownerOf(1), owner2.address)
    console.log("gameHelper.ownerOf(2)=====================>", await gameHelper.ownerOf(2), owner3.address)

    expect(await gameHelper.balanceOf(owner2.address)).to.equal(1)
    expect(await gameHelper.balanceOf(owner3.address)).to.equal(1)
    expect(await gameMinter.getReceiver(1)).to.equal(owner2.address)
    expect(await gameMinter.getReceiver(2)).to.equal(owner3.address)

  }).timeout(10000000);

  it("buy minutes", async function () {
    ust.connect(owner2).approve(gameFactory.address, 10000)
    await gameFactory.connect(owner2).buyWithContract(
      owner.address,
      owner2.address,
      owner3.address,
      "",
      1,
      0,
      [10000]
    )

    ust.connect(owner3).approve(gameFactory.address, 10000)
    await gameFactory.connect(owner3).buyWithContract(
      owner.address,
      owner3.address,
      "0x0000000000000000000000000000000000000000",
      "",
      2,
      0,
      [10000]
    )
    
    expect((await gameMinter.gameInfo_(1)).timer).to.equal(0)
    expect((await gameMinter.gameInfo_(1)).score).to.equal(0)
    expect((await gameMinter.gameInfo_(1)).deadline).to.equal(0)
    // expect((await gameMinter.gameInfo_(1)).pricePercentile).to.equal(92)
    expect((await gameMinter.gameInfo_(1)).price).to.equal(10000)
    expect((await gameMinter.gameInfo_(1)).won).to.equal(0)
    expect((await gameMinter.gameInfo_(1)).gameCount).to.equal(1)
    expect((await gameMinter.gameInfo_(1)).scorePercentile).to.equal(0)
    expect((await gameMinter.gameInfo_(1)).gameMinutes).gt(10000)
    console.log("gameMinter==============>", await gameMinter.gameInfo_(1))

    console.log("pendingRevenue============>", await gameFactory.pendingRevenue(owner3.address, ust.address))
    console.log("pendingRevenue============>", await gameFactory.pendingRevenue(owner2.address, ust.address))
    console.log("pendingRevenue============>", await gameFactory.pendingRevenue(owner.address, ust.address))
    expect(await gameFactory.pendingRevenue(owner3.address, ust.address)).to.equal(1000)
    expect(await gameFactory.pendingRevenue(owner2.address, ust.address)).to.equal(0)
    expect(await gameFactory.pendingRevenue(owner.address, ust.address)).to.equal(2200)
    expect(await gameFactory.pendingRevenue(owner.address, ust.address)).to.equal(2200)
    expect((await gameFactory.ticketInfo_(1)).totalPaid).gt(10000 - 3200)
    console.log("gameFactory==============>", await gameFactory.ticketInfo_(1))

  }).timeout(10000000);
  
  it("claim tickets", async function () {
    await gameMinter.updateScoreNDeadline(1, 100, 0)
    expect((await gameMinter.gameInfo_(1)).score).to.equal(100)
    expect((await gameFactory.ticketInfo_(1)).totalScore).to.equal(0)

    await gameFactory.connect(owner2).claimGameTicket(owner.address, 1, 1)
    expect((await gameMinter.gameInfo_(1)).score).to.equal(100)
    expect((await gameFactory.ticketInfo_(1)).totalScore).to.equal(100)

    console.log("ticketInfo_===========>", await gameFactory.ticketInfo_(1))
    console.log("paidPayable===========>", await gameFactory.paidPayable(1,1))

    await network.provider.send("evm_increaseTime", [10000])
    await network.provider.send("evm_mine")

    await gameMinter.updateScoreNDeadline(2, 100, 0)
    console.log("ticketInfo_1===========>", await gameMinter.gameInfo_(1))
    console.log("ticketInfo_2===========>", await gameMinter.gameInfo_(2))
    await expect(gameFactory.connect(owner3).claimGameTicket(owner.address, 1, 2)).to.be.reverted

  
  }).timeout(10000000);

  it("create auditor", async function () {
    // create profile
    await profile.createSpecificProfile("Owner1",1,0)

    await auditorFactory.createGauge(1, owner.address)

    let auditorAddress = (await auditorNote.getAllAuditors(0))[0]
    Auditor = await ethers.getContractFactory("Auditor");
    auditor = Auditor.attach(auditorAddress)
    // await auditor.setContractAddress(contractAddresses.address)
    await auditorHelper.updateCategory(auditor.address, 1)

    await auditor.updateProtocol(
      owner2.address,
      ust.address,
      [0,0,0,0],
      0,
      5,
      0,
      [3,2],
      "media",
      "description"
    )
  
  }).timeout(10000000);

  it("update object", async function () {
    console.log("auditor==============>", await auditorHelper.tokenIdToAuditor(1))
    console.log("protocolRatings2==============>", await auditor.getProtocolRatings(1))
    await gameHelper.updateObject(1, "diamond", [1], 1)

    console.log("resourceToObject==========>", await gameHelper.getResourceToObject(1, 0, "diamond"))
    expect((await gameHelper.getResourceToObject(1, 0, "diamond")).category).to.equal(1)
  
  }).timeout(10000000);
    
  it("mint object", async function () {
    expect(await auditorHelper.balanceOf(owner2.address)).to.equal(1)

    auditorHelper.connect(owner2).approve(gameHelper.address, 1)
    await gameHelper.connect(owner2).mintObject("diamond", 1, 1, [1])

    console.log("object token ids===========>", await gameHelper.getAllProtocolObjects(1, "diamond", 0))
    console.log("user objects===========>", await gameHelper.getAllObjects(1, 0))
    console.log("ticketInfo_===========>", await gameMinter.gameInfo_(1))

    expect(await auditorHelper.balanceOf(owner2.address)).to.equal(0)
    expect((await gameHelper.getAllObjects(1, 0))[0]).to.equal("diamond")
    
  }).timeout(10000000);

  it("burn object", async function () {
    expect(await auditorHelper.balanceOf(owner2.address)).to.equal(0)

    await gameHelper.connect(owner2).burnObject("diamond", 1, 1, owner.address)
    console.log("user objects after burn===========>", await gameHelper.getAllObjects(1, 0))

    // expect(await auditorHelper.balanceOf(owner2.address)).to.equal(1)

  }).timeout(10000000);

});
