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
  let worldNote;
  let worldHelper;
  let worldFactory;
  let world;
  let world2;
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
  let plusCodes;

  it("1) deploy contracts", async function () {
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
    
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);
    
    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    ve_dist = await ve_distContract.deploy(ve.address);
    
    const MarketPlaceEvents = await ethers.getContractFactory("MarketPlaceEvents");
    const MarketPlaceCollection = await ethers.getContractFactory("MarketPlaceCollection");
    const MarketPlaceOrders = await ethers.getContractFactory("MarketPlaceOrders");
    const MarketPlaceTrades = await ethers.getContractFactory("MarketPlaceTrades");
    const MarketPlaceHelper = await ethers.getContractFactory("MarketPlaceHelper");
    const StakeMarket = await ethers.getContractFactory("StakeMarket");
    const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
    const SSI = await ethers.getContractFactory("SSI");
    const SponsorFactory = await ethers.getContractFactory("SponsorFactory");
    const TrustBounties = await ethers.getContractFactory("TrustBounties");
    const WorldFactory = await ethers.getContractFactory("WorldFactory");
    const ContentTypes = await ethers.getContractFactory("ContentTypes");
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    const PlusCodes = await ethers.getContractFactory("contracts/Library.sol:PlusCodes")
    let percentile = await Percentile.deploy()
    plusCodes = await PlusCodes.deploy()
    
    const MarketPlaceHelper2 = await ethers.getContractFactory("MarketPlaceHelper2",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    const WorldHelper = await ethers.getContractFactory("WorldHelper",{
      libraries: {
        PlusCodes: plusCodes.address,
      },
    });
    const SponsorNote = await ethers.getContractFactory("SponsorNote",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    const Profile = await ethers.getContractFactory("Profile",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    const WorldNote = await ethers.getContractFactory("WorldNote",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    Vava =  await ethers.getContractFactory("Vava", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    Va =  await ethers.getContractFactory("Va", {
      libraries: {
        Percentile: percentile.address,
      },
    })
    BusinessBribe =  await ethers.getContractFactory("BusinessBribe")
    BusinessGauge =  await ethers.getContractFactory("BusinessGauge")
    const BusinessMinter =  await ethers.getContractFactory("BusinessMinter")

    ssi = await SSI.deploy();
    await ssi.deployed();

    contentTypes = await ContentTypes.deploy();
    await contentTypes.deployed();

    nfticketHelperContract = await ethers.getContractFactory("NFTicketHelper");
    nfticketHelper = await nfticketHelperContract.deploy(
      ust.address,
      contentTypes.address
    );

    nfticketContract = await ethers.getContractFactory("NFTicket");
    nfticket = await nfticketContract.deploy(ust.address, nfticketHelper.address);

    businessMinter = await BusinessMinter.deploy(
      nfticket.address,
      "0x0000000000000000000000000000000000000000"
    );
    
    profile = await Profile.deploy(
      owner.address,
      "0x0000000000000000000000000000000000000000", 
      ssi.address 
    );
    await profile.deployed();

    trustBounties = await TrustBounties.deploy(
      "0x0000000000000000000000000000000000000000", 
      businessMinter.address
    );
    await trustBounties.deployed();
    
    worldNote = await WorldNote.deploy(
      businessMinter.address,
      profile.address,
      trustBounties.address,
      "0x0000000000000000000000000000000000000000", 
      ssi.address
    );
    await worldNote.deployed();
    
    worldHelper = await WorldHelper.deploy(
      ust.address,
      worldNote.address,
      contentTypes.address,
      "0x0000000000000000000000000000000000000000",
    );
    await worldHelper.deployed();

    worldFactory = await WorldFactory.deploy(
      worldNote.address,
      worldHelper.address,
      ssi.address
    )
    await worldFactory.deployed()
    
    // set ups
    await contentTypes.addContent("nsfw")
    await worldNote.setFactory(worldFactory.address)
    await businessMinter.updateVes(
      [ve.address],
      [ve_dist.address],
      true
    );
    await businessMinter.updateContracts(
      ve.address,
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000"
    );
    await ve_dist.setDepositor(businessMinter.address)
    await businessMinter.initialize(ethers.BigNumber.from("1000000000000000000000000000"))

    await ssi.setProfile(profile.address);
    await trustBounties.updateVes(ve.address, true);
    await trustBounties.updateWhitelistedTokens([ust.address], true);
    
    // checks
    expect(profile.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(trustBounties.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(businessMinter.address).to.not.equal("0x0000000000000000000000000000000000000000");

  });
  
  it("2) print pluscode info", async function () {
    console.log("plusCodes====================>", plusCodes.address)
    console.log("getGlocChars=================>", await plusCodes.getGlocChars())
    console.log("generateExtensions===========>", await plusCodes.generateExtensions())
    console.log("getExtensionsRow===========>", await plusCodes.getExtensionsRow(0))
  
  });

  it("3) create world", async function () {
    // create profile
    await profile.createProfile("Tepa")
    await profile.connect(owner2).createProfile("Tetevi")
    console.log("profile==============>", await profile.profileInfo(1))

    await worldFactory.createGauge(
      1,
      owner.address,
      "gboto",
      "http://link-to-gboto.com",
      "gboto description"
    )

    await worldFactory.connect(owner2).createGauge(
      2,
      owner2.address,
      "gboto2",
      "http://link-to-gboto2.com",
      "gboto2 description"
    )

    let worldAddress = (await worldNote.getAllWorlds(0))[0]
    let worldAddress2 = (await worldNote.getAllWorlds(0))[1]
    const World = await ethers.getContractFactory("World");
    world = World.attach(worldAddress)
    world2 = World.attach(worldAddress2)
    expect(world.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(world2.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(world.address).to.equal(worldAddress);
    expect(world2.address).to.equal(worldAddress2);

    await expect(worldHelper.connect(owner2).mint(
      owner.address, 
      world2.address, 
      0,
      ["f","f","r","3"], 
      ["7","6","g","8"],
      ["27"]
    )).to.be.reverted
    
    await worldHelper.updateTimeFrame(1,0) // update to 1 week and minColor
    await worldHelper.connect(owner2).mint(
      owner.address, 
      world2.address, 
      0,
      ["6","f","r","3"], 
      ["7","6","g","8"],
      ["27"]
    )

    console.log("codeInfo====================>", await worldHelper.codeInfo(1))
    console.log("registeredTo====================>", await worldHelper.registeredTo("6fr376g8+27"))
    console.log("registeredCodes====================>", await worldHelper.registeredCodes("6fr3","76g8"))
  });

  it("4) vote", async function () {
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

    // mint ssid
    await ssi.generateIdentityProof(owner.address,1,1,86700 * 7,"ssid","tepa")
    await ssi.updateSSID(1,2)
    await profile.updateSSID(1)

    expect((await worldNote.votes(world.address)).likes).to.equal(0)
    expect((await worldNote.votes(world.address)).dislikes).to.equal(0)
    expect(await worldNote.voted(1, world.address)).to.equal(0)
    expect(await worldNote.percentiles(world.address)).to.equal(0)

    await worldNote.vote(world.address, 1, true)

    console.log("votes==============>", await worldNote.votes(world.address))
    console.log("voted==============>", await worldNote.voted(1, world.address))
    console.log("percentiles========>", await worldNote.percentiles(world.address))
    console.log("color==============>", await worldNote.getGaugeNColor(1))

    expect((await worldNote.votes(world.address)).likes).to.equal(1)
    expect((await worldNote.votes(world.address)).dislikes).to.equal(0)
    expect(await worldNote.voted(1, world.address)).to.equal(1)
    expect(await worldNote.percentiles(world.address)).to.equal(50)
    expect((await worldNote.getGaugeNColor(1))[1]).to.equal(1)

    await worldNote.vote(world.address, 1, false)

    expect((await worldNote.votes(world.address)).likes).to.equal(0)
    expect((await worldNote.votes(world.address)).dislikes).to.equal(1)
    expect(await worldNote.voted(1, world.address)).to.equal(-1)
    expect(await worldNote.percentiles(world.address)).to.equal(50)
    expect((await worldNote.getGaugeNColor(1))[1]).to.equal(1)

  });

  it("5) code's attached world falls below minColor", async function () {
    // attempt to transfer token to owner2 when owner's world is not below minColor and time has not passed
    expect(await worldHelper.ownerOf(1)).to.equal(owner.address)
    await worldHelper.mint(
      owner2.address, 
      world.address, 
      0,
      ["6","f","r","3"], 
      ["7","6","g","8"],
      ["27"]
    )
    expect(await worldHelper.ownerOf(1)).to.equal(owner.address) // fails to transfer to owner2

    await worldHelper.updateTimeFrame(1,1) // update minColor to bronze

    await expect(worldHelper.connect(owner2).mint(
      owner.address, 
      world2.address, 
      0,
      ["6","f","r","3"], 
      ["7","6","g","8"],
      ["27"]
    )).to.be.reverted // reverts because world minColor is lower than bronze
    
    expect(await worldHelper.ownerOf(1)).to.equal(owner.address)
    // transfers token to owner2 since owner's world is below bronze
    await worldHelper.mint(
      owner2.address, 
      world.address, 
      0,
      ["6","f","r","3"], 
      ["7","6","g","8"],
      ["27"]
    )
    expect(await worldHelper.ownerOf(1)).to.equal(owner2.address)

    // increase time
    await network.provider.send("evm_increaseTime", [86400*3])
    await network.provider.send("evm_mine")

    // attempt to mint new token after last one expires
    expect(await worldHelper.tokenId()).to.equal(2)
    await worldHelper.mint(
      owner2.address, 
      world.address, 
      0,
      ["6","f","r","3"], 
      ["7","6","g","8"],
      ["27"]
    )
    console.log("token id=============>", await worldHelper.tokenId())
    expect(await worldHelper.tokenId()).to.equal(3)
    expect(await worldHelper.ownerOf(2)).to.equal(owner2.address) // fails to transfer to owner2
    
    console.log("codeInfo====================>", await worldHelper.codeInfo(1))
    console.log("registeredTo====================>", await worldHelper.registeredTo("6fr376g8+27"))
    console.log("registeredCodes====================>", await worldHelper.registeredCodes("6fr3","76g8"))

  });

  // it("4) create audit", async function () {
  //   await auditor.updateProtocol(
  //     owner2.address,
  //     ust.address,
  //     [10, 86400, 0],
  //     0,
  //     5,
  //     0,
  //     "https://link-to-media.com",
  //     "auditor's description of protocol"
  //   )
  //   console.log("protocol id=======================>", await auditor.addressToProtocolId(owner2.address))
  //   console.log("protocol=======================>", await auditor.protocolInfo(1))
  //   console.log("dueReceivable====================>", await auditorNote.getDueReceivable(auditor.address, owner2.address, 0))
  //   expect(await auditor.addressToProtocolId(owner2.address)).to.equal(1)
  //   expect((await auditor.protocolInfo(1)).amountReceivable).to.equal(10)
  //   expect((await auditor.protocolInfo(1)).periodReceivable).to.equal(86400)
  //   expect((await auditor.protocolInfo(1)).rating).to.equal(5)
  //   expect(await auditor.media(1)).to.equal("https://link-to-media.com")
  //   expect(await auditor.description(1)).to.equal("auditor's description of protocol")
  //   expect((await auditorNote.getDueReceivable(auditor.address, owner2.address, 0))[0]).to.equal(0)

  //   // increase time
  //   await network.provider.send("evm_increaseTime", [86400])
  //   await network.provider.send("evm_mine")

  //   expect((await auditorNote.getDueReceivable(auditor.address, owner2.address, 0))[0]).to.equal(10)
  // });

  // it("5) create audit with identity", async function () {
  //   await auditor.updateValueNameNCode(
  //     0,
  //     false,
  //     false,
  //     "testify_age",
  //     "gt_18",
  //   )

  //   await expect(auditor.updateProtocol(
  //     owner.address,
  //     ust.address,
  //     [10, 86400, 0],
  //     0,
  //     5,
  //     0,
  //     "https://link-to-media.com",
  //     "auditor's description of protocol"
  //   )).to.be.reverted

  //   await auditor.updateProtocol(
  //     owner.address,
  //     ust.address,
  //     [10, 86400, 0],
  //     1,
  //     5,
  //     0,
  //     "https://link-to-media.com",
  //     "auditor's description of protocol"
  //   )
  //   console.log("protocol id=======================>", await auditor.addressToProtocolId(owner.address))
  //   console.log("protocol=======================>", await auditor.protocolInfo(2))
  //   console.log("dueReceivable====================>", await auditorNote.getDueReceivable(auditor.address, owner.address, 0))

  // });

  // it("6) autocharge", async function () {
  //   expect((await auditorNote.getDueReceivable(auditor.address, owner2.address, 0))[0]).to.equal(10)
  //   await ust.connect(owner2).approve(auditor.address, 10)
  //   await auditor.connect(owner2).autoCharge(
  //       [owner2.address], 
  //       0, 
  //       0
  //   )
  //   expect((await auditorNote.getDueReceivable(auditor.address, owner2.address, 0))[0]).to.equal(0)
  // });

  // it("7) update owner", async function () {
  //   await auditorHelper.connect(owner2).transferFrom(owner2.address, owner3.address, 1)
  //   expect((await auditor.protocolInfo(1)).owner).to.equal(owner2.address)
  //   await auditor.connect(owner3).updateOwner(owner2.address, 1)
  //   console.log("owner2===========>", owner2.address)
  //   expect((await auditor.protocolInfo(1)).owner).to.equal(owner3.address)

  // });

  // it("8) update bounty", async function () {
  //     // create bounty
  //   expect((await auditor.protocolInfo(1)).bountyId).to.equal(0)
  //   await trustBounties.connect(owner3).createBounty(
  //     ust.address,
  //     ve.address,
  //     owner.address,
  //     0,
  //     10,
  //     86700 * 7,
  //     0,
  //     false,
  //     0
  //   )
  //   await auditor.connect(owner3).updateBounty(1)
  //   console.log("bounty after===============>", await auditor.protocolInfo(1))
  //   expect((await auditor.protocolInfo(1)).bountyId).to.equal(1)

  // });
  
  // it("9) transfer due to note", async function () {
  //   expect((await auditorNote.notes(auditor.address,1)).due).to.equal(0)
  //   expect((await auditorNote.notes(auditor.address,1)).timer).to.equal(0)
  //   expect((await auditorNote.notes(auditor.address,1)).tokenId).to.equal(0)
  //   expect((await auditorNote.notes(auditor.address,1)).protocol).to.equal("0x0000000000000000000000000000000000000000")
  //   expect(await auditorNote.adminNotes(auditor.address,owner.address)).to.equal(0)
  //   await auditorNote.transferDueToNoteReceivable(
  //     auditor.address,
  //     owner2.address, 
  //     owner.address, 
  //     1
  //   )

  //   console.log("notes=================>", await auditorNote.notes(auditor.address,1))
  //   console.log("adminNotes=================>", await auditorNote.adminNotes(auditor.address,owner.address))
  //   expect((await auditorNote.notes(auditor.address,1)).due).to.equal(10)
  //   expect((await auditorNote.notes(auditor.address,1)).timer).to.not.equal(0)
  //   expect((await auditorNote.notes(auditor.address,1)).tokenId).to.equal(1)
  //   expect((await auditorNote.notes(auditor.address,1)).protocol).to.equal(owner.address)
  //   expect(await auditorNote.adminNotes(auditor.address,owner.address)).to.equal(1)
  // });
  
  // it("10) claim pending revenue from note", async function () {
  //   // increase time
  //   await network.provider.send("evm_increaseTime", [86400])
  //   await network.provider.send("evm_mine")

  //   await ust.approve(auditor.address, 10)
  //   await auditor.updateAutoCharge(true);
  //   await auditor.autoCharge(
  //       [owner.address], 
  //       0, 
  //       0
  //   )
  //   console.log("pending from note==================>", await auditorNote.pendingRevenueFromNote(auditor.address, 1))
  //   userBalanceBefore = await ust.balanceOf(owner2.address)
  //   expect(await auditorNote.pendingRevenueFromNote(auditor.address, 1)).to.equal(10)
  //   await auditorNote.connect(owner2).claimPendingRevenueFromNote(auditor.address, 1)
  //   expect(await auditorNote.pendingRevenueFromNote(auditor.address, 1)).to.equal(0)
  //   expect(await ust.balanceOf(owner2.address)).to.equal(userBalanceBefore.add(10))

  // });

  // it("12) Create and Add sponsor", async function () {
  //   await sponsorNote.setFactory(sponsorFactory.address)
  //   await sponsorFactory.createGauge(
  //     1,
  //     owner.address,
  //     "my card",
  //     "https://link.to.avatar.com",
  //     "my sponsor card",
  //   )
  //   let sponsorAddress = (await sponsorNote.getAllSponsors(0))[0]
  //   console.log("sponsor=============>", sponsorAddress)
  //   const Sponsor = await ethers.getContractFactory("Sponsor");
  //   sponsor = Sponsor.attach(sponsorAddress)
  //   await sponsor.updateContents("nsfw", true)
  //   expect(sponsor.address).to.equal(sponsorAddress)

  // })

  // it("13) Sponsor tag", async function () {
  //   // set up price
  //   await auditorHelper.updatePricePerAttachMinutes(1)

  //   await ust.approve(auditorHelper.address, 100);
  //   await auditorHelper.sponsorTag(
  //     sponsor.address,
  //     10, 
  //     "devices", 
  //     "https://link-to-media.com"
  //   )

  //   expect((await auditorHelper.scheduledMedia(1)).amount).to.equal(10)
  //   expect((await auditorHelper.scheduledMedia(1)).message).to.equal("https://link-to-media.com")
  //   console.log("scheduledMedia============>", await auditorHelper.scheduledMedia(1))
      
  //   await auditorHelper.updateExcludedContent("devices", "nsfw", true)
  //   await ust.approve(auditorHelper.address, 10);
  //   await expect(auditorHelper.sponsorTag(
  //     sponsor.address,
  //     10, 
  //     "devices", 
  //     "https://link-to-media.com"
  //   )).to.be.reverted
    
  // })
  
  // it("14) delete protocol", async function () {
  //   expect(await auditor.addressToProtocolId(owner3.address)).to.equal(1)
  //   expect((await auditor.protocolInfo(1)).amountReceivable).to.equal(10)
  //   expect((await auditor.protocolInfo(1)).owner).to.equal(owner3.address)
    
  //   await auditor.deleteProtocol(owner3.address)
    
  //   expect(await auditor.addressToProtocolId(owner3.address)).to.equal(0)
  //   expect((await auditor.protocolInfo(1)).amountReceivable).to.equal(0)
  //   expect((await auditor.protocolInfo(1)).owner).to.equal("0x0000000000000000000000000000000000000000")
  // });

});
