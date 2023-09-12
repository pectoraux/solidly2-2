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

  it("deploy melted NFT", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    MeltedNFT = await ethers.getContractFactory("MeltedNFT");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();

    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("2000000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
    
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);
    
    const SuperLikeGaugeFactory = await ethers.getContractFactory("SuperLikeGaugeFactory");
    superLikeGaugeFactory = await SuperLikeGaugeFactory.deploy();
    await superLikeGaugeFactory.deployed()

    meltedNFT = await MeltedNFT.deploy(
      ust.address, 
      'meltedNFT'
    );
    await meltedNFT.deployed();

  });

  it("melt = lock 3 token for 1", async function () {
    erc1155 = await ethers.getContractFactory("ERC1155_");
    
    nft = await erc1155.deploy("nft")
    await nft._mintBatch(owner.address, [1,2,3], [1,1,1], 0);

    expect(await meltedNFT.balanceOf(owner.address, 1)).to.equal(0)
    expect(await nft.balanceOf(owner.address, 1)).to.equal(1)
    expect(await nft.balanceOf(owner.address, 2)).to.equal(1)
    expect(await nft.balanceOf(owner.address, 3)).to.equal(1)

    await nft.setApprovalForAll(meltedNFT.address, true);
    await meltedNFT.lockToken(
      owner.address,
      1,
      nft.address,
      [1,2,3],
      [1,1,1]
    )

    expect(await meltedNFT.balanceOf(owner.address, 1)).to.equal(1)
    expect(await nft.balanceOf(owner.address, 1)).to.equal(0)
    expect(await nft.balanceOf(owner.address, 2)).to.equal(0)
    expect(await nft.balanceOf(owner.address, 3)).to.equal(0)

    console.log(await meltedNFT.ticketInfo_(1))
    expect(await meltedNFT.userTokenIds(1,0)).to.equal(1)
    expect(await meltedNFT.actual_tokenIds(1,0)).to.equal(1)
    expect(await meltedNFT.actual_tokenIds(1,1)).to.equal(2)
    expect(await meltedNFT.actual_tokenIds(1,2)).to.equal(3)

    await meltedNFT.setApprovalForAll(meltedNFT.address, true);
    await meltedNFT.unlockToken([1]);

    expect(await meltedNFT.balanceOf(owner.address, 1)).to.equal(0)
    expect(await nft.balanceOf(owner.address, 1)).to.equal(1)
    expect(await nft.balanceOf(owner.address, 2)).to.equal(1)
    expect(await nft.balanceOf(owner.address, 3)).to.equal(1)

  });

  it("fractionalize = lock 1 token for 3", async function () {
    await meltedNFT.lockToken(
      owner.address,
      3,
      nft.address,
      [1],
      [1]
    )

    expect(await nft.balanceOf(owner.address, 1)).to.equal(0)
    expect(await meltedNFT.balanceOf(owner.address, 2)).to.equal(1) 
    expect(await meltedNFT.balanceOf(owner.address, 3)).to.equal(1)
    expect(await meltedNFT.balanceOf(owner.address, 4)).to.equal(1)
    expect((await meltedNFT.ticketInfo_(2)).percentage).to.equal(3333)
    expect((await meltedNFT.ticketInfo_(3)).percentage).to.equal(3333)
    expect((await meltedNFT.ticketInfo_(4)).percentage).to.equal(3333)
    expect(await meltedNFT.userTokenIds(2,0)).to.equal(1)
    expect(await meltedNFT.userTokenIds(3,0)).to.equal(1)
    expect(await meltedNFT.userTokenIds(4,0)).to.equal(1)
    await expect(meltedNFT.actual_tokenIds(2,0)).to.be.reverted

    await meltedNFT.unlockToken([2,3,4])
    expect(await meltedNFT.balanceOf(owner.address, 2)).to.equal(0)
    expect(await meltedNFT.balanceOf(owner.address, 3)).to.equal(0)
    expect(await meltedNFT.balanceOf(owner.address, 4)).to.equal(0)
    expect(await nft.balanceOf(owner.address, 1)).to.equal(1)

  });

  // it("claim round", async function () {
  //   console.log("balance_1", await ust.balanceOf(owner2.address));
  //   await naturalResourceNFT.connect(owner2).claimPendingBalance(1, 100000, 2);
  //   console.log("pending round", await naturalResourceNFT.pendingRound(0));
  //   console.log("randNumberLink", await naturalResourceNFT.randNumberLink());
  // });

  // it("extractResourceFromNFT", async function () {
  //   await superLikeGaugeFactory.createGaugeSingle(ve.address, 0, 0, owner.address)
  //   Gauge = await ethers.getContractFactory("SuperLikeGauge");
  //   gauge = await Gauge.attach(await superLikeGaugeFactory.last_gauge())
  //   await superLikeGaugeFactory.createBadgeNFT("", true)
  //   console.log(await superLikeGaugeFactory.badgeNFT())
  //   await naturalResourceNFT.updateExtractorType((await superLikeGaugeFactory.badgeNFT()), true)
  //   await superLikeGaugeFactory.addIdentityProof(
  //     owner2.address,
  //     "ssid",
  //     "tepa",
  //     gauge.address,
  //     "0x0000000000000000000000000000000000000000"
  //   )
  //   await gauge.mintBadge(
  //     owner2.address, 
  //     10, 
  //     "oxygen", 
  //     "resource"
  //   )
  //   BadgeNFT = await ethers.getContractFactory("BadgeNFT");
  //   badgeNFT = await BadgeNFT.attach(await superLikeGaugeFactory.badgeNFT())
  //   expect((await badgeNFT.ticketInfo_(1)).owner).to.equal(owner2.address)
  //   expect((await badgeNFT.ticketInfo_(1)).factory).to.equal(superLikeGaugeFactory.address)
  //   expect((await badgeNFT.ticketInfo_(1)).gauge).to.equal(gauge.address)
  //   expect((await badgeNFT.ticketInfo_(1)).rating).to.equal(10)
  //   expect((await badgeNFT.ticketInfo_(1)).rating_string).to.equal("oxygen")
  //   expect((await badgeNFT.ticketInfo_(1)).rating_description).to.equal("resource")
    
  //   await naturalResourceNFT.updateValueNameNCode("ssid", 0)
  //   await naturalResourceNFT.connect(owner2).extractResourceFromNFT(
  //     badgeNFT.address,
  //     1
  //   );
    
  //   expect(await naturalResourceNFT.totalSupply_()).to.equal(12)
  //   expect((await naturalResourceNFT.ticketInfo_(3)).owner).to.equal(owner2.address)
  //   expect((await naturalResourceNFT.ticketInfo_(3)).resource).to.equal("oxygen")
  //   expect((await naturalResourceNFT.ticketInfo_(3)).ppm).to.equal(461000)

  //   // should not be able to mint more than on the badge
  //   await expect(
  //     naturalResourceNFT.connect(owner2).extractResourceFromNFT(
  //     badgeNFT.address,
  //     1
  //   )).to.be.reverted;

  //   // should not be able to mint more than allowed per week
  //   await naturalResourceNFT.updateFarmersDivisor(
  //     1,
  //     10
  //   )
  //   await gauge.mintBadge(
  //     owner2.address, 
  //     11, 
  //     "palladium", 
  //     "resource"
  //   )

  //   await expect(
  //     naturalResourceNFT.connect(owner2).extractResourceFromNFT(
  //       badgeNFT.address,
  //       2
  //   )).to.be.reverted;

  //   await network.provider.send("evm_increaseTime", [86400 * 7])
  //   await network.provider.send("evm_mine")
    
  //   await naturalResourceNFT.connect(owner2).extractResourceFromNFT(
  //     badgeNFT.address,
  //     2
  //   );
  //   expect(await naturalResourceNFT.totalSupply_()).to.equal(13)
  //   expect((await naturalResourceNFT.ticketInfo_(13)).owner).to.equal(owner2.address)
  //   expect((await naturalResourceNFT.ticketInfo_(13)).resource).to.equal("palladium")
  //   expect((await naturalResourceNFT.ticketInfo_(13)).ppm).to.equal(1)
    
  // });

  // it("transfer badgeNFT", async function () {
  //   await badgeNFT.connect(owner2).setApprovalForAll(superLikeGaugeFactory.address, true);
  //   expect(await badgeNFT.balanceOf(owner2.address, 1)).to.equal(1)
  //   expect(await badgeNFT.isApprovedForAll(owner2.address, superLikeGaugeFactory.address)).to.equal(true)

  //   await expect(
  //     badgeNFT.connect(owner2).safeTransferFrom(
  //       owner2.address, 
  //       owner3.address,
  //       1,
  //       1,
  //       0x0
  //   )).to.be.reverted;

  //   await gauge.safeTransferFrom(owner2.address, owner3.address, 1)
  //   expect(await badgeNFT.balanceOf(owner2.address, 1)).to.equal(0)
  //   expect(await badgeNFT.balanceOf(owner3.address, 1)).to.equal(1)
  // });

  // it("users with same ssid should map to same identity code", async function () {
  //   await superLikeGaugeFactory.addIdentityProof(
  //     owner3.address,
  //     "ssid",
  //     "tepa",
  //     gauge.address,
  //     "0x0000000000000000000000000000000000000000"
  //   );
  //   await naturalResourceNFT.checkIdentityProof(owner3.address, false)
  //   expect(await naturalResourceNFT.userToIdentityCode(owner2.address))
  //   .to.equal(await naturalResourceNFT.userToIdentityCode(owner3.address))

  //   await superLikeGaugeFactory.addIdentityProof(
  //     owner.address,
  //     "ssid",
  //     "tepas",
  //     gauge.address,
  //     "0x0000000000000000000000000000000000000000"
  //   );
  //   await naturalResourceNFT.checkIdentityProof(owner.address, false)
  //   expect(await naturalResourceNFT.userToIdentityCode(owner2.address))
  //   .to.not.equal(await naturalResourceNFT.userToIdentityCode(owner.address))
    
  // });

  // it("attach", async function () {
  //   expect((await naturalResourceNFT.ticketInfo_(1)).owner).to.equal(owner2.address);
  //   expect((await naturalResourceNFT.ticketInfo_(2)).owner).to.equal(owner2.address);
  //   await naturalResourceNFT.connect(owner2).batchAttach([1,2], 10, owner.address);
  //   expect((await naturalResourceNFT.ticketInfo_(1)).lender).to.equal(owner.address);
  //   expect((await naturalResourceNFT.ticketInfo_(2)).lender).to.equal(owner.address);

  //   // transferring attached token should fail
  //   await expect(
  //     naturalResourceNFT.safeTransferFrom(owner2.address, owner.address, 1, 1, 0)
  //   );
  // });

  // it("decrease/kill timer", async function () {
  //   const timer_before = (await naturalResourceNFT.ticketInfo_(1)).timer;
  //   await expect(naturalResourceNFT.connect(owner2).decreaseTimer(1, 5)).to.be.reverted;
  //   await naturalResourceNFT.decreaseTimer(1, 5);
  //   expect((await naturalResourceNFT.ticketInfo_(1)).timer).to.equal(timer_before.sub(5));

  //   await naturalResourceNFT.killTimer(1);
  //   expect((await naturalResourceNFT.ticketInfo_(1)).timer).to.equal(0);
  // });

  // it("detach", async function () {
  //   // transferring attached token should fail
  //   await expect(
  //     naturalResourceNFT.safeTransferFrom(owner2.address, owner.address, 1, 1, 0)
  //   );
  //   // should now be able to detach
  //   await naturalResourceNFT.batchDetach([1]);
  //   // should now be able to transfer
  //   expect(await naturalResourceNFT.balanceOf(owner.address, 1)).to.equal(0);
  //   expect(await naturalResourceNFT.balanceOf(owner2.address, 1)).to.equal(1);
  //   await naturalResourceNFT.connect(owner2).safeTransferFrom(owner2.address, owner.address, 1, 1, 0)
  //   expect(await naturalResourceNFT.balanceOf(owner.address, 1)).to.equal(1);
  //   expect(await naturalResourceNFT.balanceOf(owner2.address, 1)).to.equal(0);
  // });

  // it("add sponsor", async function () {
  //   expect(await naturalResourceNFT.sponsoredMessages(1)).to.equal("")
  //   await naturalResourceNFT.addSponsoredMessages(1, "Visit payswap")
  //   expect(await naturalResourceNFT.sponsoredMessages(1)).to.equal("Visit payswap")
  // });

  // it("boosting power", async function () {
  //   console.log(await naturalResourceNFT.boostingPower(1))
  //   console.log(await naturalResourceNFT.boostingPower(2))
  // });

});
