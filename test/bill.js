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
  let BILL;
  let bill;
  let bill2;
  let bill3;
  let billNote;
  let billHelper;
  let billMinter;
  let billFactory;

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
    ARP = await ethers.getContractFactory("ARP");
    const ARPHelper = await ethers.getContractFactory("ARPHelper");
    const ARPNote = await ethers.getContractFactory("ARPNote");
    const StakeMarket = await ethers.getContractFactory("StakeMarket");
    const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
    const SSI = await ethers.getContractFactory("SSI");
    const ARPFactory = await ethers.getContractFactory("ARPFactory");
    const TrustBounties = await ethers.getContractFactory("TrustBounties");
    const TrustBountiesHelper = await ethers.getContractFactory("TrustBountiesHelper");
    const BusinessVoter = await ethers.getContractFactory("BusinessVoter");
    const ReferralVoter = await ethers.getContractFactory("ReferralVoter");
    const Profile = await ethers.getContractFactory("Profile");
    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    const StakeMarketBribe =  await ethers.getContractFactory("Bribe")
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    BILL = await ethers.getContractFactory("BILL");
    const BILLMinter = await ethers.getContractFactory("BILLMinter");
    const BILLNote = await ethers.getContractFactory("BILLNote");
    const BILLFactory = await ethers.getContractFactory("BILLFactory");

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

  const BILLHelper = await ethers.getContractFactory("BILLHelper",{
    libraries: {
      Percentile: percentile.address,
    },
  });

  const ARPMinter = await ethers.getContractFactory("ARPMinter",{
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

  ve = await vecontract.deploy(ve_underlying.address);
  await ve.deployed()

  ve_dist = await ve_distContract.deploy(ve.address);
  await ve_dist.deployed()

  contractAddresses = await ContractAddresses.deploy()
  await contractAddresses.deployed()

  billFactory = await BILLFactory.deploy(contractAddresses.address)
  await billFactory.deployed()

  billMinter = await BILLMinter.deploy()
  await billMinter.deployed()

  billNote = await BILLNote.deploy()
  await billNote.deployed()

  billHelper = await BILLHelper.deploy()
  await billHelper.deployed()

  arpFactory = await ARPFactory.deploy()
  await arpFactory.deployed()

  arpMinter = await ARPMinter.deploy()
  await arpMinter.deployed()

  arpNote = await ARPNote.deploy(contractAddresses.address)
  await arpNote.deployed()

  arpHelper = await ARPHelper.deploy()
  await arpHelper.deployed()

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

  veFactory = await VeFactory.deploy()
  await veFactory.deployed()

  valuepoolVoter = await ValuepoolVoter.deploy()
  await valuepoolVoter.deployed()

  marketPlaceEvents = await MarketPlaceEvents.deploy()
  await marketPlaceEvents.deployed()

  marketPlaceHelper3 = await MarketPlaceHelper3.deploy()
  await marketPlaceHelper3.deployed()

  marketPlaceCollection = await MarketPlaceCollection.deploy(
    owner.address,
    contractAddresses.address
  )
  await marketPlaceCollection.deployed()
  
  // set ups
  await billMinter.setContractAddress(contractAddresses.address)
  console.log("billMinter.setContractAddress===========> Done!")

  await billNote.setContractAddress(contractAddresses.address)
  console.log("billNote.setContractAddress===========> Done!")

  await billHelper.setContractAddress(contractAddresses.address)
  console.log("billHelper.setContractAddress===========> Done!")

  await arpFactory.setContractAddress(contractAddresses.address)
  console.log("arpFactory.setContractAddress===========> Done!")

  await arpMinter.setContractAddress(contractAddresses.address)
  console.log("arpMinter.setContractAddress===========> Done!")

  await arpHelper.setContractAddress(contractAddresses.address)
  console.log("arpHelper.setContractAddress===========> Done!")
  
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

  await marketPlaceEvents.setContractAddress(contractAddresses.address)
  console.log("marketPlaceEvents.setContractAddress===========> Done!")

  await marketPlaceHelper3.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper3.setContractAddress===========> Done!")

  // ####################### setDev
  await contractAddresses.setDevaddr(owner.address)
  console.log("contractAddresses.setDevaddr===========> Done!")  

  await contractAddresses.addContent('nsfw')

  await contractAddresses.setMarketPlaceEvents(marketPlaceEvents.address)
  console.log("contractAddresses.setMarketPlaceEvents===========> Done!")
    
  await contractAddresses.setMarketHelpers3(marketPlaceHelper3.address)
  console.log("contractAddresses.setMarketHelpers3===========> Done!")

  await contractAddresses.setBILLFactory(billFactory.address)
  console.log("contractAddresses.setBILLFactory===========> Done!")

  await contractAddresses.setBILLNote(billNote.address)
  console.log("contractAddresses.setBILLNote===========> Done!")

  await contractAddresses.setBILLHelper(billHelper.address)
  console.log("contractAddresses.setBILLHelper===========> Done!")

  await contractAddresses.setBILLMinter(billMinter.address)
  console.log("contractAddresses.setBILLMinter===========> Done!")

  await contractAddresses.setARPFactory(arpFactory.address)
  console.log("contractAddresses.setARPFactory===========> Done!")

  await contractAddresses.setARPNote(arpNote.address)
  console.log("contractAddresses.setARPNote===========> Done!")

  await contractAddresses.setARPHelper(arpHelper.address)
  console.log("contractAddresses.setARPHelper===========> Done!")

  await contractAddresses.setARPMinter(arpMinter.address)
  console.log("contractAddresses.setARPMinter===========> Done!")

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

  await contractAddresses.setMarketCollections(marketPlaceCollection.address)
  console.log("contractAddresses.setMarketCollections===========> Done!")

  await marketPlaceHelper3.addDtoken(ust.address)
  await marketPlaceHelper3.addVetoken(ve.address)

  }).timeout(10000000);

  it("02) add collection", async function () {
    await marketPlaceCollection.addCollection(100,0,0,10,0,0,ust.address,false,false);
    
    expect((await marketPlaceCollection.addressToCollectionId(owner.address))).to.equal(1);
  }).timeout(10000000);

  it("2) create BILL for banking", async function () {
    // create profile
    await profile.createSpecificProfile("Owner1",1,0)

    await billFactory.createGauge(
      1,
      owner.address,
      true
    );
    
    let billAddress = (await billMinter.getAllBills(0))[0]
    bill = BILL.attach(billAddress)
    console.log("bill===>", billAddress, bill.address)
    expect(billAddress).to.equal(bill.address)
    expect(await bill.isPayable()).to.equal(true)

  });

  it("3) create protocol", async function () {
    expect((await bill.protocolInfo(1)).debit).to.equal(0)
    expect((await bill.protocolInfo(1)).credit).to.equal(0)
    expect((await bill.protocolInfo(1)).creditFactor).to.equal(0)
    expect((await bill.protocolInfo(1)).debitFactor).to.equal(0)
    expect((await bill.protocolInfo(1)).periodReceivable).to.equal(0)
    expect((await bill.protocolInfo(1)).periodPayable).to.equal(0)
    expect((await bill.protocolInfo(1)).version).to.equal(0)
    expect((await bill.protocolInfo(1)).startPayable).to.equal(0)
    expect((await bill.protocolInfo(1)).startReceivable).to.equal(0)
    expect(await bill.addressToProtocolId(owner2.address)).to.equal(0)
    await expect(billMinter.ownerOf(1)).to.be.reverted
    await bill.updateMigrationPoint(
      0,
      0,
      10000,
      10000
    )

    await bill.updateProtocol(
      owner2.address,
      ust.address,
      0,
      [0,0,0,3000,3000],
      0,
      0,
      "link_to_media",
      "description"
    )

    console.log("protocolInfo============>", await bill.protocolInfo(1))
    expect((await bill.protocolInfo(1)).creditFactor).to.equal(10000)
    expect((await bill.protocolInfo(1)).debitFactor).to.equal(10000)
    expect((await bill.protocolInfo(1)).token).to.equal(ust.address)
    expect((await bill.protocolInfo(1)).debit).to.equal(0)
    expect((await bill.protocolInfo(1)).credit).to.equal(0)
    expect((await bill.protocolInfo(1)).periodReceivable).to.equal(3000)
    expect((await bill.protocolInfo(1)).periodPayable).to.equal(3000)
    expect((await bill.protocolInfo(1)).version).to.equal(1)
    expect((await bill.protocolInfo(1)).startPayable).to.not.equal(0)
    expect((await bill.protocolInfo(1)).startReceivable).to.not.equal(0)
    expect(await bill.addressToProtocolId(owner2.address)).to.equal(1)
    expect(await billMinter.ownerOf(1)).to.equal(owner2.address)

  });

  it("4) autocharge", async function () {
    console.log("dueReceivable before=========>", await billNote.getDueReceivable(bill.address, 1))
    expect((await billNote.getDueReceivable(bill.address, 1))[0]).to.equal(0)
    expect((await billNote.getDueReceivable(bill.address, 1))[2]).lte(-3000)

    console.log("duePayable before=========>", await billNote.getDuePayable(bill.address, 1))
    expect((await billNote.getDuePayable(bill.address, 1))[0]).to.equal(0)
    expect((await billNote.getDuePayable(bill.address, 1))[2]).lte(-3000)

    // increase time
    await network.provider.send("evm_increaseTime", [3001])
    await network.provider.send("evm_mine")

    console.log("dueReceivable after=========>", await billNote.getDueReceivable(bill.address, 1))
    expect((await billNote.getDueReceivable(bill.address, 1))[0]).to.equal(0)
    expect((await billNote.getDueReceivable(bill.address, 1))[2]).lte(5)

    expect(await ust.balanceOf(bill.address)).to.equal(0)
    await ust.connect(owner2).approve(bill.address, 1000);
    await bill.connect(owner2).autoCharge([1], 1000)
    expect(await ust.balanceOf(bill.address)).to.equal(1000 * (100 - 1) / 100)

    console.log("dueReceivable after autocharge=========>", await billNote.getDueReceivable(bill.address, 1))
    expect((await billNote.getDueReceivable(bill.address, 1))[0]).to.equal(0)
    expect((await billNote.getDueReceivable(bill.address, 1))[2]).lte(5)
    
    console.log("protocolInfo after autocharge==========>", await bill.protocolInfo(1))
    expect((await bill.protocolInfo(1)).credit).to.equal(1000 * (100 - 1 - 0) / 100)
    console.log("duePayable after autocharge=========>", await billNote.getDuePayable(bill.address, 1))
    expect((await billNote.getDuePayable(bill.address, 1))[0]).to.equal(1000 * (100 - 1 - 0) / 100)
    expect((await billNote.getDuePayable(bill.address, 1))[2]).lte(5)

  });

  it("5) Pay Invoice Payable", async function () {
    console.log("duePayable after=========>", await billNote.getDuePayable(bill.address, 1))
    expect((await billNote.getDuePayable(bill.address, 1))[0]).to.equal(1000 * (100 - 1 - 0) / 100)
    expect((await billNote.getDuePayable(bill.address, 1))[2]).lte(5)

    console.log("bill balance before============>", await ust.balanceOf(bill.address))
    expect(await ust.balanceOf(bill.address)).to.equal(990)
    expect(await ust.balanceOf(billMinter.address)).to.equal(10)

    const user_balance_before = await ust.balanceOf(owner2.address)
    console.log("user balance before============>", user_balance_before)

    await bill.payInvoicePayable(1, 0)
    console.log("bill balance after============>", await ust.balanceOf(bill.address))
    console.log("user balance after============>", await ust.balanceOf(owner2.address))

    console.log("duePayable after autocharge=========>", await billNote.getDuePayable(bill.address, 1))
    expect(await ust.balanceOf(owner2.address)).to.equal(user_balance_before.add(981))
    expect(await ust.balanceOf(billMinter.address)).to.equal(19)
    expect((await billNote.getDuePayable(bill.address, 1))[0]).to.equal(0)
    expect((await billNote.getDuePayable(bill.address, 1))[2]).lte(10)

  });

  it("6)create BILL for utility/tax payments", async function () {
    await billFactory.createGauge(
      1,
      owner.address,
      false
    );
    
    let bill2Address = (await billMinter.getAllBills(0))[1]
    bill2 = BILL.attach(bill2Address)
    console.log("bill2===>", bill2Address, bill.address)
    expect(bill2Address).to.equal(bill2.address)
    expect(await bill2.isPayable()).to.equal(false)

  });

  it("7) create protocol", async function () {
    expect((await bill2.protocolInfo(2)).debit).to.equal(0)
    expect((await bill2.protocolInfo(2)).credit).to.equal(0)
    expect((await bill2.protocolInfo(2)).creditFactor).to.equal(0)
    expect((await bill2.protocolInfo(2)).debitFactor).to.equal(0)
    expect((await bill2.protocolInfo(2)).periodReceivable).to.equal(0)
    expect((await bill2.protocolInfo(2)).periodPayable).to.equal(0)
    expect((await bill2.protocolInfo(2)).version).to.equal(0)
    expect((await bill2.protocolInfo(2)).startPayable).to.equal(0)
    expect((await bill2.protocolInfo(2)).startReceivable).to.equal(0)
    expect(await bill2.addressToProtocolId(owner2.address)).to.equal(0)
    await expect(billMinter.ownerOf(2)).to.be.reverted
    // x * (100 - 1)/100 = 1000 => x = 1000 * 100 / (100 - 1)
    await bill2.updateMigrationPoint(
      0,
      0,
      10000,
      10100
    )

    await bill2.updateProtocol(
      owner2.address,
      ust.address,
      0,
      [0,0,0,3000,3000],
      0,
      0,
      "link_to_media",
      "description"
    )

    console.log("protocolInfo============>", await bill2.protocolInfo(1))
    expect((await bill2.protocolInfo(2)).creditFactor).to.equal(10000)
    expect((await bill2.protocolInfo(2)).debitFactor).to.equal(10100)
    expect((await bill2.protocolInfo(2)).token).to.equal(ust.address)
    expect((await bill2.protocolInfo(2)).debit).to.equal(0)
    expect((await bill2.protocolInfo(2)).credit).to.equal(0)
    expect((await bill2.protocolInfo(2)).periodReceivable).to.equal(3000)
    expect((await bill2.protocolInfo(2)).periodPayable).to.equal(3000)
    expect((await bill2.protocolInfo(2)).version).to.equal(1)
    expect((await bill2.protocolInfo(2)).startPayable).to.not.equal(0)
    expect((await bill2.protocolInfo(2)).startReceivable).to.not.equal(0)
    expect(await bill2.addressToProtocolId(owner2.address)).to.equal(2)
    expect(await billMinter.ownerOf(2)).to.equal(owner2.address)

  });

  it("8) autocharge", async function () {
    console.log("dueReceivable before=========>", await billNote.getDueReceivable(bill2.address, 2))
    expect((await billNote.getDueReceivable(bill2.address, 2))[0]).to.equal(0)
    expect((await billNote.getDueReceivable(bill2.address, 2))[2]).lte(-3000)

    console.log("duePayable before=========>", await billNote.getDuePayable(bill2.address, 2))
    expect((await billNote.getDuePayable(bill2.address, 2))[0]).to.equal(0)
    expect((await billNote.getDuePayable(bill2.address, 2))[1]).to.equal(0)
    expect((await billNote.getDuePayable(bill2.address, 2))[2]).to.equal(0)

    // add utility bill of 1000
    await bill2.notifyDebit(owner.address, owner2.address, 1000)
    console.log("protocolInfo==========>", await bill2.protocolInfo(2))

    // increase time
    await network.provider.send("evm_increaseTime", [3001])
    await network.provider.send("evm_mine")

    console.log("dueReceivable after=========>", await billNote.getDueReceivable(bill2.address, 2))
    expect((await billNote.getDueReceivable(bill2.address, 2))[0]).to.equal(1010)
    expect((await billNote.getDueReceivable(bill2.address, 2))[2]).gte(3000)

    expect(await ust.balanceOf(bill2.address)).to.equal(0)
    await ust.connect(owner2).approve(bill2.address, 1010);
    await bill2.connect(owner2).autoCharge([2], 0)
    console.log("balanceOf============>", await ust.balanceOf(bill2.address))
    expect(await ust.balanceOf(bill2.address)).to.equal(1000)

    console.log("dueReceivable after autocharge=========>", await billNote.getDueReceivable(bill2.address, 2))
    expect((await billNote.getDueReceivable(bill2.address, 2))[0]).to.equal(0)
    expect((await billNote.getDueReceivable(bill2.address, 2))[2]).lte(5)
    expect(await ust.balanceOf(billMinter.address)).to.equal(29)
    
    console.log("protocolInfo after autocharge==========>", await bill2.protocolInfo(2))
    expect((await bill2.protocolInfo(2)).credit).to.equal(1000)
    console.log("duePayable after autocharge=========>", await billNote.getDuePayable(bill2.address, 2))
    expect((await billNote.getDuePayable(bill2.address, 2))[0]).to.equal(0)
    expect((await billNote.getDuePayable(bill2.address, 2))[1]).to.equal(0)
    expect((await billNote.getDuePayable(bill2.address, 2))[2]).to.equal(0)

  });

  it("9) Pay Invoice Payable", async function () {
    console.log("duePayable after=========>", await billNote.getDuePayable(bill2.address, 2))
    expect((await billNote.getDuePayable(bill2.address, 2))[0]).to.equal(0)
    expect((await billNote.getDuePayable(bill2.address, 2))[2]).to.equal(0)

    console.log("bill balance before============>", await ust.balanceOf(bill2.address))
    expect(await ust.balanceOf(bill2.address)).to.equal(1000)
    expect(await ust.balanceOf(billMinter.address)).to.equal(29)

    const user_balance_before = await ust.balanceOf(owner2.address)
    console.log("user balance before============>", user_balance_before)

    await expect(bill2.payInvoicePayable(2, 0)).to.be.reverted
    console.log("bill balance after============>", await ust.balanceOf(bill2.address))
    console.log("user balance after============>", await ust.balanceOf(owner2.address))

    console.log("duePayable after autocharge=========>", await billNote.getDuePayable(bill2.address, 2))
    expect(await ust.balanceOf(owner2.address)).to.equal(user_balance_before.add(0))
    expect(await ust.balanceOf(billMinter.address)).to.equal(29)
    expect((await billNote.getDuePayable(bill2.address, 2))[0]).to.equal(0)
    expect((await billNote.getDuePayable(bill2.address, 2))[2]).to.equal(0)

  });

  // it("13) Pay Invoice Payable", async function () {
  //   console.log("duePayable after=========>", await billNote.getDuePayable(bill3.address, 3))
  //   expect((await billNote.getDuePayable(bill3.address, 3))[0]).to.equal(1000 * (100 - 1 - 0) / 100)
  //   expect((await billNote.getDuePayable(bill3.address, 3))[2]).lte(5)

  //   console.log("bill balance before============>", await ust.balanceOf(bill3.address))
  //   expect(await ust.balanceOf(bill3.address)).to.equal(990)
  //   expect(await ust.balanceOf(billMinter.address)).to.equal(39)

  //   expect(await ust.balanceOf(bill3.address)).to.equal(0)
  //   await ust.connect(owner2).approve(bill3.address, 1000);
  //   await bill3.connect(owner2).autoCharge([3], 1000)
  //   expect(await ust.balanceOf(bill3.address)).to.equal(1000 * (100 - 1) / 100)

  //   console.log("duePayable after autocharge=========>", await billNote.getDuePayable(bill3.address, 3))
  //   expect(await ust.balanceOf(owner2.address)).to.equal(user_balance_before.add(981))
  //   expect(await ust.balanceOf(billMinter.address)).to.equal(48)
  //   expect((await billNote.getDuePayable(bill3.address, 3))[0]).to.equal(0)
  //   expect((await billNote.getDuePayable(bill3.address, 3))[2]).lte(10)

  // });

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