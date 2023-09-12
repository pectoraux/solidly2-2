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
  let mim;
  let dai;
  let ve_underlying;
  let late_reward;
  let ve;
  let factory;
  let router;
  let pair;
  let owner;
  let gauge;
  let owner2;
  let owner3;

  it("deploy base coins", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    mim = await token.deploy('MIM', 'MIM', 18, owner.address);
    await mim.mint(owner.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await mim.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await mim.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    dai = await token.deploy('DAI', 'DAI', 18, owner.address);
    await dai.mint(owner.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await dai.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    await dai.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000000"));
    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("10000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("10000000000000000000000000"));
    late_reward = await token.deploy('LR', 'LR', 18, owner.address);
    await late_reward.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);

    await ust.deployed();
    await mim.deployed();
  });

  it("create lock", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("500000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("500000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("495063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("500000000000000000"));
  });

  it("increase lock", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("500000000000000000"));
    await ve.increase_amount(1, ethers.BigNumber.from("500000000000000000"));
    await expect(ve.increase_unlock_time(1, 4 * 365 * 86400)).to.be.reverted;
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("1000000000000000000"));
  });

  it("ve views", async function () {
    const block = await ve.block_number();
    expect(await ve.balanceOfAtNFT(1, block)).to.equal(await ve.balanceOfNFT(1));
    expect(await ve.totalSupplyAt(block)).to.equal(await ve.totalSupply());

    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("1000000000000000000"));
  });


  it("steal NFT", async function () {
    await expect(ve.connect(owner2).transferFrom(owner.address, owner2.address, 1)).to.be.reverted
    await expect(ve.connect(owner2).approve(owner2.address, 1)).to.be.reverted
    await expect(ve.connect(owner2).merge(1, 2)).to.be.reverted
  });


  it("ve merge", async function () {
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(2)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("2000000000000000000"));
    console.log(await ve.totalSupply());
    await ve.merge(2, 1);
    console.log(await ve.totalSupply());
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("1990063075414519385"));
    expect(await ve.balanceOfNFT(2)).to.equal(ethers.BigNumber.from("0"));
    expect((await ve.locked(2)).amount).to.equal(ethers.BigNumber.from("0"));
    expect(await ve.ownerOf(2)).to.equal('0x0000000000000000000000000000000000000000');
    await ve_underlying.approve(ve.address, ethers.BigNumber.from("1000000000000000000"));
    await ve.create_lock(ethers.BigNumber.from("1000000000000000000"), 4 * 365 * 86400);
    expect(await ve.balanceOfNFT(3)).to.above(ethers.BigNumber.from("995063075414519385"));
    expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("3000000000000000000"));
    console.log(await ve.totalSupply());
    await ve.merge(3, 1);
    console.log(await ve.totalSupply());
    expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("1990063075414519385"));
    expect(await ve.balanceOfNFT(3)).to.equal(ethers.BigNumber.from("0"));
    expect((await ve.locked(3)).amount).to.equal(ethers.BigNumber.from("0"));
    expect(await ve.ownerOf(3)).to.equal('0x0000000000000000000000000000000000000000');
  });

  it("confirm ust deployment", async function () {
    expect(await ust.name()).to.equal("ust");
  });

  it("confirm mim deployment", async function () {
    expect(await mim.name()).to.equal("MIM");
  });

  it("deploy BaseV1Factory and test pair length", async function () {
    const BaseV1Factory = await ethers.getContractFactory("BaseV1Factory");
    factory = await BaseV1Factory.deploy();
    await factory.deployed();

    expect(await factory.allPairsLength()).to.equal(0);
  });

  it("deploy BaseV1Router and test factory address", async function () {
    const BaseV1Router = await ethers.getContractFactory("BaseV1Router01");
    router = await BaseV1Router.deploy(factory.address, owner.address);
    await router.deployed();

    expect(await router.factory()).to.equal(factory.address);
  });

  it("deploy pair via BaseV1Factory owner", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const mim_1 = ethers.BigNumber.from("1000000000000000000");
    const dai_1 = ethers.BigNumber.from("1000000000000000000");
    await mim.approve(router.address, mim_1);
    await ust.approve(router.address, ust_1);
    await router.addLiquidity(mim.address, ust.address, true, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.approve(router.address, mim_1);
    await ust.approve(router.address, ust_1);
    await router.addLiquidity(mim.address, ust.address, false, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.approve(router.address, mim_1);
    await dai.approve(router.address, dai_1);
    await router.addLiquidity(mim.address, dai.address, true, mim_1, dai_1, 0, 0, owner.address, Date.now());
    expect(await factory.allPairsLength()).to.equal(3);
  });

  it("deploy pair via BaseV1Factory owner2", async function () {
    const ust_1 = ethers.BigNumber.from("1000000");
    const mim_1 = ethers.BigNumber.from("1000000000000000000");
    const dai_1 = ethers.BigNumber.from("1000000000000000000");
    await mim.connect(owner2).approve(router.address, mim_1);
    await ust.connect(owner2).approve(router.address, ust_1);
    await router.connect(owner2).addLiquidity(mim.address, ust.address, true, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.connect(owner2).approve(router.address, mim_1);
    await ust.connect(owner2).approve(router.address, ust_1);
    await router.connect(owner2).addLiquidity(mim.address, ust.address, false, mim_1, ust_1, 0, 0, owner.address, Date.now());
    await mim.connect(owner2).approve(router.address, mim_1);
    await dai.connect(owner2).approve(router.address, dai_1);
    await router.connect(owner2).addLiquidity(mim.address, dai.address, true, mim_1, dai_1, 0, 0, owner.address, Date.now());
    expect(await factory.allPairsLength()).to.equal(3);
  });

  it("confirm pair for mim-ust", async function () {
    const create2address = await router.pairFor(mim.address, ust.address, true);
    const BaseV1Pair = await ethers.getContractFactory("BaseV1Pair");
    const address = await factory.getPair(mim.address, ust.address, true);
    const allpairs0 = await factory.allPairs(0);
    pair = await BaseV1Pair.attach(address);
    const address2 = await factory.getPair(mim.address, ust.address, false);
    pair2 = await BaseV1Pair.attach(address2);
    const address3 = await factory.getPair(mim.address, dai.address, true);
    pair3 = await BaseV1Pair.attach(address3);

    expect(pair.address).to.equal(create2address);
  });

  it("deploy game factory", async function () {
    const GameFactory = await ethers.getContractFactory("GameFactory");
    gameFactory = await GameFactory.deploy(
      factory.address,
      ve.address
    );
    await gameFactory.deployed();

    await gameFactory.createNFT("", false)
  });

  
  it("add and update game", async function () {
    await gameFactory.updateWhitelist(ust.address, true);

    await gameFactory.addProtocol(
      pair.address,
      ust.address,
      owner.address, 
      1, 
      100,
      0,
      [],
      [],
      "tepa@gmail.com",
      "peace",
      true
    );
    
    expect((await gameFactory.ticketInfo_(owner.address)).owner).to.equal(owner.address)
    expect((await gameFactory.ticketInfo_(owner.address)).pricePerMinute).to.equal(1)
    expect((await gameFactory.ticketInfo_(owner.address)).token).to.equal(ust.address)
    expect((await gameFactory.ticketInfo_(owner.address)).teamShare).to.equal(100)
    expect((await gameFactory.ticketInfo_(owner.address)).creatorShare).to.equal(100)
    expect((await gameFactory.ticketInfo_(owner.address)).totalScore).to.equal(0)
    expect((await gameFactory.ticketInfo_(owner.address)).claimable).to.equal(true)
    expect((await gameFactory.ticketInfo_(owner.address)).cancan_email).to.equal("tepa@gmail.com")
    expect((await gameFactory.ticketInfo_(owner.address)).description).to.equal("peace")

    await gameFactory.updateProtocol(
        owner.address, 
        owner2.address, 
        2, 
        200,
        1,
        [],
        []
    );

    expect((await gameFactory.ticketInfo_(owner.address)).owner).to.equal(owner2.address)
    expect((await gameFactory.ticketInfo_(owner.address)).pricePerMinute).to.equal(2)
    expect((await gameFactory.ticketInfo_(owner.address)).token).to.equal(ust.address)
    expect((await gameFactory.ticketInfo_(owner.address)).teamShare).to.equal(100)
    expect((await gameFactory.ticketInfo_(owner.address)).creatorShare).to.equal(200)
    expect((await gameFactory.ticketInfo_(owner.address)).totalScore).to.equal(1)
    expect((await gameFactory.ticketInfo_(owner.address)).claimable).to.equal(true)
    expect((await gameFactory.ticketInfo_(owner.address)).cancan_email).to.equal("tepa@gmail.com")
    expect((await gameFactory.ticketInfo_(owner.address)).description).to.equal("peace")

    await gameFactory.connect(owner2).updateDescription(owner.address, "peace vv")
    await gameFactory.connect(owner2).updateClaimable(owner.address, false)
    expect((await gameFactory.ticketInfo_(owner.address)).claimable).to.equal(false)
    expect((await gameFactory.ticketInfo_(owner.address)).description).to.equal("peace vv")

  });

  it("buy game minutes", async function () {
    GameNFT = await ethers.getContractFactory("GameNFT")
    gameNFT = await GameNFT.attach(await gameFactory.nft())

    expect(await gameNFT.balanceOf(owner.address, 1)).to.equal(0)
    await gameFactory.createGamingNFT(owner.address, 1)
    expect(await gameNFT.balanceOf(owner.address, 1)).to.equal(1)
    
    expect((await gameNFT.ticketInfo_(1)).gameContract).to.equal('0x0000000000000000000000000000000000000000')
    await ust.approve(gameFactory.address, 20)
    await gameFactory.buyGameTicket(
      1,
      owner.address,
      10
    );
    console.log(await gameNFT.ticketInfo_(1))
    expect((await gameNFT.ticketInfo_(1)).gameContract).to.not.equal('0x0000000000000000000000000000000000000000')

  });

  it("claim reward", async function () {
    // game contract updates score
    await gameNFT.connect(owner).updateScoreNDeadline(1, 10, 1000);
    await expect(gameFactory.claimGameTicket(1)).to.be.reverted;

    // make game rewards claimable
    expect((await gameFactory.ticketInfo_(owner.address)).numPlayers).to.equal(1)
    await gameFactory.connect(owner2).updateClaimable(owner.address, true)
    await gameFactory.claimGameTicket(1)
    expect((await gameFactory.ticketInfo_(owner.address)).numPlayers).to.equal(0)
    expect((await gameFactory.ticketInfo_(owner.address)).totalScore).to.equal(11)
  });

  it("mint naturalResourceNFT", async function() {
    const SuperLikeGaugeFactory = await ethers.getContractFactory("SuperLikeGaugeFactory");
    superLikeGaugeFactory = await SuperLikeGaugeFactory.deploy();
    await superLikeGaugeFactory.deployed()

    NaturalResourceNFT = await ethers.getContractFactory("NaturalResourceNFT")
    naturalResourceNFT = await NaturalResourceNFT.deploy(
      ust.address,
      "naturalResourceNFT",
      '0x0000000000000000000000000000000000000000',
      superLikeGaugeFactory.address
    )
    await naturalResourceNFT.deployed()

    await superLikeGaugeFactory.createGaugeSingle(ve.address, 0, 0, owner.address)
    Gauge = await ethers.getContractFactory("SuperLikeGauge");
    gauge = await Gauge.attach(await superLikeGaugeFactory.last_gauge())
    await superLikeGaugeFactory.createBadgeNFT("", true)
    console.log(await superLikeGaugeFactory.badgeNFT())
    await naturalResourceNFT.updateExtractorType((await superLikeGaugeFactory.badgeNFT()), true)
    await superLikeGaugeFactory.addIdentityProof(
      owner2.address,
      "ssid",
      "tepa",
      gauge.address,
      "0x0000000000000000000000000000000000000000"
    )
    await gauge.mintBadge(
      owner2.address, 
      10, 
      "oxygen", 
      "resource"
    )
    BadgeNFT = await ethers.getContractFactory("BadgeNFT");
    badgeNFT = await BadgeNFT.attach(await superLikeGaugeFactory.badgeNFT())
    expect((await badgeNFT.ticketInfo_(1)).owner).to.equal(owner2.address)
    expect((await badgeNFT.ticketInfo_(1)).factory).to.equal(superLikeGaugeFactory.address)
    expect((await badgeNFT.ticketInfo_(1)).gauge).to.equal(gauge.address)
    expect((await badgeNFT.ticketInfo_(1)).rating).to.equal(10)
    expect((await badgeNFT.ticketInfo_(1)).rating_string).to.equal("oxygen")
    expect((await badgeNFT.ticketInfo_(1)).rating_description).to.equal("resource")
    
    await naturalResourceNFT.updateValueNameNCode("ssid", 0)
    await naturalResourceNFT.connect(owner2).extractResourceFromNFT(
      badgeNFT.address,
      1
    );
    console.log("naturalResourceNFT", await naturalResourceNFT.balanceOf(owner2.address, 1))

  });

  it("mint diamondNFT", async function () {
    DiamondNFT = await ethers.getContractFactory("DiamondNFT")
    diamondNFT = await DiamondNFT.deploy(
      ust.address,
      "diamondNFT",
      '0x0000000000000000000000000000000000000000'
    )
    await diamondNFT.deployed()
    await diamondNFT.updatePriceFactor(
      [30],
      [2]
    )

    await diamondNFT.batchBuy(
      owner2.address,
      3,
      [2,30,2,30,2,30],
      7,
      "myCertId",
      true
    );
    console.log("diamondNFT", await diamondNFT.balanceOf(owner2.address, 1))
    console.log("diamondNFT", await diamondNFT.balanceOf(owner2.address, 2))

  });

  it("mint gemNFT", async function () {
    GemNFT = await ethers.getContractFactory("GemNFT")
    gemNFT = await GemNFT.deploy(ust.address, "gemNFT", diamondNFT.address);
    await gemNFT.deployed()
    await gemNFT.updateNFTLockables(
      '0x0000000000000000000000000000000000000000',
      [7,7],
      [1],
      false
    )
    await diamondNFT.connect(owner2).setApprovalForAll(gemNFT.address, true);
    await gemNFT.connect(owner2).lockToken([1,2], [1,1], 0, 0)
    
    console.log("gemNFT", await gemNFT.balanceOf(owner2.address, 1))
  });

  it("mint from resource", async function () {
    await gameFactory.updateContracts(
      gemNFT.address, 
      diamondNFT.address, 
      naturalResourceNFT.address
    )
    // first the game owner makes the recipe
    await gameFactory.connect(owner2).updateResourceToObject(
      owner.address, 
      1,
      [30,1,2],
      [30,7,2],
      ["oxygen"]
    );
    console.log(await gameFactory.getResourceToObject(owner.address, 1))
    
    // then the player creates a gamingNFT & mints the object
    await gemNFT.connect(owner2).setApprovalForAll(gameFactory.address, true);
    await diamondNFT.connect(owner2).setApprovalForAll(gameFactory.address, true);
    await naturalResourceNFT.connect(owner2).setApprovalForAll(gameFactory.address, true);
    await gameFactory.createGamingNFT(owner2.address, 1)
    await ust.connect(owner2).approve(gameFactory.address, 20)
    await gameFactory.connect(owner2).buyGameTicket(
      2,
      owner.address,
      10
    );

    await expect(gameNFT.nftObjects(2, 0)).to.be.reverted
    await expect(
      gameFactory.connect(owner2).mintObject(
        2, 
        1,
        1,
        [1],
        [1], // user does not have this token
        [1]
    )).to.be.reverted;
    await gameFactory.connect(owner2).mintObject(
      2, 
      1,
      1,
      [1],
      [3],
      [1]
    )
    console.log(await gameNFT.ticketInfo_(2))
    expect(await gameNFT.nftObjects(2, 0)).to.equal(1)
  });

  it("add nfts to enable passage from object to resource", async function () {
    expect(await gameFactory.objectToResource(owner.address, 1)).to.equal(0)
    // user state before update
    expect(await gemNFT.balanceOf(owner2.address, 1)).to.equal(1)
    expect(await diamondNFT.balanceOf(owner2.address, 3)).to.equal(1)
    expect(await naturalResourceNFT.balanceOf(owner2.address, 1)).to.equal(1)
    // factory state before update
    expect(await gemNFT.balanceOf(gameFactory.address, 1)).to.equal(0)
    expect(await diamondNFT.balanceOf(gameFactory.address, 3)).to.equal(0)
    expect(await naturalResourceNFT.balanceOf(gameFactory.address, 1)).to.equal(0)
    // add resources for objects to desintegrate into
    await gameFactory.connect(owner2).updateObjectToResource(
      owner.address,
      1,
      1,
      [1],
      [3],
      [1]
    )
    // user does not have resources anymore
    expect(await gameFactory.objectToResource(owner.address, 1)).to.equal(1)
    expect(await gemNFT.balanceOf(owner2.address, 1)).to.equal(0)
    expect(await diamondNFT.balanceOf(owner2.address, 3)).to.equal(0)
    expect(await naturalResourceNFT.balanceOf(owner2.address, 1)).to.equal(0)
    // factory supply increases
    expect(await gemNFT.balanceOf(gameFactory.address, 1)).to.equal(1)
    expect(await diamondNFT.balanceOf(gameFactory.address, 3)).to.equal(1)
    expect(await naturalResourceNFT.balanceOf(gameFactory.address, 1)).to.equal(1)
  });

  it("desintegrate into resource", async function () {
    expect(await gameNFT.nftObjects(2, 0)).to.equal(1) // nft has object 1

    await gameFactory.connect(owner2).disintegrateObject(2, 1)
    
    expect(await gameNFT.nftObjects(2, 0)).to.equal(0) // nft does not have object 1 anymore
    expect(await gameFactory.objectToResource(owner.address, 1)).to.equal(0)
    // user receives resources
    expect(await gemNFT.balanceOf(owner2.address, 1)).to.equal(1)
    expect(await diamondNFT.balanceOf(owner2.address, 3)).to.equal(1)
    expect(await naturalResourceNFT.balanceOf(owner2.address, 1)).to.equal(1)
    // factory supply reduces
    expect(await gemNFT.balanceOf(gameFactory.address, 1)).to.equal(0)
    expect(await diamondNFT.balanceOf(gameFactory.address, 3)).to.equal(0)
    expect(await naturalResourceNFT.balanceOf(gameFactory.address, 1)).to.equal(0)

  });
  
});
