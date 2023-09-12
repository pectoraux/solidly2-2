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
  let marketPlaceCollection;
  let marketPlaceOrders;
  let marketPlaceTrades;
  let marketPlaceHelper;
  let nft_address;
  let nft_;
  let owner;
  let owner2;
  let owner3;

  it("deploy market place", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    // nfticket = await ethers.getContractFactory("NFTicket");
    // erc1155 = await ethers.getContractFactory("ERC1155_");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();

    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("2000000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
    
    // vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    // ve = await vecontract.deploy(ve_underlying.address);

    // const StakeMarket = await ethers.getContractFactory("StakeMarketVoter");
    // stakeMarket = await StakeMarket.deploy(ve.address);
    // await ve.setVoter(stakeMarket.address);

    // const RSRCNFT = await ethers.getContractFactory('BadgeNFT');
    // rsrcnft = await RSRCNFT.deploy("badgeNFT"); 
    // await rsrcnft.batchMint(
    //   owner.address, 
    //   owner.address, 
    //   1, 
    //   0,
    //   "",
    //   ""
    // );
    // await rsrcnft.deployed();
    
    const MarketPlaceEvents = await ethers.getContractFactory("MarketPlaceEvents");
    const MarketPlaceCollection = await ethers.getContractFactory("MarketPlaceCollection");
    const MarketPlaceOrders = await ethers.getContractFactory("MarketPlaceOrders");
    const MarketPlaceTrades = await ethers.getContractFactory("MarketPlaceTrades");
    const MarketPlaceHelper = await ethers.getContractFactory("MarketPlaceHelper");
    marketPlaceEvents = await MarketPlaceEvents.deploy();
    await marketPlaceEvents.deployed();
    
    marketPlaceCollection = await MarketPlaceCollection.deploy(
      "0x0000000000000000000000000000000000000000", 
      owner.address, 
      owner.address, 
      "0x0000000000000000000000000000000000000000", 
      "0x0000000000000000000000000000000000000000", 
      marketPlaceEvents.address, 
      1,
      100,
      "0x0000000000000000000000000000000000000000", 
    );
    await marketPlaceCollection.deployed();

    marketPlaceOrders = await MarketPlaceOrders.deploy(
      marketPlaceCollection.address, 
      marketPlaceEvents.address, 
      "0x0000000000000000000000000000000000000000", 
      "0x0000000000000000000000000000000000000000", 
    );
    await marketPlaceOrders.deployed();
    
    marketPlaceHelper = await MarketPlaceHelper.deploy(
      marketPlaceCollection.address, 
      marketPlaceEvents.address, 
      marketPlaceOrders.address, 
    );
    await marketPlaceHelper.deployed();

    marketPlaceTrades = await MarketPlaceTrades.deploy(
      marketPlaceCollection.address, 
      marketPlaceEvents.address, 
      marketPlaceOrders.address, 
      marketPlaceHelper.address, 
    );
    await marketPlaceTrades.deployed();
    await marketPlaceHelper.setMarketTrades(marketPlaceTrades.address);

    expect(marketPlaceEvents.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(marketPlaceCollection.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(marketPlaceOrders.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(marketPlaceTrades.address).to.not.equal("0x0000000000000000000000000000000000000000");
    expect(marketPlaceHelper.address).to.not.equal("0x0000000000000000000000000000000000000000");
    // await nftMarket.createNFTicket("nfticket", true);
    // nft_address = await nftMarket.nft_();
    // expect(nft_address).to.not.equal("0x0000000000000000000000000000000000000000");
    
    // tokenMinter = await nfticket.deploy(
    //   nftMarket.address,
    //   "tokenMinter"
    // );
  });
  
  it("add collection", async function () {
    // await tokenMinter.updateDev(nftMarket.address);
    // await nftMarket.addDtoken(ust.address);
    await marketPlaceCollection.addCollection(
      "0x0000000000000000000000000000000000000000", 
      100,
      0,
      0,
      0
    );
    expect((await marketPlaceCollection.addressToCollectionId(owner.address))).to.equal(1);
  //   expect((await nftMarket._collections(owner.address)).tokenMinter).to.equal(tokenMinter.address);
  //   expect((await nftMarket._collections(owner.address)).referrerFee).to.equal(100);
  //   expect((await nftMarket._collections(owner.address)).tradingFee).to.equal(0);
  });

  it("create ask order", async function () {
    await marketPlaceOrders.createAskOrder(
      "uber",
      10,
      0,
      0,
      true,
      0,
      10,
      0,
      ust.address,
      ve_underlying.address,
      0
    );

    // expect((await nftMarket._collections(owner.address)).tokenMinter).to.equal("0x0000000000000000000000000000000000000000");
    // expect((await nftMarket._collections(owner.address)).referrerFee).to.equal(200);
    // expect((await nftMarket._collections(owner.address)).tradingFee).to.equal(100);
  });

  it("buy with contract", async function () {
  //   // await nftMarket.addResourceCollection(rsrcnft.address);
  //   // await rsrcnft.setApprovalForAll(nftMarket.address, true);
  //   // expect((await rsrcnft.balanceOf(owner.address, 1))).to.equal(1);
  //   await nftMarket.createAskOrder(
  //     "footMercato",
  //     100,
  //     0,
  //     0,
  //     true,
  //     0,
  //     [1,2],
  //     [100,200],
  //     -1
  //   );
  //   expect((await nftMarket._askDetails(owner.address, "footMercato")).price).to.equal(100);
  //   expect((await nftMarket._askDetails(owner.address, "footMercato")).transferrable).to.equal(true);
  //   // expect((await nftMarket._askDetails(owner.address, "footMercato")).rsrcTokenId).to.equal(1);
  //   expect((await nftMarket.options(owner.address, "footMercato", 0))).to.equal(1);
  //   expect((await nftMarket.options(owner.address, "footMercato", 1))).to.equal(2);
  //   await expect((nftMarket.options(owner.address, "footMercato", 2))).to.be.reverted;
  //   expect((await nftMarket._getOptionPrices(owner.address, "footMercato", [1,2])).length).to.equal(2);
  //   expect((await nftMarket._getOptionPrices(owner.address, "footMercato", [1,2]))[0]).to.equal(100);
  //   expect((await nftMarket._getOptionPrices(owner.address, "footMercato", [1,2]))[1]).to.equal(200);
  });

  // it("modify ask order", async function () {
  //   await nftMarket.modifyAskOrder(
  //     "footMercato",
  //     150,
  //     0,
  //     0,
  //     false,
  //     0,
  //     [],
  //     [],
  //     -1
  //   );
  //   expect((await nftMarket._askDetails(owner.address, "footMercato")).price).to.equal(150);
  //   expect((await nftMarket._askDetails(owner.address, "footMercato")).transferrable).to.equal(false);
  //   // expect((await nftMarket._askDetails(owner.address, "footMercato")).rsrcTokenId).to.equal(1);
  //   expect((await nftMarket.options(owner.address, "footMercato", 0))).to.equal(1);
  //   expect((await nftMarket.options(owner.address, "footMercato", 1))).to.equal(2);
  //   await expect((nftMarket.options(owner.address, "footMercato", 2))).to.be.reverted;
  //   expect((await nftMarket._getOptionPrices(owner.address, "footMercato", [1,2])).length).to.equal(2);
  //   expect((await nftMarket._getOptionPrices(owner.address, "footMercato", [1,2]))[0]).to.equal(100);
  //   expect((await nftMarket._getOptionPrices(owner.address, "footMercato", [1,2]))[1]).to.equal(200);
  // });

  // it("Buy footMercato with no options", async function () {
  //   nft_ = nfticket.attach(nft_address);
  //   expect((await nft_.totalSupply_())).to.equal(0);
  //   await ust.connect(owner2).approve(nftMarket.address, 150);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     150,
  //     [],
  //     "deuces"
  //   );
  //   expect((await nft_.userTickets_(owner2.address, owner.address, 0))).to.equal(1);
  //   expect((await nft_.getPriceOfTicket(1))).to.equal(150);
  //   expect((await nft_.getNoteOfTicket(1))).to.equal("deuces"); // buyer + merchant's note
  //   expect((await nft_.getTicketStatuses(1))[0]).to.equal(true); // active
  //   expect((await nft_.getTicketStatuses(1))[1]).to.equal(false); // not transferrable
  // });

  // it("Buy footMercato with options 1&2", async function () {
  //   expect((await nft_.totalSupply_())).to.equal(1);
  //   await ust.connect(owner2).approve(nftMarket.address, 450);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     150,
  //     [1,2],
  //     "peace"
  //   );
  //   expect((await nft_.userTickets_(owner2.address, owner.address, 1))).to.equal(2);
  //   expect((await nft_.getPriceOfTicket(2))).to.equal(450);
  //   expect((await nft_.getNoteOfTicket(2))).to.equal("peace"); // buyer + merchant's note
  //   expect((await nft_.getTicketStatuses(2))[0]).to.equal(true); // active
  //   expect((await nft_.getTicketStatuses(2))[1]).to.equal(false); // not transferrable
  // });

  // it("Buy footMercato with option 1", async function () {
  //   expect((await nft_.totalSupply_())).to.equal(2);
  //   await ust.connect(owner2).approve(nftMarket.address, 250);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     150,
  //     [1],
  //     "peace v"
  //   );
  //   expect((await nft_.userTickets_(owner2.address, owner.address, 2))).to.equal(3);
  //   expect((await nft_.getPriceOfTicket(3))).to.equal(250);
  //   expect((await nft_.getNoteOfTicket(3))).to.equal("peace v"); // buyer + merchant's note
  //   expect((await nft_.getTicketStatuses(3))[0]).to.equal(true); // active
  //   expect((await nft_.getTicketStatuses(3))[1]).to.equal(false); // not transferrable
  // });

  // it("Buy footMercato with option 2", async function () {
  //   expect((await nft_.totalSupply_())).to.equal(3);
  //   await ust.connect(owner2).approve(nftMarket.address, 350);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     150,
  //     [2],
  //     "peace vv"
  //   );
  //   expect((await nft_.userTickets_(owner2.address, owner.address, 3))).to.equal(4);
  //   expect((await nft_.getPriceOfTicket(4))).to.equal(350);
  //   expect((await nft_.getNoteOfTicket(4))).to.equal("peace vv"); // buyer + merchant's note
  //   expect((await nft_.getTicketStatuses(4))[0]).to.equal(true); // active
  //   expect((await nft_.getTicketStatuses(4))[1]).to.equal(false); // not transferrable
  // });
  
  // it("Buy token through auction", async function () {
  //   await nftMarket.modifyAskOrder(
  //     "footMercato",
  //     100,
  //     100,
  //     1000,
  //     true,
  //     0,
  //     [],
  //     [],
  //     -1
  //   );
  //   expect((await nft_.totalSupply_())).to.equal(4);
  //   await ust.connect(owner2).approve(nftMarket.address, 300);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     101,
  //     [],
  //     ""
  //   );
  //   expect((await nft_.totalSupply_())).to.equal(4);
  //   await expect(
  //    nftMarket.connect(owner2).processAuction(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     [],
  //     "peace vvv"
  //   )).to.be.reverted;
  //   expect((await nft_.totalSupply_())).to.equal(4);

  //   await network.provider.send("evm_increaseTime", [200])
  //   await network.provider.send("evm_mine")
  //   await nftMarket.connect(owner2).processAuction(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     [],
  //     "peace vvv"
  //   );
  //   expect((await nft_.totalSupply_())).to.equal(5);
  //   expect((await nft_.userTickets_(owner2.address, owner.address, 4))).to.equal(5);
  //   expect((await nft_.getPriceOfTicket(5))).to.equal(101);
  //   expect((await nft_.getNoteOfTicket(5))).to.equal("peace vvv"); // buyer + merchant's note
  //   expect((await nft_.getTicketStatuses(5))[0]).to.equal(true); // active
  //   expect((await nft_.getTicketStatuses(5))[1]).to.equal(true); // transferrable
  //   // turn auction to fixed price
  //   await nftMarket.modifyAskOrder(
  //     "footMercato",
  //     100,
  //     0,
  //     0,
  //     false,
  //     0,
  //     [],
  //     [],
  //     -1
  //   );
  // });

  // it("Buy discounted", async function () {
  //   const date1 = (await nft_.ticketInfo_(1)).date;
  //   const date5 = (await nft_.ticketInfo_(5)).date;
  //   // should revert before discount is applied
  //   expect((await nft_.totalSupply_())).to.equal(5);
  //   await ust.connect(owner2).approve(nftMarket.address, 90);
  //   await expect(
  //     nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     [],
  //     "peace vvi"
  //   )).to.be.reverted; // because only 90 is approved and no discount will be applied to the 100
  //   expect((await nft_.totalSupply_())).to.equal(5);
  //   // discount based on number of tickets bought
  //   await nftMarket.modifyAskOrderPriceReductors(
  //     "footMercato",
  //     1,   
  //     2,
  //     false,
  //     [date1, date5, 1000, 2, 2],
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0]
  //   );

  //   expect((await nft_.totalSupply_())).to.equal(5);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     [],
  //     "peace vvi"
  //   );
  //   expect((await nft_.totalSupply_())).to.equal(6);
  //   expect((await nft_.getPriceOfTicket(6))).to.equal(90);
    
  //   // remove discount and try to buy with 90
  //   await nftMarket.modifyAskOrderPriceReductors(
  //     "footMercato",
  //     1,   
  //     2,
  //     false,
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0]    
  //   );

  //   await ust.connect(owner2).approve(nftMarket.address, 80);
  //   await expect(
  //     nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     [],
  //     "peace vvi"
  //   )).to.be.reverted;
  //   expect((await nft_.totalSupply_())).to.equal(6);

  //   // discount based on cost of tickets bought
  //   await nftMarket.modifyAskOrderPriceReductors(
  //     "footMercato",
  //     1,   
  //     2,
  //     false,
  //     [0,0,0,0,0],    
  //     [date1, date5, 2000, 1000, 20],
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0]
  //   );
    
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     [],
  //     "peace vvi"
  //   );
  //   expect((await nft_.totalSupply_())).to.equal(7);
  //   expect((await nft_.getPriceOfTicket(7))).to.equal(80);
  // });

  // it("Buy with stakeMarket agreement good", async function () {
  //   await ust.connect(owner2).approve(stakeMarket.address, 200);
  //   await nftMarket.connect(owner2).buyWithContract(
  //     stakeMarket.address,
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     200,
  //     150,
  //     [],
  //     ""
  //   );

  //   pool = await stakeMarket.poolForGauge(owner.address, "footMercato")

  //   await ust.approve(stakeMarket.address, 150);
  //   await stakeMarket.lockStake(pool, "")
    
  //   await stakeMarket.unlockStake(pool, 2)
  //   await stakeMarket.connect(owner2).unlockStake(pool, 2)
    
  //   console.log("pool===>", await stakeMarket.gauges(pool))

  //   await nftMarket.connect(owner2).buyWithContract(
  //     stakeMarket.address,
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     200,
  //     150,
  //     [],
  //     ""
  //   );

  // });

  // it("Buy with stakeMarket agreement notgood", async function () {
  //   await ust.connect(owner2).approve(stakeMarket.address, 200);

  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(0)

  //   await nftMarket.connect(owner2).buyWithContract(
  //     stakeMarket.address,
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     200,
  //     150,
  //     [],
  //     ""
  //   );

  //   pool = await stakeMarket.poolForGauge(owner.address, "footMercato")

  //   await ust.approve(stakeMarket.address, 150);
  //   await stakeMarket.lockStake(pool, "")
  //   console.log("pool===>", await stakeMarket.gauges(pool))
    
  //   await stakeMarket.unlockStake(pool, 3)
  //   await stakeMarket.connect(owner2).unlockStake(pool, 3)
    
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(0)

  //   await expect(
  //     nftMarket.connect(owner2).buyWithContract(
  //     stakeMarket.address,
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     200,
  //     150,
  //     [],
  //     ""
  //   )).to.be.reverted;
    
  // });

  // it("create lock", async function () {
  //   await ve_underlying.approve(ve.address, ethers.BigNumber.from("500000000000000000"));
  //   await ve.create_lock(ethers.BigNumber.from("500000000000000000"), 4 * 365 * 86400);
  //   expect(await ve.balanceOfNFT(1)).to.above(ethers.BigNumber.from("495063075414519385"));
  //   expect(await ve_underlying.balanceOf(ve.address)).to.be.equal(ethers.BigNumber.from("500000000000000000"));
  // });

  // it("Buy with stakeMarket disagreement", async function () {
  //   await ust.connect(owner2).approve(stakeMarket.address, 200);

  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(0)

  //   await nftMarket.connect(owner2).buyWithContract(
  //     stakeMarket.address,
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     200,
  //     150,
  //     [],
  //     ""
  //   );

  //   pool = await stakeMarket.poolForGauge(owner.address, "footMercato")

  //   await ust.approve(stakeMarket.address, 150);
  //   await stakeMarket.lockStake(pool, "")
    
  //   await stakeMarket.unlockStake(pool, 2)
  //   await stakeMarket.connect(owner2).unlockStake(pool, 3)

  //   expect((await stakeMarket.gauges(pool)).payment).to.equal(80)

  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(0)

  //   await expect(
  //     nftMarket.connect(owner2).buyWithContract(
  //     stakeMarket.address,
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     200,
  //     150,
  //     [],
  //     ""
  //   )).to.be.reverted;

  //   // settle through voting
  //   expect((await stakeMarket.frozen(pool)).amount).to.equal(0)
  //   await stakeMarket.vote(1, [pool], [5000])
  //   await stakeMarket.updateGauge(pool)
  //   console.log("pool===>", await stakeMarket.gauges(pool))
  //   console.log("weights===>", await stakeMarket.weights(pool))
  //   expect((await stakeMarket.gauges(pool)).stakedSender).to.equal(80)
  //   await stakeMarket.unlockStake(pool, 2)
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(80)
  //   // should be able to buy now
  //   await nftMarket.connect(owner2).buyWithContract(
  //     stakeMarket.address,
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     200,
  //     150,
  //     [],
  //     ""
  //   );

  //   // check voter gains
  //   expect((await stakeMarket.frozen(pool)).amount).to.equal(120)
  //   expect(await stakeMarket.poolVote(1, 0)).to.equal(pool)
  //   await stakeMarket.claimRewards(1)
  //   expect(await stakeMarket.poolVote(1, 0)).to.equal(0)
  //   expect((await stakeMarket.frozen(pool)).token).to.equal(ust.address)

  // });

  // it("Use custom ticketMinter", async function () {
  //   await nftMarket.modifyCollection(
  //     tokenMinter.address,
  //     200,
  //     ust.address
  //   );
    
  //   await ust.connect(owner2).approve(nftMarket.address, 100);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     [],
  //     "deuces"
  //   );
  //   expect(await tokenMinter.totalSupply_()).to.equal(1)
  // });

  // it("Add referral", async function () {
  //   expect(await nftMarket.pendingRevenue(owner3.address)).to.equal(0)
  //   await nftMarket.addReferral(
  //     owner3.address,
  //     owner.address, 
  //     "footMercato"
  //   );
  //   await ust.connect(owner2).approve(nftMarket.address, 100);
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     owner3.address,
  //     "footMercato",
  //     100,
  //     [],
  //     "deuces"
  //   );
  //   expect(await nftMarket.pendingRevenue(owner3.address)).to.equal(1)

  // });

  // it("Get cashback", async function () {
  //   const date1 = (await nft_.ticketInfo_(1)).date;
  //   const date5 = (await nft_.ticketInfo_(5)).date;

  //   // give 10% back to people who bought at least 2 tickets between date1 and date5
  //   await nftMarket.modifyAskOrderPriceReductors(
  //     "footMercato",
  //     2,   
  //     1,
  //     false,
  //     [0,0,0,0,0],
  //     [0,0,0,0,0],
  //     [date1, date5, 1000, 2, 20],
  //     [0,0,0,0,0]
  //   );
    
  //   // credit before
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(0)

  //   await nftMarket.connect(owner2).processCashBack(
  //     owner.address, 
  //     "footMercato",
  //     true,
  //     "footMercato"
  //   );
  //   // credit after
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(130)
    
  //   // give 20% back to people who bought at least 1000$ worth of tickets between date1 and date5
  //    await nftMarket.modifyAskOrderPriceReductors(
  //     "footMercato",
  //     2,   
  //     1,
  //     false,
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0],    
  //     [0,0,0,0,0],    
  //     [date1, date5, 2000, 1000, 2]
  //   );

  //   await nftMarket.connect(owner2).processCashBack(
  //     owner.address, 
  //     "footMercato",
  //     true,
  //     "footMercato"
  //   );
  //   // credit after
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(130 + 260)

  // });

  // it("Burn for credit", async function () {
  //   lpToken = await token.deploy('lpToken', 'lpToken', 6, owner.address);
  //   await lpToken.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));

  //   await nftMarket.updateBurnTokenForCredit(
  //     lpToken.address,
  //     3000
  //   );

  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(390)

  //   await lpToken.connect(owner2).approve(nftMarket.address, 1000);
  //   await nftMarket.connect(owner2).burnForCredit(
  //     owner.address, 
  //     lpToken.address, 
  //     1000,
  //     "footMercato"
  //   );
    
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(390 + 300)

  //   erc721 = await ethers.getContractFactory("ERC721_");
  //   collectionNft = await erc721.deploy('collectionNft', 'cNft');
  //   await collectionNft._safeMint(owner2.address, 1000);
    
  //   await nftMarket.updateBurnTokenForCredit(
  //     collectionNft.address,
  //     30000
  //   );

  //   await collectionNft.connect(owner2).setApprovalForAll(nftMarket.address, true);
  //   await nftMarket.connect(owner2).burnForCredit(
  //     owner.address, 
  //     collectionNft.address, 
  //     1000,
  //     "footMercato"
  //   );
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(690 + 3)

  // });

  // it("Sponsor video & Add sponsor msg", async function () {
  //   Gauge = await ethers.getContractFactory("SuperLikeGauge");
  //   _gauge = await Gauge.deploy(ve.address, 0, nftMarket.address, owner.address);
  //   await _gauge.deployed()
    
  //   const _gaugeCancanEmail = "tepa@gmail.com"
  //   _gauge.updateCancanEmail(_gaugeCancanEmail)
  //   await ust.approve(nftMarket.address, 100)
  //   await nftMarket.sponsorVideo(
  //     owner.address, 
  //     "footMercato", 
  //     _gauge.address,
  //     100
  //   )
  //   expect(await nftMarket.merchantCredits(owner.address, "footMercato")).to.equal(100)
  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(693)  // before merchant credits
  //   await nftMarket.connect(owner2).beforePaymentApplyMerchantCredit(owner.address, "footMercato")

  //   expect(await nftMarket.connect(owner2).getPaymentCredits(
  //     owner.address, 
  //     "footMercato"
  //   )).to.equal(693 + 50)  // after merchant credits

  //   // second application of merchant credit for same video fails
  //   await expect(
  //     nftMarket.connect(owner2).beforePaymentApplyMerchantCredit(
  //       owner.address, 
  //       "footMercato"
  //     )
  //   ).to.be.reverted

  //   // buying a ticket will add sponsor email on ticket
  //   await nftMarket.connect(owner2).buyTokenUsingWBNB(
  //     owner.address,
  //     "0x0000000000000000000000000000000000000000",
  //     "footMercato",
  //     100,
  //     [],
  //     "deuces peace"
  //   );
  //   expect((await tokenMinter.getPriceOfTicket(3))).to.equal(100); // up to 100 of credit applied
  //   expect((await tokenMinter.getNoteOfTicket(3))).to.equal("deuces peace");
  //   expect((await tokenMinter.sponsoredMessages(3))).to.equal(_gaugeCancanEmail);
  // });

  // it("cancelAskOrder", async function () {
  //   await nftMarket.cancelAskOrder("footMercato");
    
  //   expect((await nftMarket._askDetails(owner.address, "footMercato")).price).to.equal(0);
  //   // should not be able to buy video anymore
  //   await ust.connect(owner2).approve(nftMarket.address, 100)
  //   await expect(
  //     nftMarket.connect(owner2).buyTokenUsingWBNB(
  //       owner.address,
  //       "0x0000000000000000000000000000000000000000",
  //       "footMercato",
  //       100,
  //       [],
  //       "deuces peace"
  //     )).to.be.reverted;
  // });

  // it("claimPendingRevenue", async function () {
  //     expect(await nftMarket.pendingRevenue(owner3.address)).to.equal(1)
  //     await nftMarket.connect(owner3).claimPendingRevenue();
  //     expect(await nftMarket.pendingRevenue(owner3.address)).to.equal(0)
  // });
  
  // it("closeCollectionForTradingAndListing", async function () {
  //   expect((await nftMarket._collections(owner.address)).status).to.equal(1);
    
  //   await nftMarket.closeCollectionForTradingAndListing(owner.address);
    
  //   expect((await nftMarket._collections(owner.address)).status).to.equal(2);
  // });

});
