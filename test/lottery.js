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
  let va;
  let vava;
  let vavaFactory;
  let vavaHelper;

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
    const GameFactory = await ethers.getContractFactory("GameFactory");
    const GameHelper2 = await ethers.getContractFactory("GameHelper2");
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    
    const ProfileHelper = await ethers.getContractFactory("ProfileHelper",{
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

  it("start lottery", async function () {
    await lotteryHelper.startLottery(
      owner.address,
      "0x0000000000000000000000000000000000000000",
        0,
        7 * 3600,
        0,
        0,
        false,
        [1000,1000,10000,1000],
        [250, 375, 625, 1250, 2500, 5000]
    );

    expect((await lottery.viewLottery(1)).status).to.equal(1)
    expect((await lottery.viewLottery(1)).treasury.priceTicket).to.equal(10000)
    expect((await lottery.viewLottery(1)).discountDivisor).to.equal(1000)
    expect((await lottery.viewLottery(1)).treasury.fee).to.equal(1000)
    expect((await lottery.viewLottery(1)).firstTicketId).to.equal(1)
    expect((await lottery.viewLottery(1)).treasury.referrerFee).to.equal(1000)
    expect((await lottery.viewLottery(1)).treasury.useNFTicket).to.equal(false)
    expect((await lottery.viewLottery(1)).finalNumber).to.equal(0)
    console.log(await lottery.viewLottery(1))
  }).timeout(10000000);

  it("buy 100 tickets", async function () {
    // expect(await lottery.currentTicketId()).to.equal(1)
    ticketsBought = [
      "1111111",
      "1222222",
      "1333333",
      "1444444",
      "1555555",
      "1666666",
      "1777777",
      "1888888",
      "1000000",
      "1999999",
    ];
    await ust.connect(owner2).approve(lottery.address, 1000000)
    await lottery.connect(owner2).buyWithContract(
      owner.address,
      owner2.address,
      "0x0000000000000000000000000000000000000000",
      "Name",
      0,
      0, 
      ticketsBought
    )
    
  //   expect(await lottery.currentTicketId()).to.equal(101)

  }).timeout(10000000);

  it("close lottery", async function () {
    await expect(lottery.closeLottery(1,0)).to.be.reverted
    
    await network.provider.send("evm_increaseTime", [7 * 3600])
    await network.provider.send("evm_mine")

    await lottery.closeLottery(1,0)
    expect((await lottery.viewLottery(1)).status).to.equal(2)

  }).timeout(10000000);

  it("draw lottery", async function () {
    // await lottery.injectFunds("1", parseEther("10000"), { from: alice });
    await randomNumberGenerator.setNextRandomResult(199999999)
    await lottery.drawFinalNumberAndMakeLotteryClaimable(1);
    console.log("viewRandomResult==========>", await randomNumberGenerator.viewRandomResult(1))
    console.log("viewLottery=================>", await lottery.viewLottery(1))
    expect((await lottery.viewLottery(1)).finalNumber).to.equal(1999999)
    console.log("viewUserInfoForLotteryId==========>", await lotteryHelper.viewUserInfoForLotteryId(
      owner2.address,
      1,
      0,
      ticketsBought.length
    ))
  }).timeout(10000000);

  it("claim ticket", async function () {
    expect(await lotteryHelper.viewRewardsForTicketId(1,9,5,ust.address)).to.equal(0)
    expect(await lotteryHelper.viewRewardsForTicketId(1,10,5,ust.address)).to.equal(44595)
    
    expect(await lottery.getPendingReward(1, owner2.address, ust.address, false)).to.equal(0)
    await lottery.connect(owner2).claimTickets(1, [10], [5]);
    console.log("viewNumbersAndStatusesForTicketIds=========>", await lotteryHelper.viewNumbersAndStatusesForTicketIds([10]))
    expect(await lottery.getPendingReward(1, owner2.address, ust.address, false)).to.equal(44595)

    const ustBefore = await ust.balanceOf(owner2.address)
    await lottery.connect(owner2).withdrawPendingReward(ust.address, 1, 0)
    expect(await ust.balanceOf(owner2.address)).gt(ustBefore)
    expect(await lottery.getPendingReward(1, owner2.address, ust.address, false)).to.equal(0)

  }).timeout(10000000);

  it("6) create and set up valuepool", async function () {
    await vavaFactory.createValuePool(
      ust.address,
      owner.address,
      "0x0000000000000000000000000000000000000000",
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
      false
    )
    
    await ust.connect(owner).approve(va.address, ethers.BigNumber.from("100000000000000000"));
    expect(await va.balanceOfNFT(1)).to.equal(0)
    await va.create_lock_for(ethers.BigNumber.from("100000000000000000"), 4 * 365 * 86400, 0, owner.address)
    expect(await va.balanceOfNFT(1)).to.not.equal(0)
    console.log("va balance===>", await va.balanceOfNFT(1))

  }).timeout(10000000);

  it("start lottery that ends after amount reached", async function () {
    await lotteryHelper.startLottery(
        owner.address,
        vava.address,
        0,
        7 * 3600,
        9900,
        4 * 365 * 86400,
        false,
        [1000,1000,100000000,1000],
        [250, 375, 625, 1250, 2500, 5000]
    );

    console.log("valuepool============>", await lottery.viewLottery(2))
    expect((await lottery.viewLottery(2)).status).to.equal(1)
    expect((await lottery.viewLottery(2)).valuepool).to.equal(vava.address)
    expect((await lottery.viewLottery(2)).treasury.useNFTicket).to.equal(false)
    expect((await lottery.viewLottery(2)).treasury.priceTicket).to.equal(100000000)
    expect((await lottery.viewLottery(2)).discountDivisor).to.equal(1000)
    expect((await lottery.viewLottery(2)).treasury.fee).to.equal(1000)
    expect((await lottery.viewLottery(2)).firstTicketId).to.equal(11)
    expect((await lottery.viewLottery(2)).treasury.referrerFee).to.equal(1000)
    expect((await lottery.viewLottery(2)).treasury.useNFTicket).to.equal(false)
    expect((await lottery.viewLottery(2)).finalNumber).to.equal(0)
    console.log(await lottery.viewLottery(2))
  }).timeout(10000000);

  it("buy 100 tickets", async function () {
    await expect(lottery.closeLottery(2,0)).to.be.reverted
    // expect(await lottery.currentTicketId()).to.equal(1)
    ticketsBought = [
      "1111111",
      "1222222",
      "1333333",
      "1444444",
      "1555555",
      "1666666",
      "1777777",
      "1888888",
      "1000000",
      "1999999",
    ];
    await ust.connect(owner2).approve(lottery.address, 10000000000)
    await lottery.connect(owner2).buyWithContract(
      owner.address,
      owner2.address,
      "0x0000000000000000000000000000000000000000",
      "Name",
      0,
      0, 
      ticketsBought
    )
    console.log("amountCollected============>", await lottery.amountCollected(2,ust.address))
    
  //   expect(await lottery.currentTicketId()).to.equal(101)

  }).timeout(10000000);

  it("close lottery", async function () {
    await lottery.closeLottery(2,0)
    expect((await lottery.viewLottery(2)).status).to.equal(2)

  }).timeout(10000000);

  it("draw lottery", async function () {
    // await lottery.injectFunds("1", parseEther("10000"), { from: alice });
    await randomNumberGenerator.setNextRandomResult(199999999)
    await lottery.drawFinalNumberAndMakeLotteryClaimable(2);
    console.log("viewRandomResult==========>", await randomNumberGenerator.viewRandomResult(2))
    console.log("viewLottery=================>", await lottery.viewLottery(2))
    expect((await lottery.viewLottery(1)).finalNumber).to.equal(1999999)
    console.log("viewUserInfoForLotteryId==========>", await lotteryHelper.viewUserInfoForLotteryId(
      owner2.address,
      2,
      0,
      ticketsBought.length
    ))
  }).timeout(10000000);

  it("claim ticket", async function () {
    console.log("viewRewardsForTicketId=============>", await lotteryHelper.viewRewardsForTicketId(2,20,5,ust.address))
    expect(await lotteryHelper.viewRewardsForTicketId(2,19,5,ust.address)).to.equal(0)
    expect(await lotteryHelper.viewRewardsForTicketId(2,20,5,ust.address)).to.equal(445950000)
    
    expect(await lottery.getPendingReward(2, owner2.address, ust.address, false)).to.equal(0)
    await lottery.connect(owner2).claimTickets(2, [20], [5]);
    console.log("viewNumbersAndStatusesForTicketIds=========>", await lotteryHelper.viewNumbersAndStatusesForTicketIds([20]))
    expect(await lottery.getPendingReward(2, owner2.address, ust.address, false)).to.equal(445950000)

    const ustBefore = await ust.balanceOf(owner2.address)
    expect(await va.ownerOf(2)).to.equal("0x0000000000000000000000000000000000000000")
    await lottery.connect(owner2).withdrawPendingReward(ust.address, 2, 0)
    expect(await ust.balanceOf(owner2.address)).to.equal(ustBefore)
    expect(await lottery.getPendingReward(2, owner2.address, ust.address, false)).to.equal(0)
    expect(await va.ownerOf(2)).to.equal(owner2.address)
    console.log("va.balanceOf===========>", await va.balanceOfNFT(2))
    expect(await va.balanceOfNFT(2)).gt(370000000)

  }).timeout(10000000);


  it("start lottery with nfticket", async function () {
    await lotteryHelper.startLottery(
        owner.address,
        vava.address,
        0,
        7 * 3600,
        9900,
        4 * 365 * 86400,
        false,
        [1000,1000,100000000,1000],
        [250, 375, 625, 1250, 2500, 5000]
    );

    console.log("valuepool============>", await lottery.viewLottery(2))
    expect((await lottery.viewLottery(3)).status).to.equal(1)
    expect((await lottery.viewLottery(3)).valuepool).to.equal(vava.address)
    expect((await lottery.viewLottery(3)).treasury.useNFTicket).to.equal(false)
    expect((await lottery.viewLottery(3)).treasury.priceTicket).to.equal(100000000)
    expect((await lottery.viewLottery(3)).discountDivisor).to.equal(1000)
    expect((await lottery.viewLottery(3)).treasury.fee).to.equal(1000)
    expect((await lottery.viewLottery(3)).firstTicketId).to.equal(21)
    expect((await lottery.viewLottery(3)).treasury.referrerFee).to.equal(1000)
    expect((await lottery.viewLottery(3)).finalNumber).to.equal(0)
    console.log(await lottery.viewLottery(3))
  }).timeout(10000000);

  it("add burn for credit", async function () {
    // mint ssid
    await profile.createSpecificProfile("tepa", 1, 0)
    await profile.shareEmail(owner2.address)
    await profile.connect(owner2).createProfile("tepa2", 0)

    await ssi.generateShareProof(owner2.address,2,1,1,86700 * 7,"ssid","tepa")
    await ssi.generateShareProof(owner2.address,2,1,1,86700 * 7,"ssid2","tepa")
    // await ssi.connect(owner2).updateSSID(1,1)
    // await ssi.connect(owner2).updateSSID(1,2)
    console.log("====================>", await ssi.metadata(1), await ssi.ownerOf(1), owner2.address)
    console.log("====================>", await ssi.metadata(2), await ssi.ownerOf(2), owner2.address)

    await lotteryHelper.updateBurnTokenForCredit(
        ssi.address,
        ssi.address,
        lottery.address,
        100000000 * 10000,
        1,
        false,
        "ssid"
      )

      expect(await lotteryHelper.paymentCredits(owner2.address, 3)).to.equal(0)
      ticketsBought = ["1999999"];
      await ssi.connect(owner2).approve(lotteryHelper.address, 1)
      await ssi.connect(owner2).approve(lotteryHelper.address, 2)
      await ust.connect(owner2).approve(lottery.address, 0)
      await expect(lottery.connect(owner2).buyWithContract(
        owner.address,
        owner2.address,
        "0x0000000000000000000000000000000000000000",
        "Name",
        0,
        0, 
        ticketsBought
      )).to.be.reverted

      await lotteryHelper.connect(owner2).burnForCredit(owner.address, 0, 2)
      console.log("paymentCredits============>", await lotteryHelper.paymentCredits(owner2.address, 3))
      expect(await lotteryHelper.paymentCredits(owner2.address, 3)).to.equal(0)
      
      await lotteryHelper.connect(owner2).burnForCredit(owner.address, 0, 1)
      console.log("paymentCredits============>", await lotteryHelper.paymentCredits(owner2.address, 3))
      expect(await lotteryHelper.paymentCredits(owner2.address, 3)).to.equal(100000000)

      await lottery.connect(owner2).buyWithContract(
        owner.address,
        owner2.address,
        "0x0000000000000000000000000000000000000000",
        "Name",
        0,
        0, 
        ticketsBought
      )
      expect(await lotteryHelper.paymentCredits(owner2.address, 3)).to.equal(0)

  }).timeout(10000000);

});
