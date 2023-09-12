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
  let ballerNft;
  let owner;
  let owner2;
  let owner3;

  it("deploy ballers NFT", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    Baller = await ethers.getContractFactory("BallerNFT");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();
    
    ballerNft = await Baller.deploy(
      ust.address, 
      '', 
      "0x0000000000000000000000000000000000000000"
    );
    await ballerNft.deployed();

  });

  it("mint", async function () {
    console.log(await ballerNft.getUserTicketsPagination(owner2.address,0,0));
    expect((await ballerNft.getUserTicketsPagination(owner2.address,0,0)).length).to.equal(0);
    expect(await ballerNft.totalTokenHolders()).to.equal(0);
    expect(await ballerNft.tokenHolders(owner2.address)).to.equal(0);
    expect(await ballerNft.pendingRound(0)).to.equal(0);
    await ust.approve(ballerNft.address, 20);
    await ballerNft.batchMint(owner2.address, 10, 2);
    console.log(await ballerNft.getUserTicketsPagination(owner2.address,0,0));
    console.log(await ballerNft.ticketInfo_(1));
    expect((await ballerNft.getUserTicketsPagination(owner2.address,0,0)).length).to.equal(2);
    expect(await ballerNft.balanceOf(owner2.address, 1)).to.equal(1);
    expect(await ballerNft.balanceOf(owner2.address, 2)).to.equal(1);
    expect(await ballerNft.totalTokenHolders()).to.equal(1);
    expect(await ballerNft.tokenHolders(owner2.address)).to.equal(2);
    expect(await ballerNft.pendingRound(0)).to.equal(20);
    
    // try with not admin
    expect(await ballerNft.tokenHolders(owner.address)).to.equal(0);
    expect(await ballerNft.totalTokenHolders()).to.equal(1);
    await ust.approve(ballerNft.address, 20);
    await expect(ballerNft.connect(owner2).batchMint(owner.address, 10, 2))
    .to.be.reverted;
    expect(await ballerNft.tokenHolders(owner.address)).to.equal(0);
    expect(await ballerNft.totalTokenHolders()).to.equal(1);
    expect(await ballerNft.pendingRound(0)).to.equal(20);
    expect(await ballerNft.pendingRound(1)).to.equal(0);
  });

  it("claim round", async function () {
    console.log("balance_1", await ust.balanceOf(owner2.address));
    console.log("percentile_1", await ballerNft._percentile());
    console.log("pending_1", await ballerNft.pendingRound(0));
    await ballerNft.claimPendingBalance(1);
    console.log("percentile_2", await ballerNft._percentile());
    console.log("pending_2", await ballerNft.pendingRound(0));
    console.log("should add pending_1 to balance_1 if percentile_2 <= userPercentile 50",
    await ust.balanceOf(owner2.address));
  });

  it("attach", async function () {
    expect((await ballerNft.ticketInfo_(1)).owner).to.equal(owner2.address);
    expect((await ballerNft.ticketInfo_(2)).owner).to.equal(owner2.address);
    await ballerNft.connect(owner2).batchAttach([1,2], 10, owner.address);
    expect((await ballerNft.ticketInfo_(1)).lender).to.equal(owner.address);
    expect((await ballerNft.ticketInfo_(2)).lender).to.equal(owner.address);

    // transferring attached token should fail
    await expect(
      ballerNft.safeTransferFrom(owner2.address, owner.address, 1, 1, 0)
    );
  });

  it("decrease/kill timer", async function () {
    const timer_before = (await ballerNft.ticketInfo_(1)).timer;
    await expect(ballerNft.connect(owner2).decreaseTimer(1, 5)).to.be.reverted;
    await ballerNft.decreaseTimer(1, 5);
    expect((await ballerNft.ticketInfo_(1)).timer).to.equal(timer_before.sub(5));

    await ballerNft.killTimer(1);
    expect((await ballerNft.ticketInfo_(1)).timer).to.equal(0);
  });

  it("detach", async function () {
    // transferring attached token should fail
    await expect(
      ballerNft.safeTransferFrom(owner2.address, owner.address, 1, 1, 0)
    );
    // should now be able to detach
    await ballerNft.batchDetach([1]);
    // should now be able to transfer
    expect(await ballerNft.balanceOf(owner.address, 1)).to.equal(0);
    expect(await ballerNft.balanceOf(owner2.address, 1)).to.equal(1);
    await ballerNft.connect(owner2).safeTransferFrom(owner2.address, owner.address, 1, 1, 0)
    expect(await ballerNft.balanceOf(owner.address, 1)).to.equal(1);
    expect(await ballerNft.balanceOf(owner2.address, 1)).to.equal(0);
  });

  it("add sponsor", async function () {
    expect(await ballerNft.sponsoredMessages(1)).to.equal("")
    await ballerNft.addSponsoredMessages(1, "Visit payswap")
    expect(await ballerNft.sponsoredMessages(1)).to.equal("Visit payswap")
  });

  it("boosting power", async function () {
    console.log(await ballerNft.boostingPower(1))
    console.log(await ballerNft.boostingPower(2))
  });

});
