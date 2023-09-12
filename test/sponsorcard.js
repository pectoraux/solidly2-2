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
  let ve_underlying;
  let ve;
  let owner;
  let gauge;
  let receiver;
  let owner2;
  let owner3;


  it("deploy sponsorcard factory", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");

    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("10000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("10000000000000000000000000"));
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);

    const SponsorCardFactory = await ethers.getContractFactory("SponsorCardFactory");
    gauges_factory = await SponsorCardFactory.deploy();
    await gauges_factory.deployed();

    await gauges_factory.createGauge(
      ve.address, 
      owner.address,
      "_description",
      "_video_cid",
      "_creative_cid",
      "_cancan_email",
      "_website_link"
    );

  });

  it("addProtocol", async function () {
    const gauge_address = await gauges_factory.last_gauge();
    
    const Gauge = await ethers.getContractFactory("SponsorCard");
    gauge = await Gauge.attach(gauge_address);

    const Receiver = await ethers.getContractFactory("SponsorCardReceiver");
    receiver = await Receiver.deploy(gauges_factory.address, owner.address);
    await receiver.deployed();
    receiver2 = await Receiver.deploy(gauges_factory.address, owner2.address);
    await receiver2.deployed();

    await gauge.connect(owner2).addProtocol(
      receiver.address,
      100,
      100,
      100
    );

    await gauge.addProtocol(
      receiver2.address,
      100,
      1000,
      100
    );
    expect((await gauge.protocolInfo(receiver.address)).amountPayable).to.equal(100);
    expect((await gauge.protocolInfo(receiver.address)).periodPayable).to.equal(100);
    expect((await gauge.protocolInfo(receiver.address)).startPayable).to.equal(0);

    const block = await (await ethers.provider.getBlock()).timestamp;
    expect((await gauge.protocolInfo(receiver2.address)).amountPayable).to.equal(100);
    expect((await gauge.protocolInfo(receiver2.address)).periodPayable).to.equal(1000);
    expect((await gauge.protocolInfo(receiver2.address)).startPayable).to.equal(block+100);
    
  });

  it("updateProtocol", async function () {
    await gauge.updateProtocol(
      receiver.address,
      100,
      1000,
      100
    );
    const block = await (await ethers.provider.getBlock()).timestamp;
    expect((await gauge.protocolInfo(receiver.address)).amountPayable).to.equal(100);
    expect((await gauge.protocolInfo(receiver.address)).periodPayable).to.equal(1000);
    expect((await gauge.protocolInfo(receiver.address)).startPayable).to.equal(block + 100);
  });
  
  it("get due after period", async function () {
    expect(await gauge.getDuePayable(receiver.address)).to.equal(0);
    
    await network.provider.send("evm_increaseTime", [1100])
    await network.provider.send("evm_mine")

    expect(await gauge.getDuePayable(receiver.address)).to.equal(100);
    expect(await gauge.getAllDuePayables()).to.equal(200);

    await network.provider.send("evm_increaseTime", [1000])
    await network.provider.send("evm_mine")

    expect(await gauge.getDuePayable(receiver.address)).to.equal(200);
    expect(await gauge.getAllDuePayables()).to.equal(400);

  });

  it("payInvoicePayable with deposit", async function () {
    expect(await gauges_factory.THRESHOLD1()).to.equal(0);
    expect(await ve_underlying.balanceOf(receiver.address)).to.equal(0);
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(0);
    await expect(gauge.payInvoicePayable(receiver.address)).to.be.reverted;
    const allDue = await gauge.getAllDuePayables()
    await ve_underlying.approve(gauge.address, allDue)
    await gauge.depositAll()
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(allDue);
    await gauge.payInvoicePayable(receiver.address)
    expect(await ve_underlying.balanceOf(receiver.address)).to.equal(200);
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(200);
    expect(await gauges_factory.THRESHOLD1()).to.equal(200);
  }); 

  it("getReward", async function () {
    expect(await gauges_factory.THRESHOLD1()).to.equal(200);
    expect(await ve_underlying.balanceOf(receiver2.address)).to.equal(0);
    await receiver2.getReward(gauge.address);
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(0);
    expect(await ve_underlying.balanceOf(receiver2.address)).to.equal(200);
    expect(await gauges_factory.THRESHOLD1()).to.equal(400);
  });

  it("transferDueToNote", async function () {
    await receiver.transferDueToNote(gauge.address);
    await expect(receiver.transferDueToNote(gauge.address)).to.be.reverted;
    // note is minted
    expect(await gauge.balanceOf(owner.address)).to.equal(1)
    expect(await gauge.getDuePayable(receiver.address)).to.equal(0);
    expect((await gauge.notes(1)).due).to.equal(100);
    expect(await gauge.getAllDuePayables()).to.equal(0);
    expect(await gauge.getNotesDuePayableIdx(1,2)).to.equal(100);
    // fund contract
    allDue = await gauge.getAllDuePayables()
    allDue += await gauge.getNotesDuePayableIdx(1,2)
    await ve_underlying.approve(gauge.address, allDue)
    await expect(gauge.depositAll()).to.be.reverted
    await gauge.depositAllNotes(1,2)
    // cannot claim yet
    await expect(gauge.claimNote(1)).to.be.reverted;
    
    await network.provider.send("evm_increaseTime", [1000])
    await network.provider.send("evm_mine")
    // can now claim
    await gauge.claimNote(1);
    expect((await gauge.notes(1)).due).to.equal(0);
    expect((await gauge.notes(1)).timer).to.equal(0);
    // note is burned
    expect(await gauge.balanceOf(owner.address)).to.equal(0)
    expect(await gauge.getDuePayable(receiver.address)).to.equal(0);
    expect(await gauge.getDuePayable(receiver2.address)).to.equal(100);
    expect(await gauges_factory.THRESHOLD1()).to.equal(500);

    await network.provider.send("evm_increaseTime", [1000])
    await network.provider.send("evm_mine")

    expect(await gauge.getDuePayable(receiver.address)).to.equal(100);
    expect(await gauge.getDuePayable(receiver2.address)).to.equal(200);
    
  });

  it("delete protocol", async function () {
    await expect(gauge.deleteProtocol(receiver.address)).to.be.reverted;
    // fund contract
    const allDue = await gauge.getAllDuePayables()
    await ve_underlying.approve(gauge.address, allDue)
    await gauge.depositAll()

    await receiver.getReward(gauge.address);
    expect(await ve_underlying.balanceOf(receiver.address)).to.equal(300);
    expect(await ve_underlying.balanceOf(receiver2.address)).to.equal(200);

    await gauge.deleteProtocol(receiver.address);
    expect(await gauge.size()).to.equal(1);
    // in addition to permissionary note we have 300+200+100
    expect(await gauges_factory.THRESHOLD1()).to.equal(600); 
  });

  it("withdraw", async function () {
    const before = await ve_underlying.balanceOf(owner.address);
    await gauge.withdrawAll();

    expect(await ve_underlying.balanceOf(owner.address)).to.be.above(before);
  });

  it("claimTicket & Checkwinner", async function () {
    await gauges_factory.claimTicket();
    await gauges_factory.checkWinner(await gauges_factory.round());
    console.log(await gauges_factory.scaled_random());
    console.log(await gauges_factory.THRESHOLD1());
  });

});
