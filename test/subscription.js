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
  let nft;
  let owner2;
  let owner3;


  it("deploy subscription factory", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");

    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("10000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("10000000000000000000000000"));
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);

    const SuperLikeGaugeFactory = await ethers.getContractFactory("SuperLikeGaugeFactory");
    superLikeGaugeFactory = await SuperLikeGaugeFactory.deploy();
    await superLikeGaugeFactory.deployed();

    const MockRandomNumberGenerator = await ethers.getContractFactory("MockRandomNumberGenerator");
    randomNumberGenerator = await MockRandomNumberGenerator.deploy();
    await randomNumberGenerator.deployed();
    
    const SubscriptionFactory = await ethers.getContractFactory("SubscriptionFactory");
    subscriptionFactory = await SubscriptionFactory.deploy(
      owner.address, 
      ve_underlying.address, 
      superLikeGaugeFactory.address,
      randomNumberGenerator.address
    );
    
    await subscriptionFactory.deployed();

    await subscriptionFactory.createNFT(
      "sub",
      false
    )

    const SubscriptionNFT = await ethers.getContractFactory("SubscriptionNFT");
    nft_address = await subscriptionFactory.nft();
    nft = await SubscriptionNFT.attach(nft_address);
    console.log(nft.address)

  });

  it("start & sponsor channel", async function () {
    await subscriptionFactory.startChannel(
        "_channelId",
        owner.address,
        0,
        4,
        0,
        "",
        [4,3,2,1,0,0,0,0,0,0]
    );
    console.log(await subscriptionFactory._lotteries(owner.address))

    await ve_underlying.connect(owner2).approve(nft.address, 100)
    await nft.connect(owner2).batchMessage(
      [owner.address],
      100,
      true,
      'video cid goes here'
    );

    expect(await nft.sponsorFund(owner.address)).to.equal(50)
    expect(await nft.treasury()).to.equal(1)
  
  });

  it("Fund lottery with nft sponsor fund", async function () {

    expect((await subscriptionFactory._lotteries(owner.address)).amountCollectedInCake).to.equal(0)
    await subscriptionFactory.fundWithNFTFund()
    expect((await subscriptionFactory._lotteries(owner.address)).amountCollectedInCake).to.equal(50)
    expect(await nft.sponsorFund(owner.address)).to.equal(0)
    expect(await nft.treasury()).to.equal(1)
    console.log(await nft.getTicketSponsor(owner.address))
  });

  it("Fund lottery with inject funds", async function () {
    await ve_underlying.approve(subscriptionFactory.address, 1)
    await subscriptionFactory.injectFunds(owner.address, 1)
    expect((await subscriptionFactory._lotteries(owner.address)).amountCollectedInCake).to.equal(51)

  });

  it("Fund with valuepool", async function () {


  });

  it("Mint subscriptionNFT ticket", async function () {
    await subscriptionFactory.mintSubscriptionNFT(
        owner.address, 
        owner2.address, 
        1000,
        "owner2@gmail.com"
    )
    expect(await nft.balanceOf(owner2.address, 1)).to.equal(1)
    expect(await nft.getChannelSubCount(1)).to.equal(1000)
    console.log(await nft.ticketInfo_(1))

    await expect(
      subscriptionFactory.mintSubscriptionNFT(
        owner.address, 
        owner3.address, 
        10000,
        "owner2@gmail.com"
    )).to.be.reverted

    await subscriptionFactory.mintSubscriptionNFT(
        owner.address, 
        owner3.address, 
        10000,
        "owner3@gmail.com"
    )
    expect(await nft.balanceOf(owner3.address, 2)).to.equal(1)
    expect((await nft.ticketInfo_(2)).channel).to.equal(owner.address)
    expect(await nft.getChannelSubCount(1)).to.equal(10000)
    console.log(await nft.ticketInfo_(2))

  });

  it("start lottery", async function () {
  let _discountDivisor = "2000";
  let _rewardsBreakdown = ["200", "300", "500", "1500", "2500", "5000"];

  await subscriptionFactory.startLottery(
      86400,
      0,
      _discountDivisor,
      _rewardsBreakdown,
      1000000,
      1000000
    )

    expect(await subscriptionFactory.getNumTicketsAllowed(owner.address, 1)).to.equal(4)
    expect(await subscriptionFactory.getNumTicketsAllowed(owner.address, 2)).to.equal(0)
    
  });
  
  it("buy tickets", async function () {
    console.log(await subscriptionFactory.getUsedFreeTickets(owner.address, 1))
    expect(await subscriptionFactory.getUsedFreeTickets(owner.address, 1)).to.equal(0)
    await subscriptionFactory.connect(owner2).buyTickets(
      owner.address, 
      1,
      [1999999]
    )
    expect(await subscriptionFactory.getUsedFreeTickets(owner.address, 1)).to.equal(1)
    expect(await subscriptionFactory.getNumTicketsAllowed(owner.address, 1)).to.equal(3)

    await subscriptionFactory.connect(owner3).buyTickets(
      owner.address, 
      2,
      [1499999]
    )
    expect(await subscriptionFactory.getUsedFreeTickets(owner.address, 2)).to.equal(0)
    expect(await subscriptionFactory.getNumTicketsAllowed(owner.address, 2)).to.equal(0)
      
    await subscriptionFactory.connect(owner2).buyTickets(
      owner.address, 
      1,
      [1499999, 1234567]
    )
    expect(await subscriptionFactory.getUsedFreeTickets(owner.address, 1)).to.equal(3)
    expect(await subscriptionFactory.getNumTicketsAllowed(owner.address, 1)).to.equal(1)

  });

  it("close lottery", async function () {
    await randomNumberGenerator.setNextRandomResult("1999999");
    await randomNumberGenerator.changeLatestLotteryId(1);
    
    await expect(subscriptionFactory.closeLottery()).to.be.reverted
    await network.provider.send("evm_increaseTime", [86400])
    await network.provider.send("evm_mine")

    await subscriptionFactory.closeLottery()
  }); 

  it("draw final number", async function () {
    await subscriptionFactory.drawFinalNumberAndMakeLotteryClaimable();

    console.log(await subscriptionFactory.viewLottery(owner.address))
    console.log(await randomNumberGenerator.viewRandomNumbers(1, owner.address))

    console.log(await subscriptionFactory.viewUserInfoForLotteryId(
        owner2.address,
        owner.address,
        0,
        10
    ))

    expect(await subscriptionFactory.viewRewardsForTicketId(owner.address, 1, 5)).to.equal(25)
    expect(await subscriptionFactory.viewRewardsForTicketId(owner.address, 1, 4)).to.equal(12)

  });

  it("claim tickets", async function () {
    await subscriptionFactory.connect(owner2).claimTickets(
      owner.address,
      [1],
      [5]
    )
    expect((await subscriptionFactory.viewNumbersAndStatusesForTicketIds([1]))[1][0]).to.equal(true)

  });

  it("superChats", async function () {
    await ve_underlying.connect(owner2).approve(nft.address, 1)
    await nft.connect(owner2).superChat(1,1,"Hey!")
    await nft.superChat(1,0,"Howdie!")
    console.log(await nft.ticketInfo_(1))

  });
  
});
