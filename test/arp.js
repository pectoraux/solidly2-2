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
  let ARP;
  let arp;
  let arp2;
  let arp3;
  let arpNote;
  let arpHelper;
  let arpMinter;
  let arpFactory;
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
    const MarketPlaceHelper3 = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceHelper3");
    const MarketPlaceHelper03 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper3");
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

  // set ups
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

  // ####################### setDev
  await contractAddresses.setDevaddr(owner.address)
  console.log("contractAddresses.setDevaddr===========> Done!")  

  await contractAddresses.addContent('nsfw')

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

  });


  it("2) create manual/scalar based ARP", async function () {
    // create profile
    await profile.createSpecificProfile("Owner1",1,0)

    await arpFactory.createGauge(
      1,
      owner.address,
      "0x0000000000000000000000000000000000000000",
      false,
      false,
      true
    );
    
    let arpHelperAddress = (await arpHelper.getAllARPs(0))[0]
    arp = ARP.attach(arpHelperAddress)
    console.log("arp===>", arpHelperAddress, arp.address)
    expect(arpHelperAddress).to.equal(arp.address)

  });

  it("3) create protocol", async function () {
    expect((await arp.protocolInfo(1)).amountPayable).to.equal(0)
    expect((await arp.protocolInfo(1)).amountReceivable).to.equal(0)
    expect((await arp.protocolInfo(1)).periodReceivable).to.equal(0)
    expect((await arp.protocolInfo(1)).periodPayable).to.equal(0)
    expect((await arp.protocolInfo(1)).startPayable).to.equal(0)
    expect((await arp.protocolInfo(1)).startReceivable).to.equal(0)
    expect(await arp.addressToProtocolId(owner2.address)).to.equal(0)
    await expect(arpHelper.ownerOf(1)).to.be.reverted

    await arp.updateProtocol(
      owner2.address,
      ust.address,
      [1000,3000,0,2000,3000,0,0],
      0,
      0,
      0,
      "link_to_media",
      "description"
    )

    console.log("protocolInfo============>", await arp.protocolInfo(1))
    expect((await arp.protocolInfo(1)).amountPayable).to.equal(2000)
    expect((await arp.protocolInfo(1)).amountReceivable).to.equal(1000)
    expect((await arp.protocolInfo(1)).periodReceivable).to.equal(3000)
    expect((await arp.protocolInfo(1)).periodPayable).to.equal(3000)
    expect((await arp.protocolInfo(1)).startPayable).to.not.equal(0)
    expect((await arp.protocolInfo(1)).startReceivable).to.not.equal(0)
    expect(await arp.addressToProtocolId(owner2.address)).to.equal(1)
    expect(await arpHelper.ownerOf(1)).to.equal(owner2.address)

  });

  it("4) autocharge", async function () {
    console.log("dueReceivable before=========>", await arpNote.getDueReceivable(arp.address, 1, 0))
    expect((await arpNote.getDueReceivable(arp.address, 1, 0))[0]).to.equal(0)
    // expect((await arpNote.getDueReceivable(arp.address, 1, 0))[2]).to.equal(-3000)

    console.log("duePayable before=========>", await arpNote.getDuePayable(arp.address, 1, 0))
    expect((await arpNote.getDuePayable(arp.address, 1, 0))[0]).to.equal(0)
    // expect((await arpNote.getDuePayable(arp.address, 1, 0))[2]).to.equal(-3000)

    // increase time
    await network.provider.send("evm_increaseTime", [3001])
    await network.provider.send("evm_mine")

    console.log("dueReceivable after=========>", await arpNote.getDueReceivable(arp.address, 1, 0))
    expect((await arpNote.getDueReceivable(arp.address, 1, 0))[0]).to.equal(1000)
    expect((await arpNote.getDueReceivable(arp.address, 1, 0))[2]).gte(1)

    await ust.connect(owner2).approve(arp.address, 1000);
    await arp.connect(owner2).autoCharge([1], 0)

    console.log("dueReceivable after autocharge=========>", await arpNote.getDueReceivable(arp.address, 1, 0))
    // expect((await arpNote.getDueReceivable(arp.address, 1, 0))[0]).to.equal(0)
    expect((await arpNote.getDueReceivable(arp.address, 1, 0))[2]).lte(5)

  });

  it("5) Pay Invoice Payable", async function () {
    console.log("duePayable after=========>", await arpNote.getDuePayable(arp.address, 1, 0))
    expect((await arpNote.getDuePayable(arp.address, 1, 0))[0]).to.equal(2000)
    expect((await arpNote.getDuePayable(arp.address, 1, 0))[2]).gte(1)

    console.log("arp balance before============>", await ust.balanceOf(arp.address))
    expect(await ust.balanceOf(arp.address)).to.equal(990)
    expect(await ust.balanceOf(arpHelper.address)).to.equal(10)

    const user_balance_before = await ust.balanceOf(owner2.address)
    console.log("user balance before============>", user_balance_before)

    await ust.connect(owner).approve(arp.address, 2000);
    await arp.payInvoicePayable(1, 0)
    console.log("arp balance after============>", await ust.balanceOf(arp.address))
    console.log("user balance after============>", await ust.balanceOf(owner2.address))

    console.log("duePayable after autocharge=========>", await arpNote.getDuePayable(arp.address, 1, 0))
    expect(await ust.balanceOf(owner2.address)).to.equal(user_balance_before.add(1980))
    expect(await ust.balanceOf(arpHelper.address)).to.equal(30)
    expect((await arpNote.getDuePayable(arp.address, 1, 0))[0]).to.equal(0)
    expect((await arpNote.getDuePayable(arp.address, 1, 0))[2]).lte(10)

  });

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
      true
    )
    
    await ust.connect(owner).approve(va.address, ethers.BigNumber.from("100000000000000000"));
    expect(await va.balanceOfNFT(1)).to.equal(0)
    await va.create_lock_for(ethers.BigNumber.from("100000000000000000"), 4 * 365 * 86400, 0, owner.address)
    expect(await va.balanceOfNFT(1)).to.not.equal(0)
    console.log("va balance===>", await va.balanceOfNFT(1))

  })

  it("7) create manual/percentage based ARP", async function () {
    await arpFactory.createGauge(
      1,
      owner.address,
      "0x0000000000000000000000000000000000000000",
      false,
      true,
      true
    );
    
    let arp2Address = (await arpHelper.getAllARPs(0))[1]
    arp2 = ARP.attach(arp2Address)
    console.log("arp===>", arp2Address, arp2.address)
    expect(arp2Address).to.equal(arp2.address)

  });

  it("8) create protocol on percentages", async function () {
    expect((await arp2.protocolInfo(2)).amountPayable).to.equal(0)
    expect((await arp2.protocolInfo(2)).amountReceivable).to.equal(0)
    expect((await arp2.protocolInfo(2)).periodReceivable).to.equal(0)
    expect((await arp2.protocolInfo(2)).periodPayable).to.equal(0)
    expect((await arp2.protocolInfo(2)).startPayable).to.equal(0)
    expect((await arp2.protocolInfo(2)).startReceivable).to.equal(0)
    expect(await arp2.addressToProtocolId(owner3.address)).to.equal(0)
    await expect( arpHelper.ownerOf(2)).to.be.reverted

    await arp2.updateProtocol(
      owner3.address,
      ust.address,
      [1000,3000,0,2000,3000,0,0],
      0,
      0,
      0,
      "link_to_media",
      "description"
    )

    console.log("protocolInfo============>", await arp2.protocolInfo(2))
    expect((await arp2.protocolInfo(2)).amountPayable).to.equal(2000)
    expect((await arp2.protocolInfo(2)).amountReceivable).to.equal(1000)
    expect((await arp2.protocolInfo(2)).periodReceivable).to.equal(3000)
    expect((await arp2.protocolInfo(2)).periodPayable).to.equal(3000)
    expect((await arp2.protocolInfo(2)).startPayable).to.not.equal(0)
    expect((await arp2.protocolInfo(2)).startReceivable).to.not.equal(0)
    expect(await arp2.addressToProtocolId(owner3.address)).to.equal(2)
    expect(await arpHelper.ownerOf(2)).to.equal(owner3.address)

  });

  it("9) autocharge", async function () {
    await ust.approve(arp2.address, 10000)
    await arp2.notifyReward(ust.address, 10000)
    
    await arp2.notifyDebt(ust.address, 10000)

    console.log("dueReceivable before=========>", await arpNote.getDueReceivable(arp2.address, 2, 0))
    expect((await arpNote.getDueReceivable(arp2.address, 2, 0))[0]).to.equal(1000)
    // expect((await arpNote.getDueReceivable(arp2.address, 2, 0))[2]).to.equal(-2997)

    console.log("duePayable before=========>", await arpNote.getDuePayable(arp2.address, 2, 0))
    expect((await arpNote.getDuePayable(arp2.address, 2, 0))[0]).to.equal(2000)
    // expect((await arpNote.getDuePayable(arp2.address, 2, 0))[2]).to.equal(-2997)

    // increase time
    await network.provider.send("evm_increaseTime", [3001])
    await network.provider.send("evm_mine")

    console.log("dueReceivable after=========>", await arpNote.getDueReceivable(arp2.address, 2, 0))
    expect((await arpNote.getDueReceivable(arp2.address, 2, 0))[0]).to.equal(1000)
    expect((await arpNote.getDueReceivable(arp2.address, 2, 0))[2]).gte(1)

    await ust.connect(owner3).approve(arp2.address, 1000);
    await arp2.connect(owner3).autoCharge([2], 0)

    console.log("dueReceivable after autocharge=========>", await arpNote.getDueReceivable(arp2.address, 2, 0))
    expect((await arpNote.getDueReceivable(arp2.address, 2, 0))[0]).to.equal(10)
    expect((await arpNote.getDueReceivable(arp2.address, 2, 0))[2]).lte(10)

  });

  it("10) Pay Invoice Payable", async function () {
    console.log("duePayable after=========>", await arpNote.getDuePayable(arp2.address, 2, 0))
    expect((await arpNote.getDuePayable(arp2.address, 2, 0))[0]).to.equal(2000)
    expect((await arpNote.getDuePayable(arp2.address, 2, 0))[2]).gte(1)

    console.log("arp balance before============>", await ust.balanceOf(arp2.address))
    expect(await ust.balanceOf(arp2.address)).to.equal(10000 + 990)
    expect(await ust.balanceOf(arpHelper.address)).to.equal(40)

    const user_balance_before = await ust.balanceOf(owner3.address)
    console.log("user balance before============>", user_balance_before)

    await ust.connect(owner).approve(arp2.address, 2000);
    await arp2.payInvoicePayable(2, 0)
    console.log("arp balance after============>", await ust.balanceOf(arp2.address))
    console.log("user balance after============>", await ust.balanceOf(owner3.address))

    console.log("duePayable after autocharge=========>", await arpNote.getDuePayable(arp2.address, 2, 0))
    expect(await ust.balanceOf(owner3.address)).to.equal(user_balance_before.add(1980))
    expect(await ust.balanceOf(arpHelper.address)).to.equal(60)
    expect((await arpNote.getDuePayable(arp2.address, 2, 0))[0]).to.equal(0)
    expect((await arpNote.getDuePayable(arp2.address, 2, 0))[2]).lte(10)

  });

  it("11) create automatic/percentage based ARP", async function () {
    await arpFactory.createGauge(
      1,
      owner.address,
      vava.address,
      true,
      true,
      true
    );
    
    let arp3Address = (await arpHelper.getAllARPs(0))[2]
    arp3 = ARP.attach(arp3Address)
    console.log("arp===>", arp3Address, arp3.address)
    expect(arp3Address).to.equal(arp3.address)

  });

  it("12) create protocol on percentages", async function () {
    expect((await arp3.protocolInfo(3)).amountPayable).to.equal(0)
    expect((await arp3.protocolInfo(3)).amountReceivable).to.equal(0)
    expect((await arp3.protocolInfo(3)).periodReceivable).to.equal(0)
    expect((await arp3.protocolInfo(3)).periodPayable).to.equal(0)
    expect((await arp3.protocolInfo(3)).startPayable).to.equal(0)
    expect((await arp3.protocolInfo(3)).startReceivable).to.equal(0)
    expect(await arp3.addressToProtocolId(owner4.address)).to.equal(0)
    await expect( arpHelper.ownerOf(3)).to.be.reverted

    await arp3.updateProtocol(
      owner4.address,
      ust.address,
      [1000,3000,0,2000,3000,0,0],
      0,
      0,
      0,
      "link_to_media",
      "description"
    )
    
    console.log("protocolInfo============>", await arp3.protocolInfo(3))
    expect((await arp3.protocolInfo(3)).amountPayable).to.equal(2000)
    expect((await arp3.protocolInfo(3)).amountReceivable).to.equal(1000)
    expect((await arp3.protocolInfo(3)).periodReceivable).to.equal(3000)
    expect((await arp3.protocolInfo(3)).periodPayable).to.equal(3000)
    expect((await arp3.protocolInfo(3)).startPayable).to.not.equal(0)
    expect((await arp3.protocolInfo(3)).startReceivable).to.not.equal(0)
    expect(await arp3.addressToProtocolId(owner4.address)).to.equal(3)
    expect(await arpHelper.ownerOf(3)).to.equal(owner4.address)

  });

  it("13) autocharge", async function () {
    await ust.approve(arp3.address, 10000)
    await arp3.notifyReward(ust.address, 10000)
    
    await arp3.notifyDebt(ust.address, 10000)

    console.log("dueReceivable before=========>", await arpNote.getDueReceivable(arp3.address, 3, 0))
    expect((await arpNote.getDueReceivable(arp3.address, 3, 0))[0]).to.equal(0)
    // expect((await arpNote.getDueReceivable(arp3.address, 3, 0))[2]).to.equal(-2997)

    console.log("duePayable before=========>", await arpNote.getDuePayable(arp3.address, 3, 0))
    expect((await arpNote.getDuePayable(arp3.address, 3, 0))[0]).to.equal(0)
    // expect((await arpNote.getDuePayable(arp3.address, 3, 0))[2]).to.equal(-2997)

    // increase time
    await network.provider.send("evm_increaseTime", [3001])
    await network.provider.send("evm_mine")

    console.log("dueReceivable after=========>", await arpNote.getDueReceivable(arp3.address, 3, 0))
    expect((await arpNote.getDueReceivable(arp3.address, 3, 0))[0]).to.equal(0)
    expect((await arpNote.getDueReceivable(arp3.address, 3, 0))[2]).gte(1)

    expect((await arp3.protocolInfo(3)).tokenId).to.equal(0)
    await va.safeTransferFrom(owner.address, owner4.address, 1)
    await arp3.connect(owner4).updateTokenId(1)
    expect((await arp3.protocolInfo(3)).tokenId).to.equal(1)

    await ust.connect(owner4).approve(arp3.address, 1000);
    await arp3.connect(owner4).autoCharge([3], 0)

    console.log("dueReceivable after autocharge=========>", await arpNote.getDueReceivable(arp3.address, 3, 0))
    expect((await arpNote.getDueReceivable(arp3.address, 3, 0))[0]).to.equal(1)
    expect((await arpNote.getDueReceivable(arp3.address, 3, 0))[2]).lte(10)

  });

  it("14) Pay Invoice Payable", async function () {
    const userPercentile = await vavaHelper.getUserPercentile(vava.address, 1)
    console.log("userPercentile=========>", userPercentile)
    console.log("duePayable after=========>", await arpNote.getDuePayable(arp3.address, 3, 0))
    // expect((await arpNote.getDuePayable(arp3.address, 3, 0))[0]).to.equal(userPercentile * 100)
    expect((await arpNote.getDuePayable(arp3.address, 3, 0))[2]).gte(1)

    console.log("arp balance before============>", await ust.balanceOf(arp3.address))
    // expect(await ust.balanceOf(arp3.address)).to.equal(10000 + 792)
    // expect(await ust.balanceOf(arpHelper.address)).to.equal(68)

    const user_balance_before = await ust.balanceOf(owner4.address)
    console.log("user balance before============>", user_balance_before)

    await ust.connect(owner).approve(arp3.address, 2000);
    await arp3.payInvoicePayable(3, 0)
    console.log("arp balance after============>", await ust.balanceOf(arp3.address))
    console.log("user balance after============>", await ust.balanceOf(owner4.address))

    console.log("duePayable after autocharge=========>", await arpNote.getDuePayable(arp3.address, 3, 0))
    // expect(await ust.balanceOf(owner4.address)).to.equal(user_balance_before.add(792))
    // expect(await ust.balanceOf(arpHelper.address)).to.equal(76)
    // expect((await arpNote.getDuePayable(arp3.address, 3, 0))[0]).to.equal(0)
    // expect((await arpNote.getDuePayable(arp3.address, 3, 0))[2]).lte(15)

  });

  it("15) transfer admin note", async function () {
    console.log("dueReceivable before transfer=========>", await arpNote.getDueReceivable(arp.address, 1, 0))
    console.log("note====================>", await arpNote.notes(1))
    await expect(arpNote.ownerOf(1)).to.be.reverted
    const due = (await arpNote.getDueReceivable(arp.address, 1, 0))[0]
    const timer = (await arpNote.getDueReceivable(arp.address, 1, 0))[1]
    expect(due).gt(0)
    expect(timer).gt(0)

    await arpNote.transferDueToNoteReceivable(
      arp.address,
      owner2.address,
      1,
      0
    )
    console.log("dueReceivable after transfer=========>", await arpNote.getDueReceivable(arp.address, 1, 0))
    console.log("note after====================>", await arpNote.notes(1))
    expect(await arpNote.ownerOf(1)).to.equal(owner2.address)
    // expect((await arpNote.notes(1)).due).to.equal(due - due/100)
    // expect((await arpNote.notes(1)).token).to.equal(ust.address)
    // expect((await arpNote.notes(1)).timer).to.equal(timer)
    // expect((await arpNote.notes(1)).protocolId).to.equal(1)
    // expect((await arpNote.notes(1)).arp).to.equal(arp.address)
    
  })

  it("16) claim admin note", async function () {
    console.log("pendingRevenue========>", await arp.pendingRevenue(ust.address))    
    console.log("pendingRevenueFromNote========>", await arpNote.pendingRevenueFromNote(1))    
    expect(await arpNote.pendingRevenueFromNote(1)).to.equal(0)
    await expect(arpNote.claimPendingRevenueFromNote(1)).to.be.reverted;

    await ust.connect(owner2).approve(arp.address, 2000);
    await arp.connect(owner2).autoCharge([1], 0)

    // console.log("pendingRevenueFromNote ========>", await arpNote.pendingRevenueFromNote(1))    
    // expect(await arpNote.pendingRevenueFromNote(1)).to.equal(1980)

    // await arpNote.connect(owner2).claimPendingRevenueFromNote(1)
    // expect(await arpNote.pendingRevenueFromNote(1)).to.equal(0)
    // await expect(arpNote.ownerOf(1)).to.be.reverted

  })

  it("17) transfer user note", async function () {
    console.log("duePayable before transfer=========>", await arpNote.getDuePayable(arp.address, 1, 0))
    console.log("note====================>", await arpNote.notes(2))
    await expect(arpNote.ownerOf(2)).to.be.reverted
    const due = (await arpNote.getDuePayable(arp.address, 1, 0))[0]
    const timer = (await arpNote.getDuePayable(arp.address, 1, 0))[1]
    expect(due).gt(0)
    expect(timer).gt(0)

    await arpNote.connect(owner2).transferDueToNotePayable(
      arp.address,
      owner2.address,
      1,
      0
    )
    console.log("duePayable after transfer=========>", await arpNote.getDuePayable(arp.address, 1, 0))
    console.log("note after====================>", await arpNote.notes(2))
    expect(await arpNote.ownerOf(2)).to.equal(owner2.address)
    expect((await arpNote.notes(2)).due).to.equal(due - due/100)
    expect((await arpNote.notes(2)).token).to.equal(ust.address)
    expect((await arpNote.notes(2)).timer).to.equal(timer)
    expect((await arpNote.notes(2)).protocolId).to.equal(1)
    expect((await arpNote.notes(2)).arp).to.equal(arp.address)

  })

  it("18) claim user note", async function () {
    console.log("pendingRevenue========>", await arp.pendingRevenue(ust.address))    
    console.log("duePayable before claim=========>", await arpNote.getDuePayable(arp.address, 1, 0))

    await ust.approve(arp.address, 2000);
    await arp.notifyReward(ust.address, 2000)
    
    await arpNote.connect(owner2).claimPendingRevenueFromNote(2)
    console.log("duePayable after claim=========>", await arpNote.getDuePayable(arp.address, 1, 0))
    
    await expect(arpNote.ownerOf(2)).to.be.reverted

  })

  it("20) admin bounty", async function () {
    

  })

  it("21) user bounty", async function () {
    

  })
  
});